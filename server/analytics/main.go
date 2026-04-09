package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"socialdev/shared/events"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Analytics service: consumes ALL events, persists to event_log + maintains
// per-topic counter in event_counts. Replace with ClickHouse later.
func main() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		env("DB_USER", "postgres"),
		env("DB_PASSWORD", "postgres"),
		env("DB_HOST", "postgres"),
		env("DB_PORT", "5432"),
		env("DB_NAME", "socialdev_analytics"),
	)
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}
	defer pool.Close()

	if err := initSchema(ctx, pool); err != nil {
		log.Fatalf("init schema: %v", err)
	}

	events.Subscribe(ctx, "analytics-service", events.AllTopics, func(ctx context.Context, ev events.Event) error {
		payload, _ := json.Marshal(ev.Data)
		_, err := pool.Exec(ctx, `
			INSERT INTO event_log (event_id, topic, source, occurred_at, payload)
			VALUES ($1, $2, $3, $4, $5)
			ON CONFLICT (event_id) DO NOTHING
		`, ev.EventID, ev.Topic, ev.Source, ev.Timestamp, payload)
		if err != nil {
			return err
		}
		_, err = pool.Exec(ctx, `
			INSERT INTO event_counts (topic, count) VALUES ($1, 1)
			ON CONFLICT (topic) DO UPDATE SET count = event_counts.count + 1
		`, ev.Topic)
		return err
	})

	port := env("PORT", "8087")
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		rows, err := pool.Query(r.Context(), `SELECT topic, count FROM event_counts ORDER BY topic`)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		defer rows.Close()
		out := map[string]int64{}
		for rows.Next() {
			var t string
			var c int64
			rows.Scan(&t, &c)
			out[t] = c
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(out)
	})
	srv := &http.Server{Addr: ":" + port, Handler: mux}
	go func() {
		log.Printf("analytics service listening on :%s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
	log.Println("shutting down analytics service")
	srv.Shutdown(context.Background())
}

func initSchema(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS event_log (
			event_id    TEXT PRIMARY KEY,
			topic       TEXT NOT NULL,
			source      TEXT NOT NULL,
			occurred_at TIMESTAMPTZ NOT NULL,
			payload     JSONB NOT NULL,
			ingested_at TIMESTAMPTZ NOT NULL DEFAULT now()
		);
		CREATE INDEX IF NOT EXISTS idx_event_log_topic ON event_log(topic);
		CREATE TABLE IF NOT EXISTS event_counts (
			topic TEXT PRIMARY KEY,
			count BIGINT NOT NULL DEFAULT 0
		);
	`)
	return err
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

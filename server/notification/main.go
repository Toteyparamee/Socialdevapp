package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"socialdev/shared/events"
)

// Notification service: consumes events from the bus and "delivers" them
// (here: structured log lines simulating push/email). Replace with FCM/SMTP later.
func main() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	topics := []string{
		events.TopicUserRegistered,
		events.TopicProblemCreated,
		events.TopicProblemStatusChanged,
		events.TopicActivityCreated,
		events.TopicActivityJoined,
		events.TopicSubmissionReviewed,
		events.TopicChatMessageSent,
	}

	events.Subscribe(ctx, "notification-service", topics, func(ctx context.Context, ev events.Event) error {
		switch ev.Topic {
		case events.TopicUserRegistered:
			log.Printf("[notify] WELCOME EMAIL → %v (role=%v)", ev.Data["email"], ev.Data["role"])
		case events.TopicProblemCreated:
			log.Printf("[notify] PUSH organizations → new problem %v (%v)", ev.Data["title"], ev.Data["category"])
		case events.TopicProblemStatusChanged:
			log.Printf("[notify] PUSH owner → problem %v status=%v", ev.Data["problem_id"], ev.Data["status"])
		case events.TopicActivityCreated:
			log.Printf("[notify] PUSH students → new activity %v", ev.Data["title"])
		case events.TopicActivityJoined:
			log.Printf("[notify] PUSH teacher → student %v joined %v", ev.Data["student_id"], ev.Data["activity_id"])
		case events.TopicSubmissionReviewed:
			log.Printf("[notify] PUSH student → submission %v reviewed (status=%v score=%v)", ev.Data["submission_id"], ev.Data["status"], ev.Data["score"])
		case events.TopicChatMessageSent:
			log.Printf("[notify] PUSH user %v → new message in room %v", ev.Data["to_user"], ev.Data["room_id"])
		}
		return nil
	})

	// tiny health endpoint
	port := os.Getenv("PORT")
	if port == "" {
		port = "8086"
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	})
	srv := &http.Server{Addr: ":" + port, Handler: mux}
	go func() {
		log.Printf("notification service listening on :%s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
	log.Println("shutting down notification service")
	srv.Shutdown(context.Background())
}

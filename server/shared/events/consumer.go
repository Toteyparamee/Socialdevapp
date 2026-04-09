package events

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"strings"

	"github.com/segmentio/kafka-go"
)

// Handler processes a single event. Returning an error logs but does not retry.
type Handler func(ctx context.Context, ev Event) error

// Subscribe spawns one goroutine per topic with the given consumer group.
// Reads KAFKA_BROKERS env, defaulting to redpanda:9092.
func Subscribe(ctx context.Context, groupID string, topics []string, h Handler) {
	brokers := os.Getenv("KAFKA_BROKERS")
	if brokers == "" {
		brokers = "redpanda:9092"
	}
	addrs := strings.Split(brokers, ",")

	for _, topic := range topics {
		t := topic
		go func() {
			r := kafka.NewReader(kafka.ReaderConfig{
				Brokers:     addrs,
				GroupID:     groupID,
				Topic:       t,
				MinBytes:    1,
				MaxBytes:    10e6,
				StartOffset: kafka.LastOffset,
			})
			defer r.Close()
			log.Printf("[events] subscribed group=%s topic=%s", groupID, t)
			for {
				m, err := r.ReadMessage(ctx)
				if err != nil {
					if ctx.Err() != nil {
						return
					}
					log.Printf("[events] read %s err: %v", t, err)
					continue
				}
				var ev Event
				if err := json.Unmarshal(m.Value, &ev); err != nil {
					log.Printf("[events] unmarshal err: %v", err)
					continue
				}
				if err := h(ctx, ev); err != nil {
					log.Printf("[events] handler err: %v", err)
				}
			}
		}()
	}
}

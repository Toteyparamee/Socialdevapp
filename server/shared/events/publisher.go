package events

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/segmentio/kafka-go"
)

// Default is a process-global publisher; services call Init() once at startup
// then use events.Publish(...) from handlers.
var Default *Publisher

type Publisher struct {
	writer *kafka.Writer
	source string
}

// Init creates the global publisher. Reads KAFKA_BROKERS env (comma-separated).
// If unset or connection fails later, Publish becomes a no-op log line so
// handlers never block on a missing broker.
func Init(source string) {
	brokers := os.Getenv("KAFKA_BROKERS")
	if brokers == "" {
		brokers = "redpanda:9092"
	}
	addrs := strings.Split(brokers, ",")
	w := &kafka.Writer{
		Addr:                   kafka.TCP(addrs...),
		Balancer:               &kafka.LeastBytes{},
		AllowAutoTopicCreation: true,
		BatchTimeout:           50 * time.Millisecond,
		RequiredAcks:           kafka.RequireOne,
		Async:                  true,
	}
	Default = &Publisher{writer: w, source: source}
	log.Printf("[events] publisher ready source=%s brokers=%s", source, brokers)
}

// Publish is the handler-friendly entry point. Safe to call when Default is nil.
func Publish(topic string, data map[string]interface{}) {
	if Default == nil {
		return
	}
	Default.publish(context.Background(), topic, data)
}

func (p *Publisher) publish(ctx context.Context, topic string, data map[string]interface{}) {
	ev := Event{
		Topic:     topic,
		EventID:   uuid.NewString(),
		Source:    p.source,
		Timestamp: time.Now().UTC(),
		Data:      data,
	}
	payload, err := json.Marshal(ev)
	if err != nil {
		log.Printf("[events] marshal err: %v", err)
		return
	}
	if err := p.writer.WriteMessages(ctx, kafka.Message{
		Topic: topic,
		Key:   []byte(ev.EventID),
		Value: payload,
	}); err != nil {
		log.Printf("[events] publish %s err: %v", topic, err)
		return
	}
	log.Printf("[events] published %s id=%s", topic, ev.EventID)
}

func Close() {
	if Default == nil || Default.writer == nil {
		return
	}
	_ = Default.writer.Close()
}

package events

import "time"

// Topic names — must match README "Event Topics" section.
const (
	TopicUserRegistered       = "user.registered"
	TopicProblemCreated       = "problem.created"
	TopicProblemStatusChanged = "problem.status.changed"
	TopicActivityCreated      = "activity.created"
	TopicActivityJoined       = "activity.joined"
	TopicSubmissionReviewed   = "submission.reviewed"
	TopicChatRoomCreated      = "chat.room.created"
	TopicChatMessageSent      = "chat.message.sent"
	TopicImageUploaded        = "image.uploaded"
)

// AllTopics is convenient for consumers (notification/analytics) that subscribe to everything.
var AllTopics = []string{
	TopicUserRegistered,
	TopicProblemCreated,
	TopicProblemStatusChanged,
	TopicActivityCreated,
	TopicActivityJoined,
	TopicSubmissionReviewed,
	TopicChatRoomCreated,
	TopicChatMessageSent,
	TopicImageUploaded,
}

// Event is the envelope for every message on the bus.
type Event struct {
	Topic     string                 `json:"topic"`
	EventID   string                 `json:"event_id"`
	Source    string                 `json:"source"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
}

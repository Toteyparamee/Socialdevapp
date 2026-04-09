package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"chat-service/config"
	"chat-service/models"

	"socialdev/shared/events"

	"github.com/fasthttp/websocket"
	"github.com/golang-jwt/jwt/v5"
	"github.com/valyala/fasthttp"
	fasthttpadaptor "github.com/valyala/fasthttp/fasthttpadaptor"
)

// ── Hub: จัดการ connections ทั้งหมด ──

type Hub struct {
	mu    sync.RWMutex
	conns map[string]map[*websocket.Conn]bool
}

var WsHub = &Hub{
	conns: make(map[string]map[*websocket.Conn]bool),
}

func (h *Hub) Register(userID string, c *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.conns[userID] == nil {
		h.conns[userID] = make(map[*websocket.Conn]bool)
	}
	h.conns[userID][c] = true
	log.Printf("[ws] user %s connected", userID)
}

func (h *Hub) Unregister(userID string, c *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if set, ok := h.conns[userID]; ok {
		delete(set, c)
		if len(set) == 0 {
			delete(h.conns, userID)
		}
	}
	log.Printf("[ws] user %s disconnected", userID)
}

func (h *Hub) SendToUser(userID string, payload any) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	set, ok := h.conns[userID]
	if !ok {
		return
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return
	}

	for c := range set {
		if err := c.WriteMessage(websocket.TextMessage, data); err != nil {
			log.Printf("[ws] write error: %v", err)
		}
	}
}

// ── Event Types ──

type WsEvent struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

type WsIncomingMessage struct {
	ToUserID string `json:"to_user_id"`
	Content  string `json:"content"`
	ImageID  string `json:"image_id"`
}

type WsOutgoingMessage struct {
	Type    string         `json:"type"`
	Message models.Message `json:"message"`
	RoomID  string         `json:"room_id"`
}

// ── Upgrader ──

var upgrader = websocket.FastHTTPUpgrader{
	CheckOrigin: func(ctx *fasthttp.RequestCtx) bool { return true },
}

// HandleWebSocketHTTP — net/http handler that Fiber v3 adaptor can use
func HandleWebSocketHTTP(w http.ResponseWriter, r *http.Request) {
	// We need to go through fasthttp, so this is a no-op placeholder.
	// The actual handler is HandleWebSocketFastHTTP below.
	w.WriteHeader(http.StatusNotImplemented)
}

// HandleWebSocketFastHTTP — raw fasthttp handler for Fiber v3
func HandleWebSocketFastHTTP(ctx *fasthttp.RequestCtx) {
	tokenStr := string(ctx.QueryArgs().Peek("token"))
	if tokenStr == "" {
		ctx.SetStatusCode(401)
		ctx.WriteString("missing token")
		return
	}

	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
		return []byte(config.JWTSecret()), nil
	})
	if err != nil || !token.Valid {
		ctx.SetStatusCode(401)
		ctx.WriteString("invalid token")
		return
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		ctx.SetStatusCode(401)
		return
	}

	var userID string
	switch v := claims["user_id"].(type) {
	case string:
		userID = v
	case float64:
		userID = fmt.Sprintf("%.0f", v)
	}
	if userID == "" {
		ctx.SetStatusCode(401)
		return
	}

	err = upgrader.Upgrade(ctx, func(c *websocket.Conn) {
		defer c.Close()

		WsHub.Register(userID, c)
		defer WsHub.Unregister(userID, c)

		c.WriteJSON(map[string]string{"type": "connected", "user_id": userID})

		for {
			_, raw, err := c.ReadMessage()
			if err != nil {
				break
			}

			var evt WsEvent
			if err := json.Unmarshal(raw, &evt); err != nil {
				continue
			}

			switch evt.Type {
			case "send_message":
				handleSendWsMessage(userID, evt.Payload)
			case "ping":
				c.WriteJSON(map[string]string{"type": "pong"})
			}
		}
	})
	if err != nil {
		log.Printf("[ws] upgrade error: %v", err)
	}
}

func handleSendWsMessage(senderID string, payload json.RawMessage) {
	var msg WsIncomingMessage
	if err := json.Unmarshal(payload, &msg); err != nil {
		return
	}

	room, err := findOrCreateRoom(senderID, msg.ToUserID)
	if err != nil {
		return
	}

	dbMsg := models.Message{
		RoomID:   room.ID,
		SenderID: senderID,
		Content:  msg.Content,
		ImageID:  msg.ImageID,
	}
	if err := config.DB.Create(&dbMsg).Error; err != nil {
		return
	}
	config.DB.Model(room).Update("updated_at", dbMsg.CreatedAt)

	events.Publish(events.TopicChatMessageSent, map[string]any{
		"room_id":   room.ID,
		"sender_id": senderID,
		"to_user":   msg.ToUserID,
		"content":   msg.Content,
	})

	out := WsOutgoingMessage{
		Type:    "new_message",
		Message: dbMsg,
		RoomID:  room.ID.String(),
	}
	// Broadcast to both users in the room
	WsHub.SendToUser(room.UserA, out)
	WsHub.SendToUser(room.UserB, out)
}

// Keep this to avoid unused import
var _ = fasthttpadaptor.NewFastHTTPHandler

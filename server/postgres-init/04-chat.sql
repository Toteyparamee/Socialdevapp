-- Schema for socialdev_chat
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS rooms (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a     VARCHAR(64) NOT NULL,
    user_b     VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_a, user_b)
);
CREATE INDEX IF NOT EXISTS idx_rooms_user_a ON rooms(user_a);
CREATE INDEX IF NOT EXISTS idx_rooms_user_b ON rooms(user_b);

CREATE TABLE IF NOT EXISTS messages (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id    UUID        NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    sender_id  VARCHAR(64) NOT NULL,
    content    TEXT        NOT NULL,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_messages_room      ON messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender    ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_room_time ON messages(room_id, created_at);

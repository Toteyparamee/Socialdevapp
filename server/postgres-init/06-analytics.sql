-- Schema for socialdev_analytics
CREATE TABLE IF NOT EXISTS event_log (
    event_id    TEXT PRIMARY KEY,
    topic       TEXT        NOT NULL,
    source      TEXT        NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    payload     JSONB       NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_event_log_topic    ON event_log(topic);
CREATE INDEX IF NOT EXISTS idx_event_log_occurred ON event_log(occurred_at DESC);

CREATE TABLE IF NOT EXISTS event_counts (
    topic TEXT   PRIMARY KEY,
    count BIGINT NOT NULL DEFAULT 0
);

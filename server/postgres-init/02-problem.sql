-- Schema for socialdev_problem
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS problems (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id    VARCHAR(64)  NOT NULL,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    category    VARCHAR(32)  NOT NULL,                  -- flood/trash/traffic/infrastructure/other
    status      VARCHAR(32)  NOT NULL DEFAULT 'pending',-- pending/in_progress/resolved
    source      VARCHAR(32)  NOT NULL DEFAULT 'user',   -- user/government/urgent
    lat         DOUBLE PRECISION,
    lng         DOUBLE PRECISION,
    address     VARCHAR(500),
    image_ids   TEXT[]       NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_problems_owner    ON problems(owner_id);
CREATE INDEX IF NOT EXISTS idx_problems_category ON problems(category);
CREATE INDEX IF NOT EXISTS idx_problems_status   ON problems(status);
CREATE INDEX IF NOT EXISTS idx_problems_latlng   ON problems(lat, lng);

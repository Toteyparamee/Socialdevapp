-- Schema for socialdev_image
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS images (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id   VARCHAR(64)   NOT NULL,
    bucket     VARCHAR(100)  NOT NULL,
    key        VARCHAR(500)  NOT NULL UNIQUE,
    url        VARCHAR(1000) NOT NULL,
    folder     VARCHAR(100),
    mime       VARCHAR(100)  NOT NULL,
    size       BIGINT        NOT NULL,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_images_owner   ON images(owner_id);
CREATE INDEX IF NOT EXISTS idx_images_folder  ON images(folder);
CREATE INDEX IF NOT EXISTS idx_images_created ON images(created_at DESC);

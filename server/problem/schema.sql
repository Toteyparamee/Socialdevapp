-- Problem Service Schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

DO $$ BEGIN
    CREATE TYPE problem_category AS ENUM ('flood','trash','traffic','infrastructure','other');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE problem_status AS ENUM ('pending','in_progress','resolved');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE problem_source AS ENUM ('user','government','urgent');
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE TABLE IF NOT EXISTS problems (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id    VARCHAR(64) NOT NULL,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    category    problem_category NOT NULL,
    status      problem_status NOT NULL DEFAULT 'pending',
    source      problem_source NOT NULL DEFAULT 'user',
    lat         DOUBLE PRECISION,
    lng         DOUBLE PRECISION,
    location    GEOGRAPHY(POINT, 4326),
    address     VARCHAR(500),
    image_ids   TEXT[],
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_problems_owner ON problems(owner_id);
CREATE INDEX IF NOT EXISTS idx_problems_category ON problems(category);
CREATE INDEX IF NOT EXISTS idx_problems_status ON problems(status);
CREATE INDEX IF NOT EXISTS idx_problems_location ON problems USING GIST(location);

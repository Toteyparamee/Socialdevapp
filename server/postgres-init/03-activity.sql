-- Schema for socialdev_activity
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS activities (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id  VARCHAR(64)  NOT NULL,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    location    VARCHAR(255),
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    supervisor       VARCHAR(255),
    supervisor_phone VARCHAR(50),
    start_at    TIMESTAMPTZ,
    end_at      TIMESTAMPTZ,
    max_slots   INTEGER      NOT NULL DEFAULT 0,
    image_ids   TEXT[]       NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_activities_teacher  ON activities(teacher_id);
CREATE INDEX IF NOT EXISTS idx_activities_start_at ON activities(start_at);

CREATE TABLE IF NOT EXISTS registrations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID         NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    student_id  VARCHAR(64)  NOT NULL,
    status      VARCHAR(32)  NOT NULL DEFAULT 'registered',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (activity_id, student_id)
);
CREATE INDEX IF NOT EXISTS idx_registrations_activity ON registrations(activity_id);
CREATE INDEX IF NOT EXISTS idx_registrations_student  ON registrations(student_id);

CREATE TABLE IF NOT EXISTS submissions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id UUID         NOT NULL REFERENCES registrations(id) ON DELETE CASCADE,
    content         TEXT,
    image_ids       TEXT[]       NOT NULL DEFAULT '{}',
    score           INTEGER,
    feedback        TEXT,
    status          VARCHAR(32)  NOT NULL DEFAULT 'pending',
    reviewed_by     VARCHAR(64),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    reviewed_at     TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_submissions_registration ON submissions(registration_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status       ON submissions(status);

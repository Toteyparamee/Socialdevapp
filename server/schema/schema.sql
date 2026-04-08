-- ============================================================
-- Socialdev App - PostgreSQL Schema
-- ============================================================

-- ── Extensions ──
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";   -- สำหรับ location (lat/lng)

-- ── Enum Types ──
CREATE TYPE user_role AS ENUM ('นักเรียน', 'ครู', 'ทั่วไป');
CREATE TYPE auth_provider AS ENUM ('local', 'google');
CREATE TYPE problem_category AS ENUM ('flood', 'trash', 'traffic', 'infrastructure', 'other');
CREATE TYPE problem_status AS ENUM ('pending', 'in_progress', 'resolved');
CREATE TYPE problem_source AS ENUM ('user', 'government', 'urgent');

-- ============================================================
-- 1. Users
-- ============================================================
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    username    VARCHAR(100) NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL UNIQUE,
    password    VARCHAR(255),                          -- bcrypt hash (NULL ถ้า google login)
    role        user_role    NOT NULL DEFAULT 'นักเรียน',
    provider    auth_provider NOT NULL DEFAULT 'local',
    google_id   VARCHAR(255),
    avatar_url  VARCHAR(500),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ                            -- soft delete
);

CREATE INDEX idx_users_deleted_at ON users (deleted_at);
CREATE INDEX idx_users_email      ON users (email);
CREATE INDEX idx_users_google_id  ON users (google_id) WHERE google_id IS NOT NULL;

-- ============================================================
-- 2. Problem Reports (ปัญหาชุมชน)
-- ============================================================
CREATE TABLE problem_reports (
    id           BIGSERIAL PRIMARY KEY,
    title        VARCHAR(255)     NOT NULL,
    description  TEXT             NOT NULL,
    category     problem_category NOT NULL,
    status       problem_status   NOT NULL DEFAULT 'pending',
    source       problem_source   NOT NULL DEFAULT 'user',
    location     GEOGRAPHY(POINT, 4326) NOT NULL,      -- lat/lng (PostGIS)
    address      VARCHAR(500)     NOT NULL,
    reported_by  BIGINT           NOT NULL REFERENCES users(id),
    created_at   TIMESTAMPTZ      NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ      NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ
);

CREATE INDEX idx_problem_reports_category    ON problem_reports (category);
CREATE INDEX idx_problem_reports_status      ON problem_reports (status);
CREATE INDEX idx_problem_reports_reported_by ON problem_reports (reported_by);
CREATE INDEX idx_problem_reports_location    ON problem_reports USING GIST (location);
CREATE INDEX idx_problem_reports_deleted_at  ON problem_reports (deleted_at);

-- ============================================================
-- 3. Problem Images (รูปภาพปัญหา)
-- ============================================================
CREATE TABLE problem_images (
    id         BIGSERIAL PRIMARY KEY,
    problem_id BIGINT       NOT NULL REFERENCES problem_reports(id) ON DELETE CASCADE,
    image_url  VARCHAR(500) NOT NULL,
    sort_order SMALLINT     NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_problem_images_problem_id ON problem_images (problem_id);

-- ============================================================
-- 4. School Activities (กิจกรรมโรงเรียน)
-- ============================================================
CREATE TABLE school_activities (
    id             BIGSERIAL PRIMARY KEY,
    title          VARCHAR(255) NOT NULL,
    description    TEXT         NOT NULL,
    category       VARCHAR(50)  NOT NULL,           -- จิตอาสา, กีฬา, วิชาการ, ภาษา, ...
    category_color VARCHAR(7),                      -- hex color เช่น #10B981
    date_start     DATE         NOT NULL,
    date_end       DATE,                            -- NULL = กิจกรรมวันเดียว
    location       VARCHAR(255) NOT NULL,
    image_url      VARCHAR(500),
    max_capacity   INT,                             -- NULL = ไม่จำกัด
    created_by     BIGINT       NOT NULL REFERENCES users(id),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at     TIMESTAMPTZ
);

CREATE INDEX idx_school_activities_date_start ON school_activities (date_start);
CREATE INDEX idx_school_activities_category   ON school_activities (category);
CREATE INDEX idx_school_activities_deleted_at ON school_activities (deleted_at);

-- ============================================================
-- 5. Activity Registrations (ลงทะเบียนกิจกรรม)
-- ============================================================
CREATE TABLE activity_registrations (
    id          BIGSERIAL PRIMARY KEY,
    activity_id BIGINT      NOT NULL REFERENCES school_activities(id) ON DELETE CASCADE,
    user_id     BIGINT      NOT NULL REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (activity_id, user_id)   -- ลงทะเบียนซ้ำไม่ได้
);

CREATE INDEX idx_activity_registrations_user_id ON activity_registrations (user_id);

-- ============================================================
-- 6. Images (ไฟล์รูปที่เก็บใน MinIO - จัดการโดย image service)
-- ============================================================
CREATE TABLE images (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id   VARCHAR(64)  NOT NULL,                  -- user_id จาก JWT claims
    bucket     VARCHAR(100) NOT NULL,                  -- ชื่อ MinIO bucket
    key        VARCHAR(500) NOT NULL UNIQUE,           -- path ใน bucket เช่น problems/uuid.jpg
    url        VARCHAR(1000) NOT NULL,                 -- public URL (หรือว่าง ถ้า private)
    folder     VARCHAR(100),                           -- sub-folder เช่น problems / avatars / activities
    mime       VARCHAR(100) NOT NULL,                  -- image/jpeg, image/png, image/webp
    size       BIGINT       NOT NULL,                  -- bytes
    width      INT,                                    -- optional metadata
    height     INT,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_images_owner_id   ON images (owner_id);
CREATE INDEX idx_images_folder     ON images (folder);
CREATE INDEX idx_images_created_at ON images (created_at DESC);
CREATE INDEX idx_images_deleted_at ON images (deleted_at);

-- ============================================================
-- Trigger: auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_problem_reports_updated_at
    BEFORE UPDATE ON problem_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_school_activities_updated_at
    BEFORE UPDATE ON school_activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

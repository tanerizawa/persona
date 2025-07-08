-- CreateTable
CREATE TABLE "crisis_events" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "crisis_level" TEXT NOT NULL,
    "trigger_source" TEXT NOT NULL,
    "detected_keywords" TEXT,
    "user_message" TEXT,
    "intervention_provided" BOOLEAN NOT NULL DEFAULT false,
    "intervention_type" TEXT,
    "resources_provided" TEXT,
    "professional_contact_made" BOOLEAN NOT NULL DEFAULT false,
    "intervention_timestamp" DATETIME,
    "follow_up_required" BOOLEAN NOT NULL DEFAULT false,
    "follow_up_completed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL,
    CONSTRAINT "crisis_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "device_tokens" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL DEFAULT 'flutter',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL,
    CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "notification_history" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "sent" BOOLEAN NOT NULL DEFAULT false,
    "read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "notification_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "crisis_events_user_id_crisis_level_idx" ON "crisis_events"("user_id", "crisis_level");

-- CreateIndex
CREATE INDEX "crisis_events_created_at_idx" ON "crisis_events"("created_at");

-- CreateIndex
CREATE INDEX "device_tokens_user_id_active_idx" ON "device_tokens"("user_id", "active");

-- CreateIndex
CREATE UNIQUE INDEX "device_tokens_user_id_token_key" ON "device_tokens"("user_id", "token");

-- CreateIndex
CREATE INDEX "notification_history_user_id_created_at_idx" ON "notification_history"("user_id", "created_at");

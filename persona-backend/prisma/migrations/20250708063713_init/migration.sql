/*
  Warnings:

  - You are about to drop the column `device_count` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `last_sync` on the `users` table. All the data in the column will be lost.
  - Added the required column `updated_at` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- CreateTable
CREATE TABLE "user_sessions" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "device_id" TEXT NOT NULL,
    "device_name" TEXT,
    "device_type" TEXT,
    "access_token_hash" TEXT NOT NULL,
    "refresh_token_hash" TEXT NOT NULL,
    "expires_at" DATETIME NOT NULL,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "last_active" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "api_usage_logs" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "request_size" INTEGER,
    "response_size" INTEGER,
    "processing_time" INTEGER,
    "tokens_used" INTEGER,
    "cost_cents" INTEGER,
    "status_code" INTEGER NOT NULL,
    "error_message" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "api_usage_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "security_events" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT,
    "event_type" TEXT NOT NULL,
    "severity" TEXT NOT NULL DEFAULT 'medium',
    "description" TEXT NOT NULL,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "metadata" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "security_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_users" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "display_name" TEXT,
    "avatar_url" TEXT,
    "bio" TEXT,
    "email_verified" BOOLEAN NOT NULL DEFAULT false,
    "verification_token" TEXT,
    "account_status" TEXT NOT NULL DEFAULT 'pending',
    "subscription_tier" TEXT NOT NULL DEFAULT 'free',
    "api_quota_daily" INTEGER NOT NULL DEFAULT 50,
    "api_usage_today" INTEGER NOT NULL DEFAULT 0,
    "last_quota_reset" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "failed_login_attempts" INTEGER NOT NULL DEFAULT 0,
    "locked_until" DATETIME,
    "last_login" DATETIME,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL,
    "deleted_at" DATETIME
);
INSERT INTO "new_users" ("created_at", "email", "id", "password_hash") SELECT "created_at", "email", "id", "password_hash" FROM "users";
DROP TABLE "users";
ALTER TABLE "new_users" RENAME TO "users";
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE INDEX "user_sessions_user_id_device_id_idx" ON "user_sessions"("user_id", "device_id");

-- CreateIndex
CREATE INDEX "user_sessions_access_token_hash_idx" ON "user_sessions"("access_token_hash");

-- CreateIndex
CREATE UNIQUE INDEX "user_sessions_user_id_device_id_key" ON "user_sessions"("user_id", "device_id");

-- CreateIndex
CREATE INDEX "api_usage_logs_user_id_created_at_idx" ON "api_usage_logs"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "api_usage_logs_endpoint_idx" ON "api_usage_logs"("endpoint");

-- CreateIndex
CREATE INDEX "security_events_user_id_event_type_idx" ON "security_events"("user_id", "event_type");

-- CreateIndex
CREATE INDEX "security_events_severity_created_at_idx" ON "security_events"("severity", "created_at");

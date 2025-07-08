/*
  Warnings:

  - You are about to drop the column `event_type` on the `security_events` table. All the data in the column will be lost.
  - You are about to drop the column `metadata` on the `security_events` table. All the data in the column will be lost.
  - You are about to drop the column `user_agent` on the `security_events` table. All the data in the column will be lost.
  - Added the required column `eventType` to the `security_events` table without a default value. This is not possible if the table is not empty.

*/
-- CreateTable
CREATE TABLE "conversations" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "title" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL,
    CONSTRAINT "conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "messages" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "conversation_id" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "metadata" JSONB,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_api_usage_logs" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "model" TEXT,
    "request_size" INTEGER,
    "response_size" INTEGER,
    "processing_time" INTEGER,
    "tokens_used" INTEGER,
    "cost_cents" INTEGER,
    "status_code" INTEGER DEFAULT 200,
    "success" BOOLEAN NOT NULL DEFAULT true,
    "error_message" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "api_usage_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_api_usage_logs" ("cost_cents", "created_at", "endpoint", "error_message", "id", "processing_time", "request_size", "response_size", "status_code", "tokens_used", "user_id") SELECT "cost_cents", "created_at", "endpoint", "error_message", "id", "processing_time", "request_size", "response_size", "status_code", "tokens_used", "user_id" FROM "api_usage_logs";
DROP TABLE "api_usage_logs";
ALTER TABLE "new_api_usage_logs" RENAME TO "api_usage_logs";
CREATE INDEX "api_usage_logs_user_id_created_at_idx" ON "api_usage_logs"("user_id", "created_at");
CREATE INDEX "api_usage_logs_endpoint_idx" ON "api_usage_logs"("endpoint");
CREATE TABLE "new_security_events" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT,
    "eventType" TEXT NOT NULL,
    "description" TEXT,
    "ip_address" TEXT,
    "userAgent" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "severity" TEXT,
    CONSTRAINT "security_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_security_events" ("created_at", "description", "id", "ip_address", "severity", "user_id") SELECT "created_at", "description", "id", "ip_address", "severity", "user_id" FROM "security_events";
DROP TABLE "security_events";
ALTER TABLE "new_security_events" RENAME TO "security_events";
CREATE INDEX "security_events_user_id_created_at_idx" ON "security_events"("user_id", "created_at");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

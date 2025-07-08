-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_sync" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "device_count" INTEGER NOT NULL DEFAULT 1
);

-- CreateTable
CREATE TABLE "user_sync_status" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "device_id" TEXT NOT NULL,
    "last_sync_timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sync_version" INTEGER NOT NULL DEFAULT 1,
    "data_hash" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT "user_sync_status_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ai_scripts" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "script_name" TEXT NOT NULL,
    "version" TEXT NOT NULL,
    "script_content" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "user_backups" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "encrypted_data" TEXT,
    "backup_date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "data_size" INTEGER,
    "checksum" TEXT,
    CONSTRAINT "user_backups_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "user_sync_status_user_id_device_id_idx" ON "user_sync_status"("user_id", "device_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_sync_status_user_id_device_id_key" ON "user_sync_status"("user_id", "device_id");

-- CreateIndex
CREATE UNIQUE INDEX "ai_scripts_script_name_key" ON "ai_scripts"("script_name");

-- CreateIndex
CREATE INDEX "ai_scripts_is_active_idx" ON "ai_scripts"("is_active");

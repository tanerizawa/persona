-- CreateTable
CREATE TABLE "biometric_credentials" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user_id" TEXT NOT NULL,
    "device_id" TEXT NOT NULL,
    "biometric_hash" TEXT NOT NULL,
    "biometric_type" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_used" DATETIME,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL,
    CONSTRAINT "biometric_credentials_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "biometric_credentials_user_id_device_id_idx" ON "biometric_credentials"("user_id", "device_id");

-- CreateIndex
CREATE UNIQUE INDEX "biometric_credentials_user_id_device_id_key" ON "biometric_credentials"("user_id", "device_id");

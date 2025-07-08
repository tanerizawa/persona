/*
  Warnings:

  - Added the required column `user_id` to the `messages` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_messages" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "conversation_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "metadata" JSONB,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_messages" ("content", "conversation_id", "created_at", "id", "metadata", "role") SELECT "content", "conversation_id", "created_at", "id", "metadata", "role" FROM "messages";
DROP TABLE "messages";
ALTER TABLE "new_messages" RENAME TO "messages";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

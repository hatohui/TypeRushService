-- CreateTable
CREATE TABLE "public"."modes" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "modes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."personal_record" (
    "id" SERIAL NOT NULL,
    "account_id" TEXT NOT NULL,
    "accuracy" DOUBLE PRECISION NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "raw" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "personal_record_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."match_histories" (
    "id" SERIAL NOT NULL,
    "mode_id" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "match_histories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."match_participants" (
    "history_id" INTEGER NOT NULL,
    "account_id" TEXT NOT NULL,
    "rank" INTEGER NOT NULL,
    "accuracy" DOUBLE PRECISION NOT NULL,
    "raw" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "match_participants_pkey" PRIMARY KEY ("history_id","account_id")
);

-- CreateTable
CREATE TABLE "public"."achievements" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "wpm_criteria" INTEGER NOT NULL,

    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_achievements" (
    "account_id" TEXT NOT NULL,
    "achievement_id" INTEGER NOT NULL,

    CONSTRAINT "user_achievements_pkey" PRIMARY KEY ("account_id","achievement_id")
);

-- AddForeignKey
ALTER TABLE "public"."match_histories" ADD CONSTRAINT "match_histories_mode_id_fkey" FOREIGN KEY ("mode_id") REFERENCES "public"."modes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."match_participants" ADD CONSTRAINT "match_participants_history_id_fkey" FOREIGN KEY ("history_id") REFERENCES "public"."match_histories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_achievements" ADD CONSTRAINT "user_achievements_achievement_id_fkey" FOREIGN KEY ("achievement_id") REFERENCES "public"."achievements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

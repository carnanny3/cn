-- CreateEnum
CREATE TYPE "VehicleRecordType" AS ENUM ('service', 'repair', 'upgrade', 'fee');

-- CreateTable
CREATE TABLE "vehicle_records" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "type" "VehicleRecordType" NOT NULL,
    "date" DATE NOT NULL,
    "odometer_km" INTEGER,
    "title" TEXT NOT NULL,
    "cost" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'AED',
    "notes" TEXT,
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_record_photos" (
    "id" TEXT NOT NULL,
    "record_id" TEXT NOT NULL,
    "file_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vehicle_record_photos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fuel_entries" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "odometer_km" INTEGER NOT NULL,
    "liters" DOUBLE PRECISION NOT NULL,
    "cost" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'AED',
    "full_tank" BOOLEAN NOT NULL DEFAULT true,
    "missed_previous" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fuel_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_reminders" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "due_date" DATE,
    "due_odometer_km" INTEGER,
    "repeat_months" INTEGER,
    "repeat_km" INTEGER,
    "notes" TEXT,
    "completed_at" TIMESTAMP(3),
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_reminders_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "vehicle_records_vehicle_id_date_idx" ON "vehicle_records"("vehicle_id", "date");

-- CreateIndex
CREATE INDEX "vehicle_record_photos_record_id_idx" ON "vehicle_record_photos"("record_id");

-- CreateIndex
CREATE INDEX "fuel_entries_vehicle_id_odometer_km_idx" ON "fuel_entries"("vehicle_id", "odometer_km");

-- CreateIndex
CREATE INDEX "vehicle_reminders_vehicle_id_completed_at_idx" ON "vehicle_reminders"("vehicle_id", "completed_at");

-- AddForeignKey
ALTER TABLE "vehicle_records" ADD CONSTRAINT "vehicle_records_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_record_photos" ADD CONSTRAINT "vehicle_record_photos_record_id_fkey" FOREIGN KEY ("record_id") REFERENCES "vehicle_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_entries" ADD CONSTRAINT "fuel_entries_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_reminders" ADD CONSTRAINT "vehicle_reminders_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


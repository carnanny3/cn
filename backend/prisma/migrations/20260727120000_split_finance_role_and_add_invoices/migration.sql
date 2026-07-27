-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('issued', 'refunded', 'void');

-- AlterEnum
BEGIN;
-- Widen the column to text first so the admin_finance backfill isn't
-- constrained by either the old or new enum's value set, then cast into
-- the narrowed enum once the data no longer references the removed value.
ALTER TABLE "users" ALTER COLUMN "role" DROP DEFAULT;
ALTER TABLE "users" ALTER COLUMN "role" TYPE TEXT;
UPDATE "users" SET "role" = 'accountant' WHERE "role" = 'admin_finance';
CREATE TYPE "UserRole_new" AS ENUM ('customer', 'partner', 'admin_super', 'admin_ops', 'admin_inspection', 'admin_support', 'accountant', 'accounts_manager', 'admin_partner_manager', 'admin_content', 'admin_compliance', 'admin_analyst');
ALTER TABLE "users" ALTER COLUMN "role" TYPE "UserRole_new" USING ("role"::"UserRole_new");
DROP TYPE "UserRole";
ALTER TYPE "UserRole_new" RENAME TO "UserRole";
ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'customer';
COMMIT;

-- CreateTable
CREATE TABLE "invoices" (
    "id" TEXT NOT NULL,
    "invoice_number" TEXT NOT NULL,
    "payment_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "subtotal" DOUBLE PRECISION NOT NULL,
    "vat_amount" DOUBLE PRECISION NOT NULL,
    "total_amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'AED',
    "status" "InvoiceStatus" NOT NULL DEFAULT 'issued',
    "issued_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "invoices_invoice_number_key" ON "invoices"("invoice_number");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_payment_id_key" ON "invoices"("payment_id");

-- CreateIndex
CREATE INDEX "invoices_customer_id_idx" ON "invoices"("customer_id");

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

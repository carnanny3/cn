-- CreateEnum
CREATE TYPE "RewardsTransactionReason" AS ENUM ('referral_bonus', 'booking_completed', 'promo_credit', 'redemption', 'manual_adjustment');

-- CreateEnum
CREATE TYPE "ReferralStatus" AS ENUM ('pending', 'completed');

-- CreateEnum
CREATE TYPE "SupportTicketStatus" AS ENUM ('open', 'in_progress', 'resolved', 'closed');

-- CreateEnum
CREATE TYPE "WarrantyPolicyStatus" AS ENUM ('active', 'expired', 'cancelled');

-- CreateEnum
CREATE TYPE "WarrantyClaimStatus" AS ENUM ('submitted', 'under_review', 'inspection_required', 'approved', 'rejected', 'repair_authorized', 'completed', 'closed');

-- CreateEnum
CREATE TYPE "InsuranceIntegrationType" AS ENUM ('manual', 'api');

-- CreateEnum
CREATE TYPE "InsuranceQuoteStatus" AS ENUM ('requested', 'quoted', 'expired');

-- CreateEnum
CREATE TYPE "InsurancePolicyStatus" AS ENUM ('active', 'expired', 'cancelled');

-- CreateEnum
CREATE TYPE "RoadsideServiceType" AS ENUM ('tow', 'jumpstart', 'flat_tire', 'fuel_delivery', 'lockout');

-- CreateEnum
CREATE TYPE "RoadsideStatus" AS ENUM ('requested', 'matched', 'accepted', 'en_route', 'arrived', 'in_service', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "ConciergeOrderType" AS ENUM ('registration_renewal', 'ownership_transfer', 'pickup_delivery', 'detailing', 'driver_service');

-- CreateEnum
CREATE TYPE "ConciergeStatus" AS ENUM ('requested', 'assigned', 'in_progress', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "ListingSellerType" AS ENUM ('certified', 'dealer', 'private');

-- CreateEnum
CREATE TYPE "ListingStatus" AS ENUM ('draft', 'active', 'reserved', 'sold', 'withdrawn');

-- AlterTable
ALTER TABLE "partners" ADD COLUMN     "user_id" TEXT;

-- AlterTable
ALTER TABLE "support_tickets" ADD COLUMN     "assigned_admin_id" TEXT,
DROP COLUMN "status",
ADD COLUMN     "status" "SupportTicketStatus" NOT NULL DEFAULT 'open';

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "referral_code" TEXT;

-- CreateTable
CREATE TABLE "rewards_transactions" (
    "id" TEXT NOT NULL,
    "rewards_account_id" TEXT NOT NULL,
    "points" INTEGER NOT NULL,
    "reason" "RewardsTransactionReason" NOT NULL,
    "related_entity_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rewards_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "referrals" (
    "id" TEXT NOT NULL,
    "referrer_id" TEXT NOT NULL,
    "referred_user_id" TEXT NOT NULL,
    "status" "ReferralStatus" NOT NULL DEFAULT 'pending',
    "reward_issued" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "referrals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_ticket_messages" (
    "id" TEXT NOT NULL,
    "ticket_id" TEXT NOT NULL,
    "author_id" TEXT NOT NULL,
    "author_role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_ticket_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warranty_plans" (
    "id" TEXT NOT NULL,
    "provider_partner_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "coverage_summary" TEXT NOT NULL,
    "exclusions" TEXT,
    "eligibility_rules" JSONB,
    "price" DOUBLE PRECISION NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "warranty_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warranty_policies" (
    "id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "policy_number" TEXT NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3) NOT NULL,
    "status" "WarrantyPolicyStatus" NOT NULL DEFAULT 'active',
    "document_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "warranty_policies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warranty_claims" (
    "id" TEXT NOT NULL,
    "policy_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "WarrantyClaimStatus" NOT NULL DEFAULT 'submitted',
    "assigned_garage_id" TEXT,
    "rejection_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "warranty_claims_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warranty_claim_documents" (
    "id" TEXT NOT NULL,
    "claim_id" TEXT NOT NULL,
    "file_url" TEXT NOT NULL,
    "type" TEXT NOT NULL,

    CONSTRAINT "warranty_claim_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "insurance_providers" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "integration_type" "InsuranceIntegrationType" NOT NULL DEFAULT 'manual',
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "insurance_providers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "insurance_quotes" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "premium_amount" DOUBLE PRECISION,
    "coverage_type" TEXT,
    "excess_amount" DOUBLE PRECISION,
    "valid_until" TIMESTAMP(3),
    "status" "InsuranceQuoteStatus" NOT NULL DEFAULT 'requested',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "insurance_quotes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "insurance_policies" (
    "id" TEXT NOT NULL,
    "quote_id" TEXT NOT NULL,
    "policy_number" TEXT NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3) NOT NULL,
    "document_url" TEXT,
    "digital_card_url" TEXT,
    "status" "InsurancePolicyStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "insurance_policies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roadside_requests" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "service_type" "RoadsideServiceType" NOT NULL,
    "status" "RoadsideStatus" NOT NULL DEFAULT 'requested',
    "location_lat" DOUBLE PRECISION NOT NULL,
    "location_lng" DOUBLE PRECISION NOT NULL,
    "provider_id" TEXT,
    "requested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMP(3),

    CONSTRAINT "roadside_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "concierge_orders" (
    "id" TEXT NOT NULL,
    "order_type" "ConciergeOrderType" NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "status" "ConciergeStatus" NOT NULL DEFAULT 'requested',
    "assigned_partner_id" TEXT,
    "assigned_admin_id" TEXT,
    "document_checklist" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "concierge_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_listings" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT,
    "seller_id" TEXT,
    "seller_type" "ListingSellerType" NOT NULL DEFAULT 'certified',
    "make" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "mileage_km" INTEGER,
    "asking_price" DOUBLE PRECISION NOT NULL,
    "inspection_id" TEXT,
    "status" "ListingStatus" NOT NULL DEFAULT 'draft',
    "photos" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_listings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "rewards_transactions_rewards_account_id_idx" ON "rewards_transactions"("rewards_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "referrals_referred_user_id_key" ON "referrals"("referred_user_id");

-- CreateIndex
CREATE INDEX "referrals_referrer_id_idx" ON "referrals"("referrer_id");

-- CreateIndex
CREATE INDEX "support_ticket_messages_ticket_id_idx" ON "support_ticket_messages"("ticket_id");

-- CreateIndex
CREATE UNIQUE INDEX "warranty_policies_policy_number_key" ON "warranty_policies"("policy_number");

-- CreateIndex
CREATE INDEX "warranty_policies_customer_id_idx" ON "warranty_policies"("customer_id");

-- CreateIndex
CREATE INDEX "warranty_claims_policy_id_idx" ON "warranty_claims"("policy_id");

-- CreateIndex
CREATE INDEX "insurance_quotes_customer_id_idx" ON "insurance_quotes"("customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "insurance_policies_quote_id_key" ON "insurance_policies"("quote_id");

-- CreateIndex
CREATE UNIQUE INDEX "insurance_policies_policy_number_key" ON "insurance_policies"("policy_number");

-- CreateIndex
CREATE INDEX "roadside_requests_customer_id_idx" ON "roadside_requests"("customer_id");

-- CreateIndex
CREATE INDEX "roadside_requests_status_idx" ON "roadside_requests"("status");

-- CreateIndex
CREATE INDEX "concierge_orders_customer_id_idx" ON "concierge_orders"("customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "vehicle_listings_inspection_id_key" ON "vehicle_listings"("inspection_id");

-- CreateIndex
CREATE INDEX "vehicle_listings_status_idx" ON "vehicle_listings"("status");

-- CreateIndex
CREATE UNIQUE INDEX "partners_user_id_key" ON "partners"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_referral_code_key" ON "users"("referral_code");

-- AddForeignKey
ALTER TABLE "partners" ADD CONSTRAINT "partners_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rewards_transactions" ADD CONSTRAINT "rewards_transactions_rewards_account_id_fkey" FOREIGN KEY ("rewards_account_id") REFERENCES "rewards_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referrals" ADD CONSTRAINT "referrals_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referrals" ADD CONSTRAINT "referrals_referred_user_id_fkey" FOREIGN KEY ("referred_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_ticket_messages" ADD CONSTRAINT "support_ticket_messages_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "support_tickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_plans" ADD CONSTRAINT "warranty_plans_provider_partner_id_fkey" FOREIGN KEY ("provider_partner_id") REFERENCES "partners"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_policies" ADD CONSTRAINT "warranty_policies_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "warranty_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_policies" ADD CONSTRAINT "warranty_policies_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_policies" ADD CONSTRAINT "warranty_policies_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_claims" ADD CONSTRAINT "warranty_claims_policy_id_fkey" FOREIGN KEY ("policy_id") REFERENCES "warranty_policies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_claims" ADD CONSTRAINT "warranty_claims_assigned_garage_id_fkey" FOREIGN KEY ("assigned_garage_id") REFERENCES "partners"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranty_claim_documents" ADD CONSTRAINT "warranty_claim_documents_claim_id_fkey" FOREIGN KEY ("claim_id") REFERENCES "warranty_claims"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insurance_quotes" ADD CONSTRAINT "insurance_quotes_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insurance_quotes" ADD CONSTRAINT "insurance_quotes_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insurance_quotes" ADD CONSTRAINT "insurance_quotes_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "insurance_providers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insurance_policies" ADD CONSTRAINT "insurance_policies_quote_id_fkey" FOREIGN KEY ("quote_id") REFERENCES "insurance_quotes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roadside_requests" ADD CONSTRAINT "roadside_requests_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roadside_requests" ADD CONSTRAINT "roadside_requests_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roadside_requests" ADD CONSTRAINT "roadside_requests_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "partners"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "concierge_orders" ADD CONSTRAINT "concierge_orders_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "concierge_orders" ADD CONSTRAINT "concierge_orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "concierge_orders" ADD CONSTRAINT "concierge_orders_assigned_partner_id_fkey" FOREIGN KEY ("assigned_partner_id") REFERENCES "partners"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_listings" ADD CONSTRAINT "vehicle_listings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_listings" ADD CONSTRAINT "vehicle_listings_seller_id_fkey" FOREIGN KEY ("seller_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_listings" ADD CONSTRAINT "vehicle_listings_inspection_id_fkey" FOREIGN KEY ("inspection_id") REFERENCES "inspections"("id") ON DELETE SET NULL ON UPDATE CASCADE;


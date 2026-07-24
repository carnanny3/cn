# --- Build stage ---
FROM node:20-alpine AS build
WORKDIR /app
# Needed so `prisma generate` can detect the actual OpenSSL version and fetch
# the matching query engine binary, instead of silently guessing wrong.
RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma
RUN npm ci

COPY . .
RUN npx prisma generate
RUN npm run build

# --- Production stage ---
FROM node:20-alpine AS production
WORKDIR /app
RUN apk add --no-cache openssl

ENV NODE_ENV=production

COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma

EXPOSE 3000

# Apply any pending migrations, then start the API. Safe to run on every
# deploy — Prisma tracks which migrations have already been applied.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/src/main.js"]

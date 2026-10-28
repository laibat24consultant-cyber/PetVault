FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src
COPY migrations ./migrations

USER node
EXPOSE 3000
CMD ["sh", "-c", "node src/migrate.js && if [ \"$SEED_DEMO_DATA\" = \"true\" ]; then node src/seed.js || exit 1; fi && node src/server.js"]

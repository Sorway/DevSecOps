# syntax=docker/dockerfile:1.7
FROM node:24-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:24-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
RUN apk upgrade --no-cache \
  && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
  && addgroup -S nodeapp \
  && adduser -S nodeapp -G nodeapp
COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY public ./public
USER nodeapp
EXPOSE 3000
CMD ["node", "src/app.js"]

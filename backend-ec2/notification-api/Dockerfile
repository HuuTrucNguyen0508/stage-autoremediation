# notification-api/Dockerfile

# --- ÉTAPE 1: Build Stage ---
FROM node:20-alpine AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci
COPY . .

# --- ÉTAPE 2: Production Stage ---
FROM node:20-alpine AS production
WORKDIR /usr/src/app
COPY --from=build /usr/src/app/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /usr/src/app .

EXPOSE 4000

CMD [ "node", "server.js" ]

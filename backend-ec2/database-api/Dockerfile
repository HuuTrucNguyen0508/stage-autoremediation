# database-api/Dockerfile

# --- ÉTAPE 1: Build Stage ---
# Utilise une image Node.js complète pour installer les dépendances de manière robuste.
# 'AS build' nomme cette étape pour référence ultérieure.
FROM node:20-alpine AS build
WORKDIR /usr/src/app

# Copie package.json ET package-lock.json pour une installation reproductible
COPY package*.json ./

# 'npm ci' est plus rapide et plus sûr pour les builds CI/CD/Docker.
# Il installe les versions exactes de package-lock.json.
RUN npm ci

# Copie le reste du code source de l'application
COPY . .

# Si vous aviez une étape de compilation (ex: TypeScript), elle serait ici :
# RUN npm run build


# --- ÉTAPE 2: Production Stage ---
# Part d'une image "slim" ou "alpine" pour un résultat final plus léger.
FROM node:20-alpine AS production
WORKDIR /usr/src/app

# Copie uniquement le package.json et package-lock.json depuis l'étape de build
COPY --from=build /usr/src/app/package*.json ./

# Installe UNIQUEMENT les dépendances de production.
# --omit=dev garantit que nodemon, prettier, etc. ne sont pas inclus.
RUN npm ci --omit=dev

# Copie le code source compilé et les node_modules de l'étape de build
COPY --from=build /usr/src/app .

# Le port est configuré via une variable d'environnement dans compose.yaml ou la définition de tâche ECS
EXPOSE 3002

# Commande finale pour exécuter l'application en mode production
CMD [ "node", "server.js" ]

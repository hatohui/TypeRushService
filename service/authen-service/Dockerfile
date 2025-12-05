#build
FROM node:24 AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build
RUN npm prune --production

#production
FROM node:24-alpine AS production
WORKDIR /app
COPY --from=build /app ./
EXPOSE 3000
CMD ["node", "dist/main.js"]

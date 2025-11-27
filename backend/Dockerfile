
FROM node:18-alpine AS base

WORKDIR /app

COPY package*.json ./

RUN npm install --only=production

FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

FROM node:18-alpine AS runtime

WORKDIR /app

COPY --from=base /app/node_modules ./node_modules

COPY --from=build /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]

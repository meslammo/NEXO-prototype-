FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src
COPY schema.sql ./
ENV NODE_ENV=production
CMD ["node","src/server.js"]
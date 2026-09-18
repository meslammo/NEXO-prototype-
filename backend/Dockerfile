FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src
COPY schema.sql ./
COPY admin.html ./admin.html
COPY assets/nexo.css ./assets/nexo.css
ENV NODE_ENV=production
CMD ["node","src/server.js"]
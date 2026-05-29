FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY --chown=node:node package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node . .
RUN mkdir -p public/uploads && chown -R node:node public

USER node

EXPOSE 5050

CMD ["node", "server.js"]

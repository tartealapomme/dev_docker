FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

FROM node:20-alpine AS test
WORKDIR /app
COPY package.json ./
RUN npm install
COPY src ./src
COPY test ./test
RUN npm test && npm run lint

FROM alpine:3.23.4 AS runtime
ARG APP_VERSION=dev
ARG GIT_SHA=local
LABEL org.opencontainers.image.title="shopapi" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="https://github.com/shopsas/shopapi"
RUN addgroup -g 1000 node && adduser -u 1000 -G node -S -D node \
    && apk add --no-cache libcrypto3=3.5.9-r0 libssl3=3.5.9-r0
WORKDIR /app
ENV NODE_ENV=production \
    APP_VERSION=${APP_VERSION}
COPY --from=deps /usr/local/bin/node /usr/local/bin/node
COPY --from=deps /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
COPY --from=deps /usr/lib/libstdc++.so.6.0.34 /usr/lib/libstdc++.so.6.0.34
COPY --from=deps /usr/lib/libstdc++.so.6 /usr/lib/libstdc++.so.6
COPY --from=deps --chown=1000:1000 /app/node_modules ./node_modules
COPY --chown=1000:1000 package.json ./
COPY --from=test --chown=1000:1000 /app/src ./src
USER 1000
EXPOSE 3000
HEALTHCHECK --interval=5s --timeout=3s --start-period=2s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
CMD ["node", "src/server.js"]

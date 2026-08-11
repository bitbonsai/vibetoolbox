FROM oven/bun:1

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --production

COPY catalog.json ./
COPY installer ./installer
COPY scripts ./scripts
COPY public ./public
COPY src ./src

RUN bun scripts/build.ts

ENV PORT=8080
EXPOSE 8080

CMD ["bun", "src/server.ts"]

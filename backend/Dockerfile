FROM node:22.18.0-alpine AS runtime-builder

WORKDIR /backend
RUN apk add --no-cache git
COPY package.json tsconfig.json ./
RUN npm install --ignore-scripts
COPY src ./src
RUN npm run build

# Docker Hub is Heroic Labs' documented official fallback when its Scarf
# gateway rate-limits a pull. Keep this tag in lockstep with stack-lock.json.
FROM heroiclabs/nakama:3.40.0
COPY --from=runtime-builder /backend/build/index.js /nakama/data/modules/build/index.js
COPY local.yml /nakama/data/local.yml
COPY staging.yml /nakama/data/staging.yml

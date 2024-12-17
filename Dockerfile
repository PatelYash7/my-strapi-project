# Creating multi-stage build for production
FROM node:18-alpine AS build
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git > /dev/null 2>&1
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV NODE_OPTIONS="--max_old_space_size=2048"

WORKDIR /opt/
COPY package.json package-lock.json ./
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install --only=production
ENV PATH=/opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .
RUN npm run build

# Creating final production image
FROM node:18-alpine
RUN apk add --no-cache vips-dev
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /opt/

# Copy node_modules from the build stage
COPY --from=build /opt/node_modules ./node_modules

# Copy app from the build stage
COPY --from=build /opt/app ./

# Ensure .env file is copied (if it exists) and permissions are set correctly
COPY .env /opt/app/.env

# Ensure proper permissions for the .env file
RUN chown -R node:node /opt/app && chmod 644 /opt/app/.env

ENV PATH=/opt/node_modules/.bin:$PATH

RUN chown -R node:node /opt/app
USER node
EXPOSE 1337
CMD ["npm", "run", "start"]

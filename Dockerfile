# Production File 

# Creating multi-stage build for production
FROM node:18-alpine AS build
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git > /dev/null 2>&1
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV NODE_OPTIONS="--max_old_space_size=4096"

WORKDIR /opt/
COPY package.json package-lock.json ./
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install --only=production
ENV PATH=/opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .
RUN npm run build || cat /home/node/.npm/_logs/*.log

# Creating final production image
FROM node:18-alpine
RUN apk add --no-cache vips-dev
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /opt/
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./
ENV PATH=/opt/node_modules/.bin:$PATH

# Ensure proper permissions for the .env file
RUN chown -R node:node /opt/app && chmod -R 755 /opt/app

RUN chown -R node:node /opt/app
USER node
EXPOSE 1337
CMD ["npm", "run", "start"]


# Development
# FROM node:18-alpine3.18
# # FROM node:18-alpine
# # Installing libvips-dev for sharp Compatibility
# RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git
# ARG NODE_ENV=development
# ENV NODE_ENV=${NODE_ENV}
# ENV NODE_OPTIONS="--max_old_space_size=4096"

# WORKDIR /opt/
# COPY package.json package-lock.json ./
# RUN npm install -g node-gyp
# RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install
# ENV PATH=/opt/node_modules/.bin:$PATH

# WORKDIR /opt/app
# COPY . .
# RUN chown -R node:node /opt/app
# USER node
# RUN npm run build || cat /home/node/.npm/_logs/*.log
# EXPOSE 1337
# CMD ["npm", "run", "develop"]

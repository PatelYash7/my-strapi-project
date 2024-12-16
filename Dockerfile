# Step 1: Build Stage
FROM node:18-alpine AS build

# Install necessary packages
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git > /dev/null 2>&1

# Set environment variables
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Set working directory
WORKDIR /opt/

# Copy package files
COPY package.json package-lock.json ./

# Clean npm cache and install dependencies
RUN npm cache clean --force
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install --omit=dev --legacy-peer-deps

# Add node_modules binaries to PATH
ENV PATH=/opt/node_modules/.bin:$PATH

# Copy application source code and build
WORKDIR /opt/app
COPY . .
RUN npm run build

# Step 2: Production Stage
FROM node:18-alpine

# Install runtime dependencies
RUN apk add --no-cache vips-dev

# Set environment variables
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Set working directory
WORKDIR /opt/

# Copy built application and dependencies
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./

# Add node_modules binaries to PATH
ENV PATH=/opt/node_modules/.bin:$PATH

# Set permissions and user
RUN chown -R node:node /opt/app
USER node

# Expose application port
EXPOSE 1337

# Start application
CMD ["npm", "run", "start"]

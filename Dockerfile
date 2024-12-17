# Step 1: Build Stage
FROM node:18-alpine AS build

# Install necessary build dependencies
RUN apk update && apk add --no-cache \
  build-base \
  gcc \
  autoconf \
  automake \
  zlib-dev \
  libpng-dev \
  vips-dev \
  git \
  && rm -rf /var/cache/apk/*  # Clean up APK cache to reduce image size

# Set environment variables for the build
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV NODE_OPTIONS="--max_old_space_size=2048"

# Set working directory
WORKDIR /opt/

# Copy package files and install dependencies
COPY package.json package-lock.json ./
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install --only=production

# Add node_modules binaries to PATH
ENV PATH=/opt/node_modules/.bin:$PATH

# Copy application source code and build
WORKDIR /opt/app
COPY . .
RUN npm run build

# Step 2: Production Stage (Final Image)
FROM node:18-alpine

# Install runtime dependencies (VIPS for image processing)
RUN apk add --no-cache vips-dev && rm -rf /var/cache/apk/*  # Clean up APK cache to reduce image size

# Set environment variables
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Set working directory
WORKDIR /opt/

# Copy the node_modules and application build from the build stage
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./

# Add node_modules binaries to PATH
ENV PATH=/opt/node_modules/.bin:$PATH

# Set proper permissions for the application directory
RUN chown -R node:node /opt/app

# Switch to the 'node' user for security
USER node

# Expose application port
EXPOSE 1337

# Run the application in production mode
CMD ["npm", "run", "start"]

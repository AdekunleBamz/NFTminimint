# NFTminimint Dockerfile
# Development environment for Hardhat smart contract development

FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache git python3 make g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Create directories for artifacts
RUN mkdir -p artifacts cache

# Expose ports
EXPOSE 8545

# Set environment variables
ENV NODE_ENV=development

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD npm run compile || exit 1

# Default command
CMD ["npm", "run", "compile"]
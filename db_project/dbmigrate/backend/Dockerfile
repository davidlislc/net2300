# Use Node.js 18 LTS Alpine (lightweight Linux distribution)
FROM node:18-alpine

# Install additional dependencies if needed
# RUN apk add --no-cache git python3 make g++

# Create app directory
WORKDIR /app

# Copy package files first (for better layer caching)
COPY package*.json ./

# Install production dependencies only
RUN npm install --production && \
    npm cache clean --force

# Copy application source code
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application
CMD ["node", "server.js"]

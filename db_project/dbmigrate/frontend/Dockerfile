# ============================================
# Build Stage: Use Node.js to build React app
# ============================================
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm install && \
    npm cache clean --force

# Copy source files
COPY . .

# Build the React app for production
RUN npm run build

# ============================================
# Production Stage: Use Apache HTTP Server
# ============================================
FROM httpd:2.4-alpine

# Copy custom Apache configuration
COPY apache.conf /usr/local/apache2/conf/httpd.conf

# Copy built files from build stage
COPY --from=build /app/build /usr/local/apache2/htdocs/

# Create non-root user for security
RUN addgroup -g 1001 -S apache && \
    adduser -S apache -u 1001 && \
    chown -R apache:apache /usr/local/apache2/htdocs

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start Apache in foreground
CMD ["httpd-foreground"]

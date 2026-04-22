# Apache HTTP Server Configuration

The frontend React application is served using **Apache HTTP Server 2.4** in a Docker container.

## Configuration Files

### `apache.conf`
Main Apache configuration file that includes:
- **React Router Support**: Rewrites all routes to `index.html` for client-side routing
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Gzip Compression**: Compresses text, CSS, JavaScript, JSON, and XML files
- **Cache Control**: Sets long-term caching for static assets (1 year)
- **MIME Types**: Proper content type handling

### `.htaccess` (Alternative)
Located in `public/.htaccess`, this provides an alternative configuration method if you need to use `.htaccess` instead of main config.

## Key Features

### 1. React Router Support
```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-l
RewriteRule . /index.html [L]
```
This ensures all routes are handled by React Router on the client side.

### 2. Security Headers
```apache
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "no-referrer-when-downgrade"
```

### 3. Compression
```apache
AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
AddOutputFilterByType DEFLATE application/javascript application/json
```
Reduces bandwidth usage and improves load times.

### 4. Static Asset Caching
```apache
ExpiresByType image/jpg "access plus 1 year"
ExpiresByType text/css "access plus 1 year"
ExpiresByType application/javascript "access plus 1 year"
```
Browsers cache static files for better performance.

## Docker Container

The frontend uses a multi-stage Docker build:

1. **Build Stage**: Uses Node.js to build the React app
2. **Production Stage**: Uses Apache HTTP Server 2.4 Alpine image

```dockerfile
FROM httpd:2.4-alpine
COPY apache.conf /usr/local/apache2/conf/httpd.conf
COPY --from=build /app/build /usr/local/apache2/htdocs/
```

## Testing Apache Configuration

### Inside the container:
```bash
# Enter the frontend container
docker compose exec frontend sh

# Test configuration syntax
httpd -t

# View loaded modules
httpd -M

# View configuration
cat /usr/local/apache2/conf/httpd.conf
```

### View Apache logs:
```bash
# Access logs
docker compose logs frontend

# Follow logs in real-time
docker compose logs -f frontend
```

## Troubleshooting

### React Router not working (404 errors)
- Ensure `mod_rewrite` is loaded in `apache.conf`
- Verify RewriteEngine is On
- Check file permissions in `/usr/local/apache2/htdocs/`

### Configuration syntax errors
```bash
docker compose exec frontend httpd -t
```

### Permission issues
```bash
docker compose exec frontend ls -la /usr/local/apache2/htdocs/
```

## Customization

### Adding custom headers:
Edit `apache.conf` and add:
```apache
<IfModule mod_headers.c>
    Header set Custom-Header "Value"
</IfModule>
```

### Changing document root:
```apache
DocumentRoot "/usr/local/apache2/htdocs"
```

### Adding SSL (HTTPS):
1. Uncomment SSL modules in `apache.conf`
2. Add SSL certificate files
3. Update `docker-compose.yml` to expose port 443
4. Configure SSL virtual host

## Performance Tips

1. **Keep compression enabled** for text-based files
2. **Set appropriate cache headers** for static assets
3. **Enable HTTP/2** (requires SSL):
   ```apache
   LoadModule http2_module modules/mod_http2.so
   Protocols h2 h2c http/1.1
   ```
4. **Use Apache MPM Event** (already configured) for better performance

## Why Apache over Nginx?

- **Familiarity**: Apache is well-known in enterprise environments
- **.htaccess support**: Dynamic configuration without reloading
- **mod_rewrite**: Powerful URL rewriting capabilities
- **Enterprise support**: Better integration with Red Hat/Rocky Linux
- **Extensive modules**: Large ecosystem of available modules

## Resources

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/2.4/)
- [Apache Docker Hub](https://hub.docker.com/_/httpd)
- [mod_rewrite Guide](https://httpd.apache.org/docs/2.4/rewrite/)

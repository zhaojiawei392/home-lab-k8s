FROM nextcloud:latest

# Switch to root to modify permissions
USER root

WORKDIR /var/www/html

# Set correct permissions for Nextcloud directories
RUN chown -R 777 .

# Switch back to www-data user
USER www-data
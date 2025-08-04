# Use Nginx as the base image
FROM nginx:alpine

# Remove default Nginx static content
RUN rm -rf /usr/share/nginx/html/*

# Copy build files from dist folder to Nginx HTML directory
COPY dist/ /usr/share/nginx/html/

# Update Nginx config to listen on port 3000 on all IPs
RUN sed -i 's/listen       80;/listen       3000;/' /etc/nginx/conf.d/default.conf \
 && sed -i 's/listen  \[::\]:80;/listen  [::]:3000;/' /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

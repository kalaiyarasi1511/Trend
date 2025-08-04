# Use Nginx as base image
FROM nginx:alpine

# Remove default Nginx HTML
RUN rm -rf /usr/share/nginx/html/*

# Copy build files to Nginx HTML folder
COPY dist/ /usr/share/nginx/html/

# Expose port 3000
EXPOSE 3000

# Change Nginx config to listen on port 3000
RUN sed -i 's/listen       80;/listen       3000;/g' /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]

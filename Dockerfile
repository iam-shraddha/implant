FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    curl \
    npm \
    mysql-server \
    supervisor \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create app directories
RUN mkdir -p /app/backend /app/frontend

# Copy backend JAR
COPY BE-Hyper--main/BE-Hyper-main/build/libs/myapp.jar /app/backend/myapp.jar

# Copy frontend source
COPY implantweb-main/implantweb-main /app/frontend

# Copy supervisord config
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy SQL dump
COPY implant_dump.sql /docker-entrypoint-initdb.d/implant_dump.sql

WORKDIR /app/frontend

RUN npm install && npm run build

EXPOSE 8080 3000 3306

# MySQL initialisation
RUN service mysql start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS implant;" && \
    mysql implant < /docker-entrypoint-initdb.d/implant_dump.sql && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'Hyperminds@2025';" && \
    mysql -e "GRANT ALL PRIVILEGES ON implant.* TO 'root'@'%';" && \
    mysql -e "FLUSH PRIVILEGES;"

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

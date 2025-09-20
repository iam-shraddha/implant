# ----------------------------
# Stage 1: Build Backend
# ----------------------------
FROM gradle:7.6.0-jdk17 AS backend-build
WORKDIR /app

# Copy only backend source to reduce cache
COPY BE-Hyper--main/BE-Hyper-main/build.gradle.kts ./ 
COPY BE-Hyper--main/BE-Hyper-main/settings.gradle.kts ./
COPY BE-Hyper--main/BE-Hyper-main/gradlew ./
COPY BE-Hyper--main/BE-Hyper-main/gradlew.bat ./
COPY BE-Hyper--main/BE-Hyper-main/gradle ./gradle
COPY BE-Hyper--main/BE-Hyper-main/src ./src

RUN chmod +x ./gradlew
RUN ./gradlew bootJar --no-daemon -x test

# ----------------------------
# Stage 2: Build Frontend
# ----------------------------
FROM node:18-alpine AS frontend-build
WORKDIR /app

# Copy only package files first for caching
COPY implantweb-main/implantweb-main/package.json ./ 
COPY implantweb-main/implantweb-main/package-lock.json ./

RUN npm install --silent

# Copy full frontend repo and build
COPY implantweb-main/implantweb-main/ ./
RUN npm run build

# ----------------------------
# Stage 3: Final Image (Slim)
# ----------------------------
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy backend JAR
COPY --from=backend-build /app/build/libs/myapp.jar myapp.jar

# Copy frontend build
COPY --from=frontend-build /app/build app/static

# Expose ports
EXPOSE 8080 3000

# Environment variables for MySQL
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/implant?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
ENV SPRING_DATASOURCE_USERNAME=root
ENV SPRING_DATASOURCE_PASSWORD=Hyperminds@2025

# Start backend (Spring Boot serves frontend static files)
ENTRYPOINT ["java", "-jar", "myapp.jar"]

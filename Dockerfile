# ----------------------------
# Stage 1: Build Backend
# ----------------------------
FROM gradle:7.6.0-jdk17 AS backend-build
WORKDIR /app

# Copy only backend source to reduce cache
COPY backend/build.gradle.kts backend/settings.gradle.kts backend/gradlew backend/gradlew.bat backend/gradle ./ 
COPY backend/src ./src

RUN chmod +x ./gradlew
RUN ./gradlew bootJar --no-daemon -x test

# ----------------------------
# Stage 2: Build Frontend
# ----------------------------
FROM node:18-alpine AS frontend-build
WORKDIR /app

COPY frontend/package*.json ./
RUN npm install --silent

COPY frontend/ .
RUN npm run build

# ----------------------------
# Stage 3: Final Image (Slim)
# ----------------------------
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy backend jar
COPY --from=backend-build /app/build/libs/*.jar backend.jar

# Copy frontend build
COPY --from=frontend-build /app/build frontend/build

# Expose ports
EXPOSE 8080 3000

# Optional environment variables for MySQL
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/implant?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
ENV SPRING_DATASOURCE_USERNAME=root
ENV SPRING_DATASOURCE_PASSWORD=Hyperminds@2025

# Start backend (Spring Boot serves frontend static files)
ENTRYPOINT ["java", "-jar", "backend.jar"]

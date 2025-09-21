# ----------------------------
# Stage 1: Build Frontend
# ----------------------------
FROM node:18-alpine AS frontend-build
WORKDIR /frontend
COPY implantweb-main/implantweb-main/package*.json ./
RUN npm install --silent
COPY implantweb-main/implantweb-main/ ./
RUN npm run build

# ----------------------------
# Stage 2: Build Backend
# ----------------------------
FROM gradle:7.6.0-jdk17 AS backend-build
WORKDIR /backend
COPY BE-Hyper--main/BE-Hyper-main/ ./

# Copy React build into Spring Boot static folder
COPY --from=frontend-build /frontend/build ./src/main/resources/static

RUN chmod +x gradlew && ./gradlew bootJar --no-daemon -x test

# ----------------------------
# Stage 3: Final Image
# ----------------------------
FROM openjdk:17-jdk-slim
WORKDIR /app

COPY --from=backend-build /backend/build/libs/*.jar myapp.jar

EXPOSE 8080


# MySQL connection settings
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/implant?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC \
    SPRING_DATASOURCE_USERNAME=root \
    SPRING_DATASOURCE_PASSWORD=Hyperminds@2025 \
    SERVER_ADDRESS=0.0.0.0


ENTRYPOINT ["java", "-jar", "myapp.jar"]

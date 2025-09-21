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

# Do NOT hardcode passwords here—pass them at runtime or via secrets manager.
# Example runtime usage:
# docker run -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/implant \
#            -e SPRING_DATASOURCE_USERNAME=root \
#            -e SPRING_DATASOURCE_PASSWORD=Hyperminds@2025 \
#            -p 8080:8080 implant-app

ENTRYPOINT ["java", "-jar", "myapp.jar"]

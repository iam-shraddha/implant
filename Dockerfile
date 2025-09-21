# ----------------------------
# Stage 1: Build Backend
# ----------------------------
FROM gradle:7.6.0-jdk17 AS backend-build
WORKDIR /app

COPY BE-Hyper--main/BE-Hyper-main/ ./ 
RUN chmod +x ./gradlew
RUN ./gradlew bootJar --no-daemon -x test

# ----------------------------
# Stage 2: Build Frontend
# ----------------------------
FROM node:18-alpine AS frontend-build
WORKDIR /app

COPY implantweb-main/implantweb-main/package*.json ./
RUN npm install --silent
COPY implantweb-main/implantweb-main/ ./
RUN npm run build

# ----------------------------
# Stage 3: Final Image
# ----------------------------
FROM node:18-bullseye AS final
WORKDIR /app

# Install JDK
RUN apt-get update && apt-get install -y openjdk-17-jdk && rm -rf /var/lib/apt/lists/*

# Copy backend
COPY --from=backend-build /app/build/libs/myapp.jar myapp.jar

# Copy frontend
COPY --from=frontend-build /app/build /app/frontend

# Expose ports
EXPOSE 3000 8080

# Start backend and frontend
RUN npm install -g serve
CMD ["sh", "-c", "java -jar myapp.jar & serve -s /app/frontend -l 3000"]

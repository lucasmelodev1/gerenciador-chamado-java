# ---------- STAGE 1 : BUILD ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline

COPY src ./src

RUN mvn clean package -DskipTests


# ---------- STAGE 2 : RUNTIME ----------
FROM eclipse-temurin:21-jdk-jammy AS runtime

WORKDIR /app

# copia apenas o WAR gerado
COPY --from=build /app/target/*.war app.war

EXPOSE 8080


# ---------- STAGE 3 : TEST ----------
FROM build AS test

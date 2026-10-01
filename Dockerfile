# ---------- STAGE 0 : FRONTEND ----------
# Compila o CSS (Tailwind CSS 4 + daisyUI 5) a partir das views JSP.
# O bundle NAO e versionado: e artefato gerado, produzido aqui e em `npm run build:css`.
FROM node:22-alpine AS frontend

WORKDIR /ui

# O diretorio e espelhado (src/main/...), porque os `@source` do app.css sao relativos
# ao proprio arquivo CSS e apontam para as views JSP, o JS e a galeria de componentes.
COPY package.json package-lock.json ./

RUN npm ci --no-audit --no-fund

COPY src/main/resources/static/css/app.css ./src/main/resources/static/css/app.css
COPY src/main/resources/static/js ./src/main/resources/static/js
COPY src/main/resources/static/ui-preview.html ./src/main/resources/static/ui-preview.html
COPY src/main/webapp ./src/main/webapp

RUN npm run build:css


# ---------- STAGE 1 : BUILD ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline

COPY src ./src

# bundle compilado pelo estagio frontend
COPY --from=frontend /ui/src/main/resources/static/css/app.build.css src/main/resources/static/css/app.build.css

RUN mvn clean package -DskipTests


# ---------- STAGE 2 : RUNTIME ----------
FROM eclipse-temurin:21-jdk-jammy AS runtime

WORKDIR /app

# copia apenas o WAR gerado
COPY --from=build /app/target/*.war app.war

EXPOSE 8080


# ---------- STAGE 3 : TEST ----------
FROM build AS test

# ============================================================
# STAGE 1 - BUILD
# Usa Maven + JDK 17 para compilar el JAR
# ============================================================
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copiar solo pom.xml primero para aprovechar caché de capas
# Si el pom.xml no cambia, Maven no re-descarga dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Ahora copiar el código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ============================================================
# STAGE 2 - RUNTIME
# Imagen mínima solo con JRE para ejecutar el JAR
# Reduce tamaño final (~200MB vs ~600MB con JDK completo)
# ============================================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Crear usuario no-root por seguridad (evita privilege escalation)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar solo el JAR generado desde la etapa de build
COPY --from=builder /app/target/*.jar app.jar

# Asignar propietario correcto al JAR
RUN chown appuser:appgroup app.jar

# Cambiar al usuario no-root ANTES de ejecutar la app
USER appuser

# Puerto en el que escucha la aplicación (según application.properties)
EXPOSE 8081

# Health check para Docker y orquestadores
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8081/actuator/health || exit 1

# Comando de inicio con opciones JVM optimizadas para contenedores
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]

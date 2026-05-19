# ============================================================
# STAGE 1 - BUILD (opcional, útil si usas Node/npm en el futuro)
# Para HTML/JS estático, esta etapa solo valida y copia
# ============================================================
FROM node:20-alpine AS builder

WORKDIR /app
# Copiar archivos del frontend
COPY . .
# Si existiera un package.json con build script, aquí iría:
# RUN npm ci && npm run build
# Por ahora, los archivos estáticos se usan directamente.

# ============================================================
# STAGE 2 - RUNTIME con Nginx Alpine
# Imagen ultra-ligera (~25MB) para servir archivos estáticos
# ============================================================
FROM nginx:1.27-alpine

# Crear usuario no-root para Nginx
# nginx:alpine ya incluye el usuario 'nginx', lo reutilizamos
# Configuramos Nginx para correr en puerto 8080 (no root)
RUN mkdir -p /var/cache/nginx /var/run/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar los archivos estáticos construidos
COPY --from=builder /app/index.html /usr/share/nginx/html/
# Si tuvieras más archivos (css/, js/, assets/), los copiarías aquí también

# Ajustar permisos
RUN chown -R nginx:nginx /usr/share/nginx/html

# Ejecutar como usuario no-root
USER nginx

# Puerto 8080 (no necesita root, a diferencia del 80)
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

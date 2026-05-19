# 🚀 Guía Completa — Proyecto Semestral ISY1101
## Innovatech Chile: Docker + AWS EC2 + GitHub Actions

---

## 📁 Estructura del Repositorio

```
proyecto-semestral/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Pipeline CI/CD (GitHub Actions)
├── backend/
│   ├── Dockerfile              ← Imagen Spring Boot (multi-stage)
│   └── [código fuente Spring Boot]
├── frontend/
│   ├── Dockerfile              ← Imagen Nginx (multi-stage)
│   ├── nginx.conf              ← Configuración Nginx no-root
│   └── index.html              ← App web
├── mysql/
│   └── init.sql                ← Script inicialización BD
├── docker-compose.yml          ← Para desarrollo local
├── .env.example                ← Plantilla variables de entorno
└── GUIA.md                     ← Este archivo
```

---

## PARTE 1 — PRUEBA LOCAL CON DOCKER COMPOSE

### Prerrequisitos
- Docker Desktop instalado
- Git instalado

### Pasos

**1. Clonar el repositorio**
```bash
git clone https://github.com/TU_USUARIO/proyecto-semestral.git
cd proyecto-semestral
```

**2. Crear archivo .env**
```bash
cp .env.example .env
# Editar .env con tus contraseñas deseadas
```

**3. Copiar el código del backend**
```bash
# El directorio backend/ debe contener el código Spring Boot completo
# (el directorio Springboot-API-REST-DESPACHO con pom.xml, src/, etc.)
cp -r ../back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/* backend/
```

**4. Levantar todos los servicios**
```bash
docker compose up --build
```

**5. Verificar que todo funciona**
- Frontend: http://localhost:80
- Backend API: http://localhost:3001/api/v1/despachos
- Swagger UI: http://localhost:3001/swagger-ui.html

**6. Comandos útiles**
```bash
# Ver logs de un servicio
docker compose logs -f backend

# Ver estado de contenedores
docker compose ps

# Detener todo
docker compose down

# Detener y eliminar volúmenes (borra la BD)
docker compose down -v
```

---

## PARTE 2 — CONFIGURACIÓN AWS

### 2.1 Crear VPC y Subredes

1. En AWS Console → **VPC** → **Create VPC**
   - Nombre: `innovatech-vpc`
   - IPv4 CIDR: `10.0.0.0/16`

2. Crear subredes:
   - `subnet-publica` (10.0.1.0/24) → para Frontend
   - `subnet-privada-backend` (10.0.2.0/24) → para Backend
   - `subnet-privada-db` (10.0.3.0/24) → para Base de Datos

3. Crear **Internet Gateway** y asociarlo a la VPC

4. Configurar **Route Table** de la subred pública para que apunte al Internet Gateway

### 2.2 Crear Grupos de Seguridad

**SG-Frontend** (ec2-frontend-sg)
| Tipo  | Puerto | Origen        | Propósito              |
|-------|--------|---------------|------------------------|
| HTTP  | 80     | 0.0.0.0/0     | Web pública            |
| TCP   | 8080   | 0.0.0.0/0     | Puerto alternativo web |
| SSH   | 22     | Tu IP         | Administración         |
| ICMP  | -      | 0.0.0.0/0     | Ping/diagnóstico       |

**SG-Backend** (ec2-backend-sg)
| Tipo  | Puerto | Origen          | Propósito           |
|-------|--------|-----------------|---------------------|
| TCP   | 3001   | SG-Frontend     | API desde Frontend  |
| SSH   | 22     | Tu IP           | Administración      |
| ICMP  | -      | SG-Frontend     | Ping/diagnóstico    |

**SG-Database** (ec2-db-sg)
| Tipo  | Puerto | Origen          | Propósito           |
|-------|--------|-----------------|---------------------|
| MySQL | 3306   | SG-Backend      | BD desde Backend    |
| SSH   | 22     | Tu IP           | Administración      |
| ICMP  | -      | SG-Backend      | Ping/diagnóstico    |

### 2.3 Lanzar Instancias EC2

Para cada instancia (Frontend, Backend, Database):

1. **EC2** → **Launch Instance**
2. AMI: **Amazon Linux 2023** (o Ubuntu 22.04)
3. Instance type: `t2.micro` (capa gratuita)
4. Key pair: crear o usar uno existente (guarda el .pem)
5. Network settings:
   - VPC: `innovatech-vpc`
   - Subred: la correspondiente a cada servicio
   - Auto-assign Public IP: **Habilitado solo para Frontend**
   - Security Group: el correspondiente
6. Storage: 20 GB gp3

### 2.4 Instalar Docker en Cada EC2

Conectarse por SSH y ejecutar en **las 3 instancias**:

```bash
# Amazon Linux 2023
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
# Cerrar y reconectar la sesión SSH para que surta efecto

# Verificar
docker --version
```

### 2.5 Levantar MySQL en EC2-Database

```bash
# Crear volumen para persistencia
docker volume create mysql_data

# Iniciar MySQL
docker run -d \
  --name innovatech-db \
  --restart unless-stopped \
  -p 3306:3306 \
  -v mysql_data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=tu_password_root \
  -e MYSQL_DATABASE=despachos_db \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=tu_password_app \
  mysql:8.0

# Verificar que está corriendo
docker ps
docker logs innovatech-db
```

---

## PARTE 3 — CONFIGURACIÓN GITHUB ACTIONS

### 3.1 Crear cuenta Docker Hub

1. Ir a https://hub.docker.com
2. Crear cuenta (es gratis)
3. Crear repositorios públicos:
   - `TU_USUARIO/innovatech-backend`
   - `TU_USUARIO/innovatech-frontend`
4. Crear **Access Token**: Account → Security → New Access Token

### 3.2 Generar par de claves SSH para cada EC2

En tu computador local (una vez por EC2):
```bash
ssh-keygen -t ed25519 -C "github-actions-frontend" -f ~/.ssh/innovatech_frontend
ssh-keygen -t ed25519 -C "github-actions-backend"  -f ~/.ssh/innovatech_backend
```

Agregar la clave pública a cada EC2:
```bash
# Conectarse a EC2-Frontend y ejecutar:
echo "CONTENIDO_DE_innovatech_frontend.pub" >> ~/.ssh/authorized_keys

# Conectarse a EC2-Backend y ejecutar:
echo "CONTENIDO_DE_innovatech_backend.pub" >> ~/.ssh/authorized_keys
```

### 3.3 Agregar Secrets en GitHub

Ir a tu repositorio → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret                  | Valor                                         |
|-------------------------|-----------------------------------------------|
| `DOCKERHUB_USERNAME`    | Tu usuario Docker Hub                         |
| `DOCKERHUB_TOKEN`       | Token generado en Docker Hub                  |
| `EC2_FRONTEND_HOST`     | IP pública de la EC2 Frontend                 |
| `EC2_FRONTEND_USER`     | `ec2-user` (Amazon Linux) o `ubuntu`          |
| `EC2_FRONTEND_SSH_KEY`  | Contenido del archivo `innovatech_frontend`   |
| `EC2_BACKEND_HOST`      | IP privada de la EC2 Backend                  |
| `EC2_BACKEND_USER`      | `ec2-user` (Amazon Linux) o `ubuntu`          |
| `EC2_BACKEND_SSH_KEY`   | Contenido del archivo `innovatech_backend`    |
| `DB_ENDPOINT`           | IP privada de la EC2 Database                 |
| `DB_NAME`               | `despachos_db`                                |
| `DB_USERNAME`           | `appuser`                                     |
| `DB_PASSWORD`           | Tu contraseña de base de datos                |

### 3.4 Activar el Pipeline

```bash
# Asegurarse de estar en la rama main con todo listo
git add .
git commit -m "feat: configuración Docker y CI/CD completa"
git push origin main

# Crear y pushear la rama deploy para activar el pipeline
git checkout -b deploy
git push origin deploy
```

Ir a **Actions** en GitHub para ver el pipeline ejecutándose.

---

## PARTE 4 — VERIFICACIÓN FINAL

### Checklist de Funcionamiento

- [ ] `docker compose up` funciona localmente sin errores
- [ ] Frontend accesible en http://localhost:80
- [ ] Backend responde en http://localhost:3001/api/v1/despachos
- [ ] Crear un despacho desde el frontend y verlo en la tabla
- [ ] Pipeline de GitHub Actions completa sin errores
- [ ] Frontend accesible desde IP pública de EC2 en AWS
- [ ] Backend accesible desde el frontend pero NO desde internet directamente
- [ ] MySQL solo accesible desde el backend
- [ ] Los datos persisten después de reiniciar los contenedores (`docker compose down && docker compose up`)

### Comandos de Diagnóstico

```bash
# Ver imágenes construidas
docker images

# Ver contenedores en ejecución
docker ps

# Ver logs en tiempo real
docker logs -f innovatech-backend

# Entrar a un contenedor (debugging)
docker exec -it innovatech-backend sh

# Probar conexión al backend desde el frontend EC2
curl http://<IP_PRIVADA_BACKEND>:3001/api/v1/despachos

# Probar conexión a MySQL desde el backend EC2
docker exec -it innovatech-backend sh
# Dentro del contenedor:
# wget -qO- http://localhost:8081/api/v1/despachos
```

---

## Justificación Técnica para la Presentación

### Dockerfile Multi-Stage Build
El backend usa **multi-stage build** con dos etapas:
1. **Builder**: imagen Maven completa (~600MB) para compilar el JAR
2. **Runtime**: imagen JRE Alpine mínima (~200MB) con solo lo necesario

**Ventaja**: la imagen final es ~3x más pequeña, menor superficie de ataque.

### Ejecución con Usuario No-Root
Ambos Dockerfiles crean usuarios sin privilegios de root antes de ejecutar la app. Esto sigue el principio de mínimos privilegios: si hay una vulnerabilidad en la app, el atacante no obtiene acceso root al host.

### Docker Compose y Redes
Se definen **dos redes separadas**:
- `frontend-backend-net`: frontend ↔ backend
- `backend-db-net`: backend ↔ MySQL

MySQL no está conectado a la red del frontend, igual que en AWS donde la base de datos solo acepta tráfico desde el grupo de seguridad del backend.

### Variables de Entorno y Secrets
Las credenciales nunca están en el código. En desarrollo se usan en `.env` (ignorado por git). En producción, se inyectan desde los GitHub Secrets directamente al contenedor Docker.

### Pipeline CI/CD
El pipeline tiene **3 jobs** secuenciales/paralelos:
1. `build-and-push`: construye ambas imágenes y las sube a Docker Hub
2. `deploy-backend`: (post-build) se conecta por SSH a EC2 y actualiza el backend
3. `deploy-frontend`: (post-build) se conecta por SSH a EC2 y actualiza el frontend

Los jobs 2 y 3 usan `needs: build-and-push` para garantizar que solo se despliega si el build fue exitoso.

#!/bin/bash

# ==========================================
# SCRIPT DE RESPALDO (BACKUP) DE MONGODB
# ==========================================

# 1. Nos movemos al directorio raíz de la infraestructura
cd "$(dirname "$0")/.."

# 2. Cargar las contraseñas desde el archivo .env
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
else
  echo "Error: No se encontró el archivo .env"
  exit 1
fi

# 3. Crear la carpeta de respaldos si no existe
mkdir -p backups

# 4. Generar el nombre del archivo con fecha y hora exacta
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backups/tokatribe_backup_${DATE}.archive.gz"

echo "⏳ Iniciando respaldo de la base de datos 'tokatribe'..."

# 5. Ejecutar mongodump dentro del contenedor de Docker
# Usamos el usuario de aplicación para cumplir el principio de menor privilegio
docker exec tokatribe-mongo mongodump \
  --uri="mongodb://${MONGO_APP_USER}:${MONGO_APP_PASSWORD}@127.0.0.1:27017/tokatribe?replicaSet=rs0&authSource=tokatribe" \
  --archive --gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "Respaldo completado con éxito: $BACKUP_FILE"
else
  echo "Error al crear el respaldo."
  rm -f "$BACKUP_FILE"
  exit 1
fi

# 6. Limpieza: Borrar backups con más de 7 días de antigüedad para ahorrar espacio
echo "Buscando respaldos antiguos..."
find backups/ -type f -name "*.archive.gz" -mtime +7 -exec rm {} \;
echo "Limpieza finalizada."
#!/bin/bash

set -euo pipefail

: "${MONGO_ROOT_USER:?Falta MONGO_ROOT_USER}"
: "${MONGO_ROOT_PASSWORD:?Falta MONGO_ROOT_PASSWORD}"
: "${MONGO_APP_USER:?Falta MONGO_APP_USER}"
: "${MONGO_APP_PASSWORD:?Falta MONGO_APP_PASSWORD}"
MONGO_APP_DB="${MONGO_APP_DB:-tokatribe}"

echo "Esperando a que MongoDB acepte conexiones autenticadas..."
until mongosh --host mongo:27017 \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --quiet \
  --eval 'db.adminCommand({ ping: 1 }).ok' | grep -q "1"; do
  sleep 2
done

echo "Inicializando Replica Set (rs0) si hace falta..."
mongosh --host mongo:27017 \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval '
try {
  const status = rs.status();
  print("Replica Set ya inicializado: " + status.set);
} catch (e) {
  rs.initiate({ _id: "rs0", members: [{ _id: 0, host: "mongo:27017" }] });
  print("Replica Set inicializado con exito.");
}
'

echo "Esperando a que el nodo sea PRIMARY..."
until mongosh --host mongo:27017 \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --quiet \
  --eval 'db.hello().isWritablePrimary ? 1 : 0' | grep -q "1"; do
  sleep 2
done

echo "Creando usuario de aplicacion en ${MONGO_APP_DB} (si no existe)..."
mongosh --host mongo:27017 \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval '
const appDbName = process.env.MONGO_APP_DB || "tokatribe";
const appUser = process.env.MONGO_APP_USER;
const appPassword = process.env.MONGO_APP_PASSWORD;
const appDb = db.getSiblingDB(appDbName);

if (appDb.getUser(appUser)) {
  print("Usuario de aplicacion ya existe: " + appUser);
} else {
  appDb.createUser({
    user: appUser,
    pwd: appPassword,
    roles: [{ role: "readWrite", db: appDbName }]
  });
  print("Usuario de aplicacion creado: " + appUser);
}
'

echo "Inicializacion de Mongo completada."
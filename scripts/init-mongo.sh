#!/bin/bash

echo "Esperando a que MongoDB inicie..."
sleep 5

echo "Inicializando Replica Set (rs0)..."
mongosh --host mongo:27017 --eval '
try {
  rs.status();
  print("El Replica Set ya está inicializado.");
} catch (e) {
  rs.initiate({ _id: "rs0", members: [{ _id: 0, host: "mongo:27017" }] });
  print("Replica Set inicializado con éxito.");
}
'
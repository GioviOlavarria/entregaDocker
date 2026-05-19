-- Script de inicialización de la base de datos
-- Se ejecuta automáticamente al crear el contenedor por primera vez

CREATE DATABASE IF NOT EXISTS despachos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE despachos_db;

-- La tabla la crea Hibernate automáticamente (ddl-auto=update)
-- Este script puede usarse para datos de prueba iniciales

-- Datos de ejemplo (opcional)
-- INSERT INTO despacho (fecha_despacho, patente_camion, intento, id_compra, direccion_compra, valor_compra, despachado)
-- VALUES ('2025-05-01', 'ABCD12', 1, 1001, 'Av. Providencia 123, Santiago', 50000, false);

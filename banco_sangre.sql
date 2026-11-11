-- Banco de sangre (PostgreSQL)
-- Antes de ejecutar, crear la base:  createdb banco_sangre
-- Ejecutar con:  psql -d banco_sangre < banco_sangre.sql

-- Tipos de sangre (Solo los tipos validos para donante y bolsa)
CREATE TABLE tipo_sangre (
    id      SERIAL PRIMARY KEY,
    tipo  VARCHAR(3) NOT NULL UNIQUE      -- 'A+', 'O-', etc.
);

INSERT INTO tipo_sangre (tipo) VALUES
    ('A+'), ('A-'), ('B+'), ('B-'), ('AB+'), ('AB-'), ('O+'), ('O-');

-- TABLA UBICACION (hospitales, refrigeradores, etc.)
CREATE TABLE ubicacion (
    id      SERIAL PRIMARY KEY,
    nombre_ubicacion  VARCHAR(100) NOT NULL           -- 'Refrigerador 1'
);

-- TABLA DONANTE 
CREATE TABLE donante (
    id              SERIAL PRIMARY KEY,
    nombre_donante          VARCHAR(100) NOT NULL,
    tipo_sangre_id  INTEGER REFERENCES tipo_sangre(id)
);

-- TABLA UNIDAD DE SANGRE 
CREATE TABLE unidad_sangre (
    id               SERIAL PRIMARY KEY,
    tipo_sangre_id   INTEGER   NOT NULL REFERENCES tipo_sangre(id), 
    donante_id       INTEGER   REFERENCES donante(id),
    ubicacion_id     INTEGER   NOT NULL REFERENCES ubicacion(id),
    fecha_hora_extraccion  TIMESTAMP NOT NULL,
    fecha_caducidad  DATE      NOT NULL
);




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
CREATE TABLE cargo_personal (
    id SERIAL PRIMARY KEY,
    nombre_cargo VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(250) NOT NULL
);

CREATE TABLE personal_salud (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_cargo INTEGER NOT NULL REFERENCES cargo_personal(id),
    correo VARCHAR(100) UNIQUE
);

-- La extracción genera una unidad/bolsa con su propia fecha de vencimiento
CREATE TABLE extraccion (
    id SERIAL PRIMARY KEY,
    id_donante INTEGER NOT NULL REFERENCES donante(id),
    id_personal INTEGER NOT NULL REFERENCES personal_salud(id),
    fecha_extraccion DATE NOT NULL DEFAULT CURRENT_DATE,
    vigencia_dias INTEGER NOT NULL DEFAULT 35, -- Ej: 35 o 42 días para glóbulos rojos
    fecha_vencimiento DATE GENERATED ALWAYS AS (fecha_extraccion + vigencia_dias) STORED
);

-- La petición la hace un servicio médico para un paciente (idealmente tabla paciente)
CREATE TABLE peticion_sangre (
    id SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL REFERENCES paciente(id), 
    id_tipo INTEGER NOT NULL REFERENCES tipo_sangre(id),
    cantidad_ml FLOAT NOT NULL,
    prioridad VARCHAR(50) NOT NULL,
    fecha_solicitud TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);




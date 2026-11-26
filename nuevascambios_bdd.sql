
-- ----------------------------------------------------------------------------
-- cambios realizados a la base de datos por Gonza                           --
-- ----------------------------------------------------------------------------
BEGIN;

-- ----------------------------------------------------------------------------
-- Creación de la tabla de citas 
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cita (
    id_cita SERIAL PRIMARY KEY,
    id_donante INTEGER NOT NULL REFERENCES donante(id) ON DELETE CASCADE,
    id_personal INTEGER NULL REFERENCES personal_salud(id) ON DELETE SET NULL,
    fecha_hora TIMESTAMP NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'completada', 'cancelada')),
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- Actualizar restricción de estados en peticion_sangre ('en camino')
-- ----------------------------------------------------------------------------
ALTER TABLE peticion_sangre 
DROP CONSTRAINT IF EXISTS peticion_sangre_estado_check;

ALTER TABLE peticion_sangre 
ADD CONSTRAINT peticion_sangre_estado_check 
CHECK (estado IN ('pendiente', 'en camino', 'completada', 'cancelada'));

-- ----------------------------------------------------------------------------
-- Asegurar existencia del cargo 11 e insertar 5 transportistas de sangre
-- ----------------------------------------------------------------------------
INSERT INTO cargo_personal (id, nombre) 
VALUES (11, 'Transportista de sangre') 
ON CONFLICT (id) DO NOTHING;

INSERT INTO personal_salud (nombre, id_cargo, correo) VALUES
    ('Matías Esteban Rojas Valdés', 11, 'mrojas.transporte@bloodlink.cl'),
    ('Camila Fernanda Herrera Soto', 11, 'cherrera.transporte@bloodlink.cl'),
    ('Sebastián Ignacio Muñoz Díaz', 11, 'smunoz.transporte@bloodlink.cl'),
    ('Valentina Paz Contreras Silva', 11, 'vcontreras.transporte@bloodlink.cl'),
    ('Cristóbal Andrés Navarro Pino', 11, 'cnavarro.transporte@bloodlink.cl');

-- ----------------------------------------------------------------------------
-- Creación de la tabla envios y Trigger de validación (solo id_cargo = 11)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS envios (
    id SERIAL PRIMARY KEY,
    id_peticion INTEGER NOT NULL REFERENCES peticion_sangre(id) ON DELETE CASCADE,
    id_transportista INTEGER NOT NULL REFERENCES personal_salud(id) ON DELETE RESTRICT,
    fecha_salida TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega TIMESTAMP NULL,
    observaciones TEXT
);

CREATE OR REPLACE FUNCTION validar_cargo_transportista()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM personal_salud 
        WHERE id = NEW.id_transportista AND id_cargo = 11
    ) THEN
        RAISE EXCEPTION 'Error: El personal_salud con id % no tiene el cargo de Transportista de sangre (id_cargo = 11).', NEW.id_transportista;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_transportista ON envios;

CREATE TRIGGER trg_validar_transportista
BEFORE INSERT OR UPDATE ON envios
FOR EACH ROW
EXECUTE FUNCTION validar_cargo_transportista();

COMMIT;
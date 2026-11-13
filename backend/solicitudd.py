import os
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

# Lee la variable DATABASE_URL desde tu archivo .env o el link directamente por si el .env no funciona
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://neondb_owner:npg_8cJ9pvUmedLh@ep-quiet-brook-b6glc1w6-pooler.c-2.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
)


def get_connection():
    return psycopg2.connect(DATABASE_URL)


# ==========================================
# SETTERS para ingresar datos. 
# Nota: Como dentro de la Base de datos
# el tipo de sangre y id donante son FK,
# si se crea una peticion, se esta obligado
# a que la peticion de sangre este realiona con 
# alguno. Por la sangre no hay problema, pero
# si se intenta ingresar un donante no registrado
# se debe registrar previamente
# ==========================================

def registrar_unidad_sangre(
    nombre_donante: str,
    tipo_sangre: str,
    nombre_ubicacion: str,
    fecha_extraccion: datetime = None,
    dias_vigencia: int = 42,
) -> dict:
    if fecha_extraccion is None:
        fecha_extraccion = datetime.now()
    fecha_caducidad = (fecha_extraccion + timedelta(days=dias_vigencia)).date()

    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                # tipo_sangre_id es un FK, asi que la busca. se debe introducir el nombre
                cur.execute(
                    "SELECT id FROM tipo_sangre WHERE tipo = %s;",
                    (tipo_sangre,),
                )
                fila_tipo = cur.fetchone()
                if not fila_tipo:
                    raise ValueError(f"El tipo de sangre '{tipo_sangre}' no existe en la BD.")
                tipo_sangre_id = fila_tipo[0]

                # busca el id de la ubicacion por el nombre
                cur.execute(
                    "SELECT id FROM ubicacion WHERE nombre_ubicacion = %s;",
                    (nombre_ubicacion,),
                )
                fila_ubicacion = cur.fetchone()
                if not fila_ubicacion:
                    raise ValueError(f"La ubicación '{nombre_ubicacion}' no existe en la BD.")
                ubicacion_id = fila_ubicacion[0]

                # Buscar si el donante ya existe; si no, crearlo dejando que SERIAL asigne su ID
                cur.execute(
                    "SELECT id FROM donante WHERE nombre_donante = %s;",
                    (nombre_donante,),
                )
                fila_donante = cur.fetchone()

                if fila_donante:
                    donante_id = fila_donante[0]
                else:
                    cur.execute(
                        """
                        INSERT INTO donante (nombre_donante, tipo_sangre_id)
                        VALUES (%s, %s)
                        RETURNING id;
                        """,
                        (nombre_donante, tipo_sangre_id),
                    )
                    donante_id = cur.fetchone()[0]

                # Insertar la unidad_sangre sin id (en la base lo guardamos como SERIAL) y capturar el ID generado
                cur.execute(
                    """
                    INSERT INTO unidad_sangre (
                        tipo_sangre_id, donante_id, ubicacion_id, fecha_hora_extraccion, fecha_caducidad
                    ) VALUES (%s, %s, %s, %s, %s)
                    RETURNING id;
                    """,
                    (
                        tipo_sangre_id,
                        donante_id,
                        ubicacion_id,
                        fecha_extraccion,
                        fecha_caducidad,
                    ),
                )
                nueva_unidad_id = cur.fetchone()[0]

            conn.commit()
            return {
                "id": nueva_unidad_id,
                "donante_id": donante_id,
                "tipo_sangre_id": tipo_sangre_id,
                "ubicacion_id": ubicacion_id,
                "fecha_hora_extraccion": fecha_extraccion,
                "fecha_caducidad": fecha_caducidad,
            }

        except Exception as e:
            conn.rollback()
            raise e

def crear_peticion_sangre(
    tipo_sangre: str,
    cantidad_ml: float,
    prioridad: str,
    centro_salud: str,
    fecha_solicitud: datetime = None,
) -> dict:
    """
    Crea una petición de sangre realizada por un centro de salud.
    """
    if fecha_solicitud is None:
        fecha_solicitud = datetime.now()

    with get_connection() as conn:
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Verificar que el tipo de sangre sea uno válido y obtener su id
                cur.execute("SELECT id FROM tipo_sangre WHERE tipo = %s;", (tipo_sangre,))
                fila_tipo = cur.fetchone()
                if not fila_tipo:
                    raise ValueError(f"El tipo de sangre '{tipo_sangre}' no existe en la BD.")
                id_tipo = fila_tipo["id"]

                # Insertar la nueva petición en la base
                cur.execute(
                    """
                    INSERT INTO peticion_sangre (
                        id_tipo, cantidad_ml, prioridad, centro_salud, fecha_solicitud
                    ) VALUES (%s, %s, %s, %s, %s)
                    RETURNING *;
                    """,
                    (id_tipo, cantidad_ml, prioridad, centro_salud, fecha_solicitud),
                )
                peticion_creada = dict(cur.fetchone())

            conn.commit()
            return peticion_creada

        except Exception as e:
            conn.rollback()
            raise e

# ==========================================
# GETTERS: Para obtener los datos
# ==========================================

def obtener_peticion_por_id(id_peticion: int):
    query = """
        SELECT p.*, ts.tipo AS nombre_tipo_sangre
        FROM peticion_sangre p
        JOIN tipo_sangre ts ON p.id_tipo = ts.id
        WHERE p.id = %s;
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (id_peticion,))
            resultado = cur.fetchone()
            return dict(resultado) if resultado else None


def obtener_todas_las_peticiones():
    query = """
        SELECT p.*, ts.tipo AS nombre_tipo_sangre
        FROM peticion_sangre p
        JOIN tipo_sangre ts ON p.id_tipo = ts.id
        ORDER BY p.id DESC;
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            return [dict(row) for row in cur.fetchall()]

# ==========================================
# UNIDADES DE SANGRE: listar y editar
# (registrar_unidad_sangre ya existe arriba)
# ==========================================

def obtener_todas_las_unidades_sangre():
    query = """
        SELECT u.*, ts.tipo AS nombre_tipo_sangre,
               d.nombre_donante, ub.nombre_ubicacion
        FROM unidad_sangre u
        JOIN tipo_sangre ts ON u.tipo_sangre_id = ts.id
        LEFT JOIN donante d ON u.donante_id = d.id
        LEFT JOIN ubicacion ub ON u.ubicacion_id = ub.id
        ORDER BY u.id DESC;
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            return [dict(r) for r in cur.fetchall()]


def editar_unidad_sangre(unidad_id, tipo_sangre=None, nombre_donante=None,
                         nombre_ubicacion=None, fecha_extraccion=None,
                         fecha_caducidad=None):
    campos, valores = [], []
    with get_connection() as conn:
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT id FROM unidad_sangre WHERE id = %s;", (unidad_id,))
                if not cur.fetchone():
                    raise ValueError(f"No existe la unidad con ID {unidad_id}.")

                if tipo_sangre is not None:
                    cur.execute("SELECT id FROM tipo_sangre WHERE tipo = %s;", (tipo_sangre,))
                    r = cur.fetchone()
                    if not r:
                        raise ValueError(f"El tipo de sangre '{tipo_sangre}' no existe.")
                    campos.append("tipo_sangre_id = %s"); valores.append(r["id"])

                if nombre_donante is not None:
                    cur.execute("SELECT id FROM donante WHERE nombre_donante = %s;", (nombre_donante,))
                    r = cur.fetchone()
                    if not r:
                        raise ValueError(f"El donante '{nombre_donante}' no existe. Regístralo primero.")
                    campos.append("donante_id = %s"); valores.append(r["id"])

                if nombre_ubicacion is not None:
                    cur.execute("SELECT id FROM ubicacion WHERE nombre_ubicacion = %s;", (nombre_ubicacion,))
                    r = cur.fetchone()
                    if not r:
                        raise ValueError(f"La ubicación '{nombre_ubicacion}' no existe.")
                    campos.append("ubicacion_id = %s"); valores.append(r["id"])

                if fecha_extraccion is not None:
                    campos.append("fecha_hora_extraccion = %s"); valores.append(fecha_extraccion)

                if fecha_caducidad is not None:
                    campos.append("fecha_caducidad = %s"); valores.append(fecha_caducidad)

                if not campos:
                    raise ValueError("Debes indicar al menos un campo a editar.")

                valores.append(unidad_id)
                cur.execute(
                    f"UPDATE unidad_sangre SET {', '.join(campos)} WHERE id = %s RETURNING *;",
                    tuple(valores),
                )
                resultado = dict(cur.fetchone())
            conn.commit()
            return resultado
        except Exception:
            conn.rollback()
            raise
# ejemplo de prueba
#
#if __name__ == "__main__":
#    print("--- Ejecutando verificación de petición de sangre ---")
#
#    # 1. Crear una única petición de prueba hacia un centro de salud
#    # Usando el usuario existente con id = 1 y tipo de sangre id = 7
#    fecha_prueba = datetime.now()
#    peticion_creada = crear_peticion_sangre(
#        tipo_sangre="B+",
#        cantidad_ml=450.0,
#        prioridad="Media",
#        centro_salud="Hospital Guillermo Grant Benavente - Urgencias",
#        fecha_solicitud=fecha_prueba,
#    )
#
#    id_nuevo = peticion_creada["id"]
#    print(f"Petición insertada con ID automático (SERIAL): {id_nuevo}")
#
#    # 2. Recuperar desde la DB para verificar fidelidad de los datos
#    peticion_verificada = obtener_peticion_por_id(id_nuevo)
#    print("\nDatos guardados en Neon:")
#    print(f"- ID Petición: {peticion_verificada['id']}")
#    print(f"- Paciente/Donante ID: {peticion_verificada['id_donante']}")
#    print(f"- Tipo de sangre solicitada: {peticion_verificada['nombre_tipo_sangre']} (tipo: {peticion_verificada['id_tipo']})")
#    print(f"- Solicitado desde: {peticion_verificada['centro_salud']}")
#    print(f"- Fecha de solicitud: {peticion_verificada['fecha_solicitud']}")
#    print(f"- Cantidad / Prioridad: {peticion_verificada['cantidad_ml']} ml | {peticion_verificada['prioridad']}")
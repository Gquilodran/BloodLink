from connection_db import getConnection
from psycopg2 import Error

#Nota: Hay demasiadas unidades de sangre de ejemplo, borrar si es posible
def add_unidad_sangre(nombre_donante, tipo_sangre_id, nombre_ubicacion, fecha_hora_extraccion, fecha_caducidad):
    connection = getConnection()
    if connection is None:
        return

    try:
        cursor = connection.cursor()

        cursor.execute("SELECT id FROM ubicacion WHERE nombre_ubicacion = %s;", (nombre_ubicacion,))
        resultado_ubicacion = cursor.fetchone()

        if resultado_ubicacion is not None:
            ubicacion_id = resultado_ubicacion[0]
            print("Ubicacion ya registrada anteriormente")
        else:
            ubicacion_sql = """
                INSERT INTO ubicacion (nombre_ubicacion)
                VALUES (%s)
                RETURNING id;
            """
            cursor.execute(ubicacion_sql, (nombre_ubicacion,))
            ubicacion_id = cursor.fetchone()[0]
            print("Ubicacion nueva registrada")

        cursor.execute("SELECT id FROM donante WHERE nombre_donante = %s;", (nombre_donante,))
        resultado_donante = cursor.fetchone()

        if resultado_donante is not None:
            donante_id = resultado_donante[0]
            print("Donante ya registrado anteriormente")
        else:
            donante_sql = """
                INSERT INTO donante (nombre_donante, tipo_sangre_id)
                VALUES (%s, %s)
                RETURNING id;
            """
            cursor.execute(donante_sql, (nombre_donante, tipo_sangre_id))
            donante_id = cursor.fetchone()[0]
            print("Donante nuevo registrado")

        peticion_sql = """
            INSERT INTO unidad_sangre
            (tipo_sangre_id, donante_id, ubicacion_id, fecha_hora_extraccion, fecha_caducidad)
            VALUES (%s, %s, %s, %s, %s);
        """

        datos_unidad = (tipo_sangre_id, donante_id, ubicacion_id, fecha_hora_extraccion, fecha_caducidad)
        cursor.execute(peticion_sql, datos_unidad)
        connection.commit()
        print("Unidad de sangre registrada exitosamente")

    except Error as e:
        print(f"Error en la base de datos: {e}")
        connection.rollback()

    finally:
        if connection:
            cursor.close()
            connection.close()

def mostrar_unidades_actuales():
    connection = getConnection()
    if connection is None:
        return

    try:
        cursor = connection.cursor()
        consulta_sql = """
            SELECT
                u.id,
                t.tipo AS tipo_sangre,
                l.nombre_ubicacion,
                u.fecha_hora_extraccion,
                u.fecha_caducidad
            FROM unidad_sangre u
            JOIN tipo_sangre t ON u.tipo_sangre_id = t.id
            JOIN ubicacion l ON u.ubicacion_id = l.id
            ORDER BY u.id ASC;
        """
        cursor.execute(consulta_sql)
        unidades = cursor.fetchall()

        if not unidades:
            print("No hay unidades de sangre actualmente")
            return

        print("\n~ ~ ~ ~ Inventario actual de sangre ~ ~ ~ ~")

        for fila in unidades:
            idUnidad = fila[0]
            tipoSangre = fila[1]
            ubicacion = fila[2]
            fechaExtraccion = fila[3]
            fechaCaducidad = fila[4]

            print(f"ID: {idUnidad} | Tipo: {tipoSangre} | Ubicacion: {ubicacion} | Fecha de extraccion: {fechaExtraccion} | Caducidad: {fechaCaducidad}")

    except Error as e:
        print(f"Error al consultar la base de datos: {e}")

    finally:
        if connection:
            cursor.close()
            connection.close()

#Test agregando 2 unidades
if __name__ == "__main__":
    #Primera unidad con datos nuevos
    print("1ra prueba:")
    add_unidad_sangre(
        nombre_donante = "Fulano Fulanito 6",
        tipo_sangre_id = 8,
        nombre_ubicacion = "Hospital generico 6 - Refrigerador 1",
        fecha_hora_extraccion = "2026-11-12 01:40",
        fecha_caducidad = "2026-12-24"
    )

    print()
    print("2da prueba:")

    #Segunda unidad con datos existentes
    add_unidad_sangre(
        nombre_donante = "Fulano Fulanito",
        tipo_sangre_id = 8,
        nombre_ubicacion = "Hospital generico - Refrigerador 1",
        fecha_hora_extraccion = "2026-11-12 01:41",
        fecha_caducidad = "2026-12-24"
    )

    print()

    #Prueba para ver las existencias actuales
    mostrar_unidades_actuales()
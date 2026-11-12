
from datetime import datetime, date
from psycopg2 import Error
from connection_db import getConnection
from operaciones_db import add_unidad_sangre, mostrar_unidades_actuales


def extraer_unidad_sangre(unidad_id):
    conexion = getConnection()
    if conexion is None:
        return

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                SELECT u.id, t.tipo, d.nombre_donante, l.nombre_ubicacion,
                       u.fecha_hora_extraccion, u.fecha_caducidad
                FROM unidad_sangre u
                JOIN tipo_sangre t ON t.id = u.tipo_sangre_id
                LEFT JOIN donante d ON d.id = u.donante_id
                JOIN ubicacion l ON l.id = u.ubicacion_id
                WHERE u.id = %s
                FOR UPDATE OF u;
            """, (unidad_id,))
            unidad = cursor.fetchone()
            if unidad is None:
                print("No existe una unidad con ese ID.")
                return

            print(f"\nID: {unidad[0]} | Tipo: {unidad[1]}")
            print(f"Donante: {unidad[2] or 'Sin registrar'}")
            print(f"Ubicación: {unidad[3]}")
            print(f"Fecha de extracción: {unidad[4]}")
            print(f"Caducidad: {unidad[5]}")
            if input("¿Confirmar retiro del inventario? (s/n): ").strip().lower() != "s":
                print("Operación cancelada.")
                return

            cursor.execute("DELETE FROM unidad_sangre WHERE id = %s", (unidad_id,))
            conexion.commit()
            print("Unidad retirada del inventario correctamente.")
    except Error as error:
        conexion.rollback()
        print(f"Error al retirar la unidad: {error}")
    finally:
        conexion.close()


def ingresar_unidad():
    try:
        nombre = input("Nombre del donante: ").strip()
        if not nombre:
            print("El nombre no puede estar vacío.")
            return
        tipos = {"A+": 1, "A-": 2, "B+": 3, "B-": 4,
                 "AB+": 5, "AB-": 6, "O+": 7, "O-": 8}
        tipo = input("Tipo de sangre (A+, A-, B+, B-, AB+, AB-, O+, O-): ").strip().upper()
        if tipo not in tipos:
            print("Tipo de sangre inválido.")
            return
        ubicacion = input("Ubicación: ").strip()
        if not ubicacion:
            print("La ubicación no puede estar vacía.")
            return
        extraccion = datetime.strptime(input("Fecha y hora de extracción (AAAA-MM-DD HH:MM): ").strip(), "%Y-%m-%d %H:%M")
        caducidad = date.fromisoformat(input("Fecha de caducidad (AAAA-MM-DD): ").strip())
        if caducidad < extraccion.date():
            print("La caducidad no puede ser anterior a la extracción.")
            return
        add_unidad_sangre(nombre, tipos[tipo], ubicacion, extraccion, caducidad)
    except ValueError:
        print("Fecha u hora inválida.")


def editar_unidad_sangre(unidad_id):
    conexion = getConnection()
    if conexion is None:
        return

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                SELECT u.id, t.tipo, d.nombre_donante, l.nombre_ubicacion,
                       u.fecha_hora_extraccion, u.fecha_caducidad
                FROM unidad_sangre u
                JOIN tipo_sangre t ON t.id = u.tipo_sangre_id
                LEFT JOIN donante d ON d.id = u.donante_id
                JOIN ubicacion l ON l.id = u.ubicacion_id
                WHERE u.id = %s
                FOR UPDATE OF u;
            """, (unidad_id,))
            unidad = cursor.fetchone()

            if unidad is None:
                print("No existe una unidad con ese ID.")
                return

            print(f"\nID: {unidad[0]} | Tipo: {unidad[1]}")
            print(f"Donante: {unidad[2] or 'Sin registrar'}")
            print(f"Ubicación: {unidad[3]}")
            print(f"Fecha de extracción: {unidad[4]}")
            print(f"Caducidad: {unidad[5]}")

            print("\n1. Tipo de sangre")
            print("2. Donante")
            print("3. Ubicación")
            print("4. Fecha de extracción")
            print("5. Fecha de caducidad")
            print("6. Cancelar")

            opcion = input("¿Qué desea modificar?: ").strip()

            if opcion == "1":
                tipo = input("Nuevo tipo de sangre: ").strip().upper()
                cursor.execute("SELECT id FROM tipo_sangre WHERE tipo = %s", (tipo,))
                resultado = cursor.fetchone()
                if resultado is None:
                    print("Tipo de sangre inválido.")
                    return
                cursor.execute("""
                    UPDATE unidad_sangre SET tipo_sangre_id = %s WHERE id = %s
                """, (resultado[0], unidad_id))

            elif opcion == "2":
                nombre = input("Nuevo nombre del donante: ").strip()
                if not nombre:
                    print("El nombre no puede estar vacío.")
                    return
                cursor.execute("""
                    SELECT id FROM donante
                    WHERE nombre_donante = %s
                    AND tipo_sangre_id = (
                        SELECT tipo_sangre_id FROM unidad_sangre WHERE id = %s
                    )
                    LIMIT 1
                """, (nombre, unidad_id))
                resultado = cursor.fetchone()
                if resultado:
                    donante_id = resultado[0]
                else:
                    cursor.execute("""
                        INSERT INTO donante (nombre_donante, tipo_sangre_id)
                        SELECT %s, tipo_sangre_id FROM unidad_sangre
                        WHERE id = %s RETURNING id
                    """, (nombre, unidad_id))
                    donante_id = cursor.fetchone()[0]
                cursor.execute("""
                    UPDATE unidad_sangre SET donante_id = %s WHERE id = %s
                """, (donante_id, unidad_id))

            elif opcion == "3":
                ubicacion = input("Nueva ubicación: ").strip()
                if not ubicacion:
                    print("La ubicación no puede estar vacía.")
                    return
                cursor.execute("""
                    SELECT id FROM ubicacion WHERE nombre_ubicacion = %s LIMIT 1
                """, (ubicacion,))
                resultado = cursor.fetchone()
                if resultado:
                    ubicacion_id = resultado[0]
                else:
                    cursor.execute("""
                        INSERT INTO ubicacion (nombre_ubicacion)
                        VALUES (%s) RETURNING id
                    """, (ubicacion,))
                    ubicacion_id = cursor.fetchone()[0]
                cursor.execute("""
                    UPDATE unidad_sangre SET ubicacion_id = %s WHERE id = %s
                """, (ubicacion_id, unidad_id))

            elif opcion == "4":
                fecha = datetime.strptime(
                    input("Nueva fecha de extracción (AAAA-MM-DD HH:MM): "),
                    "%Y-%m-%d %H:%M"
                )
                if fecha.date() > unidad[5]:
                    print("La extracción no puede ser posterior a la caducidad.")
                    return
                cursor.execute("""
                    UPDATE unidad_sangre SET fecha_hora_extraccion = %s
                    WHERE id = %s
                """, (fecha, unidad_id))

            elif opcion == "5":
                fecha = date.fromisoformat(
                    input("Nueva fecha de caducidad (AAAA-MM-DD): ")
                )
                if fecha < unidad[4].date():
                    print("La caducidad no puede ser anterior a la extracción.")
                    return
                cursor.execute("""
                    UPDATE unidad_sangre SET fecha_caducidad = %s WHERE id = %s
                """, (fecha, unidad_id))

            elif opcion == "6":
                print("Edición cancelada.")
                return

            else:
                print("Opción inválida.")
                return

            conexion.commit()
            print("Unidad de sangre actualizada correctamente.")

    except (Error, ValueError) as error:
        conexion.rollback()
        print(f"Error al editar la unidad: {error}")
    finally:
        conexion.close()

def mostrar_detalles_unidad(unidad_id):
    conexion = getConnection()
    if conexion is None:
        return

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                SELECT u.id, t.tipo, d.nombre_donante, l.nombre_ubicacion,
                       u.fecha_hora_extraccion, u.fecha_caducidad
                FROM unidad_sangre u
                JOIN tipo_sangre t ON t.id = u.tipo_sangre_id
                LEFT JOIN donante d ON d.id = u.donante_id
                JOIN ubicacion l ON l.id = u.ubicacion_id
                WHERE u.id = %s
            """, (unidad_id,))

            unidad = cursor.fetchone()

            if unidad is None:
                print("No existe una unidad con ese ID.")
                return

            print("\n========== DETALLES DE LA UNIDAD ==========")
            print(f"ID: {unidad[0]}")
            print(f"Tipo de sangre: {unidad[1]}")
            print(f"Donante: {unidad[2] or 'Sin registrar'}")
            print(f"Ubicación: {unidad[3]}")
            print(f"Fecha de extracción: {unidad[4]}")
            print(f"Fecha de caducidad: {unidad[5]}")

    except Error as error:
        print(f"Error al consultar la unidad: {error}")
    finally:
        conexion.close()


def main():
    while True:
        print("\n========== BANCO DE SANGRE ==========")
        print("1. Ingresar una unidad de sangre")
        print("2. Extraer una unidad de sangre")
        print("3. Mostrar unidades disponibles")
        print("4. Editar una unidad de sangre")
        print("5. Ver detalles de una unidad")
        print("6. Salir")

        opcion = input("Seleccione una opción: ").strip()

        if opcion == "1":
            ingresar_unidad()

        elif opcion == "2":
            mostrar_unidades_actuales()
            try:
                unidad_id = int(input("ID de la unidad a retirar: "))
                if unidad_id <= 0:
                    raise ValueError
                extraer_unidad_sangre(unidad_id)
            except ValueError:
                print("Debe ingresar un ID numérico positivo.")

        elif opcion == "3":
            mostrar_unidades_actuales()

        elif opcion == "4":
            mostrar_unidades_actuales()
            try:
                unidad_id = int(input("ID de la unidad a editar: "))
                if unidad_id <= 0:
                    raise ValueError
                editar_unidad_sangre(unidad_id)
            except ValueError:
                print("Debe ingresar un ID numérico positivo.")

        elif opcion == "5":
            mostrar_unidades_actuales()
            try:
                unidad_id = int(input("ID de la unidad a consultar: "))
                if unidad_id <= 0:
                    raise ValueError
                mostrar_detalles_unidad(unidad_id)
            except ValueError:
                print("Debe ingresar un ID numérico positivo.")

        elif opcion == "6":
            break

        else:
            print("Opción inválida.")


if __name__ == "__main__":
    main()

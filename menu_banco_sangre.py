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


def main():
    while True:
        print("\n========== BANCO DE SANGRE ==========")
        print("1. Ingresar una unidad de sangre")
        print("2. Extraer una unidad de sangre")
        print("3. Mostrar unidades disponibles")
        print("4. Salir")
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
            break
        else:
            print("Opción inválida.")


if __name__ == "__main__":
    main()

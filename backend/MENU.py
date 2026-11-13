from datetime import datetime
from backend.solicitudd import (
    crear_peticion_sangre,
    obtener_todas_las_peticiones,
    obtener_peticion_por_id,
    registrar_unidad_sangre,
    obtener_todas_las_unidades_sangre,
    editar_unidad_sangre,
    marcar_peticion_completa,   # <-- Nueva función importada
)


def apartado_de_ingreso():
    while True:
        print("\n" + "=" * 45)
        print("GESTIÓN DE EXISTENCIAS Y PETICIONES DE UNIDADES DE SANGRE")
        print("=" * 45)
        print("1. Ingresar una nueva solicitud (petición)")
        print("2. Revisar solicitudes")
        print("3. Crear unidad de sangre")
        print("4. Ver unidades de sangre")
        print("5. Editar unidad de sangre")
        print("6. Finalizar petición de sangre")  # <-- Nueva opción
        print("7. Salir")

        try:
            opcion = int(input("\nOpción: ").strip())
        except ValueError:
            print("Ingrese un número válido (1-7).")
            continue

        # ---------- 1. NUEVA PETICIÓN ----------
        if opcion == 1:
            # ... (código existente sin cambios)
            pass

        # ---------- 2. REVISAR PETICIONES ----------
        elif opcion == 2:
            # ... (código existente sin cambios)
            pass

        # ---------- 3. CREAR UNIDAD DE SANGRE ----------
        elif opcion == 3:
            # ... (código existente sin cambios)
            pass

        # ---------- 4. VER UNIDADES ----------
        elif opcion == 4:
            # ... (código existente sin cambios)
            pass

        # ---------- 5. EDITAR UNIDAD (CON LÓGICA DE CAMPOS VACÍOS) ----------
        elif opcion == 5:
            print("\n Editar Unidad de Sangre")
            print("(Deja en blanco los campos que NO quieras cambiar)")
            try:
                uid = int(input("ID de la unidad a editar: ").strip())

                # Si el input está vacío, se asigna None y la función no lo modificará
                tipo = input("Nuevo tipo de sangre: ").strip().upper() or None
                don = input("Nuevo donante: ").strip() or None
                ubi = input("Nueva ubicación: ").strip() or None

                # Para las fechas, si el input está vacío, se mantiene en None
                fcad_str = input("Nueva caducidad (YYYY-MM-DD): ").strip()
                fcad = datetime.strptime(fcad_str, "%Y-%m-%d").date() if fcad_str else None

                fext_str = input("Nueva fecha extracción (YYYY-MM-DD HH:MM): ").strip()
                fext = datetime.strptime(fext_str, "%Y-%m-%d %H:%M") if fext_str else None

                resultado = editar_unidad_sangre(
                    unidad_id=uid,
                    tipo_sangre=tipo,
                    nombre_donante=don,
                    nombre_ubicacion=ubi,
                    fecha_extraccion=fext,
                    fecha_caducidad=fcad,
                )
                print(f"\nUnidad actualizada: {resultado}")
            except ValueError as ve:
                print(f"\n[ERROR DE VALIDACIÓN]: {ve}")
            except Exception as e:
                print(f"\n[ERROR DE BASE DE DATOS]: {e}")

        # ---------- 6. FINALIZAR PETICIÓN (NUEVA OPCIÓN) ----------
        elif opcion == 6:
            print("\n Finalizar Petición de Sangre")
            try:
                pid = int(input("ID de la petición a finalizar: ").strip())
                actualizada = marcar_peticion_completa(pid)
                print(f"\nPetición #{actualizada['id']} marcada como COMPLETADA.")
                print(f"  Estado: {actualizada['estado']}")
                print(f"  Fecha de completado: {actualizada['fecha_completada']}")
            except ValueError as ve:
                print(f"\n[ERROR]: {ve}")
            except Exception as e:
                print(f"\n[ERROR DE BASE DE DATOS]: {e}")

        # ---------- 7. SALIR ----------
        elif opcion == 7:
            print("Saliendo del sistema...")
            break
        else:
            print("Opción no válida, intenta de nuevo.")


if __name__ == "__main__":
    apartado_de_ingreso()

from datetime import datetime
from solicitudd import (crear_peticion_sangre,obtener_todas_las_peticiones,obtener_peticion_por_id)


def apartado_de_ingreso():
    while True:
        print("\n" + "=" * 45)
        print("GESTIoN DE PETICIONES")
        print("=" * 45)
        print("Seleccione una opción:")
        print("1. Ingresar una nueva solicitud")
        print("2. Revisar solicitudes")
        print("3. Salir")

        try:
            opcion = int(input("\nOpci0n: ").strip())
        except ValueError:
            print("Por favor, ingrese un número valido (1, 2 o 3).")
            continue

        if opcion == 1:
            print("\n Nueva Petición de Sangre")
            try:
                tipo_sangre = input("Tipo de sangre solicitado: ").strip().upper()
                cantidad_ml = float(input("Cantidad (en mililitros): ").strip())
                prioridad = input("Prioridad (Baja / Media / Alta / Urgencia Vital): ").strip()
                centro_salud = input("Desde donde se solicita: ").strip()
                usar_fecha_actual = input("¿Usar fecha y hora actual? (s/n): ").strip().lower()
                if usar_fecha_actual == "s":
                    fecha_solicitud = datetime.now()
                else:
                    fecha_str = input("Ingrese fecha (YYYY-MM-DD HH:MM): ").strip()
                    fecha_solicitud = datetime.strptime(fecha_str, "%Y-%m-%d %H:%M")

                nueva = crear_peticion_sangre(
                    tipo_sangre=tipo_sangre,
                    cantidad_ml=cantidad_ml,
                    prioridad=prioridad,
                    centro_salud=centro_salud,
                    fecha_solicitud=fecha_solicitud,
                )

                print(f"\nPetición registrada con exito en la base de datos (ID: {nueva['id']}).")

            except ValueError as ve:
                print(f"\n[ERROR DE VALIDACION]: {ve}")
            except Exception as e:
                print(f"\n[ERROR DE BASE DE DATOS]: {e}")

        elif opcion == 2:
            print("\n Revisar Solicitudes")
            sub = input("1. Ver todas  |  2. Buscar por ID: ").strip()

            if sub == "1":
                peticiones = obtener_todas_las_peticiones()
                if not peticiones:
                    print("No hay peticiones registradas.")
                else:
                    print(f"\nTotal de peticiones: {len(peticiones)}")
                    for p in peticiones[:10]:  # Muestra las más recientes
                        print(
                            f"- ID #{p['id']} | Sangre: {p['nombre_tipo_sangre']} "
                            f"| {p['cantidad_ml']} ml | Prioridad: {p['prioridad']} "
                            f"| Centro: {p.get('centro_salud', 'N/A')} "
                            f"| Fecha: {str(p.get('fecha_solicitud', ''))[:16]}"
                        )

            elif sub == "2":
                try:
                    id_buscado = int(input("Ingrese el ID de la petición: ").strip())
                    p = obtener_peticion_por_id(id_buscado)
                    if p:
                        print("\nDetalle de la peticion:")
                        for clave, valor in p.items():
                            print(f"  {clave}: {valor}")
                    else:
                        print(f"No existe una peticion con ID {id_buscado}.")
                except ValueError:
                    print("El ID debe ser un numero entero.")

        elif opcion == 3:
            print("Saliendo del sistema...")
            break
        else:
            print("Opción no válida, intenta de nuevo.")


if __name__ == "__main__":
    apartado_de_ingreso()
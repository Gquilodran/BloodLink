from datetime import datetime
from backend.solicitudd import (
    crear_peticion_sangre,
    obtener_todas_las_peticiones,
    obtener_peticion_por_id,
    registrar_unidad_sangre,
    obtener_todas_las_unidades_sangre,
    editar_unidad_sangre,
)

#LINK MARCADORES: https://mimidestino.blogspot.com/2019/02/separadores-para-amino-mimi-destino.html
def apartado_de_ingreso():
    while True:
        print("\n •*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•")
        print("                GESTIÓN DE EXISTENCIAS Y PETICIONES DE UNIDADES DE SANGRE ")
        print("•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.• \n \n ")
        print("1. Ingresar una nueva solicitud (petición)")
        print("2. Revisar solicitudes")
        print("3. Crear unidad de sangre")
        print("4. Ver unidades de sangre")
        print("5. Editar unidad de sangre")
        print("6. Finalizar petición de sangre") 
        print("7. Salir")


        try:
            opcion = int(input("\nOpción: ").strip())
        except ValueError:
            print("Ingrese un número válido (1-6).")
            continue

        # ---------- 1. NUEVA PETICIÓN ----------
        if opcion == 1:
            print("\n •*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•")
            print("                            Nueva Petición de Sangre ")
            print("•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•\n \n ")
            try:
                tipo_sangre = input("Tipo de sangre solicitado: ").strip().upper()
                cantidad_ml = float(input("Cantidad (ml): ").strip())
                prioridad = input("Prioridad (Baja / Media / Alta / Urgencia Vital): ").strip()
                centro_salud = input("Desde dónde se solicita: ").strip()
                usar = input("¿Usar fecha y hora actual? (s/n): ").strip().lower()
                if usar == "s":
                    fecha_solicitud = datetime.now()
                else:
                    fecha_str = input("Fecha (YYYY-MM-DD HH:MM): ").strip()
                    fecha_solicitud = datetime.strptime(fecha_str, "%Y-%m-%d %H:%M")

                nueva = crear_peticion_sangre(
                    tipo_sangre=tipo_sangre,
                    cantidad_ml=cantidad_ml,
                    prioridad=prioridad,
                    centro_salud=centro_salud,
                    fecha_solicitud=fecha_solicitud,
                )
                print(f"\nPetición registrada (ID: {nueva['id']}).")
            except ValueError as ve:
                print(f"\n[ERROR DE VALIDACIÓN]: {ve}")
            except Exception as e:
                print(f"\n[ERROR DE BASE DE DATOS]: {e}")

        # ---------- 2. REVISAR PETICIONES ----------
        elif opcion == 2:
            print("\n •*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•")
            print("                            Revisar Solicitudes ")
            print("•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.• \n \n ")
            
            sub = input("1. Ver todas  |  2. Buscar por ID: ").strip()
            if sub == "1":
                peticiones = obtener_todas_las_peticiones()
                if not peticiones:
                    print("No hay peticiones registradas.")
                else:
                    print(f"\nTotal: {len(peticiones)}")
                    for p in peticiones[:10]:
                        print(
                            f"- ID #{p['id']} | Sangre: {p['nombre_tipo_sangre']} "
                            f"| {p['cantidad_ml']} ml | Prioridad: {p['prioridad']} "
                            f"| Centro: {p.get('centro_salud', 'N/A')} "
                            f"| Fecha: {str(p.get('fecha_solicitud', ''))[:16]}"
                        )
            elif sub == "2":
                try:
                    id_buscado = int(input("ID de la petición: ").strip())
                    p = obtener_peticion_por_id(id_buscado)
                    if p:
                        print("\nDetalle:")
                        for k, v in p.items():
                            print(f"  {k}: {v}")
                    else:
                        print(f"No existe la petición con ID {id_buscado}.")
                except ValueError:
                    print("El ID debe ser un entero.")

        # ---------- 3. CREAR UNIDAD DE SANGRE ----------
        elif opcion == 3:
            print("\n •*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•")
            print("Nueva Unidad de Sangre ")
            print("•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.• \n \n ")
            try:
                nombre_donante = input("Nombre del donante: ").strip()
                tipo_sangre = input("Tipo de sangre (ej. O+, A-): ").strip().upper()
                nombre_ubicacion = input("Ubicación (hospital/centro): ").strip()
                usar = input("¿Usar fecha de extracción actual? (s/n): ").strip().lower()
                if usar == "s":
                    fecha_extraccion = datetime.now()
                else:
                    fecha_str = input("Fecha extracción (YYYY-MM-DD HH:MM): ").strip()
                    fecha_extraccion = datetime.strptime(fecha_str, "%Y-%m-%d %H:%M")
                dias = input("Días de vigencia [42]: ").strip()
                dias_vigencia = int(dias) if dias else 42

                nueva = registrar_unidad_sangre(
                    nombre_donante=nombre_donante,
                    tipo_sangre=tipo_sangre,
                    nombre_ubicacion=nombre_ubicacion,
                    fecha_extraccion=fecha_extraccion,
                    dias_vigencia=dias_vigencia,
                )
                print(f"\nUnidad registrada (ID: {nueva['id']}). Caduca: {nueva['fecha_caducidad']}")
            except ValueError as ve:
                print(f"\n[ERROR DE VALIDACIÓN]: {ve}")
            except Exception as e:
                print(f"\n[ERROR DE BASE DE DATOS]: {e}")

        # ---------- 4. VER UNIDADES ----------
        elif opcion == 4:
            print("\n •*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•")
            print("                           Unidades de Sangre ")
            print("•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.••*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.•*´¨`*•.¸¸.• \n \n ")
            try:
                unidades = obtener_todas_las_unidades_sangre()
                if not unidades:
                    print("No hay unidades registradas.")
                else:
                    print(f"\nTotal: {len(unidades)}")
                    for u in unidades:
                        print(
                            f"- ID #{u['id']} | {u['nombre_tipo_sangre']} "
                            f"| Donante: {u['nombre_donante']} "
                            f"| Ubicación: {u['nombre_ubicacion']} "
                            f"| Extraída: {str(u['fecha_hora_extraccion'])[:16]} "
                            f"| Caduca: {u['fecha_caducidad']}"
                        )
            except Exception as e:
                print(f"\n[ERROR]: {e}")

        # ---------- 5. EDITAR UNIDAD ----------
        elif opcion == 5:
            print("\n \n ┏━━━━━━━━━━━•°•☆•°•━━━━━━━━━━━┓")
            print("\Editar Unidad de Sangre")
            print("┗━━━━━━━━━━━•°•☆•°•━━━━━━━━━━━┛\n \n ")
            print("\n \n (Deja en blanco los campos que NO quieras cambiar)\n \n ")
            print("•┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈•⋆• ✧ •⋆• ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈•")            

            try:
                uid = int(input("ID de la unidad a editar: ").strip())

                tipo = input("Nuevo tipo de sangre: ").strip().upper() or None
                don = input("Nuevo donante: ").strip() or None
                ubi = input("Nueva ubicación: ").strip() or None

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
            print("\n ━━━━━━━━━ ☾ Finalizar Petición de Sangre ☽ ━━━━━━━━━ \n \n ")
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
            print("\n \n ╔════════ ❀•°❀°•❀ ════════╗")
            print("  Saliendo del sistema...")
            print("╚════════ ❀•°❀°•❀ ════════╝ \n \n ")
            break
        else:
            print("Opción no válida, intenta de nuevo.")


if __name__ == "__main__":
    apartado_de_ingreso()

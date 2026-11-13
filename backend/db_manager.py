"""
db_manager.py - Gestor de Base de Datos para el Equipo (¡Sin necesidad de saber SQL!)

Cualquier miembro del equipo puede importar este archivo o ejecutarlo directamente:
    python db_manager.py

Todas las funciones reciben tipos estándar de Python (strings, ints, floats)
y devuelven datos formateados como texto (string) o diccionarios listos para usar.
"""

from db import SessionLocal
from models import (
    Donante,
    TipoSangre,
    PersonalSalud,
    Extraccion,
    PeticionSangre,
    Ubicacion,
    FileRecord,
)


def obtener_resumen_banco_como_string() -> str:
    """
    Retorna un reporte completo en texto con las estadísticas actuales del banco de sangre.
    """
    db = SessionLocal()
    try:
        total_donantes = db.query(Donante).count()
        total_personal = db.query(PersonalSalud).count()
        total_extracciones = db.query(Extraccion).count()
        total_peticiones = db.query(PeticionSangre).count()
        total_archivos = db.query(FileRecord).count()

        tipos = db.query(TipoSangre).all()
        tipos_str = ", ".join([t.tipo for t in tipos])

        lineas = [
            "==================================================",
            "        RESUMEN DEL BANCO DE SANGRE (NEON DB)     ",
            "==================================================",
            f"• Tipos de sangre disponibles: {tipos_str}",
            f"• Donantes registrados:        {total_donantes}",
            f"• Personal de salud:           {total_personal}",
            f"• Extracciones realizadas:     {total_extracciones}",
            f"• Peticiones de sangre:        {total_peticiones}",
            f"• Archivos guardados:          {total_archivos}",
            "==================================================",
        ]
        return "\n".join(lineas)
    finally:
        db.close()


def insertar_donante(nombre: str, tipo_sangre_str: str) -> str:
    """
    Inserta un nuevo donante sin escribir SQL.
    
    Ejemplo:
        resultado = insertar_donante("Valentina Silva", "O+")
    """
    db = SessionLocal()
    try:
        # 1. Buscar el tipo de sangre en Python (sin SQL manual)
        tipo = db.query(TipoSangre).filter(TipoSangre.tipo == tipo_sangre_str.upper().strip()).first()
        if not tipo:
            tipos_validos = [t.tipo for t in db.query(TipoSangre).all()]
            return f"Error: Tipo de sangre '{tipo_sangre_str}' no válido. Tipos permitidos: {', '.join(tipos_validos)}"

        # 2. Crear objeto Donante
        nuevo_donante = Donante(
            nombre_donante=nombre,
            tipo_sangre_id=tipo.id
        )

        # 3. Guardar en la base de datos
        db.add(nuevo_donante)
        db.commit()
        db.refresh(nuevo_donante)

        return f"¡Donante insertado exitosamente! ID: {nuevo_donante.id} | Nombre: {nuevo_donante.nombre_donante} | Tipo: {tipo.tipo}"
    finally:
        db.close()


def obtener_donantes_como_string(limite: int = 10) -> str:
    """
    Obtiene los donantes registrados y los entrega como una cadena de texto legible.
    """
    db = SessionLocal()
    try:
        donantes = db.query(Donante).limit(limite).all()
        if not donantes:
            return "No hay donantes registrados."

        lineas = [f"--- LISTADO DE DONANTES (Primeros {len(donantes)}) ---"]
        for d in donantes:
            tipo = d.tipo_sangre.tipo if d.tipo_sangre else "N/A"
            lineas.append(f"• [ID {d.id:2d}] {d.nombre_donante:<30} | Tipo: {tipo}")
        return "\n".join(lineas)
    finally:
        db.close()


def insertar_peticion_sangre(id_donante: int, tipo_sangre_str: str, cantidad_ml: float, prioridad: str) -> str:
    """
    Inserta una solicitud o petición de sangre sin escribir SQL.
    
    Ejemplo:
        resultado = insertar_peticion_sangre(id_donante=1, tipo_sangre_str="A+", cantidad_ml=450.0, prioridad="Alta")
    """
    db = SessionLocal()
    try:
        tipo = db.query(TipoSangre).filter(TipoSangre.tipo == tipo_sangre_str.upper().strip()).first()
        if not tipo:
            return f"Error: Tipo de sangre '{tipo_sangre_str}' inválido."

        nueva_peticion = PeticionSangre(
            id_donante=id_donante,
            id_tipo=tipo.id,
            cantidad_ml=cantidad_ml,
            prioridad=prioridad
        )

        db.add(nueva_peticion)
        db.commit()
        db.refresh(nueva_peticion)

        return f"¡Petición registrada! ID: {nueva_peticion.id} | {cantidad_ml}ml [{tipo.tipo}] | Prioridad: {prioridad}"
    finally:
        db.close()


def obtener_peticiones_como_string(limite: int = 10) -> str:
    """
    Obtiene las peticiones de sangre registradas y las devuelve formateadas como texto.
    """
    db = SessionLocal()
    try:
        peticiones = db.query(PeticionSangre).order_by(PeticionSangre.id.desc()).limit(limite).all()
        if not peticiones:
            return "No hay peticiones de sangre registradas."

        lineas = [f"--- ÚLTIMAS {len(peticiones)} PETICIONES DE SANGRE ---"]
        for p in peticiones:
            tipo = p.tipo_sangre.tipo if p.tipo_sangre else "N/A"
            donante_nom = p.donante.nombre_donante if p.donante else f"Donante #{p.id_donante}"
            lineas.append(
                f"• [Petición #{p.id:2d}] {p.cantidad_ml:5.1f} ml [{tipo}] | Prioridad: {p.prioridad:<14} | Para: {donante_nom}"
            )
        return "\n".join(lineas)
    finally:
        db.close()


if __name__ == "__main__":
    print(obtener_resumen_banco_como_string())
    print()

    print(">>> 1. Insertando un donante de prueba con Python puro:")
    resultado_insercion = insertar_donante("Dr. Gonzalo Martínez", "O+")
    print(resultado_insercion)
    print()

    print(">>> 2. Extrayendo los donantes como STRING:")
    print(obtener_donantes_como_string(limite=8))
    print()

    print(">>> 3. Insertando una petición de sangre con Python puro:")
    resultado_peticion = insertar_peticion_sangre(
        id_donante=1,
        tipo_sangre_str="O+",
        cantidad_ml=500.0,
        prioridad="Urgencia Vital"
    )
    print(resultado_peticion)
    print()

    print(">>> 4. Extrayendo las peticiones de sangre como STRING:")
    print(obtener_peticiones_como_string(limite=6))

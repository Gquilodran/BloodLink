"""
demo_database.py - Demostración de interacción con la Base de Datos sin saber SQL.

Este script muestra cómo cualquier miembro del equipo puede:
1. INSERTAR datos en PostgreSQL usando objetos estándar de Python (sin SQL).
2. EXTRAER datos de la BD y mostrarlos como cadenas de texto (strings) legibles o JSON.
"""

import json
from datetime import datetime
from db import SessionLocal, init_db
from models import FileRecord


def insertar_archivo(nombre: str, tipo: str, tamano_bytes: int, ruta_almacenada: str) -> FileRecord:
    """
    Inserta un nuevo registro en la base de datos sin escribir una sola línea de SQL.
    Solo recibe parámetros normales de Python.
    """
    # 1. Abrir sesión con la base de datos
    db = SessionLocal()
    try:
        # 2. Crear el objeto en Python
        nuevo_archivo = FileRecord(
            filename=nombre,
            file_type=tipo,
            file_size=tamano_bytes,
            stored_path=ruta_almacenada
        )

        # 3. Guardar en la base de datos
        db.add(nuevo_archivo)
        db.commit()

        # 4. Refrescar para obtener el ID autoincremental generado por PostgreSQL
        db.refresh(nuevo_archivo)
        return nuevo_archivo
    finally:
        db.close()


def obtener_archivos_como_string() -> str:
    """
    Extrae todos los registros de la base de datos y los formatea como
    un texto (string) limpio y legible para humanos.
    """
    db = SessionLocal()
    try:
        # Consulta en Python (sin SQL): equivale a SELECT * FROM files
        archivos = db.query(FileRecord).all()

        if not archivos:
            return "No hay archivos registrados en la base de datos."

        lineas = ["=== ARCHIVOS EN LA BASE DE DATOS (POSTGRESQL) ==="]
        for f in archivos:
            fecha_str = f.created_at.strftime("%Y-%m-%d %H:%M:%S") if f.created_at else "N/A"
            lineas.append(
                f"[ID {f.id}] Nombre: '{f.filename}' | Tipo: {f.file_type} | Tamaño: {f.file_size} bytes | Fecha: {fecha_str}"
            )
        return "\n".join(lineas)
    finally:
        db.close()


def obtener_archivos_como_json_string() -> str:
    """
    Extrae los registros y los entrega como un string en formato JSON.
    Ideal para enviarlo a cualquier cliente o guardarlo en un archivo.
    """
    db = SessionLocal()
    try:
        archivos = db.query(FileRecord).all()
        lista_datos = [
            {
                "id": f.id,
                "nombre": f.filename,
                "tipo": f.file_type,
                "tamano_bytes": f.file_size,
                "ruta": f.stored_path,
                "fecha": f.created_at.isoformat() if f.created_at else None
            }
            for f in archivos
        ]
        return json.dumps(lista_datos, indent=2, ensure_ascii=False)
    finally:
        db.close()


def buscar_archivo_por_id_como_string(archivo_id: int) -> str:
    """
    Busca un archivo específico por su ID y lo devuelve como string.
    """
    db = SessionLocal()
    try:
        # Búsqueda en Python (sin SQL): equivale a SELECT * FROM files WHERE id = archivo_id LIMIT 1
        archivo = db.query(FileRecord).filter(FileRecord.id == archivo_id).first()
        if not archivo:
            return f"Archivo con ID {archivo_id} no encontrado."

        return (
            f"Archivo encontrado:\n"
            f" - ID: {archivo.id}\n"
            f" - Nombre: {archivo.filename}\n"
            f" - Tipo: {archivo.file_type}\n"
            f" - Tamaño: {archivo.file_size} bytes\n"
            f" - Ruta física: {archivo.stored_path}\n"
            f" - Fecha de registro: {archivo.created_at}"
        )
    finally:
        db.close()


if __name__ == "__main__":
    print(">>> 1. Asegurando que las tablas existan en Neon PostgreSQL...")
    init_db()

    print("\n>>> 2. Insertando un registro de prueba desde Python (sin SQL)...")
    timestamp_actual = datetime.now().strftime("%H%M%S")
    registro = insertar_archivo(
        nombre=f"analisis_sangre_{timestamp_actual}.pdf",
        tipo="application/pdf",
        tamano_bytes=245760, # 240 KB
        ruta_almacenada=f"uploads/sangre_{timestamp_actual}.pdf"
    )
    print(f"-> ¡Insertado con éxito! ID asignado por PostgreSQL: {registro.id}")

    print("\n>>> 3. Extrayendo datos de PostgreSQL como STRING legible:")
    resultado_texto = obtener_archivos_como_string()
    print(resultado_texto)

    print("\n>>> 4. Extrayendo un archivo específico (por ID) como STRING:")
    detalle = buscar_archivo_por_id_como_string(registro.id)
    print(detalle)

    print("\n>>> 5. Extrayendo datos como STRING en formato JSON:")
    resultado_json = obtener_archivos_como_json_string()
    print(resultado_json)

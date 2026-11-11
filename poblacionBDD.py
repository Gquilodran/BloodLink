from datetime import timedelta
from faker import Faker
import psycopg2
DATABASE_URL = "postgresql://neondb_owner:npg_8cJ9pvUmedLh@ep-quiet-brook-b6glc1w6-pooler.c-2.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"


def poblar_y_subir():
    fake = Faker("es_CL")
    Faker.seed(67)

    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        print("¡Conexión establecida con éxito!")
        nombres_ubicaciones = [
            "Refrigerador 1 - Piso 1",
            "Refrigerador 2 - Piso 1",
            "Congelador Principal A",
            "Congelador Principal B",
            "Cámara Fría Central",
        ]

        ubicacion_ids = []
        for nombre in nombres_ubicaciones:
            cursor.execute(
                "INSERT INTO ubicacion (nombre_ubicacion) VALUES (%s) RETURNING id;",
                (nombre,),
            )
            ubicacion_ids.append(cursor.fetchone()[0])
        cursor.execute("SELECT id FROM tipo_sangre;")
        tipos_sangre_ids = [row[0] for row in cursor.fetchall()]

        if not tipos_sangre_ids:
            raise Exception(
                "La tabla tipo_sangre está vacía. Debes llenarla primero."
            )
        donantes_creados = []
        for _ in range(50):
            nombre = fake.name()
            tipo_id = fake.random_element(tipos_sangre_ids)

            cursor.execute(
                """
                INSERT INTO donante (nombre_donante, tipo_sangre_id) 
                VALUES (%s, %s) RETURNING id;
                """,
                (nombre, tipo_id),
            )
            donante_id = cursor.fetchone()[0]
            donantes_creados.append(
                {"id": donante_id, "tipo_sangre_id": tipo_id}
            )
        for _ in range(100):
            donante = fake.random_element(donantes_creados)
            ubicacion_id = fake.random_element(ubicacion_ids)

            fecha_extraccion = fake.date_time_between(
                start_date="-30d", end_date="now"
            )
            fecha_caducidad = (fecha_extraccion + timedelta(days=42)).date()

            cursor.execute(
                """
                INSERT INTO unidad_sangre (
                    tipo_sangre_id, donante_id, ubicacion_id, 
                    fecha_hora_extraccion, fecha_caducidad
                ) VALUES (%s, %s, %s, %s, %s);
                """,
                (
                    donante["tipo_sangre_id"],
                    donante["id"],
                    ubicacion_id,
                    fecha_extraccion,
                    fecha_caducidad,
                ),
            )

        conn.commit()
        print("¡Base de datos poblada exitosamente!")

    except Exception as e:
        if "conn" in locals():
            conn.rollback()
        print(f"Error durante la inserción: {e}")

    finally:
        if "conn" in locals():
            cursor.close()
            conn.close()


if __name__ == "__main__":
    poblar_y_subir()
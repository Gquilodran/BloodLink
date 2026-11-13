from datetime import timedelta
from faker import Faker
import psycopg2
DATABASE_URL = "postgresql://neondb_owner:npg_8cJ9pvUmedLh@ep-quiet-brook-b6glc1w6-pooler.c-2.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"


def poblar_nuevas_tablas():
    fake = Faker("es_CL")
    Faker.seed(67)

    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        print("¡Conexión establecida con éxito!")

        # ---------------------------------------------------------
        # 1. Poblar cargo_personal
        # ---------------------------------------------------------
        cargos = [
            ("Director/a Médico/a", "Responsable clínico, normativo y de hemovigilancia"),
            ("Tecnólogo/a Médico", "Análisis de inmunohematología, tamizaje y fraccionamiento"),
            ("Enfermero/a", "Entrevista de selección clínica y supervisión de flebotomía"),
            ("Técnico en Enfermería (TENS)", "Apoyo en extracción, recepción y cadena de frío"),
            ("Encargado/a de Calidad", "Auditoría de procesos y trazabilidad de hemocomponentes"),
        ]

        cargo_ids = []
        for nombre_cargo, descripcion in cargos:
            cursor.execute(
                """
                INSERT INTO cargo_personal (nombre_cargo, descripcion)
                VALUES (%s, %s) RETURNING id;
                """,
                (nombre_cargo, descripcion),
            )
            cargo_ids.append(cursor.fetchone()[0])
        print(f"Insertados {len(cargo_ids)} cargos.")

        # ---------------------------------------------------------
        # 2. Poblar personal_salud (20 profesionales)
        # ---------------------------------------------------------
        personal_ids = []
        for _ in range(20):
            nombre = fake.name()
            id_cargo = fake.random_element(cargo_ids)
            # Generar correo institucional realista y único
            correo = fake.unique.email()

            cursor.execute(
                """
                INSERT INTO personal_salud (nombre, id_cargo, correo)
                VALUES (%s, %s, %s) RETURNING id;
                """,
                (nombre, id_cargo, correo),
            )
            personal_ids.append(cursor.fetchone()[0])
        print(f"Insertados {len(personal_ids)} registros en personal_salud.")

        # ---------------------------------------------------------
        # 3. Obtener IDs existentes de donante y tipo_sangre
        # ---------------------------------------------------------
        cursor.execute("SELECT id FROM donante;")
        donante_ids = [row[0] for row in cursor.fetchall()]

        cursor.execute("SELECT id FROM tipo_sangre;")
        tipos_sangre_ids = [row[0] for row in cursor.fetchall()]

        if not donante_ids or not tipos_sangre_ids:
            raise Exception(
                "Las tablas 'donante' o 'tipo_sangre' están vacías. Poblarlas primero."
            )

        # ---------------------------------------------------------
        # 4. Poblar extraccion (80 extracciones)
        # ---------------------------------------------------------
        for _ in range(80):
            id_donante = fake.random_element(donante_ids)
            id_personal = fake.random_element(personal_ids)
            fecha_extraccion = fake.date_between(start_date="-30d", end_date="today")
            vigencia_dias = fake.random_element([35, 42])  # Vigencia estándar de glóbulos rojos

            cursor.execute(
                """
                INSERT INTO extraccion (
                    id_donante, id_personal, fecha_extraccion, vigencia_dias
                ) VALUES (%s, %s, %s, %s);
                """,
                (id_donante, id_personal, fecha_extraccion, vigencia_dias),
            )
        print("Insertadas 80 extracciones.")

        # ---------------------------------------------------------
        # 5. Poblar peticion_sangre (40 solicitudes)
        # ---------------------------------------------------------
        prioridades = ["Baja", "Media", "Alta", "Urgencia Vital"]
        cantidades_ml = [250.0, 300.0, 450.0, 500.0, 900.0]

        for _ in range(40):
            # Si creaste una tabla 'paciente', cambia donante_ids por paciente_ids
            id_donante = fake.random_element(donante_ids)
            id_tipo = fake.random_element(tipos_sangre_ids)
            cantidad_ml = fake.random_element(cantidades_ml)
            prioridad = fake.random_element(prioridades)
            fecha_solicitud = fake.date_time_between(start_date="-15d", end_date="now")

            cursor.execute(
                """
                INSERT INTO peticion_sangre (
                    id_donante, id_tipo, cantidad_ml, prioridad, fecha_solicitud
                ) VALUES (%s, %s, %s, %s, %s);
                """,
                (id_donante, id_tipo, cantidad_ml, prioridad, fecha_solicitud),
            )
        print("Insertadas 40 peticiones de sangre.")

        conn.commit()
        print("¡Todas las nuevas tablas fueron pobladas exitosamente!")

    except Exception as e:
        if "conn" in locals():
            conn.rollback()
        print(f"Error durante la inserción: {e}")

    finally:
        if "conn" in locals():
            cursor.close()
            conn.close()


if __name__ == "__main__":
    poblar_nuevas_tablas()
import psycopg2
from psycopg2 import Error

URL_DB = "postgresql://neondb_owner:npg_8cJ9pvUmedLh@ep-quiet-brook-b6glc1w6-pooler.c-2.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"

def getConnection():
    try:
        connection = psycopg2.connect(URL_DB)
        return connection
    except Error as e:
        print(f"Hubo un error al conectar con PostgreSQL: {e}")
        return None
import os
import mysql.connector
from dotenv import load_dotenv

load_dotenv()


def get_db():
    """Return a new MySQL connection."""
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", 3306)),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DB", "sole_store"),
        charset="utf8mb4",
        autocommit=False,
    )

from flask import Blueprint, render_template
from utils.db import get_db

main_bp = Blueprint("main", __name__)


@main_bp.route("/")
def index():
    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT p.*, c.name AS category_name
        FROM products p JOIN categories c ON p.category_id = c.id
        WHERE p.is_featured = TRUE
        ORDER BY p.created_at DESC LIMIT 8
    """)
    featured = cur.fetchall()

    cur.execute("""
        SELECT p.*, c.name AS category_name
        FROM products p JOIN categories c ON p.category_id = c.id
        WHERE p.is_new = TRUE
        ORDER BY p.created_at DESC LIMIT 4
    """)
    new_arrivals = cur.fetchall()

    cur.execute("""
        SELECT p.*, c.name AS category_name
        FROM products p JOIN categories c ON p.category_id = c.id
        WHERE p.is_sale = TRUE
        ORDER BY p.created_at DESC LIMIT 4
    """)
    on_sale = cur.fetchall()

    cur.execute("SELECT * FROM categories")
    categories = cur.fetchall()

    db.close()
    return render_template(
        "index.html",
        featured=featured,
        new_arrivals=new_arrivals,
        on_sale=on_sale,
        categories=categories,
    )

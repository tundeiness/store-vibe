from flask import Blueprint, render_template, request, abort
from utils.db import get_db

products_bp = Blueprint("products", __name__)


@products_bp.route("/")
def listing():
    db = get_db()
    cur = db.cursor(dictionary=True)

    category_slug = request.args.get("category", "")
    brand = request.args.get("brand", "")
    sort = request.args.get("sort", "featured")
    min_price = request.args.get("min_price", 0, type=float)
    max_price = request.args.get("max_price", 9999, type=float)
    page = request.args.get("page", 1, type=int)
    per_page = 12

    filters = []
    params = []

    if category_slug:
        filters.append("c.slug = %s")
        params.append(category_slug)
    if brand:
        filters.append("p.brand = %s")
        params.append(brand)
    filters.append("p.price BETWEEN %s AND %s")
    params += [min_price, max_price]

    where = "WHERE " + " AND ".join(filters) if filters else ""

    sort_map = {
        "price_asc": "p.price ASC",
        "price_desc": "p.price DESC",
        "rating": "p.rating DESC",
        "newest": "p.created_at DESC",
        "featured": "p.is_featured DESC, p.rating DESC",
    }
    order_by = sort_map.get(sort, "p.is_featured DESC")

    count_sql = f"""
        SELECT COUNT(*) AS cnt FROM products p
        JOIN categories c ON p.category_id = c.id {where}
    """
    cur.execute(count_sql, params)
    total = cur.fetchone()["cnt"]

    offset = (page - 1) * per_page
    cur.execute(
        f"""
        SELECT p.*, c.name AS category_name, c.slug AS category_slug
        FROM products p JOIN categories c ON p.category_id = c.id
        {where} ORDER BY {order_by} LIMIT %s OFFSET %s
        """,
        params + [per_page, offset],
    )
    products = cur.fetchall()

    cur.execute("SELECT DISTINCT brand FROM products ORDER BY brand")
    brands = [r["brand"] for r in cur.fetchall()]

    cur.execute("SELECT * FROM categories ORDER BY name")
    categories = cur.fetchall()

    db.close()
    total_pages = (total + per_page - 1) // per_page

    return render_template(
        "products.html",
        products=products,
        brands=brands,
        categories=categories,
        current_category=category_slug,
        current_brand=brand,
        current_sort=sort,
        min_price=min_price,
        max_price=max_price if max_price < 9999 else "",
        page=page,
        total_pages=total_pages,
        total=total,
    )


@products_bp.route("/<slug>")
def detail(slug):
    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT p.*, c.name AS category_name, c.slug AS category_slug
        FROM products p JOIN categories c ON p.category_id = c.id
        WHERE p.slug = %s
    """, (slug,))
    product = cur.fetchone()

    if not product:
        abort(404)

    cur.execute("""
        SELECT size, stock FROM product_inventory
        WHERE product_id = %s ORDER BY CAST(size AS DECIMAL)
    """, (product["id"],))
    inventory = cur.fetchall()

    cur.execute("""
        SELECT * FROM reviews WHERE product_id = %s ORDER BY created_at DESC
    """, (product["id"],))
    reviews = cur.fetchall()

    cur.execute("""
        SELECT p.*, c.name AS category_name FROM products p
        JOIN categories c ON p.category_id = c.id
        WHERE p.category_id = %s AND p.id != %s LIMIT 4
    """, (product["category_id"], product["id"]))
    related = cur.fetchall()

    db.close()
    return render_template(
        "product_detail.html",
        product=product,
        inventory=inventory,
        reviews=reviews,
        related=related,
    )

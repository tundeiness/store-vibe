from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from utils.db import get_db
from utils.cart_helpers import (
    get_cart, get_cart_total, add_to_cart,
    remove_from_cart, update_cart_quantity, get_cart_count,
)

cart_bp = Blueprint("cart", __name__)


@cart_bp.route("/")
def view():
    cart = get_cart()
    total = get_cart_total(cart)
    shipping = 0 if total >= 100 else 9.99
    tax = round(total * 0.08, 2)
    return render_template("cart.html", cart=cart, total=total,
                           shipping=shipping, tax=tax,
                           grand_total=round(total + shipping + tax, 2))


@cart_bp.route("/add", methods=["POST"])
def add():
    product_id = request.form.get("product_id", type=int)
    size = request.form.get("size", "").strip()
    quantity = request.form.get("quantity", 1, type=int)

    if not product_id or not size:
        flash("Please select a size.", "warning")
        return redirect(request.referrer or url_for("main.index"))

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    product = cur.fetchone()

    cur.execute("""
        SELECT stock FROM product_inventory
        WHERE product_id = %s AND size = %s
    """, (product_id, size))
    inv = cur.fetchone()
    db.close()

    if not product or not inv or inv["stock"] < quantity:
        flash("Sorry, that size is out of stock.", "danger")
        return redirect(request.referrer or url_for("main.index"))

    add_to_cart(
        product_id=product["id"],
        size=size,
        product_name=product["name"],
        price=product["price"],
        image_url=product["image_url"],
        quantity=quantity,
    )
    flash(f"'{product['name']}' (size {size}) added to cart!", "success")
    return redirect(request.referrer or url_for("main.index"))


@cart_bp.route("/remove/<key>", methods=["POST"])
def remove(key):
    remove_from_cart(key)
    flash("Item removed from cart.", "info")
    return redirect(url_for("cart.view"))


@cart_bp.route("/update", methods=["POST"])
def update():
    key = request.form.get("key")
    quantity = request.form.get("quantity", type=int)
    if key and quantity is not None:
        update_cart_quantity(key, quantity)
    return redirect(url_for("cart.view"))


@cart_bp.route("/count")
def count():
    return jsonify({"count": get_cart_count()})

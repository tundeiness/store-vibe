import uuid
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.db import get_db
from utils.cart_helpers import get_cart, get_cart_total, clear_cart

checkout_bp = Blueprint("checkout", __name__)


@checkout_bp.route("/", methods=["GET", "POST"])
def index():
    cart = get_cart()
    if not cart:
        flash("Your cart is empty.", "warning")
        return redirect(url_for("cart.view"))

    subtotal = get_cart_total(cart)
    shipping = 0 if subtotal >= 100 else 9.99
    tax = round(subtotal * 0.08, 2)
    grand_total = round(subtotal + shipping + tax, 2)

    # Pre-fill if logged in
    user_data = {}
    if session.get("user_id"):
        db = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute("SELECT * FROM users WHERE id = %s", (session["user_id"],))
        u = cur.fetchone()
        cur.execute("""
            SELECT * FROM addresses WHERE user_id = %s AND is_default = TRUE LIMIT 1
        """, (session["user_id"],))
        addr = cur.fetchone()
        db.close()
        if u:
            user_data = u
        if addr:
            user_data.update(addr)

    return render_template(
        "checkout.html",
        cart=cart,
        subtotal=subtotal,
        shipping=shipping,
        tax=tax,
        grand_total=grand_total,
        user_data=user_data,
    )


@checkout_bp.route("/place-order", methods=["POST"])
def place_order():
    cart = get_cart()
    if not cart:
        return redirect(url_for("cart.view"))

    subtotal = get_cart_total(cart)
    shipping = 0 if subtotal >= 100 else 9.99
    tax = round(subtotal * 0.08, 2)
    grand_total = round(subtotal + shipping + tax, 2)

    f = request.form
    order_number = "SS-" + uuid.uuid4().hex[:8].upper()

    db = get_db()
    cur = db.cursor(dictionary=True)

    try:
        cur.execute("""
            INSERT INTO orders (order_number, user_id, guest_email, subtotal,
                shipping_cost, tax, total, shipping_name, shipping_street,
                shipping_city, shipping_state, shipping_zip, shipping_country,
                payment_method, notes)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            order_number,
            session.get("user_id"),
            f.get("email"),
            subtotal, shipping, tax, grand_total,
            f.get("first_name", "") + " " + f.get("last_name", ""),
            f.get("address"),
            f.get("city"),
            f.get("state"),
            f.get("zip"),
            f.get("country", "United States"),
            f.get("payment_method", "card"),
            f.get("notes", ""),
        ))
        order_id = cur.lastrowid

        for item in cart.values():
            cur.execute("""
                INSERT INTO order_items
                  (order_id, product_id, product_name, size, quantity, unit_price, total_price)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                order_id,
                item["product_id"],
                item["name"],
                item["size"],
                item["quantity"],
                item["price"],
                item["price"] * item["quantity"],
            ))
            # Decrement stock
            cur.execute("""
                UPDATE product_inventory SET stock = stock - %s
                WHERE product_id = %s AND size = %s AND stock >= %s
            """, (item["quantity"], item["product_id"], item["size"], item["quantity"]))

        db.commit()
        clear_cart()
        db.close()
        return redirect(url_for("checkout.success", order_number=order_number))

    except Exception as e:
        db.rollback()
        db.close()
        flash(f"Order failed: {e}", "danger")
        return redirect(url_for("checkout.index"))


@checkout_bp.route("/success/<order_number>")
def success(order_number):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM orders WHERE order_number = %s", (order_number,))
    order = cur.fetchone()
    cur.execute("SELECT * FROM order_items WHERE order_id = %s", (order["id"],))
    items = cur.fetchall()
    db.close()
    return render_template("order_success.html", order=order, items=items)

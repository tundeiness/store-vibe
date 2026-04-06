from flask import Blueprint, render_template, session, redirect, url_for
from utils.db import get_db
from utils.auth_helpers import login_required

account_bp = Blueprint("account", __name__)


@account_bp.route("/")
@login_required
def dashboard():
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM users WHERE id = %s", (session["user_id"],))
    user = cur.fetchone()
    cur.execute("""
        SELECT o.*, COUNT(oi.id) AS item_count
        FROM orders o LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.user_id = %s GROUP BY o.id ORDER BY o.created_at DESC LIMIT 5
    """, (session["user_id"],))
    recent_orders = cur.fetchall()
    db.close()
    return render_template("account.html", user=user, recent_orders=recent_orders)


@account_bp.route("/orders")
@login_required
def orders():
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT o.*, COUNT(oi.id) AS item_count
        FROM orders o LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.user_id = %s GROUP BY o.id ORDER BY o.created_at DESC
    """, (session["user_id"],))
    all_orders = cur.fetchall()
    db.close()
    return render_template("orders.html", orders=all_orders)

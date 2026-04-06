from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.db import get_db
from utils.auth_helpers import hash_password, check_password

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    if session.get("user_id"):
        return redirect(url_for("account.dashboard"))

    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        first_name = request.form.get("first_name", "").strip()
        last_name = request.form.get("last_name", "").strip()

        if not all([email, password, first_name, last_name]):
            flash("All fields are required.", "danger")
            return render_template("register.html")

        if len(password) < 8:
            flash("Password must be at least 8 characters.", "danger")
            return render_template("register.html")

        db = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            flash("An account with that email already exists.", "danger")
            db.close()
            return render_template("register.html")

        try:
            cur.execute("""
                INSERT INTO users (email, password_hash, first_name, last_name)
                VALUES (%s, %s, %s, %s)
            """, (email, hash_password(password), first_name, last_name))
            db.commit()
            user_id = cur.lastrowid
            session["user_id"] = user_id
            session["user_name"] = first_name
            flash(f"Welcome to Sole Store, {first_name}!", "success")
            return redirect(url_for("account.dashboard"))
        except Exception as e:
            db.rollback()
            flash("Registration failed. Please try again.", "danger")
        finally:
            db.close()

    return render_template("register.html")


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if session.get("user_id"):
        return redirect(url_for("account.dashboard"))

    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")

        db = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        db.close()

        if user and check_password(password, user["password_hash"]):
            session["user_id"] = user["id"]
            session["user_name"] = user["first_name"]
            flash(f"Welcome back, {user['first_name']}!", "success")
            next_page = request.args.get("next")
            return redirect(next_page or url_for("account.dashboard"))

        flash("Invalid email or password.", "danger")

    return render_template("login.html")


@auth_bp.route("/logout")
def logout():
    session.clear()
    flash("You've been logged out.", "info")
    return redirect(url_for("main.index"))

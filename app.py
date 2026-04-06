import os
from flask import Flask
from flask_session import Session
from dotenv import load_dotenv
import redis

from routes.main import main_bp
from routes.products import products_bp
from routes.cart import cart_bp
from routes.checkout import checkout_bp
from routes.auth import auth_bp
from routes.account import account_bp

load_dotenv()


def create_app():
    app = Flask(__name__)

    # ── Config ──────────────────────────────────────────────
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-secret-change-me")

    # Flask-Session backed by Redis
    app.config["SESSION_TYPE"] = "redis"
    app.config["SESSION_PERMANENT"] = False
    app.config["SESSION_USE_SIGNER"] = True
    app.config["SESSION_KEY_PREFIX"] = "sole:"
    app.config["SESSION_REDIS"] = redis.Redis(
        host=os.getenv("REDIS_HOST", "localhost"),
        port=int(os.getenv("REDIS_PORT", 6379)),
        password=os.getenv("REDIS_PASSWORD") or None,
        decode_responses=False,
    )
    Session(app)

    # ── Blueprints ───────────────────────────────────────────
    app.register_blueprint(main_bp)
    app.register_blueprint(products_bp, url_prefix="/products")
    app.register_blueprint(cart_bp, url_prefix="/cart")
    app.register_blueprint(checkout_bp, url_prefix="/checkout")
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(account_bp, url_prefix="/account")

    # ── Global template helpers ──────────────────────────────
    from utils.db import get_db
    from utils.cart_helpers import get_cart_count

    @app.context_processor
    def inject_globals():
        db = get_db()
        categories = []
        try:
            cur = db.cursor(dictionary=True)
            cur.execute("SELECT id, name, slug FROM categories ORDER BY name")
            categories = cur.fetchall()
        except Exception:
            pass
        finally:
            db.close()
        return dict(
            cart_count=get_cart_count(),
            nav_categories=categories,
        )

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True, port=5000)

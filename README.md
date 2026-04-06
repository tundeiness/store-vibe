# 👟 Sole Store — Full-Stack Shoe E-Commerce

A complete shoe e-commerce application built with **Flask**, **MySQL**, and **Redis**.

## 🗂 Project Structure

```
sole_store/
├── app.py                  # Flask application factory & entry point
├── schema.sql              # MySQL schema + seed data (8 products, reviews)
├── requirements.txt        # Python dependencies
├── setup.sh                # One-command local setup script
├── .env.example            # Environment variable template
│
├── routes/
│   ├── main.py             # Homepage / landing page
│   ├── products.py         # Product listing & detail pages
│   ├── cart.py             # Cart (add / remove / update)
│   ├── checkout.py         # Checkout form & order placement
│   ├── auth.py             # Register / Login / Logout
│   └── account.py          # Dashboard & order history
│
├── utils/
│   ├── db.py               # MySQL connection helper
│   ├── cart_helpers.py     # Cart logic (stored in Redis session)
│   └── auth_helpers.py     # Password hashing, login_required decorator
│
└── templates/
    ├── base.html           # Shared layout (nav, footer, flash messages)
    ├── index.html          # Landing page (hero, featured, categories)
    ├── products.html       # Product listing with filters & pagination
    ├── product_detail.html # Product detail with gallery, sizes, reviews
    ├── cart.html           # Cart page
    ├── checkout.html       # Checkout (contact + shipping + payment)
    ├── order_success.html  # Order confirmation page
    ├── login.html          # Login page
    ├── register.html       # Registration page
    ├── account.html        # Account dashboard
    └── orders.html         # Full order history
```

---

## ⚙️ Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Python | 3.9+ | https://python.org |
| MySQL | 8.0+ | https://dev.mysql.com/downloads/ |
| Redis | 6.0+ | https://redis.io/download |

### Quick install on macOS (Homebrew)
```bash
brew install mysql redis python
brew services start mysql
brew services start redis
```

### Quick install on Ubuntu/Debian
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv mysql-server redis-server
sudo systemctl start mysql redis-server
```

### Quick install on Windows
- Python: https://python.org/downloads
- MySQL: https://dev.mysql.com/downloads/installer/
- Redis: https://github.com/tporadowski/redis/releases (Windows port)

---

## 🚀 Quick Start

### Option A — Automated setup script (Linux/macOS)
```bash
cd sole_store
bash setup.sh
```
On first run it will create `.env` for you. Fill in your MySQL password, then run again.

---

### Option B — Manual step-by-step

#### 1. Clone / navigate to the project
```bash
cd sole_store
```

#### 2. Create and activate virtual environment
```bash
python3 -m venv venv
source venv/bin/activate        # macOS/Linux
venv\Scripts\activate.bat       # Windows CMD
venv\Scripts\Activate.ps1       # Windows PowerShell
```

#### 3. Install dependencies
```bash
pip install -r requirements.txt
```

#### 4. Configure environment variables
```bash
cp .env.example .env
```
Edit `.env` with your credentials:
```env
SECRET_KEY=change-this-to-something-random-and-long

MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password_here
MYSQL_DB=sole_store

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

#### 5. Set up the database
```bash
mysql -u root -p < schema.sql
```
This creates the `sole_store` database with all tables and seed data (8 products, 4 categories, sample reviews).

#### 6. Make sure Redis is running
```bash
redis-cli ping    # Should return PONG
```

#### 7. Run the app
```bash
python app.py
```

Open your browser: **http://localhost:5000**

---

## 📄 Pages Overview

| URL | Page |
|-----|------|
| `/` | Landing page — hero, featured products, categories |
| `/products/` | Product listing with filters (category, brand, price, sort) |
| `/products/<slug>` | Product detail — gallery, sizes, reviews, add to cart |
| `/cart/` | Cart — item list, quantity update, remove, order summary |
| `/checkout/` | Checkout — contact, shipping address, payment (demo) |
| `/checkout/success/<order_number>` | Order confirmation |
| `/auth/register` | Register new account |
| `/auth/login` | Login |
| `/auth/logout` | Logout |
| `/account/` | Account dashboard |
| `/account/orders` | Full order history |

---

## 🏗 Architecture

### Session & Cart — Redis
The shopping cart is stored in the Flask session, which is persisted in **Redis** via `Flask-Session`. Each cart item is keyed by `{product_id}_{size}` to support multiple sizes of the same shoe.

### Authentication
Passwords are hashed with **PBKDF2-HMAC-SHA256** with a random salt (no external library needed). The `login_required` decorator redirects unauthenticated users.

### Database — MySQL
Five core tables:
- `users` — accounts
- `products` + `categories` — catalog
- `product_inventory` — per-size stock
- `orders` + `order_items` — placed orders
- `reviews` — product reviews

### Payment
This is a **demo** app — no real payment gateway is integrated. The checkout form collects card details but does not process them. To add real payments, integrate **Stripe** or **PayPal** in `routes/checkout.py`.

---

## 🔧 Common Issues

**MySQL connection refused**
```bash
sudo systemctl start mysql    # Linux
brew services start mysql     # macOS
```

**Redis connection refused**
```bash
redis-server --daemonize yes  # Start in background
```

**`pip install` fails on mysql-connector**
```bash
pip install mysql-connector-python --no-cache-dir
```

**Port 5000 already in use**
```bash
python app.py  # Change port in app.py: app.run(port=5001)
```

---

## 🚢 Deploying to Production

For production deployment:

1. Set `FLASK_ENV=production` and use a strong `SECRET_KEY`
2. Use **Gunicorn** as the WSGI server: `gunicorn -w 4 "app:create_app()"`
3. Put **Nginx** in front as a reverse proxy
4. Use a managed **MySQL** (PlanetScale, AWS RDS, etc.)
5. Use a managed **Redis** (Redis Cloud, AWS ElastiCache, etc.)
6. Serve static files via Nginx or a CDN
7. Integrate a real payment gateway (Stripe recommended)

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Flask 3.0 |
| Database | MySQL 8 + mysql-connector-python |
| Sessions / Cache | Redis + Flask-Session |
| Frontend | Jinja2 templates, vanilla CSS + JS |
| Fonts | Bebas Neue + DM Sans (Google Fonts) |
| Images | Unsplash (demo) |

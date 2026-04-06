# 👟 store-vibe — Full-Stack Shoe E-Commerce

A complete shoe e-commerce application built with **Flask**, **MySQL**, and **Redis**.  
Runs locally with a single script or as a fully containerised stack via Docker.

## 🗂 Project Structure

```
sole_store/
├── app.py                  # Flask application factory & entry point
├── schema.sql              # MySQL schema + seed data (8 products, reviews)
├── requirements.txt        # Python dependencies (incl. Gunicorn)
├── setup.sh                # One-command local setup script
├── Dockerfile              # Multi-stage optimised Docker image
├── docker-compose.yml      # Orchestrates app + MySQL + Redis containers
├── .dockerignore           # Keeps Docker build context lean
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

### To run locally (without Docker)

| Tool | Version | Install |
|------|---------|---------|
| Python | 3.10+ | https://python.org |
| MySQL | 8.0+ | https://dev.mysql.com/downloads/ |
| Redis | 6.0+ | https://redis.io/download |

#### macOS (Homebrew)
```bash
brew install mysql redis python
brew services start mysql
brew services start redis
```

#### Ubuntu / Debian
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv mysql-server redis-server
sudo systemctl start mysql redis-server
```

#### Windows
- Python: https://python.org/downloads
- MySQL: https://dev.mysql.com/downloads/installer/
- Redis: https://github.com/tporadowski/redis/releases

### To run with Docker

| Tool | Install |
|------|---------|
| Docker Desktop | https://www.docker.com/products/docker-desktop |

Docker bundles MySQL and Redis automatically — no separate installs needed.

---

## 🚀 Quick Start

### Option A — Docker (recommended, no local MySQL/Redis needed)

```bash
cd sole_store

# First run — builds the image, seeds the database, starts all services
docker compose up --build
```

Open **http://127.0.0.1:5000**

```bash
# Run in background
docker compose up -d

# View live logs
docker compose logs -f app

# Stop all containers
docker compose down

# Stop and delete the database volume (full reset)
docker compose down -v
```

> **Note:** MySQL is exposed on host port `3307` and Redis on `6380` to avoid
> clashing with any locally running instances. The Flask app is still on `5000`.

> **Port conflict — running Docker alongside a local Flask app:**
> If port 5000 is already in use, change the host port in `docker-compose.yml`
> so both can run at the same time:
> ```yaml
> ports:
>   - "5001:5000"   # Docker app → http://127.0.0.1:5001
>                   # Local app  → http://127.0.0.1:5000
> ```
> **Important:** when running both side-by-side, they use **separate databases**.
> Local Flask talks to your machine's MySQL (`:3306`), Docker has its own isolated
> MySQL in the `db_data` volume (`:3307`). Orders, accounts, and cart data do not
> sync between them.
>
> Full port map when running both simultaneously:
>
> | Service | Local | Docker |
> |---------|-------|--------|
> | Flask app | http://127.0.0.1:5000 | http://127.0.0.1:5001 |
> | MySQL | localhost:3306 | localhost:3307 |
> | Redis | localhost:6379 | localhost:6380 |
>
> To switch Docker back to port 5000, stop the local process first —
> `lsof -ti :5000 | xargs kill -9` — revert the port to `5000:5000`,
> then `docker compose down && docker compose up -d`.

---

### Option B — Automated local script (macOS / Linux)

```bash
cd sole_store
bash setup.sh
```

On first run it creates `.env` for you. Add your MySQL password, then run again.

---

### Option C — Manual local setup

#### 1. Navigate to the project
```bash
cd sole_store
```

#### 2. Create and activate a virtual environment
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
Edit `.env`:
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

#### 5. Create and seed the database
```bash
mysql -u root -p < schema.sql
```
This creates `sole_store` with all tables and seed data (8 products, 4 categories, sample reviews).

#### 6. Confirm Redis is running
```bash
redis-cli ping    # Should return PONG
```

#### 7. Start the app
```bash
python app.py
```

Open **http://127.0.0.1:5000**

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
The shopping cart is stored in the Flask session, persisted in **Redis** via `Flask-Session`. Each cart item is keyed by `{product_id}_{size}` to support multiple sizes of the same shoe.

### Authentication
Passwords are hashed with **PBKDF2-HMAC-SHA256** with a random salt (no external library needed). The `login_required` decorator redirects unauthenticated users.

### Database — MySQL
Six core tables:

| Table | Purpose |
|-------|---------|
| `users` | Accounts |
| `categories` | Shoe categories |
| `products` | Catalog |
| `product_inventory` | Per-size stock levels |
| `orders` + `order_items` | Placed orders |
| `reviews` | Product reviews |

### WSGI Server — Gunicorn
In Docker, the app is served by **Gunicorn** (4 workers, 120s timeout) instead of Flask's development server. When running locally via `python app.py`, Flask's dev server is used with hot-reload enabled.

### Payment
This is a **demo** app — no real payment gateway is integrated. The checkout form collects card details but does not process them. To add real payments, integrate **Stripe** in `routes/checkout.py`.

### Docker — multi-stage build
The `Dockerfile` uses two stages:
- **builder** — installs `gcc` and compiles all Python packages (~400 MB, discarded)
- **runtime** — copies only the compiled wheels into a slim image (~120 MB final size)

The app runs as a non-root user (`appuser`) inside the container for security.

---

## 🔧 Common Issues

**Port 5000 already in use**
If Docker and a local Flask app need to run simultaneously, change the host port
in `docker-compose.yml` under the `app` service:
```yaml
ports:
  - "5001:5000"   # Docker → http://127.0.0.1:5001
                  # Local  → http://127.0.0.1:5000
```
Note that each runs against its own separate database — data does not sync.
To kill a local Flask process blocking port 5000:
```bash
lsof -ti :5000 | xargs kill -9
```

**`MYSQL_USER="root"` error in Docker**  
The MySQL image forbids setting `MYSQL_USER=root` — root is managed by `MYSQL_ROOT_PASSWORD` only. The `docker-compose.yml` already handles this correctly; if you see this error, run `docker compose down -v` to wipe the old volume and try again.

**MySQL connection refused (local)**
```bash
brew services start mysql     # macOS
sudo systemctl start mysql    # Linux
```

**Redis connection refused (local)**
```bash
redis-server --daemonize yes
```

**`pip install` fails on mysql-connector**
```bash
pip install mysql-connector-python --no-cache-dir
```

**Reset the database (local)**
```bash
mysql -u root -p < schema.sql   # drops and recreates sole_store
```

**Reset the database (Docker)**
```bash
docker compose down -v          # deletes db_data volume
docker compose up --build       # recreates and re-seeds from schema.sql
```

**Browser shows "Access denied" on localhost:5000**  
Use `http://127.0.0.1:5000` instead — some browsers block `localhost` due to HSTS settings.

---

## 🚢 Deploying to Production

The Docker setup is already production-ready at the application layer. Additional steps for a real deployment:

1. Set a strong `SECRET_KEY` and `MYSQL_ROOT_PASSWORD` in your environment / secrets manager
2. Replace `FLASK_ENV=production` (already set in `docker-compose.yml`)
3. Put **Nginx** in front as a reverse proxy and TLS terminator
4. Switch to a managed **MySQL** (PlanetScale, AWS RDS, Google Cloud SQL)
5. Switch to a managed **Redis** (Redis Cloud, AWS ElastiCache, Upstash)
6. Remove the source-code volume mounts from `docker-compose.yml` for immutable containers
7. Integrate a real payment gateway (**Stripe** recommended) in `routes/checkout.py`
8. Serve static files via Nginx or a CDN (CloudFront, Cloudflare)

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Flask 3.0 |
| WSGI Server | Gunicorn 21 (Docker) / Flask dev server (local) |
| Database | MySQL 8 + mysql-connector-python |
| Sessions / Cache | Redis 7 + Flask-Session |
| Containerisation | Docker (multi-stage) + Docker Compose |
| Frontend | Jinja2 templates, vanilla CSS + JS |
| Fonts | Bebas Neue + DM Sans (Google Fonts) |
| Images | Unsplash (demo) |

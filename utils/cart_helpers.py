from flask import session


def get_cart():
    """Return the cart dict from session. Structure: {'{product_id}_{size}': {item}}"""
    return session.get("cart", {})


def save_cart(cart):
    session["cart"] = cart
    session.modified = True


def get_cart_count():
    cart = get_cart()
    return sum(item["quantity"] for item in cart.values())


def get_cart_total(cart):
    return sum(item["price"] * item["quantity"] for item in cart.values())


def add_to_cart(product_id, size, product_name, price, image_url, quantity=1):
    cart = get_cart()
    key = f"{product_id}_{size}"
    if key in cart:
        cart[key]["quantity"] += quantity
    else:
        cart[key] = {
            "product_id": product_id,
            "size": size,
            "name": product_name,
            "price": float(price),
            "image_url": image_url,
            "quantity": quantity,
        }
    save_cart(cart)


def remove_from_cart(key):
    cart = get_cart()
    cart.pop(key, None)
    save_cart(cart)


def update_cart_quantity(key, quantity):
    cart = get_cart()
    if key in cart:
        if quantity <= 0:
            del cart[key]
        else:
            cart[key]["quantity"] = quantity
    save_cart(cart)


def clear_cart():
    session.pop("cart", None)
    session.modified = True

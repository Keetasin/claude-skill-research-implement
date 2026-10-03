#!/usr/bin/env bash
# Create a small throwaway Python repo for the skill evals.
# Usage: make_fixture.sh <dir>   (dir must not exist)
# State after setup: one commit, then uncommitted edits (dirty tree) and one pre-existing failing test.
set -euo pipefail

d=${1:?usage: make_fixture.sh <dir>}
[ -e "$d" ] && { echo "exists: $d" >&2; exit 1; }
mkdir -p "$d/shop" "$d/tests"
cd "$d"
git init -q

cat > shop/__init__.py <<'EOF'
EOF

cat > shop/cart.py <<'EOF'
"""Shopping cart totals."""


def subtotal(items):
    """Sum price * qty for each item dict."""
    total = 0
    for item in items:
        total += item["price"] * item["qty"]
    return total


def apply_discount(amount, percent):
    """Return amount after a percent discount."""
    return amount - amount * percent / 100


def bulk_price(qty, unit_price):
    """Unit price drops 10% from 10 items up."""
    if qty > 10:  # bug: should be >= 10
        return qty * unit_price * 0.9
    return qty * unit_price
EOF

cat > shop/text.py <<'EOF'
"""Display helpers."""


def money(value):
    return f"{value:.2f} THB"
EOF

cat > tests/test_cart.py <<'EOF'
from shop.cart import apply_discount, subtotal


def test_subtotal():
    assert subtotal([{"price": 10, "qty": 2}, {"price": 5, "qty": 1}]) == 25


def test_discount():
    assert apply_discount(200, 10) == 180
EOF

cat > tests/test_text.py <<'EOF'
from shop.text import money


def test_money():
    assert money(5) == "5.00 THB"


def test_money_negative_preexisting_failure():
    # Known failure that exists before any task; must stay out of scope.
    assert money(-5) == "-5.00 THB (refund)"
EOF

printf '[pytest]\npythonpath = .\n' > pytest.ini
printf '__pycache__/\n.pytest_cache/\n' > .gitignore
git add .
git -c user.email=eval@example.com -c user.name=eval commit -qm "fixture"

# Uncommitted user work that the skill must not destroy.
printf '\n\ndef item_count(items):\n    return sum(i["qty"] for i in items)\n' >> shop/cart.py
echo "fixture ready: $d (dirty tree, 1 pre-existing failing test)"

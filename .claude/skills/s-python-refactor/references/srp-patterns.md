# SRP Patterns Reference

Extended examples for Single Responsibility violations, with Django-specific patterns.

## Table of Contents
1. [Fat Model Pattern](#1-fat-model-pattern)
2. [Fat View Pattern](#2-fat-view-pattern)
3. [God Service Pattern](#3-god-service-pattern)
4. [Mixed Serializer Pattern](#4-mixed-serializer-pattern)
5. [Utility Dumping Ground](#5-utility-dumping-ground)
6. [Orchestrator Anti-Pattern](#6-orchestrator-anti-pattern)

---

## 1. Fat Model Pattern

Django models accumulate business logic over time. The model should own
data integrity (validators, properties derived from its own fields) but
not orchestration, external calls, or cross-model business rules.

```python
# ❌ Fat model — does persistence, email, and business logic
class Order(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20)

    def complete_order(self):
        self.status = "completed"
        self.save()
        # send email
        send_mail(
            subject="Your order is complete",
            message=f"Order {self.id} has been completed.",
            from_email="noreply@example.com",
            recipient_list=[self.user.email],
        )
        # update inventory
        for item in self.items.all():
            item.product.stock -= item.quantity
            item.product.save()

# ✅ Thin model + service layer
class Order(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20)

    def mark_completed(self):
        """Only owns its own state."""
        self.status = "completed"
        self.save()

class OrderCompletionService:
    """Orchestrates the completion workflow."""

    def __init__(self, mailer, inventory_service):
        self.mailer = mailer
        self.inventory_service = inventory_service

    def complete(self, order: Order):
        order.mark_completed()
        self.mailer.send_order_confirmation(order)
        self.inventory_service.deduct_for_order(order)
```

---

## 2. Fat View Pattern

Django views should handle HTTP concerns only: parse request, call service,
return response. Business logic does not belong here.

```python
# ❌ Fat view — business logic tangled with HTTP handling
class CheckoutView(View):
    def post(self, request):
        cart = Cart.objects.get(user=request.user)
        if not cart.items.exists():
            return JsonResponse({"error": "Cart is empty"}, status=400)

        total = sum(item.product.price * item.quantity for item in cart.items.all())
        if request.user.is_vip:
            total *= Decimal("0.9")

        order = Order.objects.create(user=request.user, total=total, status="pending")
        for item in cart.items.all():
            OrderItem.objects.create(order=order, product=item.product, quantity=item.quantity)
            item.product.stock -= item.quantity
            item.product.save()

        cart.items.all().delete()
        send_mail("Order confirmed", f"Order #{order.id}", "no-reply@x.com", [request.user.email])
        return JsonResponse({"order_id": order.id})

# ✅ Thin view — delegates to service
class CheckoutView(View):
    def post(self, request):
        try:
            order = checkout_service.checkout(request.user)
        except EmptyCartError:
            return JsonResponse({"error": "Cart is empty"}, status=400)
        return JsonResponse({"order_id": order.id})

# Service owns all the logic — testable without HTTP
class CheckoutService:
    def checkout(self, user: User) -> Order:
        cart = Cart.objects.get(user=user)
        if not cart.items.exists():
            raise EmptyCartError()
        total = self._calculate_total(cart, user)
        order = self._create_order(user, cart, total)
        self._clear_cart(cart)
        self._notify(order)
        return order

    def _calculate_total(self, cart, user) -> Decimal: ...
    def _create_order(self, user, cart, total) -> Order: ...
    def _clear_cart(self, cart): ...
    def _notify(self, order): ...
```

---

## 3. God Service Pattern

A "service" file that grows to handle an entire domain is a common failure mode.

```python
# ❌ UserService doing auth, profile, notifications, and reporting
class UserService:
    def authenticate(self, username, password): ...
    def issue_token(self, user): ...
    def verify_token(self, token): ...
    def update_profile(self, user, data): ...
    def upload_avatar(self, user, image): ...
    def send_welcome_email(self, user): ...
    def send_password_reset(self, user): ...
    def generate_monthly_report(self, user): ...
    def export_user_data_gdpr(self, user): ...

# ✅ Split by responsibility
class AuthService:
    def authenticate(self, username, password): ...
    def issue_token(self, user): ...
    def verify_token(self, token): ...

class UserProfileService:
    def update_profile(self, user, data): ...
    def upload_avatar(self, user, image): ...

class UserNotificationService:
    def send_welcome_email(self, user): ...
    def send_password_reset(self, user): ...

class UserDataService:
    def generate_monthly_report(self, user): ...
    def export_gdpr_data(self, user): ...
```

**Rule of thumb:** If a service class has more than 5 public methods, audit whether
they all share the same "reason to change." Different stakeholders (auth team vs.
product team vs. legal) → different classes.

---

## 4. Mixed Serializer Pattern

DRF serializers sometimes accumulate validation logic, transformation logic,
and side effects all in one place.

```python
# ❌ Serializer doing validation + business logic + side effects
class OrderSerializer(serializers.ModelSerializer):
    def validate(self, data):
        # business logic in validate
        if data["quantity"] > data["product"].stock:
            raise serializers.ValidationError("Insufficient stock")
        if data["product"].is_discontinued:
            raise serializers.ValidationError("Product discontinued")
        # discount calculation
        if self.context["request"].user.is_vip:
            data["price"] = data["product"].price * Decimal("0.9")
        return data

    def create(self, validated_data):
        order = Order.objects.create(**validated_data)
        # side effect in serializer
        send_confirmation_email(order)
        track_analytics_event("order_created", order)
        return order

# ✅ Serializer handles shape/format; service handles logic
class OrderSerializer(serializers.ModelSerializer):
    def validate_quantity(self, value):
        if value <= 0:
            raise serializers.ValidationError("Quantity must be positive")
        return value

class OrderService:
    def create_order(self, user, product, quantity) -> Order:
        self._check_availability(product, quantity)
        price = self._calculate_price(user, product)
        order = Order.objects.create(product=product, quantity=quantity, price=price)
        self._post_creation_hooks(order)
        return order
```

---

## 5. Utility Dumping Ground

`utils.py` is the most common SRP graveyard. When a util file has 15 unrelated
helper functions, it has no single responsibility.

**Detection:** Open `utils.py`. If you can't describe it in one sentence, it needs to be split.

```
# ❌ utils.py containing everything
utils.py
  format_currency()
  send_slack_alert()
  parse_csv_upload()
  get_client_ip()
  truncate_string()
  validate_colombian_id()
  haversine_distance()

# ✅ Split by domain
formatters.py        → format_currency(), truncate_string()
notifications.py     → send_slack_alert()
parsers.py           → parse_csv_upload()
http_utils.py        → get_client_ip()
validators.py        → validate_colombian_id()
geo.py               → haversine_distance()
```

---

## 6. Orchestrator Anti-Pattern

The opposite failure: splitting so aggressively that you end up with a top-level
function that does *only* orchestration and each extracted piece is too small to
have meaning. This makes code harder to navigate.

```python
# ❌ Over-extracted — each "step" is a one-liner with no semantic value
def process_payment(order):
    _prepare(order)
    _run(order)
    _finish(order)

def _prepare(order):
    order.status = "processing"   # these don't earn their own function

def _run(order):
    charge(order.total)

def _finish(order):
    order.status = "paid"

# ✅ The right level — steps are meaningful, named for their responsibility
def process_payment(order):
    order.status = "processing"
    charge_customer(order)        # this earns a function — it does real work
    order.status = "paid"
    order.save()
```

**Rule:** An extracted function earns its existence when:
1. It has a clear name that describes its responsibility
2. It could plausibly be reused, OR
3. It has enough complexity that naming it improves readability of the caller

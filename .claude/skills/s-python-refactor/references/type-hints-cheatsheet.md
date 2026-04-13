# Type Hints Cheatsheet

Quick reference for complex and commonly misused typing scenarios in Python.

## Table of Contents
1. [Modern vs Legacy Syntax](#modern-vs-legacy-syntax)
2. [Unions and Optional](#unions-and-optional)
3. [Collections](#collections)
4. [Callables](#callables)
5. [Generics](#generics)
6. [TypedDict and dataclass](#typeddict-and-dataclass)
7. [Protocols (Structural Subtyping)](#protocols)
8. [Django-Specific Patterns](#django-specific-patterns)

---

## Modern vs Legacy Syntax

Python 3.10+ allows native union syntax. Prefer it.

```python
# Legacy (pre-3.10)
from typing import Optional, Union, List, Dict, Tuple
def f(x: Optional[int]) -> Union[str, int]: ...
def g(items: List[str]) -> Dict[str, int]: ...

# Modern (3.10+)
def f(x: int | None) -> str | int: ...
def g(items: list[str]) -> dict[str, int]: ...
```

For 3.9 compatibility without the legacy imports, use `from __future__ import annotations`
at the top of the file — it defers evaluation and allows modern syntax everywhere.

---

## Unions and Optional

```python
# Nullable return
def find_user(id: int) -> User | None: ...

# Multiple valid types (use sparingly — often a design smell)
def parse(value: str | int | float) -> Decimal: ...

# Never use Optional[X] in new code — X | None is cleaner
```

---

## Collections

```python
# Immutable sequences (prefer over list when not mutating)
from collections.abc import Sequence
def process(items: Sequence[str]) -> None: ...

# Mappings (prefer over dict when read-only)
from collections.abc import Mapping
def render(context: Mapping[str, object]) -> str: ...

# Iterables (most permissive — good for generators and lists alike)
from collections.abc import Iterable
def total(values: Iterable[int]) -> int: ...

# Mutable when you need it
def append_all(target: list[str], source: list[str]) -> None: ...
```

---

## Callables

```python
from collections.abc import Callable

# Callable[[arg_types], return_type]
def apply(fn: Callable[[int, int], int], a: int, b: int) -> int:
    return fn(a, b)

# No args
def run(callback: Callable[[], None]) -> None:
    callback()

# Unknown args (use sparingly)
def wrap(fn: Callable[..., str]) -> str:
    return fn()
```

---

## Generics

```python
from typing import TypeVar, Generic

T = TypeVar("T")

# Generic function
def first(items: list[T]) -> T | None:
    return items[0] if items else None

# Generic class
class Repository(Generic[T]):
    def get(self, id: int) -> T | None: ...
    def save(self, entity: T) -> None: ...

class UserRepository(Repository[User]): ...
```

---

## TypedDict and dataclass

Use `TypedDict` for dict-shaped data you don't control (API responses, config).
Use `dataclass` for data you own.

```python
from typing import TypedDict
from dataclasses import dataclass, field

# TypedDict — for dict-like structures (JSON responses, etc.)
class MovieData(TypedDict):
    id: int
    title: str
    release_year: int
    rating: float | None

# dataclass — for your own domain objects
@dataclass
class Order:
    id: int
    user_id: int
    items: list[OrderItem] = field(default_factory=list)
    total: Decimal = Decimal("0")

    def add_item(self, item: OrderItem) -> None:
        self.items.append(item)
        self.total += item.price

# frozen=True for value objects (immutable)
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str
```

---

## Protocols

Use `Protocol` for structural subtyping — "anything that has these methods" —
without requiring inheritance. Excellent for dependency injection.

```python
from typing import Protocol

# Define the interface
class Notifier(Protocol):
    def send(self, recipient: str, message: str) -> None: ...

# Any class with a matching .send() satisfies this — no inheritance needed
class EmailNotifier:
    def send(self, recipient: str, message: str) -> None:
        send_mail(message, recipient)

class SlackNotifier:
    def send(self, recipient: str, message: str) -> None:
        slack_client.post(recipient, message)

class SMSNotifier:
    def send(self, recipient: str, message: str) -> None:
        twilio.send(recipient, message)

# Service depends on the Protocol, not any concrete class
class AlertService:
    def __init__(self, notifier: Notifier) -> None:
        self.notifier = notifier
```

---

## Django-Specific Patterns

```python
from django.db.models import QuerySet
from django.http import HttpRequest, HttpResponse

# Typed QuerySets
def get_active_users() -> QuerySet[User]:
    return User.objects.filter(is_active=True)

# View type hints
def my_view(request: HttpRequest) -> HttpResponse: ...

# Settings access
from django.conf import settings
timeout: int = settings.REQUEST_TIMEOUT  # type: ignore[attr-defined]

# Model fields don't need annotation in the model body itself,
# but service layer functions passing model instances should be typed:
def promote_to_admin(user: User) -> None:
    user.is_staff = True
    user.save()
```

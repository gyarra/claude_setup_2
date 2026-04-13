---
name: s-python-refactor
description: >
  Refactor Python code using best practices: Single Responsibility, Pythonic idioms,
  type hints, error handling, naming conventions, and testing-friendliness. Use this
  skill whenever the user asks to refactor, clean up, improve, or review Python code —
  even if they just say "make this better" or "this feels messy". Also trigger when the
  user pastes Python code and asks for feedback, a code review, or says something is
  getting hard to maintain. Always consult this skill before refactoring any Python code.
---

# Python Refactoring Skill

## Overview

Refactoring is restructuring existing code without changing its external behavior.
The goal is to improve readability, maintainability, and correctness — not to add features.

**Always follow this order:**
1. **Understand** what the code does before touching it
2. **Identify violations** using the detection checklists below
3. **Prioritize** — fix SRP first, then deduplication, then idioms, then types, then naming
4. **Annotate your reasoning** — briefly explain *why* each change was made
5. **Preserve behavior** — if logic changes are needed, call them out explicitly

---

## Pass 1 — Single Responsibility Principle (Always run this first)

SRP is the highest-leverage refactor. A function or class that does too many things
makes every other improvement harder.

### Detection Checklist

Run through these signals on every function, class, and module:

**Function-level signals**
- [ ] Longer than ~40 lines
- [ ] Contains comments like `# step 1`, `# step 2` or section dividers
- [ ] The name uses "and", e.g. `validate_and_save()`
- [ ] Named `process_*`, `handle_*`, `do_*` — vague verbs that hide multiple jobs
- [ ] Mixes I/O (DB calls, HTTP, file reads) with computation logic
- [ ] Has more than 4–5 parameters (suggests it's doing too many jobs)

**Class-level signals**
- [ ] Name contains "Manager", "Handler", "Helper", "Util", or "Service" doing 5+ things
- [ ] More than ~7 public methods
- [ ] Methods cluster into 2+ distinct themes (e.g., some touch `self.user`, others touch `self.report`)
- [ ] The same group of 3–4 args is passed across multiple methods (they belong in a sub-object)

**Module-level signals**
- [ ] Imports span 3+ unrelated domains (e.g., `smtplib`, `psycopg2`, `pandas` all in one file)
- [ ] Hard to describe the module's purpose in one sentence

### The Naming Test (do this before every extraction)

Before extracting anything, complete this sentence:
> *"This function/class is responsible for ___________."*

- If you **can't** complete it cleanly → the code has multiple responsibilities, extract
- If you **can** but the blank has "and" in it → extract
- If you **can** and it's a single clean phrase → leave it alone, even if it's long

### Fix Patterns

**Pattern A — Extract Function**
Use when: a block inside a function has a clear sub-purpose.

```python
# ❌ Before
def process_order(order):
    # validate
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Negative total")
    # apply discount
    if order.customer.is_vip:
        order.total *= 0.9
    # save
    db.session.add(order)
    db.session.commit()

# ✅ After
def validate_order(order):
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Negative total")

def apply_discount(order):
    if order.customer.is_vip:
        order.total *= 0.9

def save_order(order):
    db.session.add(order)
    db.session.commit()

def process_order(order):
    validate_order(order)
    apply_discount(order)
    save_order(order)
```

**Pattern B — Extract Class**
Use when: methods cluster around different subsets of state.

```python
# ❌ Before — UserService does auth AND reporting
class UserService:
    def authenticate(self, username, password): ...
    def reset_password(self, user): ...
    def generate_activity_report(self, user): ...
    def export_report_to_csv(self, report): ...

# ✅ After
class AuthService:
    def authenticate(self, username, password): ...
    def reset_password(self, user): ...

class UserReportService:
    def generate_activity_report(self, user): ...
    def export_to_csv(self, report): ...
```

**Pattern C — Separate I/O from Logic**
Use when: a function fetches data AND transforms it AND writes results.
This is the most common Django violation.

```python
# ❌ Before — untestable, tightly coupled
def sync_user_scores(user_ids):
    users = User.objects.filter(id__in=user_ids)  # I/O
    for user in users:
        score = sum(a.points for a in user.activities.all())  # logic + I/O
        user.score = score
        user.save()  # I/O

# ✅ After — pure logic is testable, I/O is isolated
def calculate_score(activities) -> int:
    return sum(a.points for a in activities)

def sync_user_scores(user_ids):
    users = User.objects.prefetch_related("activities").filter(id__in=user_ids)
    for user in users:
        user.score = calculate_score(user.activities.all())
        user.save()
```

**Pattern D — Extract Module**
Use when: a file mixes concerns that could stand alone.
Simply note the recommended split, e.g.:
- `utils.py` → split into `validators.py`, `formatters.py`, `converters.py`

### SRP Guardrails (read before extracting anything)

- **Don't split just because something is long.** A 40-line function doing one complex
  thing cohesively is fine. Length alone is not a reason to extract.
- **Don't create a function that's only called once and adds no semantic clarity.**
  `_do_step_one()` is not better than an inline comment.
- **Don't separate data from its natural operations.** A `User.full_name` property
  is not an SRP violation.
- **Name-driven extraction only.** If you can't give the extracted piece a clear,
  specific name, the split is probably wrong.

---

## Pass 2 — Deduplication / Extract Shared Logic

After SRP is clean within each file, look across files for duplicated code that
should live in a shared location.

### Detection Checklist

- [ ] Two or more functions with similar signatures doing the same job in different modules
- [ ] Copy-pasted blocks with only minor variations (different field names, URLs, or constants)
- [ ] Repeated error handling, retry logic, or data normalization patterns across modules
- [ ] Multiple classes implementing the same boilerplate (e.g., scrapers with identical setup/teardown)
- [ ] The same helper function defined independently in 2+ files

### Fix Patterns

**Pattern A — Extract Shared Utility**
Use when: identical or near-identical logic appears in multiple places.

```python
# ❌ Before — same date parsing in two modules
# in scrapers/cinema_a.py
def parse_showtime(raw: str) -> datetime:
    return datetime.strptime(raw.strip(), "%Y-%m-%d %H:%M")

# in scrapers/cinema_b.py
def parse_showtime(raw: str) -> datetime:
    return datetime.strptime(raw.strip(), "%Y-%m-%d %H:%M")

# ✅ After — shared utility
# in utils/parsing.py
def parse_showtime(raw: str) -> datetime:
    return datetime.strptime(raw.strip(), "%Y-%m-%d %H:%M")
```

**Pattern B — Parameterize the Differences**
Use when: blocks are mostly the same but vary in a few values.

```python
# ❌ Before — two functions that differ only in URL and field mapping
def fetch_cinema_a_showtimes():
    resp = requests.get("https://cinema-a.com/api")
    return [{"title": s["name"], "time": s["start"]} for s in resp.json()]

def fetch_cinema_b_showtimes():
    resp = requests.get("https://cinema-b.com/api")
    return [{"title": s["movie"], "time": s["showtime"]} for s in resp.json()]

# ✅ After — one function, differences passed as arguments
def fetch_showtimes(url: str, title_key: str, time_key: str) -> list[dict]:
    resp = requests.get(url)
    return [{"title": s[title_key], "time": s[time_key]} for s in resp.json()]
```

**Pattern C — Extract Base Class or Mixin**
Use when: multiple classes share the same boilerplate setup, teardown, or lifecycle.

```python
# ❌ Before — every scraper repeats session setup and error handling
class CinemaAScraper:
    def setup(self):
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": UA})

    def teardown(self):
        self.session.close()

class CinemaBScraper:
    def setup(self):
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": UA})

    def teardown(self):
        self.session.close()

# ✅ After — shared base
class BaseScraper:
    def setup(self):
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": UA})

    def teardown(self):
        self.session.close()

class CinemaAScraper(BaseScraper): ...
class CinemaBScraper(BaseScraper): ...
```

### Deduplication Guardrails

- **Don't merge things that are only superficially similar.** Two functions that
  look alike today but serve different domains may evolve independently. If they
  don't share a *reason to change*, they're not duplicates.
- **Don't create premature abstractions.** Two instances of similar code is a hint,
  not a mandate. If the "shared" version needs `if provider == "A"` branches, the
  cure is worse than the disease.
- **Proximity matters.** Duplication within the same module is a stronger signal than
  duplication across distant parts of the codebase.
- **Prefer composition over inheritance.** A shared utility function is usually better
  than a base class. Only use base classes when there's a genuine lifecycle to share.

---

## Pass 3 — Pythonic Idioms

Apply these after SRP is clean. They're mostly mechanical.

```python
# Comprehensions over manual append
users = [u for u in raw if u.is_active]           # ✅
d = {k: v for k, v in pairs}                      # ✅

# enumerate / zip
for i, item in enumerate(items):                   # ✅ not range(len(...))
for a, b in zip(list_a, list_b):                   # ✅

# Unpacking
first, *rest = items                               # ✅
x, y = point                                       # ✅ not point[0], point[1]

# any() / all()
if any(u.is_admin for u in users):                 # ✅ not manual flag loop

# f-strings
msg = f"Hello, {name}!"                            # ✅ not .format() or %

# defaultdict / Counter
from collections import defaultdict, Counter
counts = Counter(items)                            # ✅ not manual dict increment

# Generators for large sequences
total = sum(x.value for x in records)             # ✅ no intermediate list

# Context managers
with open(path) as f:                             # ✅ never bare open()
    data = f.read()
```

---

## Pass 4 — Type Hints

Add type hints to all function signatures. Use the modern syntax (Python 3.10+
where the codebase supports it).

```python
# ✅ Basic
def get_user(user_id: int) -> User | None: ...

# ✅ Collections
def process(items: list[str]) -> dict[str, int]: ...

# ✅ Optional (prefer X | None over Optional[X] in 3.10+)
def find(name: str) -> User | None: ...

# ✅ Callable
from collections.abc import Callable
def apply(fn: Callable[[int], str], value: int) -> str: ...

# ✅ TypedDict for dict-shaped data
from typing import TypedDict
class UserData(TypedDict):
    id: int
    name: str
    email: str

# ✅ dataclass for structured data
from dataclasses import dataclass
@dataclass
class Point:
    x: float
    y: float
```

**Rules:**
- Always type public function signatures
- Use `Any` only as a last resort — if you use it, add a comment explaining why
- Avoid `dict` and `list` without type params in signatures

---

## Pass 5 — Error Handling

```python
# ✅ Specific exceptions, not bare except
try:
    result = do_thing()
except ValueError as e:
    logger.warning("Invalid input: %s", e)
    raise

# ✅ Custom domain exceptions
class OrderNotFoundError(Exception): ...
class InsufficientInventoryError(Exception): ...

# ✅ Context managers for resources
with db.transaction():
    ...

# ❌ Never silently swallow
try:
    ...
except Exception:
    pass  # ← always wrong
```

---

## Pass 6 — Naming

| Context | Convention | Example |
|---|---|---|
| Variables / functions | `snake_case` | `get_active_users` |
| Classes | `PascalCase` | `OrderProcessor` |
| Constants | `UPPER_SNAKE` | `MAX_RETRIES = 3` |
| Booleans | predicate prefix | `is_active`, `has_permission` |
| Functions | verb phrases | `calculate_total`, not `total` |
| Private | single underscore | `_validate_input` |

**Rename triggers:**
- Single-letter names outside tight loops (`n`, `x`, `d` → give them meaning)
- `data`, `info`, `stuff`, `temp` → always rename to something specific
- `flag`, `result`, `output` → usually deserve a more descriptive name

---

## Pass 7 — Testing-Friendliness

Flag these patterns — they make code hard to test:

```python
# ❌ Hidden I/O inside pure logic
def calculate_discount(user_id):
    user = User.objects.get(id=user_id)  # DB call hidden in logic
    return 0.1 if user.is_vip else 0

# ✅ Inject the dependency
def calculate_discount(user: User) -> float:
    return 0.1 if user.is_vip else 0.0

# ❌ Hardcoded datetime
def is_expired(created_at):
    return (datetime.now() - created_at).days > 30

# ✅ Injectable clock
def is_expired(created_at, now=None):
    now = now or datetime.now()
    return (now - created_at).days > 30
```

---

## Output Format

When refactoring code, always produce:

1. **Violations found** — a brief list of what you detected before the code
2. **Refactored code** — the full rewritten version
3. **Change log** — a short explanation of each meaningful change and *why*

If the code is large (>100 lines), ask the user if they want:
- (A) Full rewrite
- (B) Prioritized list of changes to make themselves
- (C) One pass at a time (SRP first, then idioms, etc.)

---

## Reference Files

- `references/srp-patterns.md` — Extended SRP examples including Django-specific patterns
- `references/type-hints-cheatsheet.md` — Quick reference for complex typing scenarios

Read these when the main SKILL.md patterns don't cover the specific case at hand.
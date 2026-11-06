# Assignment 2d: Type Checking with Overloading for LITHP

## Overview

This assignment extends the LITHP parser (assignment 2c) with a **weak type checker**.
LITHP is weakly typed: expressions may have more than one valid type, and the context
decides. The checker infers and validates types for all constructs including arithmetic,
list operations, booleans, `cond`, `lambda`, `label`, `defun`, and compound `c[ad]+r`
functions.

---

## Type System

### Base Types

| Type | Meaning |
|---|---|
| `TInt` | Integer (bigint) |
| `TBool` | Boolean |
| `TNil` | The empty value `()` — unifies with both `TBool` and any `TList` |
| `TList n` | A list of exactly `n` elements |
| `TFun(params, ret)` | Function type |
| `TVar s` | Type variable (used for polymorphism) |

### Design Decision: TNil and `()` as Dual-Type

The spec says `()` has **two** types: `Bool` and `List(0)`. Rather than picking one and
losing the other, a dedicated `TNil` type is introduced. The output of the type checker
prints this as `Nil`. Unification rules make `TNil` compatible with both:

- `TNil` ~ `TBool` — so `()` acts as boolean false in `cond` conditions, `and`, `or`, `not`
- `TNil` ~ `TList n` for **any** `n` — more permissive than the strict spec reading of `List(0)` only

The second rule is a deliberate design choice toward weaker typing: it means
`(cond (t ()) (t '(1 2 3)))` unifies `TNil` with `TList 3` and succeeds. A stricter
reading would fail this because `List(0) ≠ List(3)`.

- `TList 0` ~ `TList n` for any `n` — an empty list produced by `cdr` is compatible with
  any list length for unification.

**Important asymmetry:** `TNil` (from the literal `()`) is Bool-compatible, but `TList 0`
(produced by `cdr` of a one-element list) is **not**. So `(cond (() 1) (t 2))` works, but
`(cond ((cdr '(1)) 1) (t 2))` gives `TypeError: List(0) vs Bool`. This is because `TNil`
and `TList 0` are distinct types in the checker even though both represent "empty".

### Design Decision: TList Tracks Exact Length

Lists carry their length in their type: `TList 3` is a list with exactly 3 elements.
This allows `car` and `cdr` to enforce that they are not applied to empty lists at
type-check time, and allows `cons` to compute a precise result type.

`cons e lst` — if `lst : TList n`, returns `TList (n+1)`.
`cdr lst`    — if `lst : TList n` (n > 0), returns `TList (n-1)`.
`car lst`    — if `lst : TList n` (n > 0), returns `TVar "a"` (element type is unknown).

Applying `car` or `cdr` to an empty list (`TList 0` or `TNil`) is a type error.

### Design Decision: Variadic + and *

`+` and `*` are typed as `TFun([], TInt)` — the empty param list is a sentinel meaning
"variadic, at least 2 Int arguments". All other arithmetic operators (`-`, `div`, `mod`)
are strictly binary and typed `TFun([TInt; TInt], TInt)`.

### Design Decision: eq Enforces Same-Type Only for Concrete Arguments

`eq` is handled as a special case that infers both argument types and then checks them
for compatibility — **but only when both sides resolve to concrete (non-`TVar`) types**.
If either side is still an unresolved type variable, the check is skipped and `TBool` is
returned.

**Reason:** A naive `unify t1 t2` in `eq` causes an incorrect failure in expressions like
`(defun f (x y) (+ x (cond ((eq x t) 10) (t 20))))`. The variadic `+` operator evaluates
all argument types via `List.map` **before** running its own unification pass. This means
`(eq x t)` is evaluated while `x` is still the fresh type variable `TVar "x"`, before `+`
has had a chance to constrain it to `Int`. A full `unify` would bind `TVar "x" → TBool`,
and then `+`'s pass would fail with `Bool vs Int`. Skipping unification when either side is
a `TVar` avoids this: `(eq x t)` leaves `x` unconstrained, `+` then binds `x → Int`, and
the whole expression types cleanly as `(Int * 'y → Int)`.

**Concrete mismatches are still caught:** `(eq '(1 2) 3)` fails with
`TypeError: Type mismatch: List(2) vs Int` because both sides are concrete.

### Design Decision: Polymorphism via TVar

Operators like `car`, `cons`, `atom`, `quote`, and `eq` are polymorphic. They use
`TVar "a"` as a type variable. Type variables unify with any concrete type on first
use. The `tvar_env` association list records these bindings and is cleared before each
top-level expression so that type variables do not leak between unrelated expressions.

### Design Decision: cond Branches Must All Have the Same Type

`cond` requires each **condition** to be of type `TBool` (or `TNil`, which unifies with
`TBool`), and all **result branches** are unified with each other — they must return the
same type. The spec flags this as an explicit design choice (stronger vs weaker); this
implementation takes the stronger position.

**Effect:**
- `(cond ((= 1 1) 1) (t t))` → `TypeError: Type mismatch: Int vs Bool` (branches differ)
- `(cond ((= 1 1) '(1 2)) (t 3))` → `TypeError: Type mismatch: List(2) vs Int`
- The "final boss" `(cond ((atom x) x) ((= (car x) 0) (cdr x)) (t (cons ...)))` →
  `TypeError: Type mismatch: List(3) vs List(2)` because `cdr x` shortens the list

**Conditions still must be Bool-compatible:** `(cond (1 2))` fails because
`1 : Int` does not unify with `TBool`.

### Design Decision: defun Bindings Persist

`defun` adds the function's type to `global_env`, a mutable reference that persists
across all top-level expressions in the input. This means a function defined with
`defun` earlier in the file is visible to all subsequent expressions, matching LISP
semantics. `label` introduces a local self-binding only for the duration of the
recursive function body.

### Design Decision: Compound c[ad]+r Functions

The `cadr`, `caddr`, `cddr`, etc. family of functions is recognised dynamically by
checking that an identifier matches the pattern `c[ad]+r`. The required minimum list
length is computed from the `d`-count in the name: a trailing sequence of `d`s means
cdr-calls, and the `a` suffix means one final car-call. This avoids hardcoding every
combination while still performing a meaningful length check at type-check time.

---

## Parser Change

### Empty List: `L []` Instead of `A Nil`

In assignment 2c, `()` was parsed as `A Nil` (the Nil atom). In this assignment, the
grammar rule for an empty parenthesised list was changed to produce `L []` (an empty
expression list):

```
// Before (2c):
LEFTPAREN RIGHTPAREN { A Nil }

// After (2d):
LEFTPAREN RIGHTPAREN { L [] }
```

**Why:** The type checker distinguishes between an empty list (structural, a value with
`TList 0` / `TNil`) and the atom `Nil`. Representing `()` as `L []` lets the checker
match it against the `typ_of_list` path (`[] -> TNil`) without a special-cased atom
branch. It also makes the AST more uniform: all parenthesised forms — including empty
ones — are `L` nodes.

**Impact on the lexer:** The lexer no longer needs a `NIL` token for `()`. The `NIL`
token and `|"()" {NIL}` rule remain commented out. The empty list is composed from two
existing tokens (`LEFTPAREN`, `RIGHTPAREN`) without any new token.

**Impact on the grammar:** The `NIL { A Nil }` arm in `term` is also commented out.
The atom `Nil` still exists in the AST type definition but is **never produced by parsing**
after this change — it is dead code. In particular, the `| A Nil -> TNil` branch inside
`typ_of_quoted` in the type checker is unreachable: `'()` parses as
`L [A (Id "quote"); L []]`, so `typ_of_quoted` receives `L []`, not `A Nil`.

---

## Operator Type Summary

| Operator | Argument types | Return type | Notes |
|---|---|---|---|
| `+`, `*` | ≥2 Int | Int | Variadic |
| `-`, `div`, `mod` | Int × Int | Int | Binary |
| `=`, `=/=`, `<`, `>`, `<=`, `>=` | Int × Int | Bool | |
| `eq` | α × α | Bool | Concrete same-type check; TVar-side skips |
| `atom` | α | Bool | Any argument |
| `not` | Bool | Bool | |
| `and`, `or` | Bool × Bool | Bool | |
| `car` | List(n), n>0 | α | Element type unknown |
| `cdr` | List(n), n>0 | List(n-1) | |
| `cons` | α × List(n) | List(n+1) | |
| `c[ad]+r` | List(n), n≥required | α | Dynamic arity check |
| `quote` | α | α | Identity on type |
| `cond` | clauses | α | All branches same type |
| `lambda` | — | Fun(params→ret) | Inferred from body |
| `label` | — | Fun type | Recursive self-binding |
| `defun` | — | Fun type | Persists in global env |

---

## File Roles

| File | Role |
|---|---|
| `ast.ml` | AST types: `atom`, `exp` |
| `lexer.mll` | Lexical analyser |
| `parser.mly` | Grammar and parse actions (modified for `L []`) |
| `type_cheker.ml` | Type checker: type definitions, unification, inference |
| `main.ml` | Entry point: parse then type-check and print each top-level expression |
| `Bigint.ml` | Bigint arithmetic for numeric literals |
| `Makefile` | Build and run commands |

---

## Build and Run

```bash
make           # compile everything
make run       # run on input.lisp
make run INPUT=your_file.lisp
make run-stdin # interactive stdin
make clean     # remove compiled artefacts
```

Each top-level expression is printed together with its inferred type:

```
(+ 1 2 3) : Int
(cons 1 ()) : List(1)
(eq t ())   : Bool
(eq '(1 2) 3) : TypeError: Type mismatch: List(2) vs Int
```

Type errors are caught per-expression and printed without stopping evaluation of the
remaining expressions.

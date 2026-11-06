# Assignment 3 – Lambda Calculi Interpreters

## Kashvi Khurana - 2024CS10559

Two abstract machines for toy functional languages based on **call-by-name** (Krivine) and **call-by-value** (SECD) lambda calculi. Each machine is implemented twice — once with tables as association lists, once with tables as functions — giving four implementations total.

---

## Files

| File               | Machine                 | Table implementation    |
| ------------------ | ----------------------- | ----------------------- |
| `krivine.ml`       | Krivine (call-by-name)  | `(string * clos) list`  |
| `krivine2.ml`      | Krivine (call-by-name)  | `string -> clos`        |
| `secd.ml`          | SECD (call-by-value)    | `(string * value) list` |
| `secd2.ml`         | SECD (call-by-value)    | `string -> value`       |
| `test_krivine.ml`  | Tests for `krivine.ml`  |                         |
| `test_krivine2.ml` | Tests for `krivine2.ml` |                         |
| `test_secd.ml`     | Tests for `secd.ml`     |                         |
| `test_secd2.ml`    | Tests for `secd2.ml`    |                         |

---

## Expression Language

All four files share the same `exp` type, which extends pure lambda calculus with built-in integers, booleans, arithmetic, comparisons, and conditionals (extra credit):

```ocaml
type exp =
  | V    of string                          (* variable *)
  | Abs  of string * exp                    (* \x. e   *)
  | App  of exp * exp                       (* e1 e2   *)
  | Int  of int   | Bool  of bool           (* literals *)
  | Add  of exp * exp | Mult of exp * exp
  | And  of exp * exp | Or   of exp * exp | Not of exp
  | Eq   of exp * exp | Lt   of exp * exp | Gt  of exp * exp
  | If   of exp * exp * exp
  | Pair of exp * exp | Fst of exp | Snd of exp
  | Let  of defs * exp
and defs =
  | Def of string * exp
  | Seq of defs * defs
  | Par of defs * defs
```

**Design decision:** Rather than encoding integers and booleans as Church terms (which is pedagogically correct for pure lambda calculus but produces unreadable results for numeric computations), built-in types are provided as an extension. This makes the language practically usable and lets the test suite verify concrete numeric/boolean results.

---

## Pairs and Local Definitions

### Pairs

Native pairs are supported as:

```ocaml
Pair (e1, e2)
Fst e
Snd e
```

### Local definitions

Definitions follow the abstract syntax in the handout:

```ocaml
Let (defs, body)

defs ::= Def(x, e)
  | Seq(d1, d2)   (* d1 ; d2 *)
  | Par(d1, d2)   (* d1 || d2 *)
```

Semantics:

- `Seq(d1, d2)` is sequential: `d2` is evaluated in the environment extended by `d1`.
- `Par(d1, d2)` is parallel: both sides are evaluated in the original environment and then added together.

---

## Part 1 – Krivine Machine (Call-by-Name)

### How it works

The Krivine machine is a state machine with a **focus** (the current closure being reduced) and a **stack** (closures awaiting application). It implements call-by-name: arguments are passed unevaluated (as closures), and only evaluated if/when they are actually used.

### Transition rules

```
(Op)   <<(e1 e2), γ>>,  S         =>  <<e1, γ>>,  <<e2, γ>> :: S
(Var)  <<x, γ>>,        S         =>  γ(x),        S
(App)  <<\x.e1, γ>>,    cl :: S   =>  <<e1, γ[x↦cl]>>,  S
```

- **(Op)**: An application decomposes: focus shifts to the function; the argument closure is pushed onto the stack.
- **(Var)**: A variable is looked up in the environment; the result (a closure) becomes the new focus.
- **(App)**: A lambda under a non-empty stack consumes the top of the stack as its argument; the environment is extended.

Reduction terminates when the focus is a lambda with an empty stack (weak head normal form), or a primitive value (`CInt`/`CBool`) with an empty stack.

### Closures

```ocaml
type clos =
  | CExp  of exp * table   (* a suspended lambda term paired with its environment *)
  | CInt  of int
  | CBool of bool
```

**Design decision:** Primitive values `Int n` and `Bool b` are immediately lifted to `CInt n` / `CBool b` (see the `close` helper). This avoids wrapping them in `CExp` unnecessarily and simplifies the machine rules: a primitive value with a non-empty stack is definitively stuck rather than requiring a lookup step.

### Table implementations

**krivine.ml** – `table = (string * clos) list`

Lookup: `List.assoc x env`. Extension: prepend `(x, cl)` to the list (shadowing any prior binding for `x`). Simple and transparent; linear-time lookup.

**krivine2.ml** – `table = string -> clos`

```ocaml
let empty_table : table = fun _ -> raise Not_found
let augment_table x cl env = fun y -> if y = x then cl else env y
let negative_augment_table x env = fun y -> if y = x then raise Not_found else env y
```

Lookup: call `env x`, catching `Not_found`. Extension: build a new closure over the old environment. The `negative_augment_table` is used during `unpack` to shadow a lambda's bound variable (so it appears free in the unpacked result rather than being looked up in the outer environment).

**Comparison:** The function representation (krivine2.ml) avoids list traversal and is more compositional; the list representation (krivine.ml) is easier to inspect and print for debugging.

### The `unpack` function

`unpack : clos -> exp` reconstructs a readable lambda term from a closure by substituting the environment into the expression. This is required to display the result in a meaningful way.

Key cases:

- `unpack (CExp (V x, env))` — tries to resolve `x` in `env`; if absent (free variable), returns `V x`.
- `unpack (CExp (Abs (x, e), env))` — removes `x` from `env` first (the bound variable shadows the outer environment), then recursively unpacks the body.
- `unpack (CExp (App (e1, e2), env))` — recursively unpacks both sides.

**Design decision:** `unpack` recurses structurally rather than running the machine further. This means it can handle partial results (unapplied lambdas) and is safe to call on any closure, including stuck ones.

### Entry point

```ocaml
val call_by_name : exp -> exp
(* Runs the Krivine machine on a closed expression and unpacks the result. *)
```

---

## Part 2 – SECD Machine (Call-by-Value)

### How it works

The SECD machine evaluates using a four-component state: **S**tack, **E**nvironment, **C**ode (opcode list), **D**ump. It implements call-by-value: arguments are fully evaluated to values before a function is applied.

### Machine components

- **S** – stack of `value`s (evaluated results awaiting use)
- **E** (γ) – environment mapping variable names to values
- **C** – list of opcodes (the remaining program to execute)
- **D** – dump: a list of `(S, E, C)` triples, one saved per pending function call (return contexts)

### Opcodes

```ocaml
type opcode =
  | LOOKUP of string                (* push γ(x) onto S *)
  | MKCLOS of string * opcode list  (* push closure <<x, c, γ>> onto S *)
  | APP                             (* apply: pop argument and closure, call function *)
  | RET                             (* return: restore saved (S, E, C) from D *)
  | LDN    of int                   (* push integer literal *)
  | LDB    of bool                  (* push boolean literal *)
  | PAIR | FST | SND
  | ADD | MULT | AND | OR | NOT | EQ | LT | GT
  | IFTE   of opcode list * opcode list
  | LET    of defs * opcode list
```

**Design decision:** `LDN`/`LDB` opcodes for literals are added beyond the assignment's minimal set to support the extended language. `IFTE` takes both branches as embedded opcode lists to avoid a separate jump mechanism.

### Compiler

```
compile x        = [LOOKUP x]
compile (e1 e2)  = compile e1 @ compile e2 @ [APP]
compile (\x.e)   = [MKCLOS(x, compile e @ [RET])]
compile (Int n)  = [LDN n]
compile (Bool b) = [LDB b]
compile (e1+e2)  = compile e1 @ compile e2 @ [ADD]
... (similar for all binary operators)
compile (if e1 e2 e3) = compile e1 @ [IFTE(compile e2, compile e3)]
```

### Transition rules

```
(Var)   s,              γ,  LOOKUP(x)::c,      d  =>  γ(x)::s,         γ,          c,   d
(Clos)  s,              γ,  MKCLOS(x,c1)::c,   d  =>  <<x,c1,γ>>::s,   γ,          c,   d
(App)   v::(<<x,c1,γ1>>)::s, γ, APP::c,         d  =>  [],  γ1[x↦v],  c1, (s,γ,c)::d
(Ret)   v::s',          γ', RET::_,  (s,γ,c)::d   =>  v::s, γ,         c,   d
```

### Stack ordering and LT/GT

`compile (e1 e2)` emits `compile e1` then `compile e2`, so at runtime the result of `e1` is pushed first and the result of `e2` lands on top. When the binary-op instruction executes, the pattern `v1 :: v2 :: s'` sees `v1 = result(e2)` and `v2 = result(e1)`.

For commutative operations (ADD, MULT, AND, OR, EQ) this makes no difference. But for **LT** and **GT** the operands must be ordered correctly:

```ocaml
(* compile (Lt(e1,e2)):  stack before LT is  [result_e2 ; result_e1 ; ...]
                         v1 = result_e2,  v2 = result_e1
   We want e1 < e2, i.e. v2 < v1  -->  n2 < n1  *)
| (VInt n1, VInt n2) -> stkmc (VBool (n2 < n1) :: s') e c'' d
```

Both `secd.ml` and `secd2.ml` correctly apply this reversal.

### Value closures

```ocaml
type value =
  | VClos of string * opcode list * table   (* <<x, c, γ>> *)
  | VInt  of int
  | VBool of bool
  | VPair of value * value
```

**Design decision:** Values are a separate type from expressions. This enforces the distinction between compile-time syntax and run-time values and prevents accidentally passing an unevaluated expression where a value is expected.

### Table implementations

**secd.ml** – `table = (string * value) list`

Extension: `(x, arg) :: e'`. Lookup: `List.assoc x env`.

**secd2.ml** – `table = string -> value`

```ocaml
let empty_table : table = fun _ -> raise Not_found
let augment_table x cl env = fun y -> if y = x then cl else env y
```

Extension: `augment_table x arg e'`. Lookup: `env x`.

### Entry point

```ocaml
val run : exp -> value
(* Compiles exp to opcodes and runs the SECD machine from the initial state. *)
```

---

## Running the tests

All test files use `#use` to load the corresponding implementation. Run each from the project directory:

```bash
ocaml test_krivine.ml     # 45 tests — krivine.ml  (list table)
ocaml test_krivine2.ml    # 45 tests — krivine2.ml (function table)
ocaml test_secd.ml        # 44 tests — secd.ml     (list table)
ocaml test_secd2.ml       # 44 tests — secd2.ml    (function table)
```

All tests pass (0 failures) for all four implementations. Each test line prints the actual result value:

```
PASS: identity  (\x.x) 5                              =>  5
PASS: CBN laziness  (\x.1)(\y.y y)                    =>  1
PASS: closure capture  (\x.(\f.f 4)(\y.x+y)) 3        =>  7
```

### Test coverage

| Category                                             | What is tested                                                  |
| ---------------------------------------------------- | --------------------------------------------------------------- |
| Identity, K, S combinators                           | Basic beta-reduction, multi-arg application, nested application |
| Church pairs `fst(pair 3 5)=3`                       | Higher-order functions; closures carry data                     |
| Church booleans `cond tru 1 2 = 1`                   | Lambdas as booleans                                             |
| Church NOT                                           | Church-encoded negation                                         |
| Built-in pairs `Fst/Snd` — flat and nested           | Native pair values; nested pair stays as pair                   |
| Arithmetic `3+4`, `3*4`, `2*3+1`                     | Built-in integers; operator nesting                             |
| Comparisons `Lt`, `Gt`, `Eq` — both sides            | Strict ordering tests; boundary (equal) cases                   |
| Boolean logic `And`, `Or`, `Not` — both truth values | All short-circuit combinations                                  |
| Built-in `If` — literal and computed condition       | Mixed expression evaluation                                     |
| Let `Def`, `Seq`, `Par`, nested Let                  | Sequential vs. parallel scoping; inner let sees outer           |
| Curried addition `(\x.\y.x+y) 3 4`                   | Variables captured in body                                      |
| Function composition `(inc ∘ dbl) 3 = 7`             | Closures holding other closures                                 |
| `flip` combinator                                    | Argument-order reversal via higher-order function               |
| Closure environment capture (SECD)                   | `(\x. (\f.f 4) (\y.x+y)) 3 = 7`                                 |
| Call-by-name laziness (Krivine)                      | `(\x.1)(\y.y y) = 1` — diverging arg never evaluated            |
| Call-by-name: unused arg is unevaluated (Krivine)    | `(\x.\y.y)(3+4) = \y.y`                                         |
| Call-by-value eagerness (SECD)                       | `(\x.1)(3+4) = 1` — arg evaluated even if unused                |
| CBV: arg with arithmetic `(\x.x*x)(2+3) = 25`        | Argument fully reduced before call                              |
| Unpack sanity (Krivine)                              | `\x.x+1` unpacks back to correct `Abs` term                     |
| Closure representation (SECD)                        | `run (\z.z+1)` returns `VClos("z",_,_)`                         |

---

## Extra Credit – Extended Data Types

The pure lambda calculus is extended with:

- **Integers** (`Int n`): literal integers, `Add`, `Mult`, `Eq`, `Lt`, `Gt`
- **Booleans** (`Bool b`): literal booleans, `And`, `Or`, `Not`
- **Conditional** (`If e1 e2 e3`): standard if-then-else

These constructs can be treated as syntactic sugar over Church encodings but are implemented as primitives for efficiency and readability. The `unpack` function (Krivine) and the `value` type (SECD) handle them natively.

# Assignment 1: Expressions, Substitution, Predicates

A parametric OCaml module system implementation for logic expressions, substitutions, and predicates.

## Overview

This project implements a modular system for working with:
- **Expressions**: Tree structures with variables and function symbols
- **Substitutions**: Variable-to-expression mappings
- **Predicates**: Logical formulas over expressions

## How to Use
### Compile
```bash
ocamlc -o main mail.ml
```
### Run
```bash
./main
```

## Module Structure

### Core Module Types

```ocaml
VAR - Variable representation with equality
SYM - Symbol representation with arity, equality, and comparison
EXP - Expression operations (parametric over VAR and SYM)
```

### Main Components

1. **`MakeExp(VAR)(SYM)`** - Functor that creates expression module
2. **`Pred(EXP)`** - Functor that creates predicate module over expressions

## Example Instantiation

```ocaml
  
module VarStr = struct
  type t = string
  let equal = String.equal
end
module SymStr = struct
  type t = string * int
  let arity (_, a) = a (* Extract arity from the tuple *)
  let equal = (=)
end
module E = MakeExp(VarStr)(SymStr)
module P = Pred(E)
```

## Expression Module Features

### Data Types

```ocaml
type exp = 
  | V of variable 
  | Node of symbol * (exp array) 

type sign = symbol array (* Signature *)
type substitution = (variable * exp) list
type position = int list (* Path from root *)
```

### Key Functions

- **`check_sig : sign -> bool`**  
  Validates signature (no duplicates, non-negative arities)

- **`wfexp : sign -> exp -> bool`**  
  Checks if expression is well-formed under given signature (checks against arities and is recursive)

- **`ht : exp -> int`**  
  Returns height of expression tree

- **`size : exp -> int`**  
  Returns total number of nodes

- **`vars : exp -> variable array`**  
  Returns array of all variables in expression (without duplicates)

- **`subst : substitution -> exp -> exp`**  
  Applies substitution functionally (creates new expression) by applying recursion and looking up variables in the substitution list

- **`compose : substitution -> substitution -> substitution`**  
  Composes two substitutions (g ∘ f) by first directly applying g on f, then appending mappings from g that are not already mapped in the composition

- **`edit : position -> exp -> exp -> exp`**  
  Replaces subexpression at given position

- **`in_place : substitution -> exp -> unit`**  
  Applies substitution destructively (modifies array children in-place, returns unit)



## Predicate Module Features

### Data Types

```ocaml
type pred_symbol = string * int

type pred =
  | T 
  | F
  | Pred of pred_symbol * (exp array)
  | Not of pred
  | And of pred * pred
  | Or of pred * pred
```

### Key Functions

- **`wff : pred -> pred_sign -> sign -> bool`**  
  Checks if predicate is well-formed

- **`psubst : pred -> substitution -> pred`**  
  Applies substitution to all expressions in predicate

- **`wp : variable -> exp -> pred -> pred`**  
  Substitutes expression for variable

## Usage Examples

### Creating Expressions

```ocaml
(*Variable: x *)
let x = E.V "x"

(*Function: f(x, y), f has arity 2 *)
let f_sym = ("f", 2)
let fx = E.Node(f_sym, [|E.V "x"; E.V "y"|])

(*constant: c (arity 0)*)
let c = E.Node(("c", 0), [||])

(* Substitution: {x-> f(y), y-> c} *)
let sub = [("x", E.Node(("f", 1), [|E.V "y"|])); 
           ("y", E.Node(("c", 0), [||]))]

(* Apply substitution *)
let result = E.subst sub (E.V "x")
(* Result: f(y) *)

(*compose substitutions *)
let sub1 = [("x", E.V "y")]
let sub2 = [("y", E.V "z")]
let composed = E.compose sub1 sub2
(* Result: {x-> z} *)

module P = Pred(E)

(* predicate: P(x,f(y)) *)
let p_sym = ("P", 2)
let pred1 = P.Pred(p_sym, [|E.V "x"; E.Node(("f", 1), [|E.V "y"|])|])

(* Logical formula: P(x)∧¬Q(y)*)
let formula = P.And(
  P.Pred(("P", 1), [|E.V "x"|]),
  P.Not(P.Pred(("Q", 1), [|E.V "y"|]))
)

(* Define signature *)
let sig_exp = [|("f", 2); ("g", 1); ("c", 0)|]
let sig_pred = [|("P", 2); ("Q", 1)|]

(* check if signature is valid *)
let valid = E.check_sig sig_exp  (*true*)

(* check if expression is well formed *)
let e = E.Node(("f", 2), [|E.V "x"; E.Node(("c", 0), [||])|])
let wf = E.wfexp sig_exp e  (*true*)

(* Check if predicate is well formed *)
let wf_pred = P.wff pred1 sig_pred sig_exp  (*true *)
```

## Design Decisions

This section summarises the key design choices made while implementing the assignment tasks, the rationale behind them, and notes about trade-offs and future improvements.

### Type Choices

- **Variables**: Represented as abstract type `variable = VA.t` via the `VAR` module signature This allows flexibility.

- **Symbols**: Represented as abstract type `symbol = S.t` via the `SYM` module signature.

- **Substitutions**: Represented as association lists `substitution = (variable * exp) list`. This mirrors the mathematical specification (partial function from variables to expressions) and keeps the implementation simple.

### Data Structures

- **Signature**: Array of symbols (`sign = symbol array`). `check_sig` validates by:
  1. Creating a sorted copy using `Array.sort S.compare`
  2. Checking adjacent pairs for duplicates (O(n log n) sort + O(n) scan)
  3. Checking all arities are non-negative

- **Expressions**: The type `exp = V of variable | Node of symbol * (exp array)`. Children stored in arrays (not lists) to enable:
  - O(1) indexing for tree navigation
  - Efficient destructive updates in `in_place` via array mutation
  - Concise traversals using `Array.map`, `Array.fold_left`, etc.

- **Positions**: An `int list` representing a path from the root (e.g., `[0; 3]` means "first child, third child", this is zero indexed). Simple to implement; `edit` recursively descends and reconstructs the tree.

### Algorithm Design

- **Substitution application** (`subst`): Homomorphic extension — if expression is a variable, look it up in the substitution (using linear search in `sub_helper`); if a `Node`, recursively apply to children via `Array.map`. This naturally handles variable capture because substitutions target only the specified variables.

- **Composition of substitutions** (`compose f g`): Implements g ∘ f (apply f first, then g):
  1. For each `(var, exp)` in f, compute `(var, subst g exp)` and keep it if the result is not `x->x` (redundant mapping)
  2. Append bindings from g that don't appear in f (variables only in g's domain)
  
  Complexity: O(|f| × (|g| + cost of subst) + |g|) due to the subst calls and list searches.

- **In-place substitution** (`in_place`): Destructively mutates the `exp array` children of a `Node`. Only replaces top-level `V` variables; recursively calls itself for nested `Node`s. This mutates the expression if it is named and defined. Raises `failwith` if the root is a single variable (no parent to hold the modified structure). **Returns `unit`.**

- **Edit** (`edit position exp new_exp`): Descends the tree following the position list and reconstructs edits the arrays of nodes using `Array.mapi`. Each step reconstructs a new array (immutable update), and recusrively builds back the structure. Fails if the position is invalid or points beyond the structure.

### Predicate Module

- **Predicate symbols**: Represented as `string * int` (name and arity).

- **Well formedness** (`wff`): Recursively checks that:
  - `T` and `F` are always well-formed
  - Logical connectives (`Not`, `And`, `Or`) are well formed if their subpredicates are
  - `Pred(p, a)` is well formed if the predicate symbol `p` has arity equal to `Array.length a` (looked up in the predicate signature) and all expressions in `a` are well-formed under the expression signature

- **Substitution in predicates** (`psubst`): Recursively applies the expression substitution to all expression arrays in `Pred` nodes via `Array.map (E.subst s)`.

- **Weakest precondition style replacement** (`wp x e p`): Substitutes a specific variable `x` with expression `e` everywhere in the predicate by constructing a singleton substitution list `[(x, e)]` and applying `E.subst` to all expressions. This is a convenience; mathematically it is a special case of `psubst`.


### Assumptions

- **Small signatures and substitutions**: Linear scans are used for lookups.

- **Error handling**: Basic exceptions via `failwith`.

- **In-place mutation**: Users should be aware that the function is changeed for all future uses. Also fails on the expression being just a single variable (no parent to hold the modified structure) since it cannot be mutated in place.

- **Position validation**: `edit` with an invalid position raises an exception. 

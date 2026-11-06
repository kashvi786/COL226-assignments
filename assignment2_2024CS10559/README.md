# Assignment 2a: A Bigint Package (Modules/Abstract Data Type)

An OCaml module implementing arithmetic on arbitrarily large integers, using lists of digits to represent an integer.

## Overview

This project implements a `BIGNUM` module with arithmetic, comparison, and utility operations on arbitrarily large integers.

## How to Use

### Compile

```bash
ocamlc -o main main.ml
```

### Run

```bash
./main
```

## Representational Invariant

```ocaml
type bigint = sign * int list
and sign = Neg | NonNeg
```

- Each element of the `int list` is a single decimal digit in **[0, 9]**.
- Digits are stored **most significant digit first** (e.g., 42 → `[4; 2]`).
- There are **no unnecessary leading zeros**; zero is always `(NonNeg, [0])`.
- `(Neg, [0])` (negative zero) is never produced by any operation.

## Module Structure

### Module Type

```ocaml
BIGNUM - Abstract interface for arbitrary-precision integers
```

### Main Component

```
BigInt : BIGNUM  - Concrete implementation of the BIGNUM signature
```

## Operations

### Arithmetic

- **`add : bigint -> bigint -> bigint`** — Addition
- **`subtract : bigint -> bigint -> bigint`** — Subtraction
- **`multiply : bigint -> bigint -> bigint`** — Multiplication
- **`quotient : bigint -> bigint -> bigint`** — Integer division; raises `DivisionByZero` if divisor is zero
- **`remainder : bigint -> bigint -> bigint`** — Remainder, defined as `a - (a/b)*b`; raises `DivisionByZero` if divisor is zero
- **`unary_negation : bigint -> bigint`** — Negation; `-0` remains `0`
- **`abs : bigint -> bigint`** — Absolute value

### Comparison

All comparison functions return `myBool` (`T` or `F`).

- **`greater_than : bigint -> bigint -> myBool`**
- **`equal : bigint -> bigint -> myBool`**
- **`less_than : bigint -> bigint -> myBool`**
- **`great_or_equal : bigint -> bigint -> myBool`**
- **`less_or_equal : bigint -> bigint -> myBool`**

### Conversion and Display

- **`int_to_bigint : int -> bigint`** — Convert an OCaml `int` to `bigint`
- **`pretty_print : bigint -> string`** — Return a decimal string, prefixed with `-` if negative

## Implementation Notes

- **`strip`** removes leading zeros after every operation to uphold the representational invariant.
- **`add_helper`** takes LSB-first (reversed) inputs and builds the result MSB-first by prepending each computed digit. `add_pos` reverses both inputs before calling it.
- **`sub`** / **`sub_helper`** expect LSB-first inputs. Results come out MSB-first.
- **`subtract`** dispatches on the signs of both operands: same-sign cases delegate to `sub` after reversing; mixed-sign cases delegate to `add_pos`.
- **`add`** handles same-sign cases directly via `add_pos`, and delegates mixed-sign cases to `subtract`.
- **`mult_helper`** multiplies a digit list (LSB-first) by a single digit with carry. **`mult`** iterates over the digits of `y` MSD-first, shifting the running partial result left (prepending a `0`) on each step — standard long multiplication.
- **`quotient_helper`** implements long division: pulls one digit at a time into a running current value, counts how many times the divisor fits via repeated subtraction, and records each quotient digit. Each digit stays in `[0, 9]` because the remainder is always less than the divisor.
- **`remainder`** is derived as `a - (quotient a b) * b`.
- **`int_to_bigint`** builds the digit list by repeated `mod 10` / `div 10`; `strip` removes the sentinel `[0]` that the recursion base case appends.

## Use Case

```ocaml
let () =
  let open BigInt in
  let print_res op a b res =
    Printf.printf "%s %s %s = %s\n" (pretty_print a) op (pretty_print b) (pretty_print res)
  in
  let b1 = int_to_bigint 100 in
  let b2 = int_to_bigint 33 in
  (* Addition *)
  print_res "+" b1 b2 (add b1 b2);
  (* Subtraction *)
  print_res "-" b1 b2 (subtract b1 b2);
  (* Multiplication *)
  print_res "*" b1 b2 (multiply b1 b2);
  (* Quotient *)
  print_res "/" b1 b2 (quotient b1 b2);
  (* Remainder *)
  print_res "%" b1 b2 (remainder b1 b2)
;;
```

## Exception

```ocaml
exception DivisionByZero
```

Raised by `quotient` and `remainder` when the divisor is zero.

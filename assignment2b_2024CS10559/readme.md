# Assignment 2b: Lexical Analysis (LITHP)

## Overview

This assignment implements a lexical analyzer (tokenizer) for a small LISP-like language called **LITHP** using **OCamllex**. The lexer reads input programs and converts them into a sequence of tokens.

---

## Supported Lexical Elements

### Symbols

* `(` → LEFTPAREN
* `)` → RIGHTPAREN
* `'` → QUOTE

### Constants

* `t` → TRUE
* `()` → NIL (empty list / false)
* Numerals → `NUM` (converted to bigint)

---

### Operators

#### Arithmetic

* `+`, `-`, `*`, `div`, `mod`

#### Comparison

* `=`, `<`, `>`, `<=`, `>=`, `=/=`

---

### Keywords

* `quote`, `atom`, `eq`, `car`, `cdr`, `cons`, `cond`
* `lambda`, `label`, `defun`

---

### Compound Operations

* Patterns like `cadr`, `caadr`, `cddar`, etc.
* Recognized using regex: `c[ad]+r`

---

### Identifiers

* Alphanumeric names (with `_`)
* May optionally end with `.`
  Examples: `x`, `var1`, `list.`, `append.`

---

### Comments

* Start with one or more `;`
* Continue until end of line
* Ignored by the lexer

---

### Whitespace

* Spaces, tabs, and newlines are skipped

---

## Implementation Details

* Implemented using **OCamllex**
* Longest-match and rule-order priority is used
* Keywords are matched before identifiers
* Comments and whitespace are recursively skipped

---

## Notes

* Big integers are constructed using the custom `BigInt` module designed in the last assignment
* The lexer outputs tokens suitable for further parsing
* It takes into use the int_to_bigint function to convert numeric literals into big integers, cannot handle larger than integers of Ocaml, but can handle negative numbers.

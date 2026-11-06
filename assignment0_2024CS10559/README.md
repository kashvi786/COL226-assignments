# Translation into CNF

## Assignment 0 - Programming Languages
## Kashvi Khurana - 2024CS10559

The goal of this project is to solve Sudoku by translating an input grid into a CNF (Conjunctive Normal Form) formula, writing it in DIMACS format, and solving it using the Z3 SAT solver. The solver’s output is then decoded and printed back as a completed Sudoku grid.

---

### Running

A makefile is provided. To execute, simply run:

```sh
make run
```

This will compile the project using OCaml (ocamlc) and output the required solved sudoku to output.txt.

### Files

- **PARSE**
  - Reads the file input.txt and determines the sudoku size (9x9 or 16x16).  
  - For 9x9: can handle digits '1'-'9' and '.' for blanks.
  - For 16x16: can handle '0'-'9', 'A'-'F', and '.' for blanks.
  - Hadles the encoding of the digits.
  - Generates single literals as clauses for each given value in the input.
  - These unit clauses imply that position (i, j) contains value v.

- **CONSTRAINTS**
  - Generates all sudoku constraints in CNF form based on sudoku size being 9x9 or 16x16.
  - Handles the encoding of literals in the same format as parse.
  - x(i,j,v) is used as a Boolean variable meaning: cell (i,j) contains value v, where i,j,v ∈ {1,…,n}.
  - Constraint types:
    - **At least one**: Each cell must contain at least one value (disjunction of all possible values for that cell).
        - x(i,j,1) ∨ x(i,j,2) ∨.....∨ x(i,j,n) ∀ i,j
    - **At most one**: Each cell can contain at most one value (negation of all pairs of different values in the same cell).
        - ¬x(i,j,v1) ∨ ¬x(i,j,v2) ∀ i,j, ∀ v1 < v2 
    - **Row uniqueness**: No duplicate values in any row.
        - ¬x(i,j1,v) ∨ ¬x(i,j2,v) ∀ i,v, ∀ j1 < j2  
    - **Column uniqueness**: No duplicate values in any column.
        - ¬x(i1,j,v) ∨ ¬x(i2,j,v) ∀ j,v, ∀ i1 < i2
    - **Box uniqueness**: No duplicate values in any 3×3 (9x9) or 4×4 (16x16) box.
        - ¬x(i1,j1,v) ∨ ¬x(i2,j2,v) ∀ br,bc,v, ∀ (i1,j1) < (i2,j2) in box(br,bc)

  - All other constraints are redundant via pigeonhole principle, hence can be ignored.
  - They have been written and commented out in the code for reference, and we can see that the contraints for row uniqueness, column uniqueness, box uniqueness, at least once and at most once per cell together handle the conditions of at least once per row, column and box.
  - Returns a CNF formula with all constraints combined.

- **MAIN**
  - This is the main code that handles the cnf.
  - Reads the input sudoku from input.txt using Parse.
  - Generates all constraints using Constraints.
  - Combines given constraints from Parse with general constraints from Constraints.
  - Writes the combined CNF to output1.cnf in DIMACS format.

- **WRITE**
  - Processes the first SAT solver output and decodes solution.
  - Converts it back into a grid and writes it to temp1.txt.
  - Creates a new clause which is thenegation of all positive literals from the first solution.
  - Adds this extra clause to the original CNF to create output2.cnf.
  - This second CNF will be UNSAT if the solution is unique, or SAT if multiple solutions exist.

- **LAST**
  - Determines and outputs the final result based on the two SAT solvings.
  - If first solution (sat_output1.txt) is UNSATISFIABLE: outputs "NO SOLUTION".
  - If first pass is SATISFIABLE but second pass (sat_output2.txt) is UNSATISFIABLE: outputs "UNIQUE" with the solved grid decoded from first cnf.
  - If both passes are SATISFIABLE: outputs "MULTIPLE" with one of the solutions.

- **INPUT.TXT**
  - Has input sudoku grid with blanks and numbers.

- **MAKEFILE**
  - Executes commands as required in the logical flow, includes compiling every time.


---

### Pipeline Flow

The solver uses an approach of solving with z3 twice to determine solution uniqueness:

1. **First Pass: Generate Initial CNF**
   - Parse input sudoku file to extract given values.
   - Generate all required sudoku constraints.
   - Combine given clauses with constraint clauses.
   - Write combined CNF to output1.cnf in DIMACS format.

2. **First SAT Solve**
   - Run Z3 solver on output1.cnf.
   - Output result to sat_output1.txt.
   - If UNSATISFIABLE: there is no solution, exit with "NO SOLUTION".
   - If SATISFIABLE: create second attempt solution.

3. **Second CNF**
   - Decode the first solution from sat_output1.txt into a grid (written to temp1.txt).
   - Extract all positive literals from the first solution.
   - Create a new clause by negating all positive literals from the last solution.
   - Append the extra clause to the original CNF.
   - Write the new CNF to output2.cnf.

4. **Second SAT Solve**
   - Run Z3 solver on output2.cnf (with the extra negation clause).
   - Output result to sat_output2.txt.
   - If UNSATISFIABLE: the first solution was unique, output "UNIQUE".
   - If SATISFIABLE: multiple solutions exist, output "MULTIPLE".

5. **Final Output**
   - Output result of solved sudoku is saved to output.txt (if solution exists), otherwise prints "NO SOLUTION" to output.txt.
   - The result status ("NO SOLUTION", "UNIQUE", or "MULTIPLE") is saved to case_of_output.txt.

---

## Input and Output format

### Input Format (input.txt)

For **9×9 Sudoku**:
- 9 lines, each with 9 characters.
- Valid characters: '1' through '9' for given values, '.' for empty cells.
- Example:
  ```
  .1..5.4.7
  ..8...3..
  ```

For **16×16 Sudoku**:
- 16 lines, each with 16 characters.
- Valid characters: '0'-'9' (representing values 1-10), 'A'-'F' (representing values 11-16), '.' for empty cells.
- Example:
  ```
  .72.C0E.F..D.6.A
  .C..BF97.A2451..D
  ```

### CNF Format (DIMACS)

The CNF files (output1.cnf, output2.cnf) follow the DIMACS format:

```
p cnf <num_variables> <num_clauses>
<literal> <literal> ... <literal> 0
<literal> <literal> ... <literal> 0
...
```

- First line: `p cnf` followed by total number of variables and total number of clauses.
- Each subsequent line: a clause represented as space-separated integers ending with `0`.
- Positive integer: positive literal (variable must be true).
- Negative integer: negated literal (variable must be false).

**Variable Encoding**:
- For an n×n sudoku, variable numbers range from 1 to n³.
- Variable ID for position (i, j) with value v: `n² × (i - 1) + n × (j - 1) + v`
- i, j are 1-indexed; v ranges from 1 to n.

### Output Format (output.txt)

**First line**: One of the following status messages:
- `NO SOLUTION`: The sudoku puzzle has no valid solution.
- `UNIQUE`: The sudoku puzzle has exactly one solution.
- `MULTIPLE`: The sudoku puzzle has multiple solutions.

**Remaining lines** (if a solution exists):
- The solved n×n sudoku grid, one row per line.
- For 9×9: digits '1' through '9'.
- For 16×16: '0'-'9' and 'A'-'F'.

Example output (9×9):
```
UNIQUE
572BC0E4F81D963A
EC03BF976A24518D
A9DF8651B3E7420C
...
```


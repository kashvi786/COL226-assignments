(* Test suite for the Krivine machine (call-by-name lambda calculus).
   This file tests krivine.ml, which represents the environment (gamma) as an
   association list of type (string * clos) list.

   Run:
     ocaml test_krivine.ml      -- tests krivine.ml  (list-based table)
     ocaml test_krivine2.ml     -- tests krivine2.ml (function-based table)

   The two test files are identical except for the #use line.

   For each test the output line shows:
     PASS/FAIL: <name>  |  got: <actual>  [|  expected: <expected>]
   so the reader can verify correctness at a glance without running a REPL.

   Test categories
   ---------------
   1.  Pure lambda calculus: identity, K, S combinators
   2.  Church encodings: pairs, booleans (demonstrates call-by-name works on
       higher-order representations -- the assignment's suggested examples)
   3.  Built-in data: pairs, integers, booleans with the primitive operations
   4.  Arithmetic and comparison operators
   5.  Boolean logic
   6.  Conditional (if-then-else)
   7.  Let bindings (Def, sequential Seq, parallel Par)
   8.  Higher-order functions: currying, composition
   9.  Call-by-name laziness: argument not evaluated if unused
  10.  Unpack sanity: result is a proper lambda term (no closures leak out)
*)

#use "krivine.ml";;

let passed = ref 0
let failed = ref 0

(* Pretty-print an exp value as a compact string for output. *)
let rec pp_exp e =
  match e with
  | V x -> x
  | Int n -> string_of_int n
  | Bool b -> string_of_bool b
  | Abs (x, body) -> Printf.sprintf "(\\%s.%s)" x (pp_exp body)
  | App (e1, e2) -> Printf.sprintf "(%s %s)" (pp_exp e1) (pp_exp e2)
  | Add (e1, e2) -> Printf.sprintf "(%s+%s)" (pp_exp e1) (pp_exp e2)
  | Mult (e1, e2) -> Printf.sprintf "(%s*%s)" (pp_exp e1) (pp_exp e2)
  | And (e1, e2) -> Printf.sprintf "(%s&&%s)" (pp_exp e1) (pp_exp e2)
  | Or  (e1, e2) -> Printf.sprintf "(%s||%s)" (pp_exp e1) (pp_exp e2)
  | Not e -> Printf.sprintf "(not %s)" (pp_exp e)
  | Eq  (e1, e2) -> Printf.sprintf "(%s=%s)" (pp_exp e1) (pp_exp e2)
  | Lt  (e1, e2) -> Printf.sprintf "(%s<%s)" (pp_exp e1) (pp_exp e2)
  | Gt  (e1, e2) -> Printf.sprintf "(%s>%s)" (pp_exp e1) (pp_exp e2)
  | If  (c, t, f) -> Printf.sprintf "(if %s then %s else %s)" (pp_exp c) (pp_exp t) (pp_exp f)
  | Pair (e1, e2) -> Printf.sprintf "(%s,%s)" (pp_exp e1) (pp_exp e2)
  | Fst e -> Printf.sprintf "(fst %s)" (pp_exp e)
  | Snd e -> Printf.sprintf "(snd %s)" (pp_exp e)
  | Let (_, body) -> Printf.sprintf "(let...in %s)" (pp_exp body)

(* Print PASS/FAIL, the actual result, and (on failure) the expected value. *)
let check name result expected =
  let ok = (result = expected) in
  if ok then begin
    Printf.printf "PASS: %-45s  =>  %s\n%!" name (pp_exp result);
    incr passed
  end else begin
    Printf.printf "FAIL: %-45s  =>  got: %s  expected: %s\n%!"
      name (pp_exp result) (pp_exp expected);
    incr failed
  end


(* ===================================================================
   1. Pure lambda calculus -- identity, K, S
   =================================================================== *)

(* (\x.x) 5 -- identity function applied to an integer *)
let () =
  check "identity  (\\x.x) 5"
    (call_by_name (App(Abs("x", V "x"), Int 5)))
    (Int 5)

(* K combinator: (\x.\y.x) 3 4 = 3  -- selects first argument *)
let () =
  check "K combinator  (\\x.\\y.x) 3 4"
    (call_by_name (App(App(Abs("x", Abs("y", V "x")), Int 3), Int 4)))
    (Int 3)

(* S combinator: S K K 5 = K 5 (K 5) = 5  (S acts as identity when K K is given)
   S = \f.\g.\x. f x (g x)
   K = \x.\y. x *)
let () =
  let s_comb = Abs("f", Abs("g", Abs("x",
    App(App(V "f", V "x"), App(V "g", V "x"))))) in
  let k_comb = Abs("x", Abs("y", V "x")) in
  check "S combinator  S K K 5"
    (call_by_name (App(App(App(s_comb, k_comb), k_comb), Int 5)))
    (Int 5)


(* ===================================================================
   2. Church encodings -- pairs and booleans
      These use higher-order lambda terms to encode data, which is the
      standard demonstration that call-by-name works on encoded types.
   =================================================================== *)

(* Church pair:  pair = \x.\y.\f. f x y
   Church fst:   fst  = \p. p (\x.\y. x)
   Church snd:   snd  = \p. p (\x.\y. y)
   fst (pair 3 5) = 3,   snd (pair 3 5) = 5 *)
let () =
  let pair = Abs("x", Abs("y", Abs("f", App(App(V "f", V "x"), V "y")))) in
  let fst  = Abs("p", App(V "p", Abs("x", Abs("y", V "x")))) in
  let snd  = Abs("p", App(V "p", Abs("x", Abs("y", V "y")))) in
  let mk35 = App(App(pair, Int 3), Int 5) in
  check "church pair fst  fst(pair 3 5)"
    (call_by_name (App(fst, mk35)))
    (Int 3);
  check "church pair snd  snd(pair 3 5)"
    (call_by_name (App(snd, mk35)))
    (Int 5)

(* Church booleans:
   tru  = \x.\y. x   (selects true branch)
   fls  = \x.\y. y   (selects false branch)
   cond = \b.\t.\f. b t f *)
let () =
  let tru  = Abs("x", Abs("y", V "x")) in
  let fls  = Abs("x", Abs("y", V "y")) in
  let cond = Abs("b", Abs("t", Abs("f", App(App(V "b", V "t"), V "f")))) in
  check "church true   cond tru 1 2"
    (call_by_name (App(App(App(cond, tru), Int 1), Int 2))) (Int 1);
  check "church false  cond fls 1 2"
    (call_by_name (App(App(App(cond, fls), Int 1), Int 2))) (Int 2)

(* Church NOT:  not = \b. b fls tru *)
let () =
  let tru  = Abs("x", Abs("y", V "x")) in
  let fls  = Abs("x", Abs("y", V "y")) in
  let cnot = Abs("b", App(App(V "b", fls), tru)) in
  check "church not true"
    (call_by_name (App(App(App(cnot, tru), Int 0), Int 1))) (Int 1);
  check "church not false"
    (call_by_name (App(App(App(cnot, fls), Int 0), Int 1))) (Int 0)


(* ===================================================================
   3. Built-in pairs (Pair / Fst / Snd constructors)
   =================================================================== *)

let () =
  check "pair fst  fst(3,5)"
    (call_by_name (Fst (Pair (Int 3, Int 5))))
    (Int 3);
  check "pair snd  snd(3,5)"
    (call_by_name (Snd (Pair (Int 3, Int 5))))
    (Int 5);
  (* snd of a nested pair returns the inner pair intact *)
  check "pair snd nested  snd(1,(2,3))"
    (call_by_name (Snd (Pair (Int 1, Pair (Int 2, Int 3)))))
    (Pair (Int 2, Int 3));
  (* fst of a nested pair *)
  check "pair fst nested  fst((1,2),3)"
    (call_by_name (Fst (Pair (Pair (Int 1, Int 2), Int 3))))
    (Pair (Int 1, Int 2))


(* ===================================================================
   4. Arithmetic and comparisons
   =================================================================== *)

let () =
  check "add   3+4"     (call_by_name (Add(Int 3, Int 4)))   (Int 7);
  check "mult  3*4"     (call_by_name (Mult(Int 3, Int 4)))  (Int 12);
  check "add   (\\x.x+1) 5"
    (call_by_name (App(Abs("x", Add(V "x", Int 1)), Int 5))) (Int 6);
  check "mult  2*3+1 (left-arg fn)"
    (call_by_name (Add(Mult(Int 2, Int 3), Int 1))) (Int 7)

let () =
  check "lt  3<5"   (call_by_name (Lt(Int 3, Int 5))) (Bool true);
  check "lt  5<3"   (call_by_name (Lt(Int 5, Int 3))) (Bool false);
  check "lt  4<4"   (call_by_name (Lt(Int 4, Int 4))) (Bool false);
  check "gt  5>3"   (call_by_name (Gt(Int 5, Int 3))) (Bool true);
  check "gt  3>5"   (call_by_name (Gt(Int 3, Int 5))) (Bool false);
  check "gt  4>4"   (call_by_name (Gt(Int 4, Int 4))) (Bool false);
  check "eq  3=3"   (call_by_name (Eq(Int 3, Int 3))) (Bool true);
  check "eq  3=4"   (call_by_name (Eq(Int 3, Int 4))) (Bool false)


(* ===================================================================
   5. Boolean logic
   =================================================================== *)

let () =
  check "and  T&&F"  (call_by_name (And(Bool true,  Bool false))) (Bool false);
  check "and  T&&T"  (call_by_name (And(Bool true,  Bool true)))  (Bool true);
  check "or   F||T"  (call_by_name (Or (Bool false, Bool true)))  (Bool true);
  check "or   F||F"  (call_by_name (Or (Bool false, Bool false))) (Bool false);
  check "not  !true" (call_by_name (Not(Bool true)))              (Bool false);
  check "not  !false"(call_by_name (Not(Bool false)))             (Bool true)


(* ===================================================================
   6. Conditional
   =================================================================== *)

let () =
  check "if  true  => 1" (call_by_name (If(Bool true,  Int 1, Int 2))) (Int 1);
  check "if  false => 2" (call_by_name (If(Bool false, Int 1, Int 2))) (Int 2);
  check "if  3<5   => 10"
    (call_by_name (If(Lt(Int 3, Int 5), Int 10, Int 20))) (Int 10);
  check "if  5<3   => 20"
    (call_by_name (If(Lt(Int 5, Int 3), Int 10, Int 20))) (Int 20)


(* ===================================================================
   7. Let bindings (Def / Seq / Par)
   =================================================================== *)

let () =
  (* Simple Def *)
  check "let Def   x=3 in x+4"
    (call_by_name (Let(Def("x", Int 3), Add(V "x", Int 4))))
    (Int 7);
  (* Seq: y sees x's binding *)
  check "let Seq   x=3; y=x+1 in x+y"
    (call_by_name
       (Let(Seq(Def("x", Int 3), Def("y", Add(V "x", Int 1))),
            Add(V "x", V "y"))))
    (Int 7);
  (* Par: both bindings use original env (no mutual dependency) *)
  check "let Par   x=3 || y=4 in x+y"
    (call_by_name
       (Let(Par(Def("x", Int 3), Def("y", Int 4)), Add(V "x", V "y"))))
    (Int 7);
  (* Nested let *)
  check "let nested  x=2 in (let y=x+1 in x*y)"
    (call_by_name
       (Let(Def("x", Int 2),
            Let(Def("y", Add(V "x", Int 1)), Mult(V "x", V "y")))))
    (Int 6)


(* ===================================================================
   8. Higher-order functions: currying, composition
   =================================================================== *)

(* Curried addition *)
let () =
  check "curried add  (\\x.\\y.x+y) 3 4"
    (call_by_name (App(App(Abs("x", Abs("y", Add(V "x", V "y"))), Int 3), Int 4)))
    (Int 7)

(* Function composition: compose f g x = f (g x)
   (compose inc dbl) 3  =  inc (dbl 3)  =  inc 6  =  7 *)
let () =
  let compose = Abs("f", Abs("g", Abs("x", App(V "f", App(V "g", V "x"))))) in
  let inc = Abs("x", Add(V "x", Int 1)) in
  let dbl = Abs("x", Mult(V "x", Int 2)) in
  check "compose  (inc . dbl) 3"
    (call_by_name (App(App(App(compose, inc), dbl), Int 3)))
    (Int 7)

(* flip: (\f.\x.\y. f y x)  applied to subtraction equivalent *)
let () =
  let sub = Abs("x", Abs("y", Add(V "x", Mult(Int (-1), V "y")))) in
  let flip = Abs("f", Abs("x", Abs("y", App(App(V "f", V "y"), V "x")))) in
  check "flip sub 1 10  =  10-1  =  9"
    (call_by_name (App(App(App(flip, sub), Int 1), Int 10)))
    (Int 9)


(* ===================================================================
   9. Call-by-name laziness
      Under call-by-name, an argument is NEVER evaluated if the
      bound variable is not used.  This means (\x.1) applied to a
      diverging term (like the self-application \y.y y) terminates.
   =================================================================== *)

let () =
  let const1 = Abs("x", Int 1) in
  (* \y.y y can diverge if applied to itself, but here it is never evaluated *)
  let unapplied_omega = Abs("y", App(V "y", V "y")) in
  check "CBN laziness  (\\x.1)(\\y.y y)"
    (call_by_name (App(const1, unapplied_omega)))
    (Int 1)

(* Unused argument with computation inside: (\x.\y.y)(3+4) = (\y.y)
   The 3+4 is never evaluated -- result is the identity function.
   We verify the unpack produces the correct lambda term. *)
let () =
  let result = call_by_name
    (App(Abs("x", Abs("y", V "y")), Add(Int 3, Int 4))) in
  check "CBN laziness  unused arg is not evaluated"
    result
    (Abs("y", V "y"))


(* ===================================================================
  10. Unpack sanity -- check that unpacked results are proper exp values
   =================================================================== *)

(* A function returned from call_by_name must unpack to an Abs, not a raw closure *)
let () =
  let result = call_by_name (Abs("x", Add(V "x", Int 1))) in
  check "unpack abs  \\x.x+1  stays Abs"
    result
    (Abs("x", Add(V "x", Int 1)))


let () =
  Printf.printf "\n%d passed, %d failed\n%!" !passed !failed

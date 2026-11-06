(* Test suite for the SECD machine (call-by-value lambda calculus).
   This file tests secd.ml, which represents the environment (E) as an
   association list of type (string * value) list.

   Run:
     ocaml test_secd.ml       -- tests secd.ml  (list-based table)
     ocaml test_secd2.ml      -- tests secd2.ml (function-based table)

   The two test files are identical except for the #use line.

   For each test the output line shows:
     PASS/FAIL: <name>  |  got: <actual>  [|  expected: <expected>]
   so the reader can verify correctness at a glance without running a REPL.

   The SECD machine differs from the Krivine machine in that it is
   call-by-VALUE: arguments are fully evaluated before substitution.
   Results are `value` terms (VInt, VBool, VPair, VClos), NOT exp terms.

   Compilation rules (from the assignment):
     compile(x)        = [LOOKUP(x)]
     compile(e1 e2)    = compile(e1) @ compile(e2) @ [APP]
     compile(\x.e)     = [MkCLOS(x, compile(e) @ [RET])]

   SECD transition rules:
     (Var)  s, gamma, LOOKUP(x)::c',  d  =>  gamma(x)::s, gamma, c', d
     (Clos) s, gamma, MkCLOS(x,c1)::c', d  =>  <<x,c1,gamma>>::s, gamma, c', d
     (App)  v2::(<<x,c1,gamma1>>)::s, gamma, APP::c', d
                =>  [], gamma1[x|->v2], c1, (s,gamma,c')::d
     (Ret)  v::s', gamma', RET::c'', (s,gamma,c')::d
                =>  v::s, gamma, c', d

   Stack ordering note: compile(e1 e2) pushes e1 result, then e2 result, then APP.
   At APP time the stack top is e2's value (arg), below is e1's value (function).
   Binary operator opcodes (ADD, LT, etc.) account for this reversed order.

   Test categories
   ---------------
   1.  Pure lambda calculus: identity, K, S combinators
   2.  Church encodings: pairs, booleans
   3.  Built-in pairs (VPair)
   4.  Arithmetic and comparisons (including stack-order correctness for LT/GT)
   5.  Boolean logic
   6.  Conditional (if-then-else via IFTE opcode)
   7.  Let bindings (Def, sequential Seq, parallel Par)
   8.  Higher-order functions: currying, composition, closure capture
   9.  Call-by-value eagerness: argument evaluated even when unused
  10.  Closure representation: VClos result confirmed correct
*)

#use "secd.ml";;

let passed = ref 0
let failed = ref 0

(* Pretty-print a value.
   VClos prints as <clos \x> to avoid comparing unequalable function tables. *)
let rec pp_val v =
  match v with
  | VInt n -> string_of_int n
  | VBool b -> string_of_bool b
  | VPair (v1, v2) -> Printf.sprintf "(%s,%s)" (pp_val v1) (pp_val v2)
  | VClos (x, _, _) -> Printf.sprintf "<clos \\%s>" x

(* Print PASS/FAIL with the actual value; on failure also print the expected. *)
let check name result expected =
  let ok = (result = expected) in
  if ok then begin
    Printf.printf "PASS: %-50s  =>  %s\n%!" name (pp_val result);
    incr passed
  end else begin
    Printf.printf "FAIL: %-50s  =>  got: %s  expected: %s\n%!"
      name (pp_val result) (pp_val expected);
    incr failed
  end


(* ===================================================================
   1. Pure lambda calculus -- identity, K, S
   =================================================================== *)

(* (\x.x) 5 *)
let () =
  check "identity  (\\x.x) 5"
    (run (App(Abs("x", V "x"), Int 5)))
    (VInt 5)

(* K combinator: (\x.\y.x) 3 4 = 3 *)
let () =
  check "K combinator  (\\x.\\y.x) 3 4"
    (run (App(App(Abs("x", Abs("y", V "x")), Int 3), Int 4)))
    (VInt 3)

(* S combinator: S K K 5 = 5 *)
let () =
  let s_comb = Abs("f", Abs("g", Abs("x",
    App(App(V "f", V "x"), App(V "g", V "x"))))) in
  let k_comb = Abs("x", Abs("y", V "x")) in
  check "S combinator  S K K 5"
    (run (App(App(App(s_comb, k_comb), k_comb), Int 5)))
    (VInt 5)


(* ===================================================================
   2. Church encodings -- pairs and booleans
   =================================================================== *)

(* pair = \x.\y.\f. f x y,  fst = \p. p (\x.\y. x),  snd = \p. p (\x.\y. y) *)
let () =
  let pair = Abs("x", Abs("y", Abs("f", App(App(V "f", V "x"), V "y")))) in
  let fst  = Abs("p", App(V "p", Abs("x", Abs("y", V "x")))) in
  let snd  = Abs("p", App(V "p", Abs("x", Abs("y", V "y")))) in
  let mk35 = App(App(pair, Int 3), Int 5) in
  check "church pair fst  fst(pair 3 5)"
    (run (App(fst, mk35)))
    (VInt 3);
  check "church pair snd  snd(pair 3 5)"
    (run (App(snd, mk35)))
    (VInt 5)

(* tru = \x.\y. x,  fls = \x.\y. y,  cond = \b.\t.\f. b t f *)
let () =
  let tru  = Abs("x", Abs("y", V "x")) in
  let fls  = Abs("x", Abs("y", V "y")) in
  let cond = Abs("b", Abs("t", Abs("f", App(App(V "b", V "t"), V "f")))) in
  check "church true   cond tru 1 2"
    (run (App(App(App(cond, tru), Int 1), Int 2))) (VInt 1);
  check "church false  cond fls 1 2"
    (run (App(App(App(cond, fls), Int 1), Int 2))) (VInt 2)


(* ===================================================================
   3. Built-in pairs
   =================================================================== *)

let () =
  check "pair fst  fst(3,5)"
    (run (Fst (Pair (Int 3, Int 5))))
    (VInt 3);
  check "pair snd  snd(3,5)"
    (run (Snd (Pair (Int 3, Int 5))))
    (VInt 5);
  check "pair snd nested  snd(1,(2,3))"
    (run (Snd (Pair (Int 1, Pair (Int 2, Int 3)))))
    (VPair (VInt 2, VInt 3));
  check "pair fst nested  fst((1,2),3)"
    (run (Fst (Pair (Pair (Int 1, Int 2), Int 3))))
    (VPair (VInt 1, VInt 2))


(* ===================================================================
   4. Arithmetic and comparisons
      Stack ordering note: compile(e1 op e2) pushes e1 then e2.
      At the opcode, stack top = e2 value (bound to v1 in the match),
      below = e1 value (bound to v2).  LT/GT check n2 op n1 to compensate.
   =================================================================== *)

let () =
  check "add   3+4"    (run (Add(Int 3, Int 4)))   (VInt 7);
  check "mult  3*4"    (run (Mult(Int 3, Int 4)))  (VInt 12);
  check "add   (\\x.x+1) 5"
    (run (App(Abs("x", Add(V "x", Int 1)), Int 5))) (VInt 6);
  check "arith 2*3+1"
    (run (Add(Mult(Int 2, Int 3), Int 1))) (VInt 7)

let () =
  check "lt  3<5  true"  (run (Lt(Int 3, Int 5))) (VBool true);
  check "lt  5<3  false" (run (Lt(Int 5, Int 3))) (VBool false);
  check "lt  4<4  false" (run (Lt(Int 4, Int 4))) (VBool false);
  check "gt  5>3  true"  (run (Gt(Int 5, Int 3))) (VBool true);
  check "gt  3>5  false" (run (Gt(Int 3, Int 5))) (VBool false);
  check "gt  4>4  false" (run (Gt(Int 4, Int 4))) (VBool false);
  check "eq  3=3  true"  (run (Eq(Int 3, Int 3))) (VBool true);
  check "eq  3=4  false" (run (Eq(Int 3, Int 4))) (VBool false)


(* ===================================================================
   5. Boolean logic
   =================================================================== *)

let () =
  check "and  T&&F" (run (And(Bool true,  Bool false))) (VBool false);
  check "and  T&&T" (run (And(Bool true,  Bool true)))  (VBool true);
  check "or   F||T" (run (Or (Bool false, Bool true)))  (VBool true);
  check "or   F||F" (run (Or (Bool false, Bool false))) (VBool false);
  check "not  !T"   (run (Not(Bool true)))              (VBool false);
  check "not  !F"   (run (Not(Bool false)))             (VBool true)


(* ===================================================================
   6. Conditional (IFTE opcode)
   =================================================================== *)

let () =
  check "if  true  => 1" (run (If(Bool true,  Int 1, Int 2))) (VInt 1);
  check "if  false => 2" (run (If(Bool false, Int 1, Int 2))) (VInt 2);
  check "if  3<5   => 10"
    (run (If(Lt(Int 3, Int 5), Int 10, Int 20))) (VInt 10);
  check "if  5<3   => 20"
    (run (If(Lt(Int 5, Int 3), Int 10, Int 20))) (VInt 20)


(* ===================================================================
   7. Let bindings (Def / Seq / Par)
   =================================================================== *)

let () =
  check "let Def  x=3 in x+4"
    (run (Let(Def("x", Int 3), Add(V "x", Int 4))))
    (VInt 7);
  check "let Seq  x=3; y=x+1 in x+y"
    (run
       (Let(Seq(Def("x", Int 3), Def("y", Add(V "x", Int 1))),
            Add(V "x", V "y"))))
    (VInt 7);
  check "let Par  x=3 || y=4 in x+y"
    (run
       (Let(Par(Def("x", Int 3), Def("y", Int 4)), Add(V "x", V "y"))))
    (VInt 7);
  check "let nested  x=2 in (let y=x+1 in x*y)"
    (run
       (Let(Def("x", Int 2),
            Let(Def("y", Add(V "x", Int 1)), Mult(V "x", V "y")))))
    (VInt 6)


(* ===================================================================
   8. Higher-order functions: currying, composition, closure capture
   =================================================================== *)

(* Curried addition *)
let () =
  check "curried add  (\\x.\\y.x+y) 3 4"
    (run (App(App(Abs("x", Abs("y", Add(V "x", V "y"))), Int 3), Int 4)))
    (VInt 7)

(* compose f g x = f (g x);  (compose inc dbl) 3 = inc(dbl 3) = inc 6 = 7 *)
let () =
  let compose = Abs("f", Abs("g", Abs("x", App(V "f", App(V "g", V "x"))))) in
  let inc = Abs("x", Add(V "x", Int 1)) in
  let dbl = Abs("x", Mult(V "x", Int 2)) in
  check "compose  (inc . dbl) 3"
    (run (App(App(App(compose, inc), dbl), Int 3)))
    (VInt 7)

(* Closure must capture x=3 from outer scope when building (\y.x+y). *)
let () =
  let term =
    App(
      Abs("x",
        App(
          Abs("f", App(V "f", Int 4)),
          Abs("y", Add(V "x", V "y"))
        )
      ),
      Int 3
    )
  in
  check "closure capture  (\\x.(\\f.f 4)(\\y.x+y)) 3"
    (run term)
    (VInt 7)

(* flip: (\f.\x.\y. f y x) *)
let () =
  let sub = Abs("x", Abs("y", Add(V "x", Mult(Int (-1), V "y")))) in
  let flip = Abs("f", Abs("x", Abs("y", App(App(V "f", V "y"), V "x")))) in
  check "flip sub 1 10  =  10-1  =  9"
    (run (App(App(App(flip, sub), Int 1), Int 10)))
    (VInt 9)


(* ===================================================================
   9. Call-by-value eagerness
      Under call-by-value, the argument IS evaluated before the call.
      (\x.1)(3+4) evaluates 3+4 to 7, then discards it; result is 1.
      (Contrast with call-by-name where 3+4 would never be evaluated.)
   =================================================================== *)

let () =
  check "CBV eagerness  (\\x.1)(3+4)"
    (run (App(Abs("x", Int 1), Add(Int 3, Int 4))))
    (VInt 1)

(* Argument with side-effects (arithmetic): must be evaluated first. *)
let () =
  check "CBV evaluates arg  (\\x.x*x)(2+3)"
    (run (App(Abs("x", Mult(V "x", V "x")), Add(Int 2, Int 3))))
    (VInt 25)


(* ===================================================================
  10. Closure representation
      run on a lambda with no arguments returns a VClos value.
      We check its parameter name to confirm compilation was correct.
   =================================================================== *)

let () =
  let result = run (Abs("z", Add(V "z", Int 1))) in
  (match result with
   | VClos ("z", _, _) ->
       Printf.printf "PASS: %-50s  =>  %s\n%!" "closure repr  \\z.z+1" (pp_val result);
       incr passed
   | _ ->
       Printf.printf "FAIL: %-50s  =>  got: %s\n%!" "closure repr  \\z.z+1" (pp_val result);
       incr failed)


let () =
  Printf.printf "\n%d passed, %d failed\n%!" !passed !failed

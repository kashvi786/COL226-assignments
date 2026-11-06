open Main

let test name expr =
  let result = eval expr in
  Printf.printf "TEST: %s\n" name;
  Printf.printf "Result: %s\n\n" (string_of_comb result)

(* ---------------- CHURCH NUMERALS ---------------- *)

(* Church numerals *)
let zero =
  Lam ("f", Lam ("x", V "x"))

let one =
  Lam ("f", Lam ("x", App (V "f", V "x")))

let two =
  Lam ("f", Lam ("x", App (V "f", App (V "f", V "x"))))

(* Successor: λn.λf.λx. f (n f x) *)
let succ =
  Lam ("n",
    Lam ("f",
      Lam ("x",
        App (V "f", App (App (V "n", V "f"), V "x"))
      )
    )
  )

(* Addition: λm.λn.λf.λx. m f (n f x) *)
let plus =
  Lam ("m",
    Lam ("n",
      Lam ("f",
        Lam ("x",
          App (
            App (V "m", V "f"),
            App (App (V "n", V "f"), V "x")
          )
        )
      )
    )
  )

(* ---------------- CHURCH TESTS ---------------- *)

let () =
  (* Identity: λx.x *)
  test "identity" (Lam ("x", V "x"));

  (* Constant: λx.y *)
  test "const" (Lam ("x", V "y"));

  (* Self application: λx. x x *)
  test "self-app" (Lam ("x", App (V "x", V "x")));

  (* (λx.x) y → y *)
  test "apply identity"
    (App (Lam ("x", V "x"), V "y"));

  (* (λx.λy.x) a b → a *)
  test "K behavior"
    (App (
      App (Lam ("x", Lam ("y", V "x")), V "a"),
      V "b"
    ));

  (* (λx.λy.y) a b → b *)
  test "second projection"
    (App (
      App (Lam ("x", Lam ("y", V "y")), V "a"),
      V "b"
    ));

(* ---------------- NESTED / COMPLEX ---------------- *)

  (* λx.λy. x y *)
  test "apply function"
    (Lam ("x", Lam ("y", App (V "x", V "y"))));

  (* (λx.λy. x y) f a → f a *)
  test "apply function instantiated"
    (App (
      App (Lam ("x", Lam ("y", App (V "x", V "y"))), V "f"),
      V "a"
    ));
  (* 0 applied → should return x *)
  test "zero f x"
    (App (App (zero, V "f"), V "x"));

  (* 1 applied → f x *)
  test "one f x"
    (App (App (one, V "f"), V "x"));

  (* 2 applied → f (f x) *)
  test "two f x"
    (App (App (two, V "f"), V "x"));

  (* succ 1 → 2 *)
  test "succ 1 applied to f x"
    (App (
      App (
        App (succ, one),
        V "f"
      ),
      V "x"
    ));

  (* plus 1 1 → 2 *)
  test "1 + 1"
    (App (
      App (
        App (
          App (plus, one),
          one
        ),
        V "f"
      ),
      V "x"
    ));

  (* plus 2 1 → 3 *)
  test "2 + 1"
    (App (
      App (
        App (
          App (plus, two),
          one
        ),
        V "f"
      ),
      V "x"
    ));
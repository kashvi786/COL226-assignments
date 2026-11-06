type exp = V of string | Abs of string * exp | App of exp * exp | Int of int | Bool of bool
  | Add of exp * exp | Mult of exp*exp | And of exp*exp | Or of exp*exp | Not of exp
  | Eq of exp * exp | Lt of exp * exp | Gt of exp * exp
  | If of exp * exp * exp
  | Pair of exp * exp | Fst of exp | Snd of exp
  | Let of defs * exp
and defs = Def of string * exp | Seq of defs * defs | Par of defs * defs;;

type opcode =
  | MKCLOS of string * opcode list
  | LOOKUP of string
  | APP
  | RET
  | LDN of int
  | LDB of bool
  | PAIR | FST | SND
  | ADD | MULT | AND | OR | NOT | EQ | LT | GT
  | IFTE of opcode list * opcode list
  | LET of defs * opcode list
;;

type value =
  | VClos of string * opcode list * table
  | VInt of int
  | VBool of bool
  | VPair of value * value
and table = string -> value;;

exception Stuck;;

let empty_table : table = fun _ -> raise Not_found;;

let augment_table x cl env = fun y -> if y = x then cl else env y;;

let lookup x env =
  try env x with Not_found -> raise Stuck
;;

type dump_type = (value list * table * opcode list) list;;
let rec compile exp =
  match exp with
  | V x -> [LOOKUP x]
  | Int n -> [LDN n]
  | Bool b -> [LDB b]
  | Abs (x, e) -> [MKCLOS (x, (compile e) @ [RET])]
  | App (e1, e2) -> (compile e1) @ (compile e2) @ [APP]
  | Add (e1, e2) -> (compile e1) @ (compile e2) @ [ADD]
  | Mult (e1, e2) -> (compile e1) @ (compile e2) @ [MULT]
  | And (e1, e2) -> (compile e1) @ (compile e2) @ [AND]
  | Or (e1, e2) -> (compile e1) @ (compile e2) @ [OR]
  | Not e -> (compile e) @ [NOT]
  | Eq (e1, e2) -> (compile e1) @ (compile e2) @ [EQ]
  | Lt (e1, e2) -> (compile e1) @ (compile e2) @ [LT]
  | Gt (e1, e2) -> (compile e1) @ (compile e2) @ [GT]
  | If (e1, e2, e3) -> (compile e1) @ [IFTE (compile e2, compile e3)]
  | Pair (e1, e2) -> (compile e1) @ (compile e2) @ [PAIR]
  | Fst e -> (compile e) @ [FST]
  | Snd e -> (compile e) @ [SND]
  | Let (defs, body) -> [LET (defs, compile body)]
;;

let rec stkmc s e c d =
  match (s, e, c, d) with
  | (a :: _, _, [], []) -> a
  | (_, _, [], _) -> raise Stuck
  | (s, e, LOOKUP x :: c', d) ->
      let a = lookup x e in
      stkmc (a :: s) e c' d
  | (s, e, LDN n :: c', d) ->
      stkmc (VInt n :: s) e c' d
  | (s, e, LDB b :: c', d) ->
      stkmc (VBool b :: s) e c' d
  | (s, e, LET (defs, body) :: c', d) ->
      let env' = eval_defs defs e in
      let v = stkmc [] env' body [] in
      stkmc (v :: s) e c' d
  | (s, e, MKCLOS (x, c') :: c'', d) ->
      let clos = VClos (x, c', e) in
      stkmc (clos :: s) e c'' d
  | (arg :: VClos (x, c', e') :: s', e, APP :: c'', d) ->
      stkmc [] (augment_table x arg e') c' ((s', e, c'') :: d)
  | (a :: s', e, RET :: _, (s'', e'', c'') :: d') ->
      stkmc (a :: s'') e'' c'' d'
  | (v2 :: v1 :: s', e, PAIR :: c'', d) ->
      stkmc (VPair (v1, v2) :: s') e c'' d
  | (v :: s', e, FST :: c'', d) ->
      (match v with
       | VPair (v1, _) -> stkmc (v1 :: s') e c'' d
       | _ -> raise Stuck)
  | (v :: s', e, SND :: c'', d) ->
      (match v with
       | VPair (_, v2) -> stkmc (v2 :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, ADD :: c'', d) ->
      (match (v1, v2) with
       | (VInt n1, VInt n2) -> stkmc (VInt (n1 + n2) :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, MULT :: c'', d) ->
      (match (v1, v2) with
       | (VInt n1, VInt n2) -> stkmc (VInt (n1 * n2) :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, AND :: c'', d) ->
      (match (v1, v2) with
       | (VBool b1, VBool b2) -> stkmc (VBool (b1 && b2) :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, OR :: c'', d) ->
      (match (v1, v2) with
       | (VBool b1, VBool b2) -> stkmc (VBool (b1 || b2) :: s') e c'' d
       | _ -> raise Stuck)
  | (v :: s', e, NOT :: c'', d) ->
      (match v with
       | VBool b -> stkmc (VBool (not b) :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, EQ :: c'', d) ->
      (match (v1, v2) with
       | (VInt n1, VInt n2) -> stkmc (VBool (n1 = n2) :: s') e c'' d
       | (VBool b1, VBool b2) -> stkmc (VBool (b1 = b2) :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, LT :: c'', d) ->
      (match (v1, v2) with
       | (VInt n1, VInt n2) -> stkmc (VBool (n2 < n1) :: s') e c'' d
       | _ -> raise Stuck)
  | (v1 :: v2 :: s', e, GT :: c'', d) ->
      (match (v1, v2) with
       | (VInt n1, VInt n2) -> stkmc (VBool (n2 > n1) :: s') e c'' d
       | _ -> raise Stuck)
  | (v :: s', e, IFTE (c1, c2) :: c'', d) ->
      (match v with
       | VBool b -> stkmc s' e (if b then c1 @ c'' else c2 @ c'') d
       | _ -> raise Stuck)
  | _ -> raise Stuck

and eval_with env exp =
  stkmc [] env (compile exp) []

and eval_defs_with_bindings defs env =
  match defs with
  | Def (x, e) ->
      let v = eval_with env e in
      ([(x, v)], augment_table x v env)
  | Seq (d1, d2) ->
      let (b1, env1) = eval_defs_with_bindings d1 env in
      let (b2, env2) = eval_defs_with_bindings d2 env1 in
      (b1 @ b2, env2)
  | Par (d1, d2) ->
      let (b1, _) = eval_defs_with_bindings d1 env in
      let (b2, _) = eval_defs_with_bindings d2 env in
      let bindings = b1 @ b2 in
      let env' =
        List.fold_right (fun (x, v) acc -> augment_table x v acc) bindings env
      in
      (bindings, env')

and eval_defs defs env =
  let (_, env') = eval_defs_with_bindings defs env in
  env'
;;

let run exp =
  stkmc [] empty_table (compile exp) []
;;



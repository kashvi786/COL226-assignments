type exp = V of string | Abs of string * exp | App of exp * exp | Int of int | Bool of bool
  | Add of exp * exp | Mult of exp*exp | And of exp*exp | Or of exp*exp | Not of exp
  | Eq of exp * exp | Lt of exp * exp | Gt of exp * exp
  | If of exp * exp * exp
  | Pair of exp * exp | Fst of exp | Snd of exp
  | Let of defs * exp
and defs = Def of string * exp | Seq of defs * defs | Par of defs * defs;;

type clos =
  | CExp of exp * table
  | CInt of int
  | CBool of bool
  | CPair of clos * clos
and table = string -> clos;;

let rec close exp env =
  match exp with
  | Int n -> CInt n
  | Bool b -> CBool b
  | Pair (e1, e2) -> CPair (close e1 env, close e2 env)
  | _ -> CExp (exp, env)
;;

let empty_table : table = fun _ -> raise Not_found;;

let augment_table x cl env = fun y -> if y = x then cl else env y;;
let negative_augment_table x env = fun y -> if y = x then raise Not_found else env y;;

let rec bindings_defs defs env =
  match defs with
  | Def (x, e) ->
      let b = (x, close e env) in
      ([b], augment_table x (close e env) env)
  | Seq (d1, d2) ->
      let (b1, env1) = bindings_defs d1 env in
      let (b2, env2) = bindings_defs d2 env1 in
      (b2 @ b1, env2)
  | Par (d1, d2) ->
      let (b1, _) = bindings_defs d1 env in
      let (b2, _) = bindings_defs d2 env in
      let env' =
        List.fold_right (fun (x, c) acc -> augment_table x c acc) (b1 @ b2) env
      in
      (b1 @ b2, env')
;;

let extend_defs defs env =
  let (_, env') = bindings_defs defs env in
  env'
;;

exception Stuck;;

let rec unpack cl =
  match cl with
  | CInt n -> Int n
  | CBool b -> Bool b
  | CPair (c1, c2) -> Pair (unpack c1, unpack c2)
  | CExp (V x, env) ->
    (try unpack (env x) with Not_found -> V x)
  | CExp (Abs (x, e), env) ->
    Abs (x, unpack (close e (negative_augment_table x env)))
  | CExp (App (e1, e2), env) -> App (unpack (close e1 env), unpack (close e2 env))
  | CExp (Pair (e1, e2), env) -> Pair (unpack (close e1 env), unpack (close e2 env))
  | CExp (Fst e, env) -> Fst (unpack (close e env))
  | CExp (Snd e, env) -> Snd (unpack (close e env))
  | CExp (Let (defs, body), env) -> Let (defs, unpack (close body env))
  | CExp (Int n, _) -> Int n
  | CExp (Bool b, _) -> Bool b
  | CExp (Add (e1, e2), env) -> Add (unpack (close e1 env), unpack (close e2 env))
  | CExp (Mult (e1, e2), env) -> Mult (unpack (close e1 env), unpack (close e2 env))
  | CExp (And (e1, e2), env) -> And (unpack (close e1 env), unpack (close e2 env))
  | CExp (Or (e1, e2), env) -> Or (unpack (close e1 env), unpack (close e2 env))
  | CExp (Not e, env) -> Not (unpack (close e env))
  | CExp (Eq (e1, e2), env) -> Eq (unpack (close e1 env), unpack (close e2 env))
  | CExp (Lt (e1, e2), env) -> Lt (unpack (close e1 env), unpack (close e2 env))
  | CExp (Gt (e1, e2), env) -> Gt (unpack (close e1 env), unpack (close e2 env))
  | CExp (If (e1, e2, e3), env) ->
    If (unpack (close e1 env), unpack (close e2 env), unpack (close e3 env))
;;

let rec krivine focus stack =
  match focus with
  | CExp (App (e1, e2), env) ->
      krivine (close e1 env) (close e2 env :: stack)
    | CExp (Let (defs, body), env) ->
      krivine (close body (extend_defs defs env)) stack
  | CExp (V x, env) ->
      (try krivine (env x) stack with Not_found ->
         if stack = [] then focus else raise Stuck)
  | CExp (Abs (x, e), env) ->
      (match stack with
       | arg :: rest -> krivine (close e (augment_table x arg env)) rest
       | [] -> focus)
  | CExp (Int n, _) -> krivine (CInt n) stack
  | CExp (Bool b, _) -> krivine (CBool b) stack
    | CExp (Pair (e1, e2), env) ->
      if stack = [] then CPair (close e1 env, close e2 env) else raise Stuck
    | CExp (Fst e, env) ->
      let v = krivine (close e env) [] in
      (match v with
       | CPair (c1, _) -> krivine c1 stack
       | _ -> raise Stuck)
    | CExp (Snd e, env) ->
      let v = krivine (close e env) [] in
      (match v with
       | CPair (_, c2) -> krivine c2 stack
       | _ -> raise Stuck)
    | CInt _ | CBool _ | CPair _ -> if stack = [] then focus else raise Stuck
  | CExp (Add (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CInt n1, CInt n2) -> if stack = [] then CInt (n1 + n2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (Mult (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CInt n1, CInt n2) -> if stack = [] then CInt (n1 * n2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (And (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CBool b1, CBool b2) -> if stack = [] then CBool (b1 && b2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (Or (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CBool b1, CBool b2) -> if stack = [] then CBool (b1 || b2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (Not e, env) ->
      let v = krivine (close e env) [] in
      (match v with
       | CBool b -> if stack = [] then CBool (not b) else raise Stuck
       | _ -> raise Stuck)
  | CExp (Eq (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CInt n1, CInt n2) -> if stack = [] then CBool (n1 = n2) else raise Stuck
       | (CBool b1, CBool b2) -> if stack = [] then CBool (b1 = b2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (Lt (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CInt n1, CInt n2) -> if stack = [] then CBool (n1 < n2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (Gt (e1, e2), env) ->
      let v1 = krivine (close e1 env) [] in
      let v2 = krivine (close e2 env) [] in
      (match (v1, v2) with
       | (CInt n1, CInt n2) -> if stack = [] then CBool (n1 > n2) else raise Stuck
       | _ -> raise Stuck)
  | CExp (If (e1, e2, e3), env) ->
      let v1 = krivine (close e1 env) [] in
      (match v1 with
       | CBool b ->
           if b then krivine (close e2 env) stack else krivine (close e3 env) stack
       | _ -> raise Stuck)
;;

let call_by_name exp =
  let final_focus = krivine (close exp empty_table) [] in
  unpack final_focus
;;

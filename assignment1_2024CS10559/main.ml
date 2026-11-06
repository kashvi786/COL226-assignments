module type VAR = sig (*parameterisation for variable*)
  type t
  val equal : t-> t-> bool
end

module type SYM = sig (*parameterisation for symbol*)
  type t
  val arity: t-> int
  val equal : t-> t-> bool
  val compare : t -> t -> int
end

module type EXP = sig
  (*stating and defining all types used in this module*)
  type variable 
  type symbol
  type exp = V of variable | Node of symbol * (exp array)
  type sign = symbol array
  type substitution = (variable*exp) list
  type position = int list

  (*specifying all usable functions*)
  val check_sig: sign-> bool
  val wfexp: sign-> exp-> bool
  val ht: exp-> int
  val size: exp-> int
  val vars: exp-> variable array
  val subst: substitution-> exp-> exp
  val compose: substitution-> substitution-> substitution
  val sub_helper: substitution-> variable->exp
  val edit: position-> exp->exp-> exp
  val in_place: substitution-> exp-> exp
end

module MakeExp (VA : VAR) (S : SYM) : EXP with type variable = VA.t and type symbol = S.t = struct
type variable = VA.t
  type symbol = S.t
  type exp = V of variable | Node of symbol * (exp array)
  type sign = symbol array
  type substitution = (variable * exp) list
  type position = int list

  let check_unique s =  (*this function checks if there are any repeated symbols in the signature, creates a temporary copy and sorts it using compare to check adjacent symbols*)
    let copy = Array.copy s in Array.sort S.compare copy ;
  let rec helper i = if i = Array.length copy - 1 then true 
  else if S.equal copy.(i) copy.(i+1) then false else helper (i+1) in helper 0

  let check_sig s = (*this function uses check_unique to check for cymbol uniqueness and checks all the symbols for arity >=0*)
    let b = Array.fold_left (fun e sym -> if S.arity sym < 0 then false else e) true s
    in b && check_unique s

  let finds ps sign = (*this is a helper function that searches through a signature returns the arity of a symbol in the signature*)
  let rec search i = if i = Array.length sign then -1 else 
    if S.equal ps sign.(i) then S.arity sign.(i) else search (i+1) in search 0

  let rec wfexp s ex = (*this function calls finds and checks if exp is wellformed by seeing if the array of each node matches the arity of the symbol, recursive*)
    match ex with 
    | V _ -> true
    | Node(ps, arr) -> let b = (finds ps s = Array.length arr) in
     b && Array.fold_left (fun e exp -> e && wfexp s exp) true arr

  let rec ht ex = (*this function recursively computes the height of the expression, leaf nodes have 0 height*)
    match ex with
    | V _ -> 0
    | Node(s, exps) -> if Array.length exps = 0 then 0 else 1+ Array.fold_left (fun e ex -> max e (ht ex)) 0 exps

  let rec size ex = (*this function recursively computes the size of the expression, leaf nodes have size 1*)
    match ex with
    |V _->1
    |Node(s,exps)-> 1 + Array.fold_left (fun e ex -> e+ size ex) 0 exps

  let insert_helper varslist v = (*this helps insert only a new var into the current varlist*)
    let c = List.fold_left (fun e var -> if VA.equal var v then true else e) false varslist in 
    if c then varslist else v::varslist

  let rec vars ex = (*this gives an array for all variables in the expression*)
    let rec collect exr varslist = match exr with
    |V v -> insert_helper varslist v
    |Node(s, exps) -> Array.fold_left (fun e ex -> collect ex e) varslist exps
    in Array.of_list (collect ex [])

  let rec sub_helper sub v = match sub with (*helper to help in substituting a value given a substitution, returns the same variable if it has no mapping, so effectively makes substition into a total function*)
  |[] -> V v
  |(var, ex)::rest -> if VA.equal var v then ex else sub_helper rest v

  let rec subst sub ex = match ex with (*applies substitution to expression recursively, returns a new expression with variables replaced*)
    | V v -> sub_helper sub v
    | Node(s,exps) -> Node(s, Array.map (subst sub) exps)

  let compose f g = (*composes to substitutions to give another substitution, here does g(f), basically composes directly first then adds whatever variables from g taht have not been mapped yet*)
    let compose_helper f g = List.fold_left (fun e (var, ex) -> if subst g ex = V var then e else (var, subst g ex) :: e) [] f 
    in List.fold_left (fun e (v,exr) -> if List.exists (fun (var,_) -> VA.equal var v) f then e else (v,exr)::e) (compose_helper f g) g

  let edit position exp new_exp = (*edits expression at given position to put new_exp there and returns the changed expression, works by removing head from the int list of position every time and applying recursively on tail*)
    let rec helper position exp = match exp with
      |V v -> if position = [] then new_exp else failwith "invalid pos"
      |Node(s, exps) -> if position = [] then new_exp 
      else let p = List.hd position in Node(s,Array.mapi (fun i exp -> if i =p then helper (List.tl position) exp else exp) exps)
    in helper position exp

  let rec in_place sub ex = match ex with (*changes the function in_place, returns unit type. note that it fails on the expression being just a single variable, 
  since in that case the whole expression will get changed and there is no parent to hinge it to that holds the charactersitic of the original expression*)
    | V v -> sub_helper sub v
    | Node(s,exps) -> let rec helper i = if i >= Array.length exps then ()
     else (match exps.(i) with 
     | V v-> exps.(i) <- sub_helper sub v ; helper(i+1)
     | Node(_,_) -> ignore(in_place sub exps.(i)); helper (i+1)) 
    in helper 0; ex

end




module Pred (E : EXP) = struct (*defining struct for predicates*)
  type pred_symbol = string * int
  type pred_sign = pred_symbol array
  type pred =
    | T
    | F
    | Pred of pred_symbol * (E.exp array)
    | Not of pred
    | And of pred * pred
    | Or of pred * pred

  let lookup ps sign = (*helper function to find parity of a pred_symbol in a given signature*)
  let (name, _) = ps in 
  let rec search i = if i = Array.length sign then -1 else 
    let (n,a) = sign.(i) in if n = name then a else search (i+1)
  in search 0

  let rec wff pred1 s es = (*checks if a pre predicate is well formed according to the specified arities in the signature, es is E.sign, applies recusrively wheever applies*)
    match pred1 with
    |T|F -> true
    |Not pred2 -> wff pred2 s es
    |And (predi, predj) -> wff predi s es && wff predj s es
    |Or (predi, predj) -> wff predi s es && wff predj s es
    |Pred(p,a) -> let k = lookup p s in k = Array.length a && Array.fold_left (fun e ex -> e && E.wfexp es ex) true a

  let rec psubst p s = (*returns a new predicate with all the required variables substituted given a substitution (from E), applies recursively wheever applies*)
    match p with
    |T -> T
    |F-> F
    |Not pred2 -> Not (psubst pred2 s)
    |And(predi, predj) -> And( psubst predi s, psubst predj s)
    |Or(predi, predj) -> Or( psubst predi s, psubst predj s)
    |Pred(d,a) -> Pred(d, Array.map (E.subst s) a)

  let rec wp x e p = (*returns a predicate where x is replaced for a given e wherever found, just recursively checks for x, returns a new changed predicate*)
    match p with
    |T->T
    |F->F
    |Not pred2 -> Not (wp x e pred2)
    |And(predi, predj) -> And( wp x e predi, wp x e predj)
    |Or(predi, predj) -> Or( wp x e predi, wp x e predj)
    |Pred(d,a) -> Pred(d, Array.map (fun ex -> E.subst [(x,e)] ex) a)   

end


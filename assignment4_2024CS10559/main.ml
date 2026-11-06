type comb = Vc of string | I | K | S | Appc of comb * comb;;

type lam = V of string | Lam of string * lam | App of lam * lam;;

let rec free_in x p =
  match p with
  | Vc y -> x = y
  | I | K | S -> false
  | Appc (p1, p2) -> free_in x p1 || free_in x p2

let rec abstc p x = if not (free_in x p) then Appc (K, p)
  else match p with 
  | Vc y -> if y = x then I else Appc (K,Vc y)
  | I | K | S -> Appc (K, p)
  | Appc (p1, p2) -> Appc (Appc (S, abstc p1 x), abstc p2 x)

let rec abs (x, e) =
  match e with
  | V y -> if y = x then I else Appc (K, Vc y)
  | App (e1, e2) -> Appc (Appc (S, abs (x, e1)), abs (x, e2))
  | Lam (y, e1) -> abstc (abs (y, e1)) x

let rec to_comb e =
  match e with
  | V x -> Vc x
  | App (e1, e2) -> Appc (to_comb e1, to_comb e2)
  | Lam (x, e1) -> abs (x, e1)

let rec wnf (c, s) =
  match (c, s) with
  | (I, s1::s') -> wnf (s1, s')
  | (K, s1::s2::s') -> wnf (s1, s')
  | (S, s1::s2::s3::s') ->
      wnf (Appc (Appc (s1, s3), Appc (s2, s3)), s')
  | (Appc (c1, c2), s') -> wnf (c1, c2::s')
  | _ -> unstack (c, s)

and unstack (c, s) =
  match (c, s) with
  | (c', []) -> c'
  | (c', s1::s') ->
      let ans = wnf (s1, []) in
      unstack (Appc (c', ans), s')

let eval e =
  let c = to_comb e in
  wnf (c, [])

let rec string_of_comb c =
  match c with
  | Vc x -> x
  | I -> "I"
  | K -> "K"
  | S -> "S"
  | Appc (c1, c2) ->
      "(" ^ string_of_comb c1 ^ " " ^ string_of_comb c2 ^ ")"
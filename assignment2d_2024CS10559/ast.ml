open Bigint

type atom =
  | Num of Bigint.BigInt.bigint
  | Id of string
  | True
  | Nil

type exp =
  | A of atom
  | L of exp list

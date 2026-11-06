open Ast

let string_of_atom = function
  | Num n -> Bigint.BigInt.pretty_print n
  | Id s -> s
  | True -> "t"
  | Nil -> "()"

let rec string_of_exp = function
  | A atom -> string_of_atom atom
  | L expressions ->
      "(" ^ String.concat " " (List.map string_of_exp expressions) ^ ")"

let print_parsed = function
  | L expressions -> List.iter (fun expression -> print_endline (string_of_exp expression)) expressions
  | expression -> print_endline (string_of_exp expression)

let () =
  let lexbuf = Lexing.from_channel stdin in
  try
    let parsed = Parser.main Lexer.token lexbuf in
    print_parsed parsed
  with
  | Lexer.Eof -> print_endline "EOF"
  | Parsing.Parse_error -> print_endline "Parse error"
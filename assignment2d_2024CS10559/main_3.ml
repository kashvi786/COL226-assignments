open Ast

let string_of_atom_raw = function
  | Num n -> "Num(" ^ Bigint.BigInt.pretty_print n ^ ")"
  | Id s -> "Id(" ^ s ^ ")"
  | True -> "True"
  | Nil -> "Nil"

let rec string_of_exp_raw = function
  | A atom -> "A(" ^ string_of_atom_raw atom ^ ")"
  | L expressions ->
      "L[" ^ String.concat "; " (List.map string_of_exp_raw expressions) ^ "]"

let read_all_input () =
  let buf = Buffer.create 1024 in
  (try
    while true do
      Buffer.add_string buf (input_line stdin);
      Buffer.add_char buf '\n'
    done
  with End_of_file -> ());
  Buffer.contents buf

let blocks_of_input input =
  let lines = String.split_on_char '\n' input in
  let rec loop curr acc = function
    | [] ->
        if curr = [] then List.rev acc
        else List.rev (String.concat "\n" (List.rev curr) :: acc)
    | line :: rest ->
        if String.trim line = "" then
          if curr = [] then loop [] acc rest
          else loop [] (String.concat "\n" (List.rev curr) :: acc) rest
        else
          loop (line :: curr) acc rest
  in
  loop [] [] lines

let parse_string s =
  let lexbuf = Lexing.from_string s in
  Parser.main Lexer.token lexbuf

let () =
  let input = read_all_input () in
  let blocks = blocks_of_input input in
  List.iteri
    (fun i block ->
      print_endline ("[Parser " ^ string_of_int (i + 1) ^ "]");
      print_endline block;
      (try
        let parsed = parse_string block in
        (match parsed with
        | L exprs -> List.iter (fun e -> print_endline (string_of_exp_raw e)) exprs
        | e -> print_endline (string_of_exp_raw e))
      with Parsing.Parse_error -> print_endline "Parse error");
      print_endline "")
    blocks
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

let typecheck_and_print e =
  print_string (string_of_exp e ^ " : ");
  (try
    let t = Type_cheker.typecheck e in
    print_endline (Type_cheker.string_of_typ t)
  with Failure msg ->
    print_endline ("TypeError: " ^ msg))

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
      print_endline ("[Typecheck " ^ string_of_int (i + 1) ^ "]");
      (try
        let parsed = parse_string block in
        (match parsed with
        | L exprs -> List.iter typecheck_and_print exprs
        | e -> typecheck_and_print e)
      with Parsing.Parse_error -> print_endline "Parse error");
      print_endline "")
    blocks

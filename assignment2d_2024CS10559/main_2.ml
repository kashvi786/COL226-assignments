module BI = Bigint.BigInt

let string_of_token = function
  | Parser.NUM n -> "NUM(" ^ BI.pretty_print n ^ ")"
  | Parser.PLUS -> "PLUS"
  | Parser.SUB -> "SUB"
  | Parser.TIMES -> "TIMES"
  | Parser.DIV -> "DIV"
  | Parser.MODULO -> "MOD"
  | Parser.LEFTPAREN -> "LPAREN"
  | Parser.RIGHTPAREN -> "RPAREN"
  | Parser.QUOTE -> "QUOTE"
  | Parser.TRUE -> "TRUE"
  | Parser.NIL -> "NIL"
  | Parser.NOT_EQUALS -> "NOT_EQUALS"
  | Parser.LESS_THAN_EQUALS -> "LESS_EQ"
  | Parser.GREATER_THAN_EQUALS -> "GREATER_EQ"
  | Parser.EQUALS -> "EQUALS"
  | Parser.LESS_THAN -> "LESS"
  | Parser.GREATER_THAN -> "GREATER"
  | Parser.QUOTE_KW -> "QUOTE_KW"
  | Parser.ATOM -> "ATOM"
  | Parser.EQ -> "EQ"
  | Parser.CONS -> "CONS"
  | Parser.CAR -> "CAR"
  | Parser.CDR -> "CDR"
  | Parser.COND -> "COND"
  | Parser.LAMBDA -> "LAMBDA"
  | Parser.LABEL -> "LABEL"
  | Parser.DEFUN -> "DEFUN"
  | Parser.COMPOUNDED_KEYWORD s -> "COMPOUNDED(" ^ s ^ ")"
  | Parser.IDENT s -> "IDENT(" ^ s ^ ")"
  | Parser.EOF -> "EOF"

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

let tokens_of_string s =
  let lexbuf = Lexing.from_string s in
  let rec loop acc =
    match Lexer.token lexbuf with
    | Parser.EOF -> List.rev ("EOF" :: acc)
    | tok -> loop (string_of_token tok :: acc)
  in
  loop []

let () =
  let input = read_all_input () in
  let blocks = blocks_of_input input in
  List.iteri
    (fun i block ->
      print_endline ("[Lexer " ^ string_of_int (i + 1) ^ "]");
      print_endline block;
      let tokens = tokens_of_string block in
      print_endline ("TOKENS: " ^ String.concat " " tokens);
      print_endline "")
    blocks
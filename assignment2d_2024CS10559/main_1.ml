open Bigint

module BI = Bigint.BigInt

let my_true = BI.greater_than (BI.int_to_bigint 1) (BI.int_to_bigint 0)
let my_false = BI.greater_than (BI.int_to_bigint 0) (BI.int_to_bigint 1)

let string_of_mybool b =
  if b = my_true then "T" else if b = my_false then "F" else "?"

let split_words s =
  let s = String.map (fun c -> if c = '\t' then ' ' else c) s in
  s
  |> String.split_on_char ' '
  |> List.filter (fun w -> w <> "")

let is_comment_line s =
  let t = String.trim s in
  t = "" || t.[0] = ';' || t.[0] = '#'

let bigint_of_string s =
  let s = String.trim s in
  if s = "" then failwith "empty bigint"
  else
    let is_neg = s.[0] = '-' in
    let digits =
      if is_neg then String.sub s 1 (String.length s - 1) else s
    in
    if digits = "" then failwith "invalid bigint"
    else
      let ten = BI.int_to_bigint 10 in
      let acc = ref (BI.int_to_bigint 0) in
      String.iter
        (fun ch ->
          if ch < '0' || ch > '9' then
            failwith ("invalid digit: " ^ String.make 1 ch)
          else
            let d = BI.int_to_bigint (Char.code ch - Char.code '0') in
            acc := BI.add (BI.multiply !acc ten) d)
        digits;
      if is_neg then BI.unary_negation !acc else !acc

let run_line line =
  let parts = split_words line in
  match parts with
  | ["INT"; n] ->
      let b = bigint_of_string n in
      print_endline ("int_to_bigint " ^ n ^ " = " ^ BI.pretty_print b)
  | ["NEG"; n] ->
      let b = bigint_of_string n in
      let r = BI.unary_negation b in
      print_endline ("neg " ^ n ^ " = " ^ BI.pretty_print r)
  | ["ABS"; n] ->
      let b = bigint_of_string n in
      let r = BI.abs b in
      print_endline ("abs " ^ n ^ " = " ^ BI.pretty_print r)
  | ["ADD"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      let r = BI.add x y in
      print_endline (a ^ " + " ^ b ^ " = " ^ BI.pretty_print r)
  | ["SUB"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      let r = BI.subtract x y in
      print_endline (a ^ " - " ^ b ^ " = " ^ BI.pretty_print r)
  | ["MUL"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      let r = BI.multiply x y in
      print_endline (a ^ " * " ^ b ^ " = " ^ BI.pretty_print r)
  | ["QUO"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      (try
        let r = BI.quotient x y in
        print_endline ("quotient(" ^ a ^ ", " ^ b ^ ") = " ^ BI.pretty_print r)
      with BI.DivisionByZero ->
        print_endline ("quotient(" ^ a ^ ", " ^ b ^ ") = DivisionByZero"))
  | ["REM"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      (try
        let r = BI.remainder x y in
        print_endline ("remainder(" ^ a ^ ", " ^ b ^ ") = " ^ BI.pretty_print r)
      with BI.DivisionByZero ->
        print_endline ("remainder(" ^ a ^ ", " ^ b ^ ") = DivisionByZero"))
  | ["GT"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      print_endline (a ^ " > " ^ b ^ " = " ^ string_of_mybool (BI.greater_than x y))
  | ["EQ"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      print_endline (a ^ " = " ^ b ^ " = " ^ string_of_mybool (BI.equal x y))
  | ["LT"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      print_endline (a ^ " < " ^ b ^ " = " ^ string_of_mybool (BI.less_than x y))
  | ["GE"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      print_endline (a ^ " >= " ^ b ^ " = " ^ string_of_mybool (BI.great_or_equal x y))
  | ["LE"; a; b] ->
      let x = bigint_of_string a in
      let y = bigint_of_string b in
      print_endline (a ^ " <= " ^ b ^ " = " ^ string_of_mybool (BI.less_or_equal x y))
  | _ ->
      print_endline ("Skipping unrecognized line: " ^ line)

let read_lines () =
  let rec loop acc =
    try
      let line = input_line stdin in
      loop (line :: acc)
    with End_of_file -> List.rev acc
  in
  loop []

let () =
  let lines = read_lines () in
  List.iter
    (fun line ->
      if not (is_comment_line line) then run_line line)
    lines

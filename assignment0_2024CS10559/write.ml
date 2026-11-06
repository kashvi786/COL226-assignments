open Printf

let read_file filename =
  let input = open_in filename in
  let rec read () =
    try
      let line = input_line input in
      line :: read ()
    with End_of_file ->
      close_in input;
      []
  in
  read ()

let get_size lines =
  match lines with
  | [] -> failwith "no input"
  | x :: _ ->
      let n = String.length x in
      let ok = List.fold_left (fun e s -> e && (String.length s = n)) true lines
      in
      if ok then n else failwith "not square"


let get_ints line = 
  let parts = 
    line
    |> String.split_on_char ' '
    |> List.filter (fun s -> s <> "")
  in 
  let rec only_ints lst =
    match lst with
    | [] -> []
    | x::xs -> (try int_of_string x:: only_ints xs
      with _ -> only_ints xs)
  in
  only_ints parts

let read_sat_file filename =
  let input = open_in filename in
  let rec read e =
    try
      let line = input_line input in
      read (get_ints line @ e)
    with End_of_file ->
      close_in input;
      List.rev e
  in
  read []

let is_unsat lines =
  List.fold_left (fun e s ->
    e || (String.trim s = "s UNSATISFIABLE")
  ) false lines

let decode_var size k =
  let id0 = k - 1 in
  let i = (id0/(size*size)) + 1 in
  let rem = id0 mod (size*size) in
  let j = (rem/size) + 1 in
  let v = (rem mod size) + 1 in (i, j, v)

let int_to_char size v =
  if size = 9 then
    Char.chr (int_of_char '0' + v) 
  else if size = 16 then
    if v = 1 then '0'
    else if v>= 2 && v <= 10 then Char.chr (int_of_char '0'+(v - 1))
    else Char.chr (int_of_char 'A'+(v - 11))
  else
    failwith "invalid size"

let get_positives sat_output_file = 
  read_sat_file sat_output_file
  |> List.filter (fun k -> k > 0)

let decode_positives size pos = 
  List.map (decode_var size) pos


let find_value decoded i j =
  let rec collect xs =
    match xs with
    | [] -> 0
    | (ri, rj, v) :: rest ->
        if ri = i && rj = j then v else collect rest
  in
  collect decoded
let write_grid size decoded outFile =
  let output = open_out outFile in
  let vals = List.init size (fun k -> k + 1) in

  List.fold_left (fun () i ->
    let row_chars =
      List.map (fun j ->
        let v = find_value decoded i j in
        int_to_char size v
      ) vals
    in
    Printf.fprintf output "%s\n"
      (String.concat "" (List.map (String.make 1) row_chars));
    ()
  ) () vals;

  close_out output

let clause_to_cnf cl = 
  let body = List.fold_left (fun e lit -> e ^ string_of_int lit ^ " ") "" cl in
  body^"0\n"

let read_dimacs cnf_output =
  let lines = read_file cnf_output in
  let header =
    List.fold_left (fun e line ->
      if e <> "" then e
      else
        let t = String.trim line in
        if t <> "" && t.[0] = 'p' then t else ""
    ) "" lines
  in
  if header = "" then failwith "No DIMACS header found";

  let parts =
    header
    |> String.split_on_char ' '
    |> List.filter (fun s -> s <> "")
  in
  match parts with
  | ["p"; "cnf"; a; b] -> (int_of_string a, int_of_string b)
  | _ -> failwith "bad DIMACS header format"

let make_extra_clause pos =
  List.map (fun x -> -x) pos

let add_new first_cnf second_cnf extra =
  let lines = read_file first_cnf in
  let (num_vars,num_clauses) = read_dimacs first_cnf in
  let output = open_out second_cnf in
  fprintf output "p cnf %d %d\n" num_vars (num_clauses + 1);

  List.fold_left (fun () line ->
    let t = String.trim line in
    if t <> "" && t.[0] <> 'c' && t.[0] <> 'p' then
      fprintf output "%s\n" t;
    ()
  ) () lines;

  fprintf output "%s" (clause_to_cnf extra);

  close_out output

let solve_and_write_temps inputFile sat_output_file original_cnf original_decoded new_cnf=
  let lines = read_file inputFile in
  let size = get_size lines in

  let sat_lines = read_file sat_output_file in
  if is_unsat sat_lines then
    let output = open_out "temp1.txt" in
    fprintf output "UNSAT\n";
    close_out output
  else (
    let positives = get_positives sat_output_file in
    let decoded = decode_positives size positives in
    write_grid size decoded original_decoded;
    let extra_clause = make_extra_clause positives in
    add_new original_cnf new_cnf extra_clause
  )

let () =
  if Array.length Sys.argv <> 6 then
    failwith "Usage: ./write <input.txt> <sat_output.txt> <output.cnf> <temp1.txt> <output2.cnf>";

  let inputFile = Sys.argv.(1) in
  let sat_output_file = Sys.argv.(2) in
  let original_cnf = Sys.argv.(3) in
  let original_decoded = Sys.argv.(4) in
  let new_cnf = Sys.argv.(5) in

  solve_and_write_temps inputFile sat_output_file original_cnf original_decoded new_cnf
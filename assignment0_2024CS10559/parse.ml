type lit = int
type clause = lit list

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
      if List.for_all (fun s -> String.length s = n) lines then n
      else failwith "not square"

let make_var size =
  fun i j v -> size * size * (i - 1) + size * (j - 1) + v

let char_to_value size c =
  match size with
  | 9 -> (match c with
       | '1'..'9' -> int_of_char c - int_of_char '0'
       | '.' -> 0
       | _ -> failwith "invalid char for 9x9")
  | 16 -> (match c with
       | '.' -> 0
       | '0' -> 1
       | '1'..'9' -> (int_of_char c - int_of_char '0') + 1
       | 'A'..'F' -> (int_of_char c - int_of_char 'A') + 11
       | _ -> failwith "Invalid char for 16x16")
  | _ ->
      failwith "invalid size"

let parse_file filename =
  let lines = read_file filename in
  let size = get_size lines in
  let var = make_var size in

  let values = List.init size (fun k -> k + 1) in

  let (given_vars , _) =
    List.fold_left (fun (e,i) line ->
      e @ (List.fold_left (fun f j ->
        let v = char_to_value size line.[j-1] in
        if v = 0 then f else f @ [[var i j v]]
      ) [] values),
      i+1) ([],1) lines
    in

  (size, given_vars)

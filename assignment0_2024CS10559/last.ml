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

let is_unsat filename =
  let lines = read_file filename in
  List.fold_left (fun e s ->
    e || (String.trim s = "s UNSATISFIABLE")
  ) false lines

let copy_file_to_out inFile output =
  let lines = read_file inFile in
  List.fold_left (fun () line ->
    fprintf output "%s\n" line;
    ()
  ) () lines

let print_grid outFile tempfile1 sat_out_1 sat_out_2 caseSOL=
  let unsat1 = is_unsat sat_out_1 in

  if unsat1 then (
    let out_sols = open_out caseSOL in
    fprintf out_sols "NO SOLUTION\n";
    close_out out_sols;
    let output = open_out outFile in
    fprintf output "NO SOLUTION\n";
    close_out output
  )
  else (
    let unsat2 = is_unsat sat_out_2 in
    let out_sols = open_out caseSOL in
    

    if unsat2 then
      fprintf out_sols "UNIQUE\n"
    else
      fprintf out_sols "MULTIPLE\n";
    close_out out_sols;

    let output = open_out outFile in

    copy_file_to_out tempfile1 output;

    close_out output
  )

  


let () =
  if Array.length Sys.argv <> 6 then
    failwith "Usage: ./final <sat_out_1.txt> <sat_out_2.txt> <temp1.txt> <output.txt> <case_of_output.txt";

  let sat_out_1 = Sys.argv.(1) in
  let sat_out_2 = Sys.argv.(2) in
  let tempfile1 = Sys.argv.(3) in
  let outFile = Sys.argv.(4) in
  let caseSOL = Sys.argv.(5) in
  print_grid outFile tempfile1 sat_out_1 sat_out_2 caseSOL

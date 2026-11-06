open Printf
type lit = int
type clause = lit list
type cnf = clause list

let write_dimacs filename num_vars cnf =
  let output = open_out filename in
  fprintf output "p cnf %d %d\n" num_vars (List.length cnf);

  List.fold_left (fun () cl -> List.fold_left (fun () lit -> fprintf output "%d " lit; () ) 
  () cl; fprintf output "0\n"; ()) () cnf;
  close_out output


let () =
  let inputFile = Sys.argv.(1) in
  let outputFile = Sys.argv.(2) in

  let (size, givens) = Parse.parse_file inputFile in
  let normal = Constraints.generate_all_constraints size in

  let cnf = normal @ givens in
  let num = size * size * size in

  write_dimacs outputFile num cnf

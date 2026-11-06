type lit = int
type clause = lit list
type cnf = clause list

let vals n =
  List.init n (fun k -> k + 1)

let generate_all_constraints size =
  let var i j v =
    size * size * (i - 1) + size * (j - 1) + v
  in

  let r = int_of_float (sqrt (float_of_int size)) in

  let values = vals size in
  let rows = values in
  let cols = values in

  let cells =
    List.fold_left (fun e i -> 
      List.fold_left (fun e j -> (i, j) :: e) e cols
      ) [] rows
  in

  (* 1 *)
  let at_least_one i j = List.map (fun v -> var i j v) values
  in

  let least_one_constraints =
    List.map (fun (i, j) -> at_least_one i j) cells
  in

  (* 2 *)
  let at_most_one i j = List.fold_left (fun e v1 -> 
    List.fold_left (fun e v2 -> if v1 < v2 then [-(var i j v1); -(var i j v2)] :: e
  else e) e values) [] values
  in

  let most_one_constraints =  List.fold_left (fun e (i,j) -> let thisCNF = at_most_one i j in 
    List.fold_left (fun e cl -> cl::e) e thisCNF
    )[] cells
  in

  (* 3 *)
  let row_cons i v = List.fold_left (fun e j1 -> 
    List.fold_left (fun e j2 -> if j1 < j2 then [-(var i j1 v); -(var i j2 v)] :: e
  else e) e cols
  ) [] cols
  in

  let row_constraints =  List.fold_left (fun e i -> 
    List.fold_left (fun e v -> let thisCNF = row_cons i v in 
      List.fold_left(fun e cl->cl::e) e thisCNF) e values
    )[] rows
  in

  (* 4 *)
  let col_cons j v = 
    List.fold_left (fun e i1 -> 
      List.fold_left (fun e i2 -> if i1 < i2 then [-(var i1 j v); -(var i2 j v)] :: e
  else e) e rows
  ) [] rows
  in

  let col_constraints =  List.fold_left (fun e i -> 
    List.fold_left (fun e v -> let thisCNF = col_cons i v in 
      List.fold_left(fun e cl->cl::e) e thisCNF) e values
    )[] cols
  in

  (* 5 *)
  (* let row_at_least_once i v = List.map (fun j -> var i j v) cols
  in

  let row_at_least_constraints = List.fold_left (fun e i -> List.fold_left (fun e v -> (row_at_least_once i v) :: e) e values) [] rows
  in

  (* 6 *)
  let col_at_least_once j v = List.map (fun i -> var i j v) rows
  in

  let col_at_least_constraints = List.fold_left (fun e j -> List.fold_left (fun e v -> (col_at_least_once j v) :: e) e values) [] cols
  in

  (* 7 *)
  let box_at_least_once box_row box_col v =
    let start_i = r * (box_row - 1) + 1 in
    let start_j = r * (box_col - 1) + 1 in
    let offsets = List.init r (fun k -> k) in
    List.fold_left (fun e di -> List.fold_left (fun e dj -> let i = start_i + di in let j = start_j + dj in (var i j v) :: e) e offsets) [] offsets
  in *)

  (* 8 *)
  let box_at_most_once box_row box_col v =
    let start_i = r * (box_row - 1) + 1 in
    let start_j = r * (box_col - 1) + 1 in
    let offsets = List.init r (fun k -> k) in

    let positions =
      List.fold_left (fun e di -> 
        List.fold_left (fun e dj -> let i = start_i + di in let j = start_j + dj in (i, j) :: e) e offsets) [] offsets
    in

    List.fold_left (fun e (i1, j1) -> 
      List.fold_left (fun e (i2, j2) -> if (i1 < i2) || (i1 = i2 && j1 < j2) then [-(var i1 j1 v); -(var i2 j2 v)] :: e
    else e) e positions) [] positions
  in

  let box_ids = vals r in

  (* let box_at_least_constraints = List.fold_left (fun e box_row -> List.fold_left (fun e box_col -> List.fold_left (fun e v ->(box_at_least_once box_row box_col v) :: e) e values) e box_ids) [] box_ids
  in *)

  let box_at_most_constraints =
    List.fold_left (fun e box_row -> 
      List.fold_left (fun e box_col -> 
        List.fold_left (fun e v -> let thisCNF = box_at_most_once box_row box_col v in 
          List.fold_left (fun e cl -> cl :: e) e thisCNF ) e values) e box_ids) [] box_ids
  in


  least_one_constraints
  @ most_one_constraints
  @ row_constraints
  @ col_constraints
  (* @ row_at_least_constraints
  @ col_at_least_constraints
  @ box_at_least_constraints *)
  @ box_at_most_constraints



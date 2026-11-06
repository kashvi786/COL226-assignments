open Ast

type typ =
    | TInt
    | TBool
    | TNil (* works as both Bool and List(0)*)
    | TList of int
    | TFun  of typ list * typ
    | TVar  of string

let tvar_env : (string * typ) list ref = ref []

let rec resolve_typ = function
    | TVar v as t ->
        (match List.assoc_opt v !tvar_env with
        | Some t' -> resolve_typ t'
        | None -> t)
    | TFun (ps, r) -> TFun (List.map resolve_typ ps, resolve_typ r)
    | (TInt | TBool | TNil | TList _) as t -> t

let rec string_of_typ t =
    match resolve_typ t with
    | TInt -> "Int"
    | TBool -> "Bool"
    | TNil-> "Nil"
    | TList n -> "List(" ^ string_of_int n ^ ")"
    | TVar  s -> "'" ^ s
    | TFun([], r) -> "(... -> " ^ string_of_typ r ^ ")"
    | TFun(ps, r) ->
        "(" ^ String.concat " * " (List.map string_of_typ ps)
        ^ " -> " ^ string_of_typ r ^ ")"

let base_env = [
    ("+", TFun([], TInt));
    ("-", TFun([TInt; TInt], TInt));
    ("*", TFun([], TInt));
    ("div", TFun([TInt; TInt], TInt));
    ("mod", TFun([TInt; TInt], TInt));
    ("car", TFun([TList 1], TVar "a"));
    ("cdr", TFun([TList 1], TList 0)); 
    ("cons", TFun([TVar "a"; TList 0], TList 1));
    ("atom", TFun([TVar "a"], TBool));
    ("eq", TFun([TVar "a"; TVar "a"], TBool));
    ("and", TFun([TBool; TBool], TBool));
    ("or", TFun([TBool; TBool], TBool));
    ("not", TFun([TBool], TBool));
    ("=/=", TFun([TInt; TInt], TBool));
    ("=", TFun([TInt; TInt], TBool));
    ("<", TFun([TInt; TInt], TBool));
    (">", TFun([TInt; TInt], TBool));
    ("<=", TFun([TInt; TInt], TBool));
    (">=", TFun([TInt; TInt], TBool));
    ("quote", TFun([TVar "a"], TVar "a"));
]

(* mutable so that defun bindings persist across top-level expressions *)
let global_env = ref base_env

let lookup env x =
    match List.assoc_opt x env with
    | Some t -> t
    | None -> failwith ("Unbound variable: " ^ x)

let unify t1 t2 =
    let t1 = resolve_typ t1 in
    let t2 = resolve_typ t2 in
    let bind_tvar v t =
        match resolve_typ t with
        | TVar v' when v = v' -> ()
        | t' -> tvar_env := (v, t') :: !tvar_env
    in
    match (t1, t2) with
    | (TInt, TInt) |(TBool, TBool)-> ()
    | (TNil, TNil) -> ()
    | (TNil, TBool) | (TBool, TNil)->()
    | (TNil, TList _)| (TList _, TNil) -> () 
    | (TList 0,TList _) | (TList _, TList 0) ->()
    | (TList n1, TList n2) when n1 = n2 -> ()
    | (TVar v1, TVar v2) when v1 = v2 -> ()
    | (TVar v, t) | (t, TVar v) -> bind_tvar v t
    | _ -> failwith ("Type mismatch: " ^ string_of_typ t1 ^ " vs " ^ string_of_typ t2)


let is_it_cadr s = (*helper to identify cadr type fns*)
    let n = String.length s in
    if n < 3 || s.[0] <> 'c' || s.[n - 1] <> 'r' then false
    else begin
        let ok = ref true in
        for i = 1 to n - 2 do
        if s.[i] <> 'a' && s.[i] <> 'd' then ok := false 
        done; !ok
    end

let cadr_required_len s =
    let n = String.length s in
    let trailing_d = ref 0 in
    let i = ref (n - 2) in
    while !i > 0 && s.[!i] = 'd' do
        incr trailing_d;
        decr i
    done;
    let has_a = ref false in
    for j = 1 to n - 2 do
        if s.[j] = 'a' then has_a := true
    done;
    if !has_a then !trailing_d + 1 else !trailing_d

let rec typ_of env e =
    match e with
    | A atom -> typ_of_atom env atom
    | L lst  -> typ_of_list env lst

and typ_of_atom env atom =
    match atom with
    | Num _ -> TInt
    | Id x  -> lookup env x
    | True  -> TBool
    | Nil   -> TNil

and typ_of_list env lst =
    match lst with
    | [] -> TNil
    | [A (Id "quote"); arg] ->
        typ_of_quoted arg
    | A (Id "atom") :: [arg] ->
        let _ = typ_of env arg in
        TBool

    | A (Id "lambda") :: rest ->
        typ_of_lambda env rest

    | A (Id "label") :: [A (Id fname); func] ->
        let new_env = match func with
        | L (A (Id "lambda") :: L params :: _) ->
            let param_names = List.map (function
                | A (Id x) -> x
                | _ -> failwith "label: parameter must be an identifier"
            ) params in
            let param_types = List.map (fun x -> TVar x) param_names in
            let self_ty = TFun (param_types, TVar "ret") in
            (fname, self_ty) :: env
        | _ -> (fname, TVar fname) :: env in
        typ_of new_env func
    | A (Id "defun") :: A (Id fname) :: [L params; body] ->
        let param_names = List.map (function
        | A (Id x) -> x
        | _ -> failwith "defun: parameter must be an identifier"
        ) params in
        let param_types = List.map (fun x -> TVar x) param_names in
        let self_ty = TFun (param_types, TVar "ret") in
        let new_env =
            List.combine param_names param_types @ [(fname, self_ty)] @ env
        in
        let ret_type = typ_of new_env body in
        let fun_ty = TFun (List.map resolve_typ param_types, resolve_typ ret_type) in
        global_env := (fname, fun_ty) :: !global_env;
        fun_ty

    | A (Id "cond") :: clauses ->
        let b_types = List.map (function
            | L [cond_expr; result_expr] ->
                let ct = typ_of env cond_expr in
                unify ct TBool;
                typ_of env result_expr
            | _ -> failwith "each clause must be a 2-element list"
        ) clauses in
        (match b_types with
        | [] -> failwith "no clauses"
        | t :: rest ->
            List.iter (fun t' -> unify t t') rest;
            t)

    | A (Id "eq") :: args ->
        if List.length args <> 2 then failwith "eq operator requires exactly 2 arguments"
        else begin
            let t1 = typ_of env (List.nth args 0) in
            let t2 = typ_of env (List.nth args 1) in
            (match (resolve_typ t1, resolve_typ t2) with
             | (TVar _, _) | (_, TVar _) -> ()
             | (r1, r2) -> unify r1 r2);
            TBool
        end
    | A (Id "cons") :: args ->
        if List.length args <> 2 then failwith "cons operator requires exactly 2 arguments"
        else
            let _  = typ_of env (List.nth args 0) in
            let t2 = typ_of env (List.nth args 1) in
            (match t2 with
            | TList n -> TList (n + 1)
            | TNil -> TList 1
            | TVar _ -> TList 1
            | _ -> failwith "second argument must be a list for cons")
    | A (Id "car") :: [arg] ->
        let t = typ_of env arg in
        (match t with
        | TList n when n > 0 -> TVar "a"
        | TList 0 | TNil -> failwith "car: cannot apply to empty list"
        | TVar _ -> TVar "a" 
        | _ -> failwith "argument must be a list for car")

    | A (Id "cdr") :: [arg] ->
        let t = typ_of env arg in
        (match t with
        | TList n when n > 0 -> TList (n - 1)
        | TList 0 | TNil -> failwith "cdr cannot apply to empty list"
        | TVar _ -> TVar "a" 
        | _ -> failwith "cdr argument must be a list")
    | A (Id op) :: [arg] when is_it_cadr op ->
        let t = typ_of env arg in
        let req_len = cadr_required_len op in
        (match t with
        | TList n when n >= req_len -> TVar "a"
        | TList _ | TNil -> failwith (op ^ " cannot apply to empty list")
        | TVar _ -> TVar "a"
        | _ -> failwith (op ^ " argument must be a list"))
    | L (A (Id "lambda") :: L params :: body :: []) :: args ->
        let param_names = List.map (function
            | A (Id x) -> x
            | _ -> failwith "lambda parameter must be an identifier"
        ) params in
        let nparams = List.length param_names
        and nargs = List.length args in
        if nparams <> nargs then
            failwith (Printf.sprintf
            "Arity mismatch: expected %d argument(s), got %d" nparams nargs)
        else
            let arg_types = List.map (typ_of env) args in
            let new_env = List.combine param_names arg_types @ env in
            typ_of new_env body
    | head :: args ->
        let ftype = typ_of env head in
        apply_function env ftype args

and typ_of_quoted e =
    match e with
    | A (Num _) -> TInt
    | A True -> TBool
    | A Nil -> TNil
    | A (Id _) -> TVar "a"
    | L [] -> TNil
    | L lst -> TList (List.length lst)

and typ_of_lambda env args =
    match args with
    | [L params; body] ->
        let param_names = List.map (function
            | A (Id x) -> x
            | _ -> failwith "lambda parameter must be an identifier"
        ) params in
        let param_types = List.map (fun x -> TVar x) param_names in
        let new_env = List.combine param_names param_types @ env in
        let ret_type = typ_of new_env body in
        TFun (List.map resolve_typ param_types, resolve_typ ret_type)
    | _ -> failwith "expected (lambda (params) body)"
    

and apply_function env ftype args =
    let ftype = resolve_typ ftype in
    match ftype with

    (* + and * *)
    | TFun ([], TInt) ->
        if List.length args < 2 then
            failwith "Expected at least 2 arguments"
        else begin
            let arg_types = List.map (typ_of env) args in
            List.iter (fun t -> unify t TInt) arg_types;
            TInt
        end

    | TFun (param_types, ret_type) ->
        let nparams = List.length param_types
        and nargs   = List.length args in
        if nparams <> nargs then
            failwith (Printf.sprintf
            "Arity mismatch: expected %d argument(s), got %d" nparams nargs)
        else begin
            let arg_types = List.map (typ_of env) args in
            List.iter2 unify param_types arg_types;
            resolve_typ ret_type
        end

    | TVar _ -> TVar "a"

    | _ -> failwith ("Not a function: " ^ string_of_typ ftype)

let typecheck e =
    tvar_env := [];
    typ_of !global_env e

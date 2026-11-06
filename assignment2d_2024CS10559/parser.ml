type token =
  | NUM of (
# 9 "parser.mly"
        Bigint.BigInt.bigint
# 6 "parser.ml"
)
  | PLUS
  | SUB
  | TIMES
  | DIV
  | MODULO
  | LEFTPAREN
  | RIGHTPAREN
  | QUOTE
  | TRUE
  | NIL
  | NOT_EQUALS
  | LESS_THAN_EQUALS
  | GREATER_THAN_EQUALS
  | EQUALS
  | LESS_THAN
  | GREATER_THAN
  | QUOTE_KW
  | ATOM
  | EQ
  | CONS
  | CAR
  | CDR
  | COND
  | LAMBDA
  | LABEL
  | DEFUN
  | COMPOUNDED_KEYWORD of (
# 16 "parser.mly"
        string
# 37 "parser.ml"
)
  | IDENT of (
# 16 "parser.mly"
        string
# 42 "parser.ml"
)
  | EOF

open Parsing
let _ = parse_error;;
# 2 "parser.mly"
    open Ast
# 50 "parser.ml"
let yytransl_const = [|
  258 (* PLUS *);
  259 (* SUB *);
  260 (* TIMES *);
  261 (* DIV *);
  262 (* MODULO *);
  263 (* LEFTPAREN *);
  264 (* RIGHTPAREN *);
  265 (* QUOTE *);
  266 (* TRUE *);
  267 (* NIL *);
  268 (* NOT_EQUALS *);
  269 (* LESS_THAN_EQUALS *);
  270 (* GREATER_THAN_EQUALS *);
  271 (* EQUALS *);
  272 (* LESS_THAN *);
  273 (* GREATER_THAN *);
  274 (* QUOTE_KW *);
  275 (* ATOM *);
  276 (* EQ *);
  277 (* CONS *);
  278 (* CAR *);
  279 (* CDR *);
  280 (* COND *);
  281 (* LAMBDA *);
  282 (* LABEL *);
  283 (* DEFUN *);
    0 (* EOF *);
    0|]

let yytransl_block = [|
  257 (* NUM *);
  284 (* COMPOUNDED_KEYWORD *);
  285 (* IDENT *);
    0|]

let yylhs = "\255\255\
\001\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\002\000\002\000\002\000\004\000\004\000\005\000\
\005\000\000\000"

let yylen = "\002\000\
\002\000\001\000\001\000\001\000\001\000\001\000\001\000\001\000\
\001\000\001\000\001\000\001\000\001\000\001\000\001\000\001\000\
\001\000\001\000\001\000\001\000\001\000\001\000\001\000\001\000\
\001\000\001\000\001\000\001\000\002\000\000\000\002\000\002\000\
\003\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\002\000\006\000\007\000\008\000\009\000\010\000\
\000\000\000\000\003\000\016\000\019\000\020\000\021\000\017\000\
\018\000\022\000\023\000\013\000\014\000\011\000\012\000\015\000\
\024\000\025\000\026\000\005\000\004\000\034\000\000\000\027\000\
\000\000\028\000\032\000\000\000\029\000\031\000\001\000\033\000"

let yydgoto = "\002\000\
\030\000\031\000\032\000\033\000\034\000"

let yysindex = "\255\255\
\030\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\001\255\030\255\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\030\255\000\000\
\012\000\000\000\000\000\033\255\000\000\000\000\000\000\000\000"

let yyrindex = "\000\000\
\061\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\001\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"

let yygindex = "\000\000\
\000\000\052\000\000\000\029\000\000\000"

let yytablesize = 265
let yytable = "\001\000\
\030\000\003\000\004\000\005\000\006\000\007\000\008\000\009\000\
\035\000\010\000\011\000\039\000\012\000\013\000\014\000\015\000\
\016\000\017\000\018\000\019\000\020\000\021\000\022\000\023\000\
\024\000\025\000\026\000\027\000\028\000\029\000\003\000\004\000\
\005\000\006\000\007\000\008\000\009\000\036\000\010\000\011\000\
\040\000\012\000\013\000\014\000\015\000\016\000\017\000\018\000\
\019\000\020\000\021\000\022\000\023\000\024\000\025\000\026\000\
\027\000\028\000\029\000\038\000\030\000\037\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\030\000"

let yycheck = "\001\000\
\000\000\001\001\002\001\003\001\004\001\005\001\006\001\007\001\
\008\001\009\001\010\001\000\000\012\001\013\001\014\001\015\001\
\016\001\017\001\018\001\019\001\020\001\021\001\022\001\023\001\
\024\001\025\001\026\001\027\001\028\001\029\001\001\001\002\001\
\003\001\004\001\005\001\006\001\007\001\009\000\009\001\010\001\
\008\001\012\001\013\001\014\001\015\001\016\001\017\001\018\001\
\019\001\020\001\021\001\022\001\023\001\024\001\025\001\026\001\
\027\001\028\001\029\001\031\000\000\000\010\000\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\008\001"

let yynames_const = "\
  PLUS\000\
  SUB\000\
  TIMES\000\
  DIV\000\
  MODULO\000\
  LEFTPAREN\000\
  RIGHTPAREN\000\
  QUOTE\000\
  TRUE\000\
  NIL\000\
  NOT_EQUALS\000\
  LESS_THAN_EQUALS\000\
  GREATER_THAN_EQUALS\000\
  EQUALS\000\
  LESS_THAN\000\
  GREATER_THAN\000\
  QUOTE_KW\000\
  ATOM\000\
  EQ\000\
  CONS\000\
  CAR\000\
  CDR\000\
  COND\000\
  LAMBDA\000\
  LABEL\000\
  DEFUN\000\
  EOF\000\
  "

let yynames_block = "\
  NUM\000\
  COMPOUNDED_KEYWORD\000\
  IDENT\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : Ast.exp list) in
    Obj.repr(
# 23 "parser.mly"
                 ( L _1 )
# 244 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : Bigint.BigInt.bigint) in
    Obj.repr(
# 26 "parser.mly"
        ( A (Num _1) )
# 251 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 27 "parser.mly"
           ( A True )
# 257 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 29 "parser.mly"
            ( A (Id _1) )
# 264 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 30 "parser.mly"
                         ( A (Id _1) )
# 271 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 31 "parser.mly"
           ( A (Id "+") )
# 277 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 32 "parser.mly"
           ( A (Id "-") )
# 283 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 33 "parser.mly"
            ( A (Id "*") )
# 289 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 34 "parser.mly"
          ( A (Id "div") )
# 295 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 35 "parser.mly"
             ( A (Id "mod") )
# 301 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 36 "parser.mly"
          ( A (Id "car") )
# 307 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 37 "parser.mly"
          ( A (Id "cdr") )
# 313 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 38 "parser.mly"
          ( A (Id "eq") )
# 319 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 39 "parser.mly"
           ( A (Id "cons") )
# 325 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 40 "parser.mly"
           ( A (Id "cond") )
# 331 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 41 "parser.mly"
                 ( A (Id "=/=") )
# 337 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 42 "parser.mly"
                ( A (Id "<") )
# 343 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 43 "parser.mly"
                   ( A (Id ">") )
# 349 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 44 "parser.mly"
                       ( A (Id "<=") )
# 355 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 45 "parser.mly"
                          ( A (Id ">=") )
# 361 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 46 "parser.mly"
             ( A (Id "=") )
# 367 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 47 "parser.mly"
               ( A (Id "quote") )
# 373 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 48 "parser.mly"
           ( A (Id "atom") )
# 379 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 49 "parser.mly"
             ( A (Id "lambda") )
# 385 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 50 "parser.mly"
            ( A (Id "label") )
# 391 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 51 "parser.mly"
            ( A (Id "defun") )
# 397 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : Ast.exp) in
    Obj.repr(
# 54 "parser.mly"
                ( _1 )
# 404 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'list) in
    Obj.repr(
# 55 "parser.mly"
                ( _1 )
# 411 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : Ast.exp) in
    Obj.repr(
# 56 "parser.mly"
                ( L [A (Id "quote"); _2] )
# 418 "parser.ml"
               : Ast.exp))
; (fun __caml_parser_env ->
    Obj.repr(
# 59 "parser.mly"
                ( [] )
# 424 "parser.ml"
               : Ast.exp list))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : Ast.exp) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : Ast.exp list) in
    Obj.repr(
# 60 "parser.mly"
                  ( _1 :: _2 )
# 432 "parser.ml"
               : Ast.exp list))
; (fun __caml_parser_env ->
    Obj.repr(
# 64 "parser.mly"
                         ( L [] )
# 438 "parser.ml"
               : 'list))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : Ast.exp list) in
    Obj.repr(
# 65 "parser.mly"
                                    ( L _2 )
# 445 "parser.ml"
               : 'list))
(* Entry main *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let main (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Ast.exp)

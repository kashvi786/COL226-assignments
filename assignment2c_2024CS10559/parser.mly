// header, declaration, rules and trailer sections of the .mly file
/* File parser.mly */
%{
    open Ast
%}

%type <Ast.exp> main
%type <Ast.exp> expr term
%type <Ast.exp list> elements

%token <Bigint.BigInt.bigint> NUM
%token PLUS SUB TIMES DIV MODULO
%token LEFTPAREN RIGHTPAREN
%token QUOTE
%token TRUE NIL
%token NOT_EQUALS LESS_THAN_EQUALS GREATER_THAN_EQUALS EQUALS LESS_THAN GREATER_THAN 
%token QUOTE_KW ATOM EQ CONS CAR CDR COND LAMBDA LABEL DEFUN
%token <string> COMPOUNDED_KEYWORD IDENT
%token EOF

%start main

%%
main:
    elements EOF { L $1 }
;
term:
    NUM { A (Num $1) }
    | TRUE { A True }
    | NIL  { A Nil }
    | IDENT { A (Id $1) }
    | COMPOUNDED_KEYWORD { A (Id $1) }
    | PLUS { A (Id "+") }
    | SUB  { A (Id "-") }
    | TIMES { A (Id "*") }
    | DIV { A (Id "div") }
    | MODULO { A (Id "mod") }
    | CAR { A (Id "car") }
    | CDR { A (Id "cdr") }
    | EQ  { A (Id "eq") }
    | CONS { A (Id "cons") }
    | COND { A (Id "cond") }
    | NOT_EQUALS { A (Id "=/=") }
    | LESS_THAN { A (Id "<") }
    | GREATER_THAN { A (Id ">") }
    | LESS_THAN_EQUALS { A (Id "<=") }
    | GREATER_THAN_EQUALS { A (Id ">=") }
    | EQUALS { A (Id "=") }
    | QUOTE_KW { A (Id "quote") }
    | ATOM { A (Id "atom") }
    | LAMBDA { A (Id "lambda") }
    | LABEL { A (Id "label") }
    | DEFUN { A (Id "defun") }
;
expr:
    term        { $1 }
  | list        { $1 }
  | QUOTE expr  { L [A (Id "quote"); $2] }
;
elements:
    /* empty */ { [] }
  | expr elements { $1 :: $2 }
;
list:
    LEFTPAREN RIGHTPAREN          { A Nil }
    | LEFTPAREN elements RIGHTPAREN { L $2 }
;

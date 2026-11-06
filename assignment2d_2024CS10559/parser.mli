type token =
  | NUM of (
# 9 "parser.mly"
        Bigint.BigInt.bigint
# 6 "parser.mli"
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
# 37 "parser.mli"
)
  | IDENT of (
# 16 "parser.mly"
        string
# 42 "parser.mli"
)
  | EOF

val main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.exp

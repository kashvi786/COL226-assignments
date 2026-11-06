{
    open Bigint
    exception Eof
}

(* Named regular expressions *)

let comment = [';']+ [^ '\n']*('\n' | eof)
let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z']
let identifier = letter (letter | digit | '_')* '.'?
let bignum = '-'? digit+  (* Simple representation for big numbers*)
let whitespace = [' ' '\t' '\n']+
let compounded_keywords = "c" ['a' 'd']+ "r"


rule token = parse
    |comment { token lexbuf }  (* Skip comments *)
    |whitespace { token lexbuf }  (* Skip whitespace *)
    |'(' {LEFTPAREN}
    |')' {RIGHTPAREN}
    |'\'' {QUOTE}
    |"t" {TRUE}
    |"()" {NIL}
    |bignum {let s = Lexing.lexeme lexbuf in NUM (BigInt.int_to_bigint (int_of_string s))}
    |'+' {PLUS}
    |'*' {TIMES}
    |'-' {SUB}
    |"div" {DIV}
    |"mod" {MODULO}
    |"=/=" {NOT_EQUALS}
    |"<=" {LESS_THAN_EQUALS}
    |">=" {GREATER_THAN_EQUALS}
    |'=' {EQUALS}
    |'<' {LESS_THAN}
    |'>' {GREATER_THAN}
    |"quote" {QUOTE_KW}
    |"atom" {ATOM}
    |"eq" {EQ}
    |"cons" {CONS}
    |"car" {CAR}
    |"cdr" {CDR}
    |"cond" {COND}
    |"lambda" {LAMBDA}
    |"label" {LABEL}
    |"defun" {DEFUN}
    |compounded_keywords {COMPOUNDED_KEYWORD (Lexing.lexeme lexbuf)}
    |identifier { IDENT (Lexing.lexeme lexbuf) }
    |eof {EOF}
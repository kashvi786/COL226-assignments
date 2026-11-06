.PHONY: all parser lexer run run-stdin clean

all: parser lexer main

INPUT ?= input.lisp

parser: parser.cmo

parser.cmo: parser.mly Bigint.ml ast.ml
	ocamlyacc parser.mly
	ocamlc -c Bigint.ml
	ocamlc -c ast.ml
	ocamlc -c parser.mli
	ocamlc -c parser.ml

lexer: lexer.cmo

lexer.cmo: lexer.mll parser.cmi
	ocamllex lexer.mll
	ocamlc -c -open Parser lexer.ml

main: Bigint.cmo ast.cmo parser.cmo lexer.cmo main.cmo
	ocamlc -o main Bigint.cmo ast.cmo parser.cmo lexer.cmo main.cmo

main.cmo: main.ml parser.cmi lexer.cmi ast.cmi
	ocamlc -c main.ml

run: all
	./main < $(INPUT)

run-stdin: all
	./main

clean:
	rm -f *.cmo *.cmi lexer.ml parser.ml parser.mli main

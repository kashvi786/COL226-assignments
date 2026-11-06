.PHONY: all parser lexer run run-all run-1 run-2 run-3 run-4 run-stdin clean

all: parser lexer main_2 main_1 main_3 main_4

INPUT_1 ?= input_1.txt
INPUT_2 ?= input_2.lisp
INPUT_3 ?= input_3.lisp
INPUT_4 ?= input_4.lisp

parser: parser.cmo

Bigint.cmo: Bigint.ml
	ocamlc -c Bigint.ml

ast.cmo: ast.ml Bigint.cmo
	ocamlc -c ast.ml

parser.cmo: parser.mly Bigint.cmo ast.cmo
	ocamlyacc parser.mly
	ocamlc -c parser.mli
	ocamlc -c parser.ml

lexer: lexer.cmo

lexer.cmo: lexer.mll parser.cmi
	ocamllex lexer.mll
	ocamlc -c -open Parser lexer.ml

type_cheker.cmo: type_cheker.ml ast.cmi
	ocamlc -c type_cheker.ml

main_2: Bigint.cmo parser.cmo lexer.cmo main_2.cmo
	ocamlc -o main_2 Bigint.cmo parser.cmo lexer.cmo main_2.cmo

main_2.cmo: main_2.ml parser.cmi lexer.cmi Bigint.cmi
	ocamlc -c main_2.ml

main_1: Bigint.cmo main_1.cmo
	ocamlc -o main_1 Bigint.cmo main_1.cmo

main_1.cmo: main_1.ml Bigint.cmi
	ocamlc -c main_1.ml

main_3: Bigint.cmo ast.cmo parser.cmo lexer.cmo main_3.cmo
	ocamlc -o main_3 Bigint.cmo ast.cmo parser.cmo lexer.cmo main_3.cmo

main_3.cmo: main_3.ml parser.cmi lexer.cmi ast.cmi
	ocamlc -c main_3.ml

main_4: Bigint.cmo ast.cmo parser.cmo lexer.cmo type_cheker.cmo main_4.cmo
	ocamlc -o main_4 Bigint.cmo ast.cmo parser.cmo lexer.cmo type_cheker.cmo main_4.cmo

main_4.cmo: main_4.ml parser.cmi lexer.cmi ast.cmi type_cheker.cmi
	ocamlc -c main_4.ml

run: run-all

run-all: all
	./main_1 < $(INPUT_1)
	./main_2 < $(INPUT_2)
	./main_3 < $(INPUT_3)
	./main_4 < $(INPUT_4)

run-1: main_1
	./main_1 < $(INPUT_1)

run-2: main_2
	./main_2 < $(INPUT_2)

run-3: main_3
	./main_3 < $(INPUT_3)

run-4: main_4
	./main_4 < $(INPUT_4)

run-stdin: main_4
	./main_4

clean:
	rm -f *.cmo *.cmi lexer.ml parser.ml parser.mli main_2 main_1 main_3 main_4

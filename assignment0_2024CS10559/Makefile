make:
	ocamlc -o sudoku2cnf parse.ml constraints.ml main.ml
	ocamlc -o write write.ml
	ocamlc -o sol2grid last.ml
run:
	make
	./sudoku2cnf input.txt output1.cnf
	z3 -dimacs output1.cnf > sat_output1.txt
	./write input.txt sat_output1.txt output1.cnf temp1.txt output2.cnf
	z3 -dimacs output2.cnf > sat_output2.txt
	./sol2grid sat_output1.txt sat_output2.txt temp1.txt output.txt case_of_output.txt

clean:
	rm -f sudoku2cnf write sol2grid *.cmi *.cmo
	rm -f output1.cnf output2.cnf sat_output1.txt sat_output2.txt temp1.txt output.txt case_of_output.txt
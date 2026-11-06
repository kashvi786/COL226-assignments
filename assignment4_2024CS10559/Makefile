TARGET = test

all:
	ocamlc -o $(TARGET) main.ml test.ml

run: all
	./$(TARGET)

clean:
	rm -f *.cmo *.cmi $(TARGET)
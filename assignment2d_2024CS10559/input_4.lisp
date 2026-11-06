; SECTION 2.4: TYPE CHECKING WITH OVERLOADING
t
()
12345
'(a b c d)

(+ 1 2 3)
(> (+ 1 2) 2)
(and (not t) (or t t))
(cdr '(a b c))
(cons 1 '(2 3))

(eq 1 t)
(+ 1 t)
(car ())
(cons 1 2)
(cond (1 10) (t 20))

((lambda (x y) (+ x y)) 4 5)
((lambda (x y) (+ x y)) 4)

(defun fact (n)
  (cond ((<= n 1) 1)
        (t (* n (fact (- n 1))))))

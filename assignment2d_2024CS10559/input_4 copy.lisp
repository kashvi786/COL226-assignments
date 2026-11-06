; SECTION 2.4: TYPE CHECKING WITH OVERLOADING
t
()
12345
'(a b c d)

(+ 1 2 3)
(* 2 3 4)
(- 10 4)
(div 17 5)
(mod 17 5)
(> 5 3)
(and (not t) (or t t))

(atom 1)
(atom '(a b c))
(cdr '(a b c))
(cons 1 '(2 3))

(eq 1 2)
(eq 1 t)
(+ 1 t)
(car ())
(cons 1 2)

(cond ((atom 1) 10) ((> 3 4) 20) (t 30))
(cond (1 10) (t 20))

((lambda (x y) (+ x y)) 4 5)
((lambda (x) (cons x '(2 3))) 1)
((lambda (x y) (+ x y)) 4)

(defun fact (n)
  (cond ((<= n 1) 1)
        (t (* n (fact (- n 1))))))

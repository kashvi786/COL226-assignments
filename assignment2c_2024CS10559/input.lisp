; ===== Basic arithmetic =====
(+ 1 2)
(* 3 4)
(- 10 5)
(div 20 3)
(mod 20 3)

; ===== Negative numbers =====
-10
-999
(+ -3 5)
(- -10 5)
(- 10 -5)
(- -10 -5)

; ===== Comparisons =====
(= 1 1)
(< 1 2)
(> 3 2)
(<= 2 2)
(>= 3 2)
(=/= 1 2)

; ===== Constants =====
t
()
( )

; ===== List operations =====
(cons 1 ())
(car (cons 1 2))
(cdr (cons 1 2))

; ===== Nested expressions =====
(cadr (cons 1 (cons 2 ())))

; ===== Deep cadr patterns =====
(caadr x)
(cddar y)
(cadadr z)

; ===== Keywords =====
(atom x)
(eq x y)
(cond (t 1) (t 2))

(lambda (x) (+ x 1))
(label f (lambda (x) x))

(defun fact (n)
  (cond
    ((eq n 0) 1)
    (t (* n (fact (- n 1)))))
)

; ===== Identifiers =====
myVar
another_var
list.
append.

; ===== Mixed expressions =====
(append. (list. 1 2) (list. 3 4))

; ===== Edge cases =====

; negative numbers next to parentheses
(-(-10)5)

; multiple spaces and tabs
(   +    10     -5   )

; only comment
; this entire line should be ignored

; empty lines below
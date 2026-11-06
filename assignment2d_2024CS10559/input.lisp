; =========================
; A2 TESTCASES (plain LISP format)
; =========================

; SECTION 2.1: BIGINT PACKAGE (run in OCaml, not via LISP input)
; INT 0
; INT 7
; INT -42
; INT 120030
; NEG 0
; NEG 42
; ABS -98765
; ADD 99999999999999999999 1
; SUB 99999999999999999999 99999999999999999999
; ADD 5000 -5000
; SUB 12345 54321
; SUB 54321 12345
; MUL 12345 -6789
; MUL 99999 99999
; MUL 0 987654321
; MUL -12 -13
; QUO 123456789 12345
; REM 123456789 12345
; QUO 9876543210 97
; REM 9876543210 97
; GT 12345 12345
; EQ 12345 12345
; LT 12345 12345
; GE 12345 12345
; LE 12345 12345
; GT -100 0
; EQ -100 0
; LT -100 0
; GE -100 0
; LE -100 0
; GT -5 -10
; EQ -5 -10
; LT -5 -10
; GE -5 -10
; LE -5 -10
; GT 99999 100000
; EQ 99999 100000
; LT 99999 100000
; GE 99999 100000
; LE 99999 100000
; QUO 12345 0
; REM 12345 0

; SECTION 2.2: LEXER INPUTS (uncomment if you want lexer-only runs)
; (+ 12 (* 3 4) (- 10 5) (div 20 3) (mod 20 3))
; (= 1 1) (=/= 1 2) (<= 2 3) (>= 3 2) (> 4 1) (< 1 4)
; (quote a) 'a '(a b c) t ()
; (car x) (cdr x) (cadr x) (caadr x) (cdar x) (cdadr x) (cons a b) (cond (t a))
; ;;;; file header comment
; (defun append. (x y)
;   (cond ; inline comment after cond
;     ((null. x) y) ;; indented comment
;     (t (cons (car x) (append. (cdr x) y))))) ; final inline comment

; SECTION 2.3: PARSER INPUTS (uncomment for parser-only runs)
; foo
; 123
; ()
; (foo)
; (a b (c) (+ e) f)
; (quote a)
; 'a
; '(a b (c d) 123)
; (a ; comment about a
;  b (c) ;; comment about nested list
;  d) ;; comment after list
; (a b (c)

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

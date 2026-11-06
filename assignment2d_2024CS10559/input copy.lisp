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

'a
'(a b c)
(quote (a b c))

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

; =========================
; BASIC ATOMS
; =========================

5
t
()
'a
'(1 2 3)
'(1 t x)

; =========================
; NIL AS LIST AND BOOL
; =========================

()                         ; should type as List(0)
(atom ())                  ; true → Bool
(cond (() 1) (t 2))        ; () is false → skip → returns 2
(and () t)                 ; () treated as false
(or () t)                  ; returns t
(not ())                   ; true

; =========================
; QUOTE TESTS
; =========================

'(1 2 3)
'()
'(a b c)
'((1 2) (3 4))

; =========================
; ARITHMETIC (INCLUDING VARIADIC)
; =========================

(+ 1 2)
(+ 1 2 3 4 5)
(* 2 3 4)
(- 5 2)
(div 10 2)
(mod 10 3)

; =========================
; COMPARISONS
; =========================

(= 3 3)
(< 2 5)
(> 10 1)
(<= 4 4)
(>= 5 2)
(=/= 3 4)

; =========================
; EQ (WEAK TYPING)
; =========================

(eq 1 1)
(eq 'a 'a)
(eq () ())                 ; NIL comparisons

; =========================
; LIST OPERATIONS
; =========================

(car '(1 2 3))
(cdr '(1 2 3))
(cons 1 '(2 3))
(cons 'a '(b c))
(cons () '(1 2))           ; NIL as element

; nested list
(car '((1 2) (3 4)))
(cdr '((1 2) (3 4)))

; =========================
; CADR STYLE FUNCTIONS
; =========================

(cadr '(1 2 3))
(caddr '(1 2 3 4))
(caadr '((1 2) (3 4)))

; =========================
; COND TESTS
; =========================

(cond ((atom 'a) 1) (t 2))
(cond ((eq 1 2) 3) ((= 2 2) 4))
(cond (() 1) (t 2))        ; NIL as false
(cond ((atom ()) 1) (t 2))

; mixed unknown (lambda param)
((lambda (x)
   (cond (x 1) (t 2)))
 t)

; =========================
; LAMBDA TESTS
; =========================

((lambda (x) (+ x 1)) 5)
((lambda (x y) (+ x y)) 3 4)

; lambda with list
((lambda (x) (car x)) '(10 20 30))

; lambda with NIL
((lambda (x) (cond (x 1) (t 2))) ())

; =========================
; LABEL (RECURSION)
; =========================

(label fact
  (lambda (n)
    (cond
      ((= n 0) 1)
      (t (* n (fact (- n 1))))
    )
  )
)

; =========================
; DEFUN (GLOBAL FUNCTION)
; =========================

(defun add2 (x) (+ x 2))
(add2 5)

(defun sum2 (x y) (+ x y))
(sum2 3 4)

; =========================
; MIXED / EDGE CASES
; =========================

; TVar propagation
((lambda (x) (car x)) '(1 2))
((lambda (x) (cdr x)) '(1 2))

; NIL in list context
(cons 1 ())
(cdr (cons 1 '(2 3)))

; NIL as bool in cond
((lambda (x)
   (cond (x 1) (t 2)))
 ())

; unknown variable behavior (should fail if not in env)
; (foo 5)

; =========================
; ERROR CASES (should FAIL)
; =========================

; wrong types
; (+ 1 t)
; (car 5)
; (cdr 5)
; (cons 1 2)
; (cond (1 2))              ; condition not bool-like
; (eq 1 t)
; (/ 10 0)                  ; runtime issue, type ok

; =========================
; TVar + Boolean ambiguity
; =========================

((lambda (x) (and x t)) t)
((lambda (x) (and x t)) ())
((lambda (x) (and x t)) 5)        ; should FAIL

((lambda (x) (cond (x 1) (t 2))) t)
((lambda (x) (cond (x 1) (t 2))) ())
((lambda (x) (cond (x 1) (t 2))) 5) ; should FAIL


; =========================
; Nested unknown propagation
; =========================

((lambda (x) (car (cdr x))) '(1 2 3))
((lambda (x) (car (cdr x))) x)     ; allowed (TVar)

((lambda (x) (cdr (cdr x))) '(1 2 3))
((lambda (x) (cdr (cdr x))) '(1))  ; should FAIL


; =========================
; cond branch mismatch
; =========================

(cond ((= 1 1) 1) (t t))          
(cond ((= 1 1) '(1 2)) (t 3))    


; =========================
; malformed cond
; =========================

(cond (1 2))                      
(cond ((= 1 1)))                  
(cond ())                         


; =========================
; deep cadr chains
; =========================

(cadddr '(1 2 3 4 5))
(caadr '((1 2) (3 4)))
(cddddr '(1 2 3))                 


; =========================
; cons + length propagation
; =========================

(cons 1 (cons 2 (cons 3 ())))
(cdr (cons 1 (cons 2 ())))
(cdr (cdr (cons 1 (cons 2 ()))))
(cdr (cdr (cdr (cons 1 (cons 2 ()))))) 


; =========================
; lambda + polymorphism traps
; =========================

((lambda (x) x) 5)
((lambda (x) x) '(1 2))
((lambda (x) x) t)

((lambda (x) (+ x 1)) '(1 2))     


; =========================
; higher-order behavior
; =========================

((lambda (f) (f 5)) (lambda (x) (+ x 1)))
((lambda (f) (f '(1 2))) (lambda (x) (car x)))


; =========================
; recursion (label)
; =========================

(label f (lambda (x) (f x)))
(label f (lambda (x) (+ x (f x))))

((label f (lambda (x)
   (cond ((= x 0) 1)
         (t (* x (f (- x 1))))))) 5)


; =========================
; defun shadowing
; =========================

(defun f (x) (+ x 1))
(defun f (x) (* x 2))
(f 5)


; =========================
; NIL corner cases
; =========================

(car ())                
(cdr ())                

(cons () ())            
(car (cons () '(1 2)))  

(cond ((atom ()) 1) (t 2))
(cond (() 1) (() 2) (t 3))


; =========================
; weak typing edge cases
; =========================

(eq '(1 2) '(3 4))      
(eq '(1 2) 3)           

((lambda (x) (eq x x)) '(1 2))


; =========================
; parser edge cases
; =========================

(- (-10) 5)             
(- 10)                  


; =========================
; final boss case
; =========================

((lambda (x)
   (cond
     ((atom x) x)
     ((= (car x) 0) (cdr x))
     (t (cons (car x) (cdr x)))))
 '(0 1 2))


(defun f (x y) (+ x (cond ((eq x t) 10) (t 20))))
 
; empty lines below

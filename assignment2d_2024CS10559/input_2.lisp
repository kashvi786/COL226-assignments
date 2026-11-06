; SECTION 2.2: LEXICAL ANALYSIS
(+ 12 (* 3 4) (- 10 5) (div 20 3) (mod 20 3))
(= 1 1) (=/= 1 2) (<= 2 3) (>= 3 2) (> 4 1) (< 1 4)
(quote a) 'a '(a b c) t ()

;;;; file header comment
(defun append. (x y)
  (cond ; inline comment after cond
    ((null. x) y) ;; indented comment
    (t (cons (car x) (append. (cadr x) (caadr y)))))) ; final inline comment

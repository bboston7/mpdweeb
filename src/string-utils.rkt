#lang typed/racket

(provide string-contains?
         string-starts-with?)

#|
Returns a true value if token is in str
|#
(: string-contains? (String String -> Boolean))
(define (string-contains? str token)
  (regexp-match?
    (regexp (regexp-quote (string-downcase token)))
    (string-downcase str)))

#|
Returns true if str starts with token
|#
(: string-starts-with? (String String -> Boolean))
(define (string-starts-with? str token)
  (regexp-match?
    (regexp (string-append "^" (regexp-quote (string-downcase token))))
    (string-downcase str)))


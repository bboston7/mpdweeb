#lang racket

(require web-server/http/response-structs
         web-server/http/xexpr
         "config.rkt"
         "mpd-utils.rkt")

(provide path->response)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Public Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (path->response path)
  (match path
    [(list "") (response/xexpr (render-artists))]
    [(list artist) (response/xexpr (render-albums artist))]
    [(list artist album) (response/xexpr (render-tracks artist album))]
    [(list-rest "static" path) (response/output (get-binary path))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Private Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (get-binary path)
  (lambda (out)
    (let ([path (format "~a/~a" DIR (string-join path "/"))])
      (if TRANSCODE
        (transcode-file path out)
        (display (file->bytes (string->path path)) out)))
    (close-output-port out)
    (void)))

(define (render-albums artist)
  (list->ul-list (map (lambda (x) (cons x (format "~a/~a" artist x)))
                      (get-albums artist))))

(define (render-artists)
  (list->ul-list (map (lambda (x) (cons x x)) (get-artists))))

(define (render-tracks artist album)
  (list->ul-list (map (lambda (x) (cons (car x) (format "/static/~a" (cdr x))))
                      (get-tracks artist album))))

(define (transcode-file path out)
  ((fifth (process/ports out #f #f (format TRANS path))) 'wait))

#|
Transform lst into a ul X-expression list that can be embedded in html
|#
(define (list->ul-list lst)
  `(ul ,@(map (lambda (x) `(li (a ((href ,(cdr x))) ,(car x)))) lst)))

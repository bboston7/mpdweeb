#lang web-server

(require web-server/servlet-env
         "html-renderer.rkt")

(provide interface-version stuffer start)

(define interface-version 'stateless)
(define stuffer default-stuffer)

(define (start req)
  (let ([path (map path/param-path (url-path (request-uri req)))])
    (displayln path)
    (path->response path)))
    ;`(html (head (title "YOOOOOOOOOOOO"))
    ;       (body (p "welcome to my lil server")))))

(serve/servlet start
               #:command-line? #t
               #:listen-ip #f
               #:servlet-path "/"
               #:servlet-regexp #rx""
               #:stateless? #t)

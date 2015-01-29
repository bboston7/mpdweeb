#lang web-server

(require web-server/servlet-env
         web-server/managers/timeouts
         web-server/servlet/setup
         web-server/servlet-dispatch
         (prefix-in timeout: web-server/dispatchers/dispatch-timeout)
         (prefix-in seq: web-server/dispatchers/dispatch-sequencer)
         "html-renderer.rkt")

(provide interface-version stuffer start)

(define interface-version 'stateless)
(define stuffer default-stuffer)

(define (start req)
  (let ([path (map path/param-path (url-path (request-uri req)))])
    (displayln path)
    (path->response path)))

(serve/launch/wait
  (lambda (sema)
    (seq:make (timeout:make 3600)
              (dispatch/servlet start #:regexp #rx"")))
  #:listen-ip #f
  #:port 8080)
#|
(serve/servlet start
               #:command-line? #t
               #:listen-ip #f
               #:servlet-path "/"
               #:servlet-regexp #rx""
               #:stateless? #f
               #:port 8080
               #:manager (create-timeout-manager false 3600 3600))
|#

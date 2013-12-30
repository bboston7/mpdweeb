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
    [(list-rest "static" path) (response/full 200
                                              #"OK"
                                              (current-seconds)
                                              #f
                                              null
                                              (list (get-binary path)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Private Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (get-binary path)
  (let ([path (format "~a/~a" DIR (string-join path "/"))])
    (if TRANSCODE
      (transcode-file path)
      (file->bytes (string->path path)))))

(define (render-albums artist)
  (list->ul-list (map (lambda (x) (cons x (format "~a/~a" artist x)))
                      (get-albums artist))))

(define (render-artists)
  (list->ul-list (map (lambda (x) (cons x x)) (get-artists))))

(define (render-tracks artist album)
  (list->ul-list (map (lambda (x) (cons (car x) (format "/static/~a" (cdr x))))
                      (get-tracks artist album))))

(define (transcode-file path)
  (displayln path)
  (let* ([proc (process (format
                          "ffmpeg -v 0 -i ~s -f ogg -vn -acodec libvorbis -aq ~a -"
                          path
                          OGG_QUAL))]
         [ogg (port->bytes (car proc))])
    (close-input-port (car proc))
    (close-output-port (cadr proc))
    (close-input-port (cadddr proc))
    ogg))

#|
Transform lst into a ul X-expression list that can be embedded in html
|#
(define (list->ul-list lst)
  `(ul ,@(map (lambda (x) `(li (a ((href ,(cdr x))) ,(car x)))) lst)))

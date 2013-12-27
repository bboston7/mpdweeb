#lang typed/racket

(require "config.rkt")

#|
Connects to mpd server on HOST:PORT
|#
(define-values (mpd-in mpd-out) (tcp-connect HOST PORT))

#|
Sends a string to the mpd server
|#
(: send-string (String -> Void))
(define (send-string str)
  (write-string (string-append str "\n") mpd-out)
  (flush-output mpd-out))

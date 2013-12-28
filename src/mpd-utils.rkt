#lang typed/racket

(require "config.rkt"
         "string-utils.rkt")

(require/typed typed/racket
               [#:opaque Event evt?]
               [alarm-evt (Real -> Event)]
               [sync (Event -> Any)])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Module Variables                                                      ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#|
Connects to mpd server on HOST:PORT
|#
(define-values (mpd-in mpd-out) (tcp-connect HOST PORT))
(define TIMER_DURATION 30000)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Public functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#|
Get a list of all artists from the mpd server

Throws:
    Exception if server is unreachable
Returns
    String list of artist names
|#
(: get-artists (-> (Listof String)))
(define (get-artists)
  (send-string "list artist")
  (letrec: ([res->list : (-> (Listof String))
              (lambda ()
                (let ([line (read-string)])
                  (if (string-starts-with? line "Artist:")
                    (cons (substring line 8) (res->list))
                    (begin
                      (check-response line)
                      null))))])
    (res->list)))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Private functions                                                     ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#|
Checks the response string

Parameters:
    res: Result response to check
Throws:
    Exception if response is not "OK"
Returns:
    True
|#
(: check-response (Any -> True))
(define (check-response res)
  (if (equal? res "OK")
    #t
    (error "Bad response from MPD server: " res)))

#|
Creates a thread that sends a ping to the server at regular intervals and
checks the response

Returns:
    Thread
|#
(: keep-alive (-> Thread))
(define (keep-alive)
  (thread
    (lambda ()
      (sync (alarm-evt (+ (current-inexact-milliseconds) TIMER_DURATION)))
      (send-string "ping")
      (check-response (read-line mpd-in))
      (keep-alive))))

#|
Reads in a line from the server and returns the result

Throws:
    Exception if EOF from server
Returns:
    String of next line from server
|#
(: read-string (-> String))
(define (read-string)
  (let ([line (read-line mpd-in)])
    (if (eof-object? line)
      (raise "Unexpected EOF from server")
      line)))

#|
Sends a string to the mpd server
|#
(: send-string (String -> Void))
(define (send-string str)
  (write-string (string-append str "\n") mpd-out)
  (flush-output mpd-out))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;  Module Initialization                                                ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(void (check-response (substring (read-string) 0 2)))
(void (keep-alive))

#lang typed/racket

(require "config.rkt"
         "string-utils.rkt")

(require/typed typed/racket
               [#:opaque Event evt?]
               [alarm-evt (Real -> Event)]
               [sync (Event -> Any)])

(provide get-artists)

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
Get a list of albums from a given artist

Parameters
    artist - Artist to get albums by
Throws
    Exception if server is unreachable
Returns
    String list of albums by artist
|#
(: get-albums (String -> (Listof String)))
(define (get-albums artist)
  (send-string (format "list album ~s" artist))
  (map (lambda: ([x : String]) (substring x 7)) (response->list "Album:")))

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
  (map (lambda: ([x : String]) (substring x 8)) (response->list "Artist:")))

#|
Get a list of all tracks from a certain artist

Parameters
    artist - Artist that album belongs to
    album  - Album to get tracks for
Throws
    Exception if server is unreachable
Returns
    List of pairs in format '(title filename)
|#
(: get-tracks (String String -> (Listof (Pair String String))))
(define (get-tracks artist album)
  (send-string (format "find album ~s artist ~s" album artist))
  (letrec: ([next-track : (-> (Listof (Pair String String)))
              (lambda ()
                (let ([file (get-next "file:")])
                  (if file
                    (cons (cons (assert (get-next "Title:") string?) file)
                          (next-track))
                    null)))])
    (next-track)))

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
Get next line starting with start from server response

Parameters
    start - Line to return
Throws
    Exception if EOF or line starting with "ACK"
Returns
    First line starting with start or #f if end of stream is reached
|#
(: get-next (String -> (Option String)))
(define (get-next start)
  (let ([line (read-string)])
    (cond
      [(string-starts-with? line start) line]
      [(string-starts-with? line "OK") #f]
      [(string-starts-with? line "ACK") (error "Illegal command: " line)]
      [else (get-next start)])))


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
Builds a list of responses starting with start

Parameters:
    start - Expected start of each line
Throws:
    Exception if EOF, or unexpected server response
Returns:
    List of responses from the server
|#
(: response->list (String -> (Listof String)))
(define (response->list start)
  (let ([line (read-string)])
    (if (string-starts-with? line start)
      (cons line (response->list start))
      (begin
        (check-response line)
        null))))

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

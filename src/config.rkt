#lang typed/racket/base

(provide (all-defined-out))

(define DIR "/home/brett/Music")
(define HOST "localhost")
(define PORT 6600)
(define TRANSCODE #t)
(define OGG_QUAL 6)
(define TRANS "ffmpeg -v 0 -i ~s -f ogg -vn -acodec libvorbis -aq 6 -")
;(define TRANS "ffmpeg -v 0 -i ~s -f mp3 -vn -acodec libmp3lame -aq 2 -")

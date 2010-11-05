#lang racket

;; example
(require ffi/unsafe
         "gst-bus.rkt"
         "gst-message.rkt"
         "init.rkt"         
         "playbin.rkt")

(define loop (g_main_loop_new #f #f))

(when (gst_init_check #f #f #f)
  (displayln "Initialization success"))

(define pb (make-playbin%))

(define bus (send pb get-bus))
(send bus add-watch
      (lambda (bus msg data)
        (begin
          (display "Message: ")
          (displayln
           (GstMessage-type msg))
          #t)))

;;(send pb set-uri! "file:///home/asumu/Tank.mp3")
(send pb connect-signal 'about-to-finish 
      (lambda (instance data)
        (displayln "About to finish")))

(send pb set-uri!
      "file:///usr/share/sounds/gnome/default/alerts/drip.ogg")
(send pb set-state! 'playing)
;(send pb get-state)

;(g_main_loop_run loop)

;;(send pb set-state! 'null)

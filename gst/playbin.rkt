#lang racket

;; playbin.rkt

(require ffi/unsafe
         "gst-element.rkt"
         "gst-element-factory.rkt"
         "utils.rkt")

(provide make-playbin%
         playbin%)

(define _GstPlaybin (_cpointer 'GstPlaybin))

(define (make-playbin%)
  (make-object playbin%
    (gst_element_factory_make "playbin2" "play")))

(define playbin%
  (class gst-element%
    (init _instance)
    (inherit-field _gst-element)
    
    (super-new (_gst-element _instance))
    
    (define/public (connect-signal signal handler)
      (define-signal-handler connect-signal (symbol->string signal)
        (_fun _GstPlaybin _pointer -> _void)
        (lambda (instance data)
          (handler (make-object playbin% instance) data)))
      (connect-signal _gst-element #f))
    
    (define/public (set-uri! uri)
      (gobject-set-string _gst-element "uri" uri))))

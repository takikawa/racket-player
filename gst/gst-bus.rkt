#lang racket

;; gst-bus.rkt

(require ffi/unsafe
         "gst-message.rkt"
         "utils.rkt"
         "types.rkt")

(provide _GstBus
         _GstBusFunc
         
         make-gst-bus%
         gst-bus%)

(define _GstBus (_cpointer 'GstBus))
(define _GstBusFunc 
  (_fun #:atomic? #t _GstBus _GstMessage _pointer -> _gboolean))

(define-gst gst_bus_add_watch 
  (_fun _GstBus _GstBusFunc _pointer -> _uint))
(define-gst gst_bus_new (_fun -> _GstBus))
(define-gst gst_bus_add_signal_watch (_fun _GstBus -> _void))

(define (make-gst-bus%)
  (make-object gst-bus% (gst_bus_new)))

(define gst-bus%
  (class object%
    (super-new)
    (init-field _gst_bus)
    
    (define/public (add-watch f)
      (gst_bus_add_watch _gst_bus f #f))))
      ;(gst_bus_add_signal_watch _gst_bus))))

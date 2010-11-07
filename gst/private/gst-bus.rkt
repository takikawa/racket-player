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
  (_fun _GstBus _GstMessage-pointer _pointer -> _gboolean))

(define-gst gst_bus_add_watch 
  (_fun _GstBus _GstBusFunc _pointer -> _uint))
(define-gst gst_bus_new (_fun -> _GstBus))
(define-gst gst_bus_add_signal_watch (_fun _GstBus -> _void))

(define-signal-handler connect-message "message"
  (_fun _GstBus _GstMessage-pointer _pointer -> _void)
  (lambda (bus msg data)
    (void)))

(define (make-gst-bus%)
  (make-object gst-bus% (gst_bus_new)))

(define gst-bus%
  (class object%
         (super-new)
         (init-field _gst_bus)

	 ;(connect-message _gst_bus)
	 ;(gst_bus_add_signal_watch _gst_bus)

	 (define/public (on-message msg)
	   (void))
         
         (define/public (add-watch f)
           (let ([callback
                  (lambda (bus msg data)
                    (f (GstMessage-type msg)))])
             (gst_bus_add_watch _gst_bus callback #f)))))

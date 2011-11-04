#lang racket

;; bus.rkt

(require ffi/unsafe
         "message.rkt"
         "utils.rkt"
         "types.rkt")

(provide _GstBus
         _GstBusFunc

         bus%)

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

(define bus%
  (class object%
    (init gst-bus)
    (super-new)

    (define instance
      (or gst-bus (gst_bus_new)))

    ;(connect-message instance)
    ;(gst_bus_add_signal_watch instance)

    (define/public (on-message msg)
      (void))

    (define/public (add-watch f)
      (let ([callback
             (lambda (bus msg data)
               (f (GstMessage-type msg)))])
        (gst_bus_add_watch instance callback #f)))))

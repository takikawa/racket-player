#lang racket/base

;; element.rkt

(require ffi/unsafe
         racket/class
         "bus.rkt"
         "utils.rkt")

(provide _GstElement
         element%)
 
(define _GstElement (_cpointer 'GstElement))

(define _GstState (_enum '(void-pending null
                           ready paused playing)))
(define _GstStateChangeReturn
  (_enum '(failure success async no-preroll)))

(define-gst gst_element_get_bus (_fun _GstElement -> _GstBus))
(define-gst gst_element_set_state 
  (_fun _pointer _GstState -> _GstStateChangeReturn))
(define-gst gst_element_get_state
  (_fun _GstElement _pointer _pointer _uint64 -> _void))

(define element%
  (class object%
    (super-new)
    (init instance)

    (define gst-instance instance)

    (define/public (get-instance)
      gst-instance)
    
    (define/public (get-bus)
      (make-object bus%
        (gst_element_get_bus gst-instance)))
    
    (define/public (get-state)
      (define state (malloc _GstState))
      (define pending (malloc _GstState))
      (gst_element_get_state gst-instance state pending 0)
      (cons (ptr-ref state _GstState)
            (ptr-ref pending _GstState)))
    
    (define/public (set-state st)
      (gst_element_set_state gst-instance st))))

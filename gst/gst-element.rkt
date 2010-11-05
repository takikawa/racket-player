#lang racket

;; gst-element

(require ffi/unsafe
         racket/class
         "gst-bus.rkt"
         "utils.rkt")

(provide _GstElement
         gst-element%)
 
(define _GstElement (_cpointer 'GstElement))

(define _GstState (_enum '(void-pending null
                           ready paused playing)))
(define _GstStateChangeReturn
  (_enum '(failure success async no-preroll)))

(define-gst gst_element_get_bus (_fun _GstElement -> _GstBus))
(define-gst gst_element_set_state 
  (_fun _pointer _GstState -> _GstStateChangeReturn))
(define-gst gst_element_get_state
  (_fun _GstElement -> _void))

(define gst-element%
  (class object%
    (super-new)
    (init-field _gst-element)
    
    (define/public (get-bus)
      (make-object gst-bus%
        (gst_element_get_bus _gst-element)))
    
    (define/public (get-state)
      (gst_element_get_state _gst-element))
    
    (define/public (set-state! st)
      (gst_element_set_state _gst-element st))))

#lang racket/base

;; element.rkt

(require ffi/unsafe
         racket/class
         "bus.rkt"
         "utils.rkt"
	 "types.rkt")

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
(define-gst gst_element_query_position
  (_fun _GstElement _pointer _pointer -> _bool))
(define-gst gst_element_query_duration
  (_fun _GstElement _pointer _pointer -> _bool))
(define-gst gst_element_seek_simple
  (_fun _GstElement _GstFormat _GstSeekFlags _gint64 -> _bool))

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

    (define/public (get-position)
      (define format (malloc _GstFormat))
      (define cur (malloc _gint64))
      (ptr-set! format _GstFormat 'time)
      (when (gst_element_query_position gst-instance format cur)
        (ptr-ref cur _gint64)))

    (define/public (get-duration)
      (define format (malloc _GstFormat))
      (define duration (malloc _gint64))
      (ptr-set! format _GstFormat 'time)
      (when (gst_element_query_duration gst-instance format duration)
        (ptr-ref duration _gint64)))

    (define/public (seek-simple seek-flag pos)
      (gst_element_seek_simple gst-instance 'time seek-flag pos))

    (define/public (get-state)
      (define state (malloc _GstState))
      (define pending (malloc _GstState))
      (gst_element_get_state gst-instance state pending 0)
      (cons (ptr-ref state _GstState)
            (ptr-ref pending _GstState)))

    (define/public (set-state st)
      (gst_element_set_state gst-instance st))))

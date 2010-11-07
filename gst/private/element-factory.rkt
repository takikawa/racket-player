#lang racket

;; element-factory.rkt

(require ffi/unsafe
         "element.rkt"
         "utils.rkt")

(provide gst_element_factory_make)

(define _GstElementFactory (_cpointer 'GstElementFactory))

(define-gst gst_element_factory_make
  (_fun _string _string -> _GstElement))

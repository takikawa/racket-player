#lang racket

;; gst-pipeline.rkt
;; 

(require ffi/unsafe
         racket/class
         "gst-bus.rkt"
         "gst-element.rkt"
         "utils.rkt"
         "types.rkt")

(define _GstPipeline (_cpointer '(GstElement GstPipeline)))

(define-gst gst_pipeline_new (_fun _string -> _GstElement))
(define-gst gst_pipeline_get_bus (_fun _GstPipeline -> _GstBus))
;;(define-gst gst_pipeline_set_clock (_fun _GstPipeline _GstClock -> _gboolean))
;;(define-gst gst_pipeline_get_clock (_fun _GstPipeline -> _GstClock))
;;(define-gst gst_pipeline_use_clock (_fun _GstPipeline -> _GstClock -> _void))
(define-gst gst_pipeline_auto_clock (_fun _GstPipeline -> _void))
(define-gst gst_pipeline_set_auto_flush_bus (_fun _GstPipeline _gboolean -> _void))
(define-gst gst_pipeline_get_auto_flush_bus (_fun _GstPipeline -> _gboolean))
;;(define-gst gst_pipeline_set_delay (_fun _GstPipeline _GstClockTime -> _void))
;;(define-gst gst_pipeline_get_delay (_fun _GstPipeline -> _GstClockTime))

(define gst-pipeline
  (class gst-element%
    (init _gst_pipeline)
    
    (super-new (_gst-element _gst_pipeline))
    (inherit-field _gst-element)
    
    (define/override (get-bus)
      (make-object gst-bus%
        (gst_pipeline_get_bus _gst-element)))
    
    (define/public (auto-clock)
      (gst_pipeline_auto_clock _gst-element))
    
    (define/public (set-auto-flush-bus flag)
      (gst_pipeline_set_auto_flush_bus _gst-element flag))
    
    (define/public (get-auto-flush-bus)
      (gst_pipeline_get_auto_flush_bus _gst-element))))
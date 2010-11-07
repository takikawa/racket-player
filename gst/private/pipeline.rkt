#lang racket/base

;; pipeline.rkt
;; 

(require ffi/unsafe
         racket/class
         "bus.rkt"
         "element.rkt"
         "utils.rkt"
         "types.rkt")

(provide _GstPipeline

	 pipeline%)

(define _GstPipeline (_cpointer 'GstPipeline _GstElement))

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

(define pipeline%
  (class element%
    (inherit get-instance)
    (init [instance #f])
    
    (super-new [instance (or instance
			     (gst_pipeline_new "pipeline"))])

    (define gst-instance (get-instance))
    (cpointer-push-tag! gst-instance 'GstPipeline)
    
    (define/override (get-bus)
      (make-object bus%
        (gst_pipeline_get_bus gst-instance)))
    
    (define/public (auto-clock)
      (gst_pipeline_auto_clock gst-instance))
    
    (define/public (set-auto-flush-bus flag)
      (gst_pipeline_set_auto_flush_bus gst-instance flag))
    
    (define/public (get-auto-flush-bus)
      (gst_pipeline_get_auto_flush_bus gst-instance))))

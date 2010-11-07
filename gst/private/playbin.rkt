#lang racket

;; playbin.rkt

(require ffi/unsafe
         "element-factory.rkt"
         "pipeline.rkt"
         "utils.rkt")

(provide playbin%)

(define _GstPlaybin (_cpointer 'GstPlaybin _GstPipeline))
    
(define-signal-handler connect-about-to-finish "about-to-finish"
  (_fun _GstPlaybin _pointer -> _void)
  (lambda (instance data)
    (displayln "about to finish")))

(define playbin%
  (class pipeline%
    (inherit get-instance)

    (super-new 
      [instance (gst_element_factory_make "playbin2" "play")])
    
    (define gst-instance (get-instance))
    (cpointer-push-tag! gst-instance 'GstPlaybin)

    ;(connect-about-to-finish gst-instance)
  
    (define/public (set-uri uri)
      (gobject-set-string gst-instance "uri" uri))
   
    ;; default impl.
    (define/public (on-about-to-finish)
      ;; debug
      (displayln "About to finish!")
      (void))))

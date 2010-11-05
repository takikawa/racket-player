#lang racket

;; gst-message.rkt

(require ffi/unsafe
         "types.rkt")

(provide _GstMessage
         GstMessage-type
         GstMessage-timestamp
         GstMessage-mini-object
         GstMessage-src
         GstMessage-structure)

;; opaque and not meant to be used
(define _GTypeInstance (_list-struct _pointer))

(define _GstObject (_cpointer 'GstObject))
(define _GstStructure (_cpointer 'GstStructure))

(define-cstruct _GstMiniObject
  ([instance _GTypeInstance]
   [refcount _gint]
   [flags _guint]))

(define-cstruct _GstMessage
  ([mini-object _GstMiniObject]
   [type _GstMessageType]
   [timestamp _guint64]
   [src _GstObject]
   [structure _GstStructure]))
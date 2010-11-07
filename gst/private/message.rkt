#lang racket

;; message.rkt

(require ffi/unsafe
         "types.rkt")

(provide _GstMessage
         _GstMessage-pointer
	 
	 GstMessage?
	 GstMessage-type
	 GstMessage-timestamp)

(define _GstObject (_cpointer 'GstObject))
(define _GstStructure (_cpointer 'GstStructure))

(define-cstruct _GstMiniObject
  (;; opaque type instance
   [instance _pointer]
   ;; public
   [refcount _gint]
   [flags _guint]
   ;; private
   [gst_reserved _pointer]))

(define-cstruct _GstMessage
  (;; parent structure
   [mini-object _GstMiniObject]
   ;; private
   [lock _pointer]
   [gcond _pointer]
   ;; public
   [type _GstMessageType]
   [timestamp _guint64]
   [src _GstObject]
   [structure _GstStructure]
   ;; private
   [abidata _pointer]))

#lang racket

;; utils.rkt
;; Gstreamer Utilities

(require ffi/unsafe
         ffi/unsafe/alloc
         "types.rkt")

(provide define-gst
         define-glib
         define-gobject
         gstreamer-lib
         
         define-signal-handler
         
         gobject-set-string)

;; FFI libraries for GStreamer
(define gstreamer-lib
  (ffi-lib "libgstreamer-0.10" "0"))
(define glib-lib
  (ffi-lib "libglib-2.0"))
(define gobject-lib
  (ffi-lib "libgobject-2.0"))

;; Definers for GStreamer
;; roll our own ffi-definer since ffi/unsafe/define
;; does not seem to work across modules for this
(define-syntax-rule (define-definer name library)
  (define-syntax name
    (lambda (stx)
      (syntax-case stx ()
        [(_ name ctype)
         #'(define name
             (get-ffi-obj (symbol->string (quote name)) library ctype))]))))

(define-definer define-gst gstreamer-lib)
(define-definer define-gobject gobject-lib)
(define-definer define-glib glib-lib)

(define-gobject g_signal_connect_data 
  (_fun _pointer _string _pointer _pointer _pointer _int -> _gulong))
(define (g_signal_connect instance signal-name callback data)
  (g_signal_connect_data instance signal-name callback data #f 0))

;; Utility functions
;; gobject-set-string : GObject String String -> void
;; sets a property on a GObject (only for strings)
(define (gobject-set-string gobj str val)
  (define c-setter
    (get-ffi-obj "g_object_set"
                 gobject-lib 
                 (_fun _pointer _string _string _pointer -> _void)))
  (c-setter gobj str val #f))

;; signal-handler macro taken from MrEd
(define-syntax-rule (define-signal-handler 
                      connect-name
                      signal-name
                      (_fun . args)
                      proc)
  (begin
    (define handler-proc proc)
    (define handler_function
      (function-ptr handler-proc (_fun #:atomic? #t . args)))
    (define (connect-name instance [user-data #f])
      (g_signal_connect instance signal-name handler_function user-data))))
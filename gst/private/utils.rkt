#lang racket

;; utils.rkt
;; Gstreamer Utilities

(require ffi/unsafe
         ffi/unsafe/alloc
         "types.rkt")

(provide define-gst
         define-glib
         define-gobject

         define-signal-handler
	 gst->rkt

	 path->uri
	 uri->path
         
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

(define-gst gst_object_ref (_fun _pointer -> _pointer))
(define-gst gst_object_unref (_fun _pointer -> _void))

(define-gobject g_signal_connect_data 
  (_fun _fpointer _string _fpointer _pointer _fpointer _int -> _gulong))
(define (g_signal_connect instance signal-name callback data)
  (g_signal_connect_data instance signal-name callback data #f 0))
(define-gobject g_object_get_data
  (_fun _pointer _string -> _pointer))

;; Utility functions
;; gobject-set-string : GObject String String -> void
;; sets a property on a GObject (only for strings)
(define (gobject-set-string gobj str val)
  (define c-setter
    (get-ffi-obj "g_object_set"
                 gobject-lib 
                 (_fun _pointer _string _string _pointer -> _void)))
  (c-setter gobj str val #f))

;; URI functions
(define-glib g_filename_from_uri 
	     (_fun _string _pointer _pointer ->  _path))
(define-glib g_filename_to_uri
	     (_fun _path _string _pointer ->  _string))
(define (path->uri path)
  (g_filename_to_uri path #f #f))
(define (uri->path uri)
  (g_filename_from_uri uri #f #f))

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

;; taken from MrEd as well
(define (gst->rkt gst)
  (let ([ptr (g_object_get_data gst "rkt")])
    (and ptr
         (let ([wb (ptr-ref ptr _scheme)])
           (and wb (weak-box-value wb))))))

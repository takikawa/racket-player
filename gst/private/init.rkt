#lang racket

;; init.rkt

(require ffi/unsafe
         "utils.rkt"
         "types.rkt")

(provide g_main_loop_new
         g_main_loop_run
         g_main_loop_quit

	 gstreamer-initialize
         gst_init
         gst_init_check)

(define (gstreamer-initialize)
  (gst_init_check #f #f #f))

(define-gst gst_init (_fun _pointer _pointer -> _void))
(define-gst gst_init_check (_fun _pointer _pointer _pointer -> _bool))

(define-glib g_main_loop_new (_fun _GMainContext _gboolean -> _GMainLoop))
(define-glib g_main_loop_run (_fun _GMainLoop -> _void))
(define-glib g_main_loop_quit (_fun _GMainLoop -> _void))

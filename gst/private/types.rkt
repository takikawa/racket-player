#lang racket

;; types.rkt
;; GStreamer types and constants

(require ffi/unsafe)

(provide _gboolean
         _gint
	 _gint64
         _guint
         _guint64
         _gulong
         
         _GMainContext
         _GMainLoop
        
	 _GstFormat
	 GST_FORMAT_PERCENT_MAX
	 GST_FORMAT_PERCENT_SCALE

	 _GstSeekFlags

         _GstMessageType)

(define << arithmetic-shift)

(define _gint _int)
(define _guint _uint)
(define _gint64 _int64)
(define _guint64 _uint64)
(define _gulong _ulong)
(define _gboolean _bool)

(define _GMainContext (_cpointer/null 'GMainContext))
(define _GMainLoop (_cpointer 'GMainLoop))

(define GST_FORMAT_PERCENT_MAX 1000000)
(define GST_FORMAT_PERCENT_SCALE 10000)

(define _GstFormat
  (_enum '(undefined default bytes time
           buffers percent)))

(define _GstSeekFlags
  (_enum
    `(none      = 0
      flush     = ,(1 . << . 0)
      accurate  = ,(1 . << . 1)
      key-unit  = ,(1 . << . 2)
      segment   = ,(1 . << . 3)
      flag-skip = ,(1 . << . 4))))

(define _GstMessageType
  (_enum
   `(unknown          = 0
     eos              = ,(1 . << . 0)
     error            = ,(1 . << . 1)
     warning          = ,(1 . << . 2)
     info             = ,(1 . << . 3)
     tag              = ,(1 . << . 4)
     buffering        = ,(1 . << . 5)
     state-changed    = ,(1 . << . 6)
     state-dirty      = ,(1 . << . 7)
     step-done        = ,(1 . << . 8)
     clock-provide    = ,(1 . << . 9)
     clock-lost       = ,(1 . << . 10)
     new-clock        = ,(1 . << . 11)
     structure-change = ,(1 . << . 12)
     stream-status    = ,(1 . << . 13)
     application      = ,(1 . << . 14)
     element          = ,(1 . << . 15)
     segment-start    = ,(1 . << . 16)
     segment-done     = ,(1 . << . 17)
     duration         = ,(1 . << . 18)
     latency          = ,(1 . << . 19)
     async-start      = ,(1 . << . 20)
     async-done       = ,(1 . << . 21)
     request-state    = ,(1 . << . 22)
     step-start       = ,(1 . << . 23)
     qos              = ,(1 . << . 24)
     any              = ,(bitwise-not 0))
     _gint))

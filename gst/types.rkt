#lang racket

;; types.rkt
;; GStreamer types

(require ffi/unsafe)

(provide _gboolean
         _gint
         _guint
         _guint64
         _gulong
         
         _GMainContext
         _GMainLoop
         
         _GstMessageType)

(define << arithmetic-shift)

(define _gint _int)
(define _guint _uint)
(define _guint64 _uint64)
(define _gulong _ulong)
(define _gboolean _bool)

(define _GMainContext (_cpointer/null 'GMainContext))
(define _GMainLoop (_cpointer 'GMainLoop))

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
     any              = ,(bitwise-not 0))))
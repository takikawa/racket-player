#lang racket/base

;; wrapper module that applies contracts before exports

(require racket/contract
         racket/class
         "private/bus.rkt"
         "private/element.rkt"
         "private/element-factory.rkt"
         "private/init.rkt"
         "private/message.rkt"
         "private/pipeline.rkt"
         "private/playbin.rkt"
         "private/types.rkt"
         "private/utils.rkt")

(define message-type/c
  (one-of/c 'unknown 'eos 'error 'warning 'info
            'tag 'buffering 'state-changed 'state-dirty 'step-done
            'clock-provide 'clock-lost 'new-clock 'structure-change 'stream-status
            'application 'element 'segment-start 'segment-done 'duration
            'latency 'async-start 'async-done 'request-state 'step-start
            'qos 'any))

(define state/c
  (one-of/c 'pending 'null 'ready 'paused 'playing))

(define seek-flag/c
  (one-of/c 'none 'flush 'accurate 'key-unit 'segment 'skip))

(provide/contract
  [gstreamer-initialize (-> boolean?)]
  [path->uri (-> path-string? string?)]
  [uri->path (-> string? path-string?)]
  [bus%
    (class/c
      [on-message (->m message-type/c void?)]
      [add-watch (->m (-> message-type/c void?) void?)])]
  [element%
    (class/c
      [get-bus (->m (is-a?/c bus%))]
      [get-position (->m exact-nonnegative-integer?)]
      [get-duration (->m exact-nonnegative-integer?)]
      [seek-simple (->m seek-flag/c exact-nonnegative-integer? boolean?)]
      [get-state (->m (cons/c state/c state/c))]
      [set-state (->m state/c void?)]
      (override
        [get-bus (->m (is-a?/c bus%))]
        [get-state (->m (cons/c state/c state/c))]
        [set-state (->m state/c void?)]))]
  [pipeline%
    (class/c
      [auto-clock (->m void?)]
      [set-auto-flush-bus (->m boolean? void?)]
      [get-auto-flush-bus (->m boolean?)]
      (override
        [auto-clock (->m void?)]
        [set-auto-flush-bus (->m boolean? void?)]
        [get-auto-flush-bus (->m boolean?)]))]
  [playbin%
    (class/c
      [set-uri (->m string? void?)]
      [on-about-to-finish (->m void?)])])

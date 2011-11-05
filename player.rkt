#lang racket/base

;; example music player

(require racket/class
         (except-in racket/gui tag)
         framework
         taglib
         "gst/gst.rkt")

(unless (gstreamer-initialize)
  (error "Could not initialize GStreamer"))

(define icon-color (make-object color% "white"))
(define play-icon  (make-object bitmap% "icons/media-playback-start.png" 'png icon-color))
(define pause-icon (make-object bitmap% "icons/media-playback-pause.png" 'png icon-color))
(define stop-icon  (make-object bitmap% "icons/media-playback-stop.png" 'png icon-color))
(define fwd-icon   (make-object bitmap% "icons/media-skip-forward.png" 'png icon-color))
(define bwd-icon   (make-object bitmap% "icons/media-skip-backward.png" 'png icon-color))

(define player-frame%
  (class frame%
    (inherit create-status-line set-status-text)
    (super-new [label "Music player"]
               [stretchable-width #t])

    (create-status-line)

    (define player (new player% [playbin (new playbin%)]
                                [frame this]))

    (define control-panel (new horizontal-panel%
                               [parent this]
                               [stretchable-height #f]))

    (define backward-button
      (make-object button% bwd-icon control-panel
                   (lambda (b e)
                     (send playlist play-last))))

    (define play-button
      (make-object button% play-icon control-panel
                   (lambda (b e)
                     (send player toggle-pause-play))))

    (define stop-button
      (make-object button% stop-icon control-panel
                   (lambda (b e)
                     (send player stop))))

    (define forward-button
      (make-object button% fwd-icon control-panel
                   (lambda (b e)
                     (send playlist play-next))))

    (define now-playing (new message%
                             [label "No file"]
                             [parent control-panel]
                             [stretchable-width #t]))

     (define progress
       (new slider%
            [label #f]
            [min-value 0]
            [max-value 1000]
            [init-value 0]
            [style '(plain horizontal)]
            [parent control-panel]
            [callback
            (lambda (sl e)
              (send player set-progress
                (/ (send sl get-value) 1000)))]))

     (define play-timer
       (new timer% [notify-callback
                    (lambda ()
                      (send progress set-value
                            (floor (* 1000 (send player get-progress)))))]))

     (send now-playing auto-resize #t)

     (define playlist (new playlist% [player player] [parent this]))

     (define menu-bar (make-object menu-bar% this))
     (define fmenu (make-object menu% "&File" menu-bar))
     (define open-item
       (make-object menu-item%
         "&Open file"
         fmenu
         (lambda (mi evt)
           (define path (finder:get-file))
           (when path
             (send playlist open-and-play
                   (new song% [path path]))))))

     (define enqueue-item
       (make-object menu-item%
                    "&Enqueue file"
                    fmenu
                    (lambda (mi evt)
                      (define path (finder:get-file))
                      (when path
            	    (send playlist enqueue (new song% [path path]))))))

     (define/override (on-size w h)
       ;(send playlist update-width w)
       (super on-size w h))

     (define/public (on-paused)
       (send play-button set-label play-icon)
       (send play-timer stop))

     (define/public (on-playing)
       (send play-button set-label pause-icon)
       (send play-timer start 500))

     (define/public (on-stopped)
       (send play-button set-label play-icon)
       (send play-timer stop))

     (define/public (on-song-ended)
       (send play-button set-label play-icon)
       (send play-timer stop)
       (send playlist play-next))

     (define/public (set-metadata tag audio-props)
       (send now-playing set-label (tag-title tag))
       (set-status-text
        (format "Length: ~a Bitrate: ~a Samplerate: ~a Channels: ~a"
          (audio-properties-length audio-props)
          (audio-properties-bitrate audio-props)
          (audio-properties-samplerate audio-props)
          (audio-properties-channels audio-props))))))

(define player%
  (class object%
    (init playbin frame)

    (super-new)

    (define pb playbin)
    (define ui frame)
    (define current-song #f)

    (define bus (send pb get-bus))
    (send bus add-watch
          (lambda (msg)
            (case msg
              ['state-changed
               (let ([st (current-state)])
                 (case st
                   ['paused (send ui on-paused)]
                   ['playing (send ui on-playing)]
           	['null (send ui on-stopped)]))]
              ['eos (begin
                     (stop)
                     (send ui on-song-ended))])
            #t))

    (define (current-state)
      (car (send pb get-state)))

    (define (stopped? st)
      (eq? st 'null))

    (define (playing? st)
      (eq? st 'playing))

    (define (paused? st)
      (eq? st 'paused))

    (define/public (get-progress)
      (/ (send pb get-position)
         (send pb get-duration)))

    (define/public (set-progress pct)
      (send pb seek-simple 'flush (* pct (send pb get-duration))))

    (define/public (toggle-pause-play)
      (let ([st (current-state)])
        (cond [(or (stopped? st) (paused? st))
               (play)]
              [(playing? st) (pause)])))

    (define/public (play)
      (send pb set-state 'playing))

    (define/public (stop)
      (send pb set-state 'null))

    (define/public (pause)
      (send pb set-state 'paused))

    (define/public (set-next-song song)
      (stop)
      (send pb set-uri (path->uri (get-field path song)))
      (send ui set-metadata
            (get-field tag song)
            (get-field audio-props song))
      (play))))

(define song%
  (class object%
    (init-field path)
    (define metadata (get-tags path))
    (field [tag (first metadata)]
           [audio-props (second metadata)])

    (super-new)))


(define playlist%
  (class list-box%

    ;; start with supplying parent inits
    (super-new [label ""] [choices '()]
               [style (list 'single 'column-headers)]
               [columns '("Title" "Artist" "Album" "Track")]
               ;; undo user choice if it's a single click, but
               ;; play the selection if it's a double click
               [callback (λ (this ce)
                           (match (send ce get-event-type)
                             ['list-box
                              (unless (null? current)
                                (select (first current)))]
                             ['list-box-dclick
                              ;; TODO: should change selection
                              (play-current)]))])

    ;; additional initialization
    (init-field player)

    (inherit append clear get-data get-number
             get-selections select set-string)

    ;; keep track of the selection separately so that
    ;; user selections can be undone
    (define current '())

    ;; song% -> void?
    ;; put a new song into the playlist
    (define (append-song song)
      (define tag (get-field tag song))
      (define title (tag-title tag))
      (append title song)
      (define index (sub1 (get-number)))
      (set-string index (tag-artist tag) 1)
      (set-string index (tag-album tag) 2)
      (set-string index (number->string (tag-track tag)) 3))

    ;; song% -> void?
    ;; clear the playlist and play a new song
    (define/public (open-and-play song)
      (clear)
      (append-song song)
      (select 0)
      (set! current '(0))
      (play-current))

    ;; song% -> void?
    ;; enqueue the next song
    (define/public (enqueue song)
      (append-song song))

    ;; move backward in the playlist
    (define/public (play-last)
      (define selection (first (get-selections)))
      (unless (<= selection 0)
        (select (sub1 selection))
        (set! current (list (sub1 selection)))
        (play-current)))

    ;; move forward in the playlist
    (define/public (play-next)
      (define selection (first (get-selections)))
      (unless (>= selection (sub1 (get-number)))
        (select (add1 selection))
        (set! current (list (add1 selection)))
        (play-current)))

    ;; play whatever is selected now
    (define/public (play-current)
      (define selections (get-selections))
      (define song (get-data (first selections)))
      (send player set-next-song song))))

(define ui (new player-frame%))

(send ui show #t)

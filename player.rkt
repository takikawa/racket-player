#lang racket/base

;; example music player

(require framework
         racket/class
         racket/runtime-path
         taglib
         (except-in racket/gui tag)
         "files.rkt"
         "gst/gst.rkt")

(unless (gstreamer-initialize)
  (error "Could not initialize GStreamer"))

;; GUI constants
(define icon-color (make-object color% "white"))

(define-runtime-path play-icon-path "icons/media-playback-start.png")
(define-runtime-path pause-icon-path "icons/media-playback-pause.png")
(define-runtime-path stop-icon-path "icons/media-playback-stop.png")
(define-runtime-path fwd-icon-path "icons/media-skip-forward.png")
(define-runtime-path bwd-icon-path "icons/media-skip-backward.png")

(define play-icon  (make-object bitmap% play-icon-path 'png icon-color))
(define pause-icon (make-object bitmap% pause-icon-path 'png icon-color))
(define stop-icon  (make-object bitmap% stop-icon-path 'png icon-color))
(define fwd-icon   (make-object bitmap% fwd-icon-path 'png icon-color))
(define bwd-icon   (make-object bitmap% bwd-icon-path 'png icon-color))

(define player-frame%
  (class frame%
    (inherit create-status-line set-status-text)
    (super-new [label "Music player"]
               [stretchable-width #t])

    (create-status-line)

    (define player (new player% [playbin (new playbin%)] [frame this]))

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
                     (send playlist play-toggle))))

    (define stop-button
      (make-object button% stop-icon control-panel
                   (lambda (b e)
                     (send player stop)
                     (on-stopped))))

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
            (λ (sl e)
               (send player set-progress
                     (/ (send sl get-value) 1000)))]))

    (define play-timer
      (new timer%
           [notify-callback
            (λ ()
               (send progress set-value
                     (floor (* 1000 (send player get-progress)))))]))

    (send now-playing auto-resize #t)

    (define playlist (new playlist% [player player] [parent this]))

    (define menu-bar (make-object menu-bar% this))
    (define fmenu (make-object menu% "&File" menu-bar))
    (define open-item
      (make-object
       menu-item%
       "&Open file"
       fmenu
       (lambda (mi evt)
         (define path (finder:get-file))
         (when path
           (send playlist open-and-play
                 (new song% [path path]))))))

    (define enqueue-item
      (make-object
       menu-item%
       "&Enqueue file"
       fmenu
       (lambda (mi evt)
         (define path (finder:get-file))
         (when path
           (send playlist enqueue (new song% [path path]))))))

    (define folder-item
      (make-object
       menu-item%
       "Add folder"
       fmenu
       (lambda (mi evt)
         (define path (get-directory))
         (unless (false? path)
           (define media (get-media-from-folder-path path))
           (for ([fpath media])
             (send playlist enqueue (new song% [path fpath])))))))

    (define/override (on-size w h)
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
      (send pb seek-simple 'flush (floor (* pct (send pb get-duration)))))

    (define/public (toggle-pause-play)
      (let ([st (current-state)])
        (cond [(or (stopped? st) (paused? st)) (play)]
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
           [audio-props (second metadata)]
           [title (tag-title tag)])

    (super-new)))


(define playlist%
  (class list-box%

    ;; start with supplying parent inits
    (super-new [label ""] [choices '()]
               [style (list 'single 'column-headers)]
               [columns '("Title" "Artist" "Album" "Track")]
               [callback (λ (this ce)
                           (match (send ce get-event-type)
                             ['list-box-dclick (play-current)]
                             [_ (void)]))])

    ;; additional initialization
    (init-field player)

    (inherit append clear get-data get-number
             get-selections select get-string set-string)

    ;; used to indicate currently playing song
    (define current-label "▶")

    ;; number of columns
    (define column-num 4)

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
      (play-current))

    ;; song% -> void?
    ;; enqueue the next song
    (define/public (enqueue song)
      (append-song song))

    ;; move backward in the playlist
    (define/public (play-last)
      (define selections (get-selections))
      (unless (null? selections)
        (define selection (first (get-selections)))
        (unless (<= selection 0)
          (select (sub1 selection))
          (play-current))))

    ;; move forward in the playlist
    (define/public (play-next)
      (define selections (get-selections))
      (unless (null? selections)
        (define selection (first selections))
        (unless (>= selection (sub1 (get-number)))
          (select (add1 selection))
          (play-current))))

    ;; play whatever is selected now
    (define/public (play-current)
      (define selections (get-selections))
      (unless (null? selections)
        (define selection (first selections))
        (update-playing selection)
        (define song (get-data selection))
        (send player set-next-song song)))

    ;; pause or play the current song
    (define/public (play-toggle)
      (define selections (get-selections))
      (unless (null? selections)
        (send player toggle-pause-play)))

    ;; add or remove selection label
    (define old-playing #f)
    (define (update-playing n)
      (when old-playing
        (set-string old-playing
                    (substring (get-field title (get-data old-playing)) 2)
                    0))
      (set! old-playing n)
      (set-string n (string-append current-label " "
                                   (get-field title (get-data n)))
                  0))

    (inherit get-width get-column-width set-column-width)
    ;; used to initialize the column widths
    (define (resize-columns/uniform)
      (define total-width (get-width))
      (define each-width (quotient total-width column-num))
      (for ([col column-num])
        (define-values (width min-width max-width) (get-column-width col))
        (set-column-width col each-width min-width max-width)))

    ;; on the first size event, resize columns to reasonable widths
    (define first-size? #t)
    (define/override (on-size w h)
      (when first-size?
        (resize-columns/uniform)
        (set! first-size? #f))
      (super on-size w h))))

(define ui (new player-frame%))

(send ui show #t)

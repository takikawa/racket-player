#lang racket

;; example
(require framework
         mrlib/hierlist
         racket/gui
	 (prefix-in taglib- taglib)
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
	
	 (define progress (new slider%
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
         
         (define playlist (new playlist% [player player]
                               [parent this]))
         
         (define menu-bar (make-object menu-bar% this))
         (define fmenu (make-object menu% "&File" menu-bar))
         (define open-item
           (make-object menu-item%
                        "&Open file"
                        fmenu
                        (lambda (mi evt)
                          (define path (finder:get-file))
                          (when path
			    (send playlist open-and-play (new song% [path path]))))))
         
         (define enqueue-item
           (make-object menu-item%
                        "&Enqueue file"
                        fmenu
                        (lambda (mi evt)
                          (define path (finder:get-file))
                          (when path
			    (send playlist enqueue (new song% [path path]))))))

	 (define/override (on-size w h)
	   (send playlist update-width w)
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
           (send now-playing set-label (taglib-tag-title tag))
           (set-status-text
            (format "Length: ~a Bitrate: ~a Samplerate: ~a Channels: ~a"
	      (taglib-audio-properties-length audio-props)
	      (taglib-audio-properties-bitrate audio-props)
	      (taglib-audio-properties-samplerate audio-props)
	      (taglib-audio-properties-channels audio-props))))))

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
    (define metadata (taglib-get-tags path))
    (field [tag (first metadata)]
           [audio-props (second metadata)])

    (super-new)))


(define playlist%
  (class hierarchical-list%

    ;; "constants" (we set! them on resizes) for
    ;; displaying the list items
    (define CARET-WIDTH 20)
    (define ARTIST-WIDTH 200)
    (define TITLE-WIDTH 200)
    (define ALBUM-WIDTH 200)
    (define SPACING 20)

    ;; mixin for playlist items in hierlist
    (define playlist-item-mixin
      (lambda (item%)
	(class item%
	  (field [playing? #f])

	  (define/public (set-playing? status)
	    (set! playing? status))

	  (define/public (get-playing?)
	    playing?)

	  (super-new))))

    ;; snips for showing playlist items
    ;; with copious help from reading SirMail source code
    (define playlist-item-snip%
      (class snip%
	(inherit get-style)
	(init-field artist title album item)

	(define (playing?) (send item get-playing?))

	(define selected-text-color (make-object color% "olive"))

	(define/override (draw dc x y left top right bottom dx dy draw-caret)
	  (define old-foreground (send dc get-text-foreground))
	  (define old-mode (send dc get-text-mode))
	  (define-values (_1 h _2 _3) (send dc get-text-extent "yX"))

	  (when (playing?)
	    (send dc set-text-foreground selected-text-color))

	  (when (playing?)
	    (send dc draw-text ">" x y #t))

	  (send dc draw-text artist (+ x CARET-WIDTH) y #t)
	  (send dc draw-text title (+ x CARET-WIDTH ARTIST-WIDTH SPACING) y)
	  (send dc draw-text album (+ x CARET-WIDTH ARTIST-WIDTH TITLE-WIDTH (* 2 SPACING)) y)
	
	  (define old-pen (send dc get-pen))
	  (send dc set-pen (send the-pen-list find-or-create-pen "green" 0 'solid))
	  (send dc draw-line (+ x CARET-WIDTH ARTIST-WIDTH (/ SPACING 2))
	                     y
			     (+ x CARET-WIDTH ARTIST-WIDTH (/ SPACING 2))
			     (+ y h))
	  (send dc draw-line (+ x CARET-WIDTH ARTIST-WIDTH TITLE-WIDTH SPACING (/ SPACING 2))
	                     y
			     (+ x CARET-WIDTH ARTIST-WIDTH TITLE-WIDTH SPACING (/ SPACING 2))
			     (+ y h))

	  (send dc set-pen old-pen)
	  (send dc set-text-foreground old-foreground)
	  (send dc set-text-mode old-mode))

	(define/override (get-extent dc x y wb hb db sb lb rb)
	  (define (set-box/f! b v) (when (box? b) (set-box! b v)))
	  (define-values (w h d s) (send dc get-text-extent "yX" (send (get-style) get-font)))
	  (set-box/f! hb h)
	  (set-box/f! wb (get-width))
	  (set-box/f! db d)
	  (set-box/f! sb s)
	  (set-box/f! lb 2)
	  (set-box/f! rb 0))

        (inherit get-admin) 
	(field [width 500])

	(define/public (set-width w)
	  (define admin (get-admin))
	  (when admin
	    (send admin resized this #t))
	  (set! width w))

	(define/public (get-width)
	  width)

	(super-new)))

    ;; playlist% starts here
    (init-field player parent)
    (inherit new-item delete-item select-prev get-items
      select-next set-no-sublists get-selected refresh)

    (super-new [parent parent])

    (set-no-sublists #t)

    (define current-item #f)
    
    (define/override (on-double-select i)
      (update-selected i)
      (play-current))

    (define/public (update-width w)
      (define remaining (- w (* 2 SPACING) CARET-WIDTH))
      (set! ARTIST-WIDTH (floor (* 1/4 remaining)))
      (set! TITLE-WIDTH  (floor (* 1/2 remaining)))
      (set! ALBUM-WIDTH  (floor (* 1/4 remaining)))
      (for-each
        (lambda (snip) 
	  (send snip set-width w))
        (map (lambda (i) 
               (send (send i get-editor) 
	             find-snip 0 'after))
	     (get-items))))

    (define (clear)
      (for ([i (get-items)])
        (delete-item i)))

    (define (update-selected new-sel)
      (when current-item 
	(send current-item set-playing? #f))
      (set! current-item new-sel)
      (send new-sel set-playing? #t))

    ;; song% -> void?
    ;; put a new song into the playlist
    (define (append song)
      (define (format-item item tag)
        (define editor (send item get-editor))
        (define snip
          (new playlist-item-snip%
               [artist (taglib-tag-artist tag)]
               [title  (taglib-tag-title tag)]
               [album  (taglib-tag-album tag)]
               [item   item]))
        (send editor insert snip))

      (let* ([tag (get-field tag song)]
             [title (taglib-tag-title tag)])
	(define item (new-item playlist-item-mixin))
	(format-item item tag)
	(send item user-data song)))

    ;; song% -> void?
    ;; called to play a new song, ignore the playlist
    (define/public (open-and-play song)
      (clear)
      (append song)
      (update-selected (first (get-items)))
      (play-current))

    ;; song% -> void?
    ;; enqueue the next song (at the end)
    (define/public (enqueue song)
      (append song))
   
    ;; move backward in the playlist
    (define/public (play-last)
      (select-prev)
      (update-selected (get-selected))
      (play-current))

    ;; move forward in the playlist
    (define/public (play-next)
      (select-next)
      (update-selected (get-selected))
      (play-current))

    ;; play whatever is selected now
    (define/public (play-current)
      (refresh)
      (when current-item
        (let ([next-song (send current-item user-data)])
	  (send player set-next-song next-song))))))

(define ui (new player-frame%))

(send ui show #t)

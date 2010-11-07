#lang racket

;; example
(require framework
         mrlib/hierlist
         racket/gui
	 (prefix-in taglib- "taglib/taglib.rkt")
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

         (define/public (set-metadata metadata)
           (send now-playing set-label (taglib-tag-title metadata))
           (set-status-text
            (format "Length: ~a Bitrate: ~a Samplerate: ~a Channels: ~a"
	      (taglib-tag-length metadata)
	      (taglib-tag-bitrate metadata)
	      (taglib-tag-samplerate metadata)
	      (taglib-tag-channels metadata))))))

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
           (send ui set-metadata (get-field metadata song))
           (play))))

(define song%
  (class object%
    (init-field path)
    (field [metadata (taglib-get-tags path)])

    (super-new)))


(define playlist%
  (class hierarchical-list%
    (init-field player parent)
    (inherit new-item delete-item select-prev get-items
      select-next set-no-sublists get-selected)

    (super-new [parent parent])

    (set-no-sublists #t)

    (define current-item #f)
    
    (define/override (on-double-select i)
      (set! current-item (get-selected))
      (play-current))

    (define (clear)
      (for ([i (get-items)])
        (delete-item i)))

    (define (append song)
      (let* ([tag (get-field metadata song)]
             [title (taglib-tag-title tag)])
	(define item (new-item))
	(send (send item get-editor) insert title)
	(send item user-data song)))

    ;; song% -> void?
    ;; called to play a new song, ignore the playlist
    (define/public (open-and-play song)
      (clear)
      (append song)
      (set! current-item (first (get-items)))
      (play-current))

    ;; song% -> void?
    ;; enqueue the next song (at the end)
    (define/public (enqueue song)
      (append song))
   
    ;; move backward in the playlist
    (define/public (play-last)
      (select-prev)
      (set! current-item (get-selected))
      (play-current))

    ;; move forward in the playlist
    (define/public (play-next)
      (select-next)
      (set! current-item (get-selected))
      (play-current))

    ;; play whatever is selected now
    (define/public (play-current)
      (when current-item
        (let ([next-song (send current-item user-data)])
	  (send player set-next-song next-song))))))

(define ui (new player-frame%))

(send ui show #t)

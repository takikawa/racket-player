#lang racket

;; example
(require framework
         racket/gui
	 (prefix-in taglib- "taglib/taglib.rkt")
	 "gst/gst.rkt")

(when (gstreamer-initialize)
  (displayln "Initialization success"))

(define play-icon (make-object bitmap% "icons/media-playback-start.png" 'png))
(define pause-icon (make-object bitmap% "icons/media-playback-pause.png" 'png))
(define stop-icon (make-object bitmap% "icons/media-playback-stop.png" 'png))

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
                                    [stretchable-height #f]
                                    [spacing 2]))
         (define play-button
           (make-object button% play-icon control-panel
                        (lambda (b e)
                          (send player toggle-pause-play))))
         
         (define stop-button
           (make-object button% stop-icon control-panel
                        (lambda (b e)
                          (send player stop))))
         
         (define now-playing (new message%
                                  [label "No file"]
                                  [parent control-panel]
                                  [stretchable-width #t]))
         
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
			    (send playlist push-and-play (new song% [path path]))))))
         
         (define enqueue-item
           (make-object menu-item%
                        "&Enqueue file"
                        fmenu
                        (lambda (mi evt)
                          (define path (finder:get-file))
                          (when path
			    (send playlist enqueue (new song% [path path]))))))

         (define/public (on-paused)
           (send play-button set-label pause-icon))
         
         (define/public (on-playing)
           (send play-button set-label play-icon))
         
         (define/public (on-song-ended)
	   (send playlist remove-song))

         (define/public (set-metadata metadata)
           (send now-playing set-label (taglib-tag-title metadata))
           (set-status-text
            (string-append "Now playing: "
                           (number->string (taglib-tag-track metadata))
                           " - " (taglib-tag-title metadata)
                           " (" (taglib-tag-artist metadata) ")")))))

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
                        ['playing (send ui on-playing)]))]
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
	   (send pb set-uri (path->uri (get-field path song)))
           (send ui set-metadata (get-field metadata song))
           (stop)
           (play))))

(define song%
  (class object%
    (init-field path)
    (field [metadata (taglib-get-tags path)])

    (super-new)))


(define playlist%
  (class list-box%
    (init-field player parent)
    (inherit append delete get-data set-string
             get-number set-data get-string)

    (super-new [label #f]
               [choices '()]
	       [parent parent])

    ;; -> song% or #f
    ;; gets the head of the queue
    (define/public (get-current-song)
      (if (zero? (get-number))
          #f
	  (get-data 0)))

    ;; song% -> void?
    ;; called to play a new song as the head of the queue
    (define/public (push-and-play song)
      (let ([tag (get-field metadata song)])
        (push-on-front (taglib-tag-title tag) song)
	(play-next)))

    ;; push to front of list-box choices
    (define (push-on-front str data)
      (if (zero? (get-number))
	  (append str data)
	  (let* ([temp-str (get-string 0)]
	         [temp-dat (get-data 0)])
	    (begin
	      (set-string 0 str)
	      (set-data 0 data)
	      (set-string 1 temp-str)
	      (set-data 1 temp-dat)))))

    ;; song% -> void?
    ;; enqueue the next song (at the end)
    (define/public (enqueue song)
      (let ([tag (get-field metadata song)])
	(append (taglib-tag-title tag) song)))

    (define/public (remove-song)
      (when (not (zero? (get-number)))
	(delete 0)
	(play-next)))

    (define/public (play-next)
      (when (not (zero? (get-number)))
	(let* ([next-song (get-data 0)])
	  (send player set-next-song next-song))))))

(define ui (new player-frame%))

(send ui show #t)

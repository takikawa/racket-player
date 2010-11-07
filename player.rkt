#lang racket

;; example
(require framework
         racket/gui
	 (prefix-in taglib- "../taglib/taglib.rkt")
         "gst-bus.rkt"
         "gst-message.rkt"
         "init.rkt"         
         "playbin.rkt"
	 "utils.rkt")

(define loop (g_main_loop_new #f #f))

(when (gst_init_check #f #f #f)
  (displayln "Initialization success"))

(define pb (make-object playbin%))

(define play-icon (make-object bitmap% "../icons/media-playback-start.png" 'png))
(define pause-icon (make-object bitmap% "../icons/media-playback-pause.png" 'png))
(define stop-icon (make-object bitmap% "../icons/media-playback-stop.png" 'png))

(define frame (new frame% 
		   [label "frame"]
		   [stretchable-width #t]))

(send frame create-status-line)

(define panel (new horizontal-panel% 
		   [parent frame]
		   [stretchable-height #f]
		   [spacing 2]))

(define button 
  (make-object button% play-icon panel
    (lambda (b e)
      (let ([st (car (send pb get-state))])
        (cond [(eq? st 'null)
	       (play-next)]
	      [(eq? st 'paused)
	       (send pb set-state 'playing)]
	      [(eq? st 'playing)
	       (send pb set-state 'paused)]
	      [else (void)])))))

(define (remove-song)
  (when (not (zero? (send list-box get-number)))
    (send list-box delete 0)
    (play-next)))

(define (play-next)
  (when (not (zero? (send list-box get-number)))
    (let* ([next-song (send list-box get-data 0)]
	   [path (car next-song)]
	   [meta (cdr next-song)])
      (send pb set-uri (path->uri path))
      (send pb set-state 'playing)
      (set-metadata meta))))

(define stop
  (make-object button% stop-icon panel
    (lambda (b e)
      (let ([st (car (send pb get-state))])
        (cond [(or (eq? st 'playing) (eq? st 'paused))
	       (send pb set-state 'null)]
	      [else (void)])))))

(define message (new message% 
		     [label "No file"] 
		     [parent panel]
		     [stretchable-width #t]))
(send message auto-resize #t)

(define list-box (new list-box%
		      [label #f]
		      [choices '()]
		      [parent frame]))

(define menu-bar (make-object menu-bar% frame))
(define fmenu (make-object menu% "&File" menu-bar))
(define open-item
  (make-object menu-item%
               "&Open file"
               fmenu
               (lambda (mi evt)
                 (define path (finder:get-file))
                 (when path
                   (send pb set-uri (path->uri path))
                   (let ([metadata (taglib-get-tags path)])
		     (set-metadata metadata))))))

(define (set-metadata metadata)
  (send message set-label (taglib-tag-title metadata))
  (send frame set-status-text
        (string-append "Now playing: "
                       (number->string (taglib-tag-track metadata))
                       " - " (taglib-tag-title metadata)
                       " (" (taglib-tag-artist metadata) ")")))

(define enqueue-item
  (make-object menu-item%
               "&Enqueue file"
               fmenu
               (lambda (mi evt)
                 (define path (finder:get-file))
                 (when path
                   (send pb set-uri (path->uri path))
                   (let ([metadata (taglib-get-tags path)])
		     (send list-box append (taglib-tag-title metadata)
			   (cons path metadata)))))))

(define bus (send pb get-bus))
(send bus add-watch
      (lambda (msg)
        (case msg
	  ['state-changed
	   (let ([new-state (car (send pb get-state))])
	     (case new-state
	       ['paused (send button set-label play-icon)]
	       ['playing (send button set-label pause-icon)]))]
	  ['eos (begin
		  (send button set-label play-icon)
		  (remove-song)
		  (send pb set-state 'null))]
	  [else (displayln msg)])
	#t))

(send frame show #t)

;(send pb set-state 'playing)

#lang racket

;; Utility functions for dealing with media files and folders

(provide/contract
  [media-file-path? (-> path-string? boolean?)]
  [get-media-from-folder-path 
    (-> path-string? (listof path-string?))])

(define media-extensions
  (list #"mp3" #"ogg" #"flac" #"wav"))

;; path-string? -> boolean
;; check if this path points to a media file
(define (media-file-path? path)
  (and (member (filename-extension path) media-extensions)
       (file-exists? path)))

;; path-string? -> (list path-string?)
;; get paths of all media files in a folder
;; precondition: path-string? is a directory path
(define (get-media-from-folder-path path)
  (if (directory-exists? path)
      (append-map (lambda (p) (get-media-from-path (build-path path p)))
                  (directory-list path))
      '()))

;; path-string? -> (list path-string?)
;; mutually recursive helper to collect paths of media from some path
(define (get-media-from-path path)
  (cond
    [(and (file-exists? path)
          (media-file-path? path))
     (list path)]
    ;; ignore links to avoid cycles
    [(and (directory-exists? path) (not (link-exists? path)))
     (get-media-from-folder-path path)]
    [else '()]))

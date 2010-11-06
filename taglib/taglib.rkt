#lang racket

(require ffi/unsafe
	 ffi/unsafe/define)

(provide (struct-out tag)
         get-tags

         taglib_set_strings_unicode
         taglib_set_string_management_enabled
         
         taglib_file_new
         taglib_file_new_type
         taglib_file_free
         taglib_file_is_valid
         taglib_file_tag
         taglib_file_audioproperties
         taglib_file_save
         
         taglib_tag_title
         taglib_tag_artist
         taglib_tag_album
         taglib_tag_comment
         taglib_tag_genre
         taglib_tag_year
         taglib_tag_track
         
         taglib_tag_set_title
         taglib_tag_set_artist
         taglib_tag_set_album
         taglib_tag_set_comment
         taglib_tag_set_genre
         taglib_tag_set_year
         taglib_tag_set_track
         
         taglib_tag_free_strings
         
         taglib_audioproperties_length
         taglib_audioproperties_bitrate
         taglib_audioproperties_samplerate
         taglib_audioproperties_channels
         
         _TagLib_ID3v2_Encoding
         
         taglib_id3v2_set_default_text_encoding)

(define taglib (ffi-lib "libtag_c"))
(define-ffi-definer define-tl taglib)

(define _TagLib_File (_cpointer 'TagLib_File))
(define _TagLib_Tag  (_cpointer 'TagLib_Tag))
(define _TagLib_AudioProperties (_cpointer 'TagLib_AudioProperties))

(define _TagLib_File_Type
  (_enum '(mpeg oggvorbis flac mpc
           oggflac wavpack speex trueaudio
	   mp4 asf type)))

;; Racket API

(struct tag
  (title artist album comment genre year track)
  #:transparent)

;; path-string? -> #f or tag
;; get tag structure for the given file
(define (get-tags path)
  (unless (path-string? path)
    (raise-type-error 'get-tags "path-string" path))
  (define file (taglib_file_new path))
  (dynamic-wind
   void
   (lambda ()
     (and file
          (let* ([ctag (taglib_file_tag file)]
                 [tag-for-file
                  (tag
                   (taglib_tag_title ctag)
                   (taglib_tag_artist ctag)
                   (taglib_tag_album ctag)
                   (taglib_tag_comment ctag)
                   (taglib_tag_genre ctag)
                   (taglib_tag_year ctag)
                   (taglib_tag_track ctag))])
            (begin
             (taglib_tag_free_strings ctag)
             tag-for-file))))
   (lambda ()
     (taglib_file_free file))))

;; Low Level C API

(define-tl taglib_set_strings_unicode (_fun _bool -> _void))
(define-tl taglib_set_string_management_enabled (_fun _bool -> _void))

;; File API
(define-tl taglib_file_new (_fun _path -> _TagLib_File))
(define-tl taglib_file_new_type (_fun _path _TagLib_File_Type -> _TagLib_File))
(define-tl taglib_file_free (_fun _TagLib_File -> _void))
(define-tl taglib_file_is_valid (_fun _TagLib_File -> _bool))
(define-tl taglib_file_tag (_fun _TagLib_File -> _TagLib_Tag))
(define-tl taglib_file_audioproperties (_fun _TagLib_File -> _TagLib_AudioProperties))
(define-tl taglib_file_save (_fun _TagLib_File -> _bool))

;; Tag API
(define-tl taglib_tag_title   (_fun _TagLib_Tag -> _string))
(define-tl taglib_tag_artist  (_fun _TagLib_Tag -> _string))
(define-tl taglib_tag_album   (_fun _TagLib_Tag -> _string))
(define-tl taglib_tag_comment (_fun _TagLib_Tag -> _string))
(define-tl taglib_tag_genre   (_fun _TagLib_Tag -> _string))
(define-tl taglib_tag_year    (_fun _TagLib_Tag -> _uint))
(define-tl taglib_tag_track   (_fun _TagLib_Tag -> _uint))

(define-tl taglib_tag_set_title   (_fun _TagLib_Tag _string -> _void))
(define-tl taglib_tag_set_artist  (_fun _TagLib_Tag _string -> _void))
(define-tl taglib_tag_set_album   (_fun _TagLib_Tag _string -> _void))
(define-tl taglib_tag_set_comment (_fun _TagLib_Tag _string -> _void))
(define-tl taglib_tag_set_genre   (_fun _TagLib_Tag _string -> _void))
(define-tl taglib_tag_set_year    (_fun _TagLib_Tag _uint -> _void))
(define-tl taglib_tag_set_track   (_fun _TagLib_Tag _uint -> _void))

(define-tl taglib_tag_free_strings (_fun _TagLib_Tag -> _void))

;; Audio Properties API
(define-tl taglib_audioproperties_length     (_fun _TagLib_AudioProperties -> _int))
(define-tl taglib_audioproperties_bitrate    (_fun _TagLib_AudioProperties -> _int))
(define-tl taglib_audioproperties_samplerate (_fun _TagLib_AudioProperties -> _int))
(define-tl taglib_audioproperties_channels   (_fun _TagLib_AudioProperties -> _int))

;; ID3v2
(define _TagLib_ID3v2_Encoding
  (_enum '(latin1 utf16 utf16be utf8)))

(define-tl taglib_id3v2_set_default_text_encoding (_fun _TagLib_ID3v2_Encoding -> _void))

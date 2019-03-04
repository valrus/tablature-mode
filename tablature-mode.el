;;; tablature-mode.el --- Tablature modes for Emacs, 25th anniversary edition  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Ian McCowan

;; Author:  Mark R. Rubin <mark@phineas.jpl.nasa.gov>
;; Maintainer: Ian McCowan <imccowan@fastmail.fm>
;; Created: July 28, 1993
;; Modified: December 22, 2018
;; Version: 2.0
;; Keywords: tools, tablature
;; Homepage: https://github.com/valrus/tablature-mode
;; Package-Requires: ((cl-lib "0.5"))
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;;
;; Major mode for entering tablature.  Always use minor modes lead-mode
;; or chord-mode instead.

;; In tablature-mode, single keys represent notes on the guitar fretboard, and
;; pressing them creates tablature.  This only happens if the cursor is
;; in a tablature staff; otherwise the keys have their normal, text, meaning.
;; The keys are:

;;                    strings

;;              E   A    D   G   B   e

;;                 1   2   3   4   5   6         N
;;                  q   w   e   r   t   y        N+1    frets
;;                   a   s   d   f   g   h       N+2
;;                    z   x   c   v   b   n      N+3

;; In chord-mode, the cursor remains in place (for entry of multiple-note
;; chords) until manually moved forward with SPACE or `\\[forward-char]'.  In
;; lead-mode, the cursor automatically advances after each note.

;; For more information on a key or action, do:
;;   `\\[describe-key]' and then enter the key(s) for the action
;; or
;;   `\\[describe-function]' and then enter the name of the action


;;   KEY	ACTION

;;   {	enter chord mode
;;   }	enter lead mode

;;   =	make a new tablature staff

;;   <	decrement base fret position by one (is printed on mode line)
;;   >	increment base fret position by one (is printed on mode line)
;;   ?	prompt for numeric entry of base fret position

;;   SPACE 	move one tab position forward
;;   \\[tablature-forward-char]	move one tab position forward
;;   \\[tablature-backward-char]	move one tab position backward
;;   \\[tablature-forward-barline]	move forward one bar line
;;   \\[tablature-backward-barline]	move back one bar line
;;   \\[tablature-up-staff]	move up one staff
;;   \\[tablature-down-staff]	move down one staff


;;   C-h	delete previous (lead-mode) or current (chord-mode) note
;;   C-?	delete previous note/chord
;;   \\[tablature-delete-chord-forward]	delete current note/chord

;;   C-i	insert blank space

;;   |	toggle bar line

;;   [	mark current note as hammer-on
;;   ]	mark current note as pull-off
;;   ;	mark current note as bend
;;   '	mark current note as release
;;   /	mark current note as slide-up
;;   \	mark current note as slide-down
;;   ~	mark current note as vibrato
;;   (	mark current note as ghost note
;;   -	mark current note as normal note

;;   +	transpose notes in region by N frets (tablature-transpose)

;;   \\[tablature-copy-region-as-kill]	memorize tab between dot and mark (incl).
;;   \\[tablature-kill-region]	as above, but also delete
;;   \\[tablature-yank]	insert previously killed tablature

;;   \\[tablature-copy-retune]	copy tab staff, transposing to current tuning
;;   \\[tablature-learn-tuning] memorize new tuning (cursor first string)
;;   \\[tablature-retune-string] return current string and learn new tuning

;;   \\[tablature-analyze-chord]	analyze chord (cursor on root note)
;;   \\[tablature-label-chord]	insert previously analyzed chord name
;;   \\[tablature-note-name]	change whether chords are A# vs. Bb, etc.

;;   \\[tablature-higher-string]	move note to next higher string
;;   \\[tablature-lower-string] move note to next higher string

;;   \\[tablature-up-12]	move note up 12 frets
;;   \\[tablature-down-12]	move note down 12 frets

;; Tablature mode recognizes when the cursor is on a tab staff (and draws
;; new tab staffs) with six, three-character long, strings.  Each of the six
;; must be unique.  To change these strings (e.g. for alternate tunings),
;; enter them (while *not* in tablature-mode) at the beginnings of six consecutive
;; lines, and use `\\[execute-extended-command] tablature-learn-tuning'.


;; Full list of commands:
;; \\{tablature-mode-map}"

;; This code is released into the public domain without any express or implied
;; warranty.  The author accepts no responsibility for any consequences
;; arising from its use.

;; This code may be distributed and modified in any way; however, please
;; retain notice of original authorship in this and any derivative work.

;;; Revision history:
;;
;; 1.00  9/20/93		Added 'xfretboard and related functions and
;; 			variables.  Removed optional args from 'chord-mode
;; 			and 'lead-mode.  Removed "tablature-" prefix from
;; 			'tablature-lead-mode and 'tablature-chord-mode variables.
;; 			Added 'tablature-delete-note, and fixed 'tablature-delete-
;; 			chord-backward (wasn't handling non-tab delete,
;; 			and wipe out tuning).  Added 'tablature-forward-barline
;; 			(and backward), and 'tablature-up-staff (and down).
;; 			Added 'tablature-set-tuning and 'tablature-delete-current-note.
;; 0.09	9/ 4/93		Added chord-spelling, and changed logic of 'tablature-
;; 			analyze-chord and 'tablature-analyze-chord-internal.  Added
;; 			'tablature-12-tone-chords flag and function.  Fixed in/out
;; 			of tab handling of `+' key.
;; 0.08	8/ 8/93		Broke 'tablature-analyze-chord into two parts for
;; 			detection of X/Y chords.  Changed complicated defmacro
;; 			to defun due to speed/garbage-collection concerns.
;; 			Added 'tablature-current-tuning, and changed
;; 			'tablature-learn-tuning to set it.  Changed 'tablature-copy-retune
;; 			and 'tablature-analyze-chord to use 'tablature-current-tuning.
;; 			Added 'tablature-higher-string and 'tablature-lower-string.  Added
;; 			'tablature-move-string and 'tablature-goto-string utilities.
;; 			Changed 'tablature-label-chord to handle "X,noY/Z" chords.
;; 			Changed 'tablature-pending-embellishement, 'tablature-analyze-note,
;; 			and 'tablature-analyze-fret to use 'nil rather than normal
;; 			data type value for flag.  Removed redundant "(progn
;; 			(let", etc. constructs.  Changed 'tablature-label-chord
;; 			alignment of name over tab chord.
;; 0.07	 8/ 7/93	Finished 'tablature-label-chord.  Added more chords to
;; 			'tablature-analyze-chord.
;; 0.06   8/ 6/93	Added generic 'tablature-begin-end-region, with safety
;; 			checks.  Changed 'tablature-kill-internal to use it.
;; 			Changed 'tablature-transpose to work on region.  Improved
;; 			tablature-mode documentation.  Added 'tablature-analyze-chord
;; 			and 'tablature-label-chord.  Allowed 'tablature-change-position
;; 			to use prefix arg.  Added 'tablature-note-name.
;; 			Change 'tablature-transpose-chord to use 'tablature-analyze-fret.
;; 0.05   8/ 2/93	Added 'tablature-copy-retune.  Changed 'tablature-transpose to use
;; 			'tablature-transpose-chord.
;; 0.04   8/ 1/93	Fixed 'tablature-transpose in lead mode.  Added alternate
;; 			tunings.  Improved mode documentation.
;; 0.03	 7/31/93	Removed 'tablature-delete-note-backward ("\C-h") and
;; 			replaced with mode-dependent 'tablature-delete-note.
;; 0.02	 7/29/93	Added hard-coded VT-100 arrow-key bindings.  Added
;; 			"pending embellishment", indicated on mode line.
;; 			Added "X" embellishment.
;; 0.01	 7/28/93	Original posting to rec.music.makers.guitar.tablature,
;; 			alt.guitar.tab,rec.music.makers.guitar,alt.guitar,
;; 			gnu.emacs.sources
;
;;; Code:

(require 'cl-lib)

; CUSTOMIZABLE DEFAULTS

(defvar tablature-note-names
  ["E" "F" "F#" "G" "Ab" "A" "Bb" "B" "C" "C#" "D" "Eb"]
  "Names of notes (like A# vs. Bb) for 'tablature-analyze-chord.
Change via \\[tablature-note-name] (tablature-note-name).")

(defvar tablature-current-tuning ; must match tablature-X-string-prefix, below
	[0 7 3 10 5 0]
"Numeric values of the six strings, high-to-low, in current tuning.")

; must match tablature-current-tuning, above
(defvar tablature-0-string-prefix "e-|" "Unique beginning of string 0 line.")
(defvar tablature-1-string-prefix "B-|" "Unique beginning of string 1 line.")
(defvar tablature-2-string-prefix "G-|" "Unique beginning of string 2 line.")
(defvar tablature-3-string-prefix "D-|" "Unique beginning of string 3 line.")
(defvar tablature-4-string-prefix "A-|" "Unique beginning of string 4 line.")
(defvar tablature-5-string-prefix "E-|" "Unique beginning of string 5 line.")

(defcustom tablature-12-tone-chords
  t
  "Spell chords in 12-tone system in addition to normal 1st, 3rd, 5th, b7th, etc."
  :type 'boolean
  :group 'tablature)

(defcustom default-tablature-width
  80
  "Default width of a tablature line."
  :type '(choice (const :tag "Current window width" nil)
                 (integer :tag "Number of characters"))
  :group 'tablature)

; end of customizable defaults


(defvar tablature-mode-map
	 nil
"Mode map for tab mode.
Commands:
\\{tablature-mode-map}")

(defvar tablature-saved-point
  nil
  "Saved point for moving between staff and lyrics.")

(defvar tablature-current-string
	0
"What string cursor is on.")

(defvar tablature-position
	0
"What fret index finger is on.")

(defvar tablature-position-as-string
	"0"
"String variant of tablature-position for mode line.")

(defvar tablature-pending-embellishment
	nil
"Embellishment to be added to next entered note, or nil if none.")

(defvar tablature-killed-width
	""
"Width of last killed region.")

(defvar tablature-last-chord
	""
"Chord analyzed by `\\[tablature-analyze-chord]' (tablature-analyze-chord).
Available for automatic insertion into tab by `\\[tablature-label-chord]' (tablature-label-chord).")

(defvar tablature-string-regexp
  "^[a-gA-G][-b#]\|")

(defconst tablature-font-lock-keywords-1
  `(((,tablature-string-regexp . font-lock-constant-face)
     ("\|" . font-lock-constant-face)
     ("\\([0-9]+\\)-" . (1 font-lock-variable-name-face))
     ("\n\t\\(.*\\)" . (1 font-lock-comment-face))))
  "Highlighting for tab mode.")

(defvar tablature-syntax-highlights tablature-font-lock-keywords-1)

(define-derived-mode tablature-mode fundamental-mode "Tablature"
  "Basic tab mode. Use chord-mode or lead-mode instead."
  (if (not tablature-mode-map) (tablature-make-mode-map))
  (use-local-map tablature-mode-map)

  (make-local-variable 'tablature-current-string)
  (make-local-variable 'tablature-position)
  (make-local-variable 'tablature-position-as-string)
  (make-local-variable 'tablature-pending-embellishment)
  (make-local-variable 'tablature-killed-width)
  (make-local-variable 'tablature-note-names)
  (make-local-variable 'tablature-last-chord)
  (make-local-variable 'tablature-current-tuning)
  (make-local-variable 'tablature-12-tone-chords)
  (make-local-variable 'tablature-0-string-prefix)
  (make-local-variable 'tablature-1-string-prefix)
  (make-local-variable 'tablature-2-string-prefix)
  (make-local-variable 'tablature-3-string-prefix)
  (make-local-variable 'tablature-4-string-prefix)
  (make-local-variable 'tablature-5-string-prefix)

  (setq font-lock-defaults tablature-syntax-highlights))

(make-variable-buffer-local
 (defvar lead-mode nil
   "Flag for whether the lead-mode minor mode is active."))

(make-variable-buffer-local
 (defvar chord-mode nil
   "Flag for whether the chord-mode minor mode is active."))

(define-minor-mode lead-mode
  "Turn on lead-mode, a minor mode of tablature-mode.
Use `\\[describe-function] tablature-mode' to see documentation for tablature-mode."
  :lighter " Lead"
  (if (not (equal major-mode 'tablature-mode))
      (tablature-mode))

  (setq chord-mode nil
        lead-mode t)

  ;; No-op, but updates mode line.
  (set-buffer-modified-p (buffer-modified-p)))


(define-minor-mode chord-mode
  "Turn on chord-mode, a minor mode of tablature-mode.
Use `\\[describe-function] tablature-mode' to see documentation for tablature-mode."
  :lighter " Chord"
  (if (not (equal major-mode 'tablature-mode))
      (tablature-mode))

  (setq lead-mode nil
        chord-mode t)

  ;; No-op, but updates mode line.
  (set-buffer-modified-p (buffer-modified-p)))


(defun ensure-lead-mode ()
    "Turn on lead-mode, if it's not on already. No-op if it is."
    (interactive)
    (lead-mode t))

(defun ensure-chord-mode ()
    "Turn on chord-mode, if it's not on already. No-op if it is."
    (interactive)
    (chord-mode t))


(defun tablature-toggle-minor-mode ()
  "Toggle between chord-mode and lead mode.
If not already in tablature-mode, activate that too."
  (interactive)

  (if (not (equal major-mode 'tablature-mode))
      (tablature-mode))

  (if lead-mode (chord-mode) (lead-mode)))


(defun tablature-12-tone-chords (arg)
  "Toggle 'tablature-12-tone-chords flag, or set/clear according to ARG.
Flag controls whether chord spelling also includes rational 12-tone version."
  (interactive "P")
  (setq tablature-12-tone-chords (if (null arg) (not tablature-12-tone-chords)
                             (> (prefix-numeric-value arg) 0))))


(defun rebind-keys (stock custom)
  "Rebind all keys currently bound to STOCK to CUSTOM."
  (let ((binding-list (where-is-internal stock)))
    (while binding-list
      (define-key tablature-mode-map (car binding-list) custom)
      (setq binding-list (cdr binding-list)))))


(defvar tablature-normal-mode-map-alist
  '(("{" . ensure-chord-mode)
    ("}" . ensure-lead-mode)

    ("=" . tablature-make-staff)

    ("<" . tablature-decrement-position)
    (">" . tablature-increment-position)
    ("?" . tablature-set-position)

    (" " . tablature-forward)
    ("|" . tablature-barline)

    ("\C-h" . tablature-delete-note)
    ("\C-?" . tablature-delete-chord-backward)

    ("\C-i" . tablature-insert)

    ("+" . tablature-transpose)
    ("8" . tablature-analyze-chord)
    ("*" . tablature-label-chord)

    ("9" . tablature-higher-string)
    ("o" . tablature-lower-string)
    ("0" . tablature-up-12)
    ("p" . tablature-down-12)

    ("[" . tablature-hammer)
    ("]" . tablature-pull)
    (";" . tablature-bend)
    ("'" . tablature-release)
    ("/" . tablature-slide-up)
    ("\\" . tablature-slide-down)
    ("~" . tablature-vibrato)
    ("(" . tablature-ghost)
    ("." . tablature-muffled)
    ("-" . tablature-normal)))


(defun tablature-make-mode-map ()
  "Create tab mode map."

  ;; DEBUG ... hard-coded arrow-key bindings
  (global-unset-key	 "\M-[")
  ;; (global-unset-key	 "\M-O")

  (setq tablature-mode-map (copy-keymap (current-global-map)))

  ;; DEBUG ... hard-coded arrow-key bindings
  (define-key tablature-mode-map "\M-[A"	'previous-line)
  (define-key tablature-mode-map "\M-[B"	'next-line)
  (define-key tablature-mode-map "\M-[C"	'tablature-forward-char)
  (define-key tablature-mode-map "\M-[D"	'tablature-backward-char)
  ;; (define-key tablature-mode-map "\M-OA"	'previous-line)
  ;; (define-key tablature-mode-map "\M-OB"	'next-line)
  ;; (define-key tablature-mode-map "\M-OC"	'tablature-forward-char)
  ;; (define-key tablature-mode-map "\M-OD"	'tablature-backward-char)

  ;; DEBUG ... doesn't work in 19.X in non-X mode
  ;; (define-key tablature-mode-map [up]		'previous-line)
  ;; (define-key tablature-mode-map [down]		'next-line)
  ;; (define-key tablature-mode-map [right]	'tablature-forward-char)
  ;; (define-key tablature-mode-map [left]		'tablature-backward-char)

  (let ((key-ndx 32))
    (while (< key-ndx 128)
      (progn
        (define-key tablature-mode-map (char-to-string key-ndx) 'tablature-unused-key)
        (setq key-ndx (1+ key-ndx)))))

  (loop for (key . action) in tablature-normal-mode-map-alist
        do (define-key tablature-mode-map key action))

  (rebind-keys 'delete-char 'tablature-delete-chord-forward)

  (rebind-keys 'backward-char 'tablature-backward-char)
  (rebind-keys 'forward-char  'tablature-forward-char)
  (rebind-keys 'scroll-down   'tablature-up-staff)
  (rebind-keys 'scroll-up     'tablature-down-staff)

  (rebind-keys 'kill-region 'tablature-kill-region)
  (rebind-keys 'copy-region-as-kill 'tablature-copy-region-as-kill)
  (rebind-keys 'yank 'tablature-yank)

  ;; Chord diagram style keybindings
  (define-key tablature-mode-map "\M-1"	'tablature-E-open)
  (define-key tablature-mode-map "\M-2"	'tablature-A-open)
  (define-key tablature-mode-map "\M-3"	'tablature-D-open)
  (define-key tablature-mode-map "\M-4"	'tablature-G-open)
  (define-key tablature-mode-map "\M-5"	'tablature-B-open)
  (define-key tablature-mode-map "\M-6"	'tablature-e-open)
  (define-key tablature-mode-map "!"	'tablature-E-1)
  (define-key tablature-mode-map "@"	'tablature-A-1)
  (define-key tablature-mode-map "#"	'tablature-D-1)
  (define-key tablature-mode-map "$"	'tablature-G-1)
  (define-key tablature-mode-map "%"	'tablature-B-1)
  (define-key tablature-mode-map "^"	'tablature-e-1)
  (define-key tablature-mode-map "1"	'tablature-E0)
  (define-key tablature-mode-map "2"	'tablature-A0)
  (define-key tablature-mode-map "3"	'tablature-D0)
  (define-key tablature-mode-map "4"	'tablature-G0)
  (define-key tablature-mode-map "5"	'tablature-B0)
  (define-key tablature-mode-map "6"	'tablature-e0)
  (define-key tablature-mode-map "q"	'tablature-E1)
  (define-key tablature-mode-map "w"	'tablature-A1)
  (define-key tablature-mode-map "e"	'tablature-D1)
  (define-key tablature-mode-map "r"	'tablature-G1)
  (define-key tablature-mode-map "t"	'tablature-B1)
  (define-key tablature-mode-map "y"	'tablature-e1)
  (define-key tablature-mode-map "a"	'tablature-E2)
  (define-key tablature-mode-map "s"	'tablature-A2)
  (define-key tablature-mode-map "d"	'tablature-D2)
  (define-key tablature-mode-map "f"	'tablature-G2)
  (define-key tablature-mode-map "g"	'tablature-B2)
  (define-key tablature-mode-map "h"	'tablature-e2)
  (define-key tablature-mode-map "z"	'tablature-E3)
  (define-key tablature-mode-map "x"	'tablature-A3)
  (define-key tablature-mode-map "c"	'tablature-D3)
  (define-key tablature-mode-map "v"	'tablature-G3)
  (define-key tablature-mode-map "b"	'tablature-B3)
  (define-key tablature-mode-map "n"	'tablature-e3)
  (define-key tablature-mode-map "Z"	'tablature-E4)
  (define-key tablature-mode-map "X"	'tablature-A4)
  (define-key tablature-mode-map "C"	'tablature-D4)
  (define-key tablature-mode-map "V"	'tablature-G4)
  (define-key tablature-mode-map "B"	'tablature-B4)
  (define-key tablature-mode-map "N"	'tablature-e4))


(defun tablature-check-in-tab ()
  "Return whether cursor is in a tab staff line.
Also, force cursor to nearest modulo 3 note position.
Set global variable tablature-current-string."
  (let ((in-tab t)
        (strings-above 0)
        (real-case-fold-search case-fold-search))

    (save-excursion
      (beginning-of-line)

      (setq case-fold-search nil)

      ;; see how many tab strings are above this one (inclusive)
      (while (looking-at tablature-string-regexp)
        (setq strings-above (1+ strings-above))
        (forward-line -1))

      (if (> strings-above 0)
          (setq tablature-current-string (1- strings-above))
        (setq tablature-current-string 0
              in-tab nil)))

    (setq case-fold-search real-case-fold-search)

    (let ((alignment (% (1+ (current-column)) 3)))
      ;; put cursor on note position
      (if in-tab
          (cond
           ((< (current-column) 5) (forward-char (- 5 (current-column))))
           ((/= alignment 0) (backward-char alignment)))))

    (setq in-tab in-tab)))


(defun tablature-decrement-position ()
  "Decrement the base fret position."
  (interactive)
  (if (tablature-check-in-tab)
      (if (> tablature-position 0) (setq tablature-position (1- tablature-position)))
    (insert (this-command-keys)))
  (setq tablature-position-as-string (int-to-string tablature-position))
  ;; No-op, but updates mode line.
  (set-buffer-modified-p (buffer-modified-p)))


(defun tablature-increment-position ()
  "Increment the base fret position."
  (interactive)
  (if (tablature-check-in-tab)
      (setq tablature-position (1+ tablature-position))
    (insert (this-command-keys)))
  (setq tablature-position-as-string (int-to-string tablature-position))
  ;; No-op, but updates mode line.
  (set-buffer-modified-p (buffer-modified-p)))


(defun tablature-set-position (fret)
  "Set current fret position to FRET or prompt for it."
  (interactive "P")
  (if (tablature-check-in-tab)
      (progn
        (if fret
            (setq tablature-position fret)
          ;; else
          (setq fret (read-string "Fret: "))
          (setq tablature-position (string-to-number fret)))

        (if (< tablature-position 0) (setq tablature-position 0))
        (setq tablature-position-as-string (int-to-string tablature-position))
        (set-buffer-modified-p (buffer-modified-p)))
    ;; else
    (insert (this-command-keys))))


(defun tablature-forward-char (count)
  "Move cursor forward COUNT spaces in the tab."
  (interactive "p")
  (let ((original-column (current-column)))

    (if (tablature-check-in-tab)
        (progn
          (if (< original-column 5) (backward-char 3))
          (forward-char (* count 3)))
      ;; else
      (forward-char count))))


(defun tablature-backward-char (count)
  "Move cursor backward COUNT spaces in the tab."
  (interactive "p")
  (if (tablature-check-in-tab) (setq count (* count 3)))
  (backward-char count))


(defun tablature-forward-barline ()
  "Move cursor forward to the next barline."
  (interactive)
  (if (tablature-check-in-tab) (progn
                           (if (looking-at "|") (forward-char 1))
                           (re-search-forward "|\\|$")
                           (tablature-check-in-tab))))


(defun tablature-backward-barline ()
  "Move cursor backwards to the previous barline."
  (interactive)
  (if (tablature-check-in-tab) (progn
                           (re-search-backward "|\\|^")
                           (tablature-check-in-tab))))


(defun choose-re-search (count)
  "Return a forward/backward search function according to the sign of COUNT."
  (if (> count 0) 're-search-forward 're-search-backward))


(defun tablature-navigate-string (count)
  "Move cursor up or down COUNT strings."
  (let ((column (current-column))
        (real-case-fold-search case-fold-search)
        (search-fun (choose-re-search count))
        (loop-count (abs count)))

    (setq case-fold-search nil)
    (while
        (> loop-count 0)
      (progn
        (funcall search-fun tablature-string-regexp nil t)
        (setq loop-count (1- loop-count))))
    (beginning-of-line)
    (forward-char column)
    (tablature-check-in-tab)
    (setq case-fold-search real-case-fold-search)))


(defun tablature-up-string (count)
  "Move cursor up COUNT strings."
  (interactive "p")
  (tablature-navigate-string (- (1+ count))))


(defun tablature-down-string (count)
  "Move cursor down COUNT strings."
  (interactive "p")
  (tablature-navigate-string count))


(defun tablature-restore-staff-location (string column)
  "Move the cursor to tab string STRING and text column COLUMN."
  (when (tablature-check-in-tab)
    (move-to-column column)
    (next-line string)
    (tablature-check-in-tab)))


(defun tablature-integer-sign (n)
  "Return the sign (as -1/0/1) of N."
  (if (= n 0)
      0
    (if (> n 0)
        1
      -1)))


(defun tablature-move-beyond-staff (direction)
  "Move to the line above or below the current staff, depending on DIRECTION.
Return nil if there is no such line (or we're not in tab), t otherwise."
  (if (not (tablature-check-in-tab))
      nil
    (if (< direction 0)
        (forward-line (- (1+ tablature-current-string)))
      (forward-line (- 6 tablature-current-string)))
    (not (tablature-check-in-tab))))


(defun tablature-move-staff-start ()
  "Move to the beginning of a tab staff. Does nothing if not in tab."
  (when (tablature-check-in-tab)
    (next-line (- tablature-current-string))))


(defun tablature-move-staff (direction)
  "Move one staff up or down depending on sign of DIRECTION.
Leave the cursor on the first character of the first line of the staff moved to."
  (let ((tmp-saved-point (copy-marker (point)))
        (can-move t)
        (search-fun (choose-re-search direction)))
    (when (tablature-check-in-tab)
      ;; go to the line after this staff, if possible
      (when (not (tablature-move-beyond-staff direction))
        ;; no lines beyond this staff, bail
        (setq can-move nil)
        (goto-char tmp-saved-point)))
    ;; go to the "next" (up or down depending on direction) tab line
    (when can-move
      (if (funcall search-fun tablature-string-regexp nil t)
          (tablature-move-staff-start)
        (goto-char tmp-saved-point)
        (setq can-move nil)))
    can-move))


(defun tablature-up-staff (count)
  "Move up COUNT staves, maintaining cursor location relative to the staff."
  (interactive "p")
  (let ((starting-column (current-column))
        (starting-string tablature-current-string))

    (cl-loop repeat count
             do (tablature-move-staff -1))

    (tablature-restore-staff-location starting-string starting-column)))


(defun tablature-down-staff (count)
  "Move down COUNT staves, maintaining cursor location relative to the staff."
  (interactive "p")
  (let ((starting-column (current-column))
        (starting-string tablature-current-string))

    (cl-loop repeat count
             do (tablature-move-staff 1))

    (tablature-restore-staff-location starting-string starting-column)))


(defun new-tablature-line-width ()
  "Return tablature column width, limited by window width."
  (or default-tablature-width (window-body-width)))


(defun tablature-toggle-lyric-line ()
  "Toggle the presence of a lyric line on this tab line."
  (interactive)
  (if (tablature-check-in-tab)
      (progn
        (setq tablature-saved-point (copy-marker (point)))
        (let ((starting-string tablature-current-string))
          (if (tablature-move-beyond-staff 1)
              (end-of-line)
            (newline))))
    (goto-char tablature-saved-point)))


(defun tablature-make-staff ()
  "Make a tab staff.
Do this below the current staff if in staff, or three lines below
cursor if not already in staff."
  (interactive)

  (let ((starting-string tablature-current-string)
        (starting-column (current-column)))

    (save-excursion
      ;; if we're not in a staff, try to move to the closest previous one
      (if (not (tablature-check-in-tab))
          (tablature-move-staff -1))

      (if (tablature-check-in-tab)
          (let ((newline-count (if (tablature-move-beyond-staff 1) 4 5)))
            (end-of-line)
            (newline (forward-line newline-count))
            ;; lyric line
            (insert "   ")
            (forward-line -1))
        ;; there is no previous staff, make a lyric line and then move above it
        (newline 2)
        (forward-line -1)
        (beginning-of-line))

      (insert tablature-0-string-prefix) (insert-char ?- (- (new-tablature-line-width) 5)) (newline)
      (insert tablature-1-string-prefix) (insert-char ?- (- (new-tablature-line-width) 5)) (newline)
      (insert tablature-2-string-prefix) (insert-char ?- (- (new-tablature-line-width) 5)) (newline)
      (insert tablature-3-string-prefix) (insert-char ?- (- (new-tablature-line-width) 5)) (newline)
      (insert tablature-4-string-prefix) (insert-char ?- (- (new-tablature-line-width) 5)) (newline)
      (insert tablature-5-string-prefix) (insert-char ?- (- (new-tablature-line-width) 5)) (newline))

    (tablature-move-staff 1)
    (tablature-restore-staff-location starting-string starting-column)))


(defun toggle-barline (advance)
  "Toggle barline at point on staff. Advance cursor if ADVANCE is true."
  (let ((linecount 6)
        (starting-string tablature-current-string)
        (barline-string "--|"))

    (backward-char 2)
    (setq temporary-goal-column (current-column))
    (previous-line tablature-current-string)

    (while (> linecount 0)
      (insert (if (looking-at barline-string) "---" barline-string))
      (delete-char 3)
      (backward-char 3)
      (if (> linecount 1) (next-line 1))
      (setq linecount (1- linecount)))

    (next-line (- starting-string 5))

    (if (and advance (< (current-column) (- (line-end-position) 5)))
        (forward-char 5)
      (forward-char 2))))


(defun tablature-barline-in-place ()
  "Toggle a barline at point."
  (interactive)
	(if (tablature-check-in-tab)
      (toggle-barline nil)
    (insert (this-command-keys))))


(defun tablature-barline ()
  "Toggle barline at point and advance cursor."
  (interactive)
  (if (tablature-check-in-tab)
      (toggle-barline t)
    (insert (this-command-keys))))


(defun tablature-forward ()
  "Move point forward one tablature space."
  (interactive)
  (let ((original-column (current-column)))

    (if (tablature-check-in-tab)
        (progn
          (if (< original-column 5) (backward-char 3))
          (forward-char 3))
      ;; else
      (insert (this-command-keys)))))


(defun tablature-delete ()
  "Delete vertical `chord' of notes at point."
  (let ((index 0) (placemark))
    (setq temporary-goal-column (current-column))
    (previous-line tablature-current-string)
    (backward-char 2)
    (while (< index 6)
      (delete-char 3)
      (setq placemark (point-marker))
      (end-of-line)
      (insert "---")
      (goto-char placemark)
      (setq temporary-goal-column (current-column))
      (if (< index 5) (next-line 1))
      (setq index (1+ index)))

    (if (/= tablature-current-string 5) (next-line (- tablature-current-string 5)))
    (forward-char 2)))


(defun tablature-delete-chord-forward (count)
  "Delete COUNT vertical chords of notes at nearest tab position to point."
  (interactive "p")
  (if (<= count 0) (setq count 1))

  (if (tablature-check-in-tab)
      (while (> count 0)
        (progn
          (tablature-delete)
          (setq count (1- count))))
    ;; else
    (delete-char count)))


(defun tablature-delete-chord-backward (count)
  "Delete COUNT vertical chords of notes to left of cursor position."
  (interactive "p")
  (if (<= count 0) (setq count 1))

  (if (tablature-check-in-tab)
      (while (and (> count 0) (> (current-column) 5))
        (progn
          (backward-char 3)
          (tablature-delete)
          (setq count (1- count))))
    ;; else
    (delete-backward-char count)))


(defun tablature-delete-note (count)
  "Delete a note, or previous COUNT chars if not in a tab.
Note deleted is the current one in chord mode or previous one in lead mode."

  (interactive "p")

  (if (tablature-check-in-tab)
      (progn
        (if (and (bound-and-true-p lead-mode) (> (current-column) 5))
            (progn
              (backward-char 2)
              (delete-backward-char 3)
              (insert "---")
              (backward-char 1)))

        (if (bound-and-true-p chord-mode) (tablature-delete-current-note)))
    ;; else
    (delete-backward-char count)))


(defun tablature-delete-current-note ()
  "Delete note at point, regardless of chord/lead mode."
  (interactive)

  (when (tablature-check-in-tab)
    (forward-char 1)
    (delete-backward-char 3)
    (insert "---")
    (backward-char 1)))


(defun tablature-insert (count)
  "Insert COUNT blank tablature spaces at cursor position."
  (interactive "p")

  (if (tablature-check-in-tab)
      (let ((index 0)
            (placemark))
        (setq temporary-goal-column (current-column))
        (previous-line tablature-current-string)
        (backward-char 2)
        (while (< index 6)
          (setq placemark (point-marker))
          (insert-char ?- (* count 3))
          (end-of-line)
          (delete-backward-char (* count 3))
          (goto-char placemark)
          (setq temporary-goal-column (current-column))
          (if (< index 5) (next-line 1))
          (setq index (1+ index)))
        (next-line (- tablature-current-string 5))
        (forward-char 2))
    ;; else
    (insert (this-command-keys))))


(defun tablature-begin-end-region (caller-begin caller-end)
  "Set CALLER-BEGIN/CALLER-END to ends of top tab line above point/mark.
Return t if dot was left of mark, nil otherwise.
Check that both dot and mark are inside same staff of tab."

  (let ((placemark (point-marker))
        (local-begin)
        (local-end)
        (begin-col)
        (end-col)
        (dot-before-mark))

    ;; figure beginning and end
    (setq begin-col (current-column))
    (goto-char (mark-marker))
    (setq end-col (current-column))

    (if (< begin-col end-col)
        (progn
          (setq local-begin placemark)
          (setq local-end (mark-marker))
          (setq dot-before-mark t))
      ;; else
      (setq local-begin (mark-marker))
      (setq local-end placemark)
      (setq dot-before-mark nil))

    ;; set beginning to top staff line
    (goto-char local-begin)
    (unless (tablature-check-in-tab)
      (goto-char placemark)
      (error "Mark not in tablature"))
    (setq temporary-goal-column (current-column))
    (previous-line tablature-current-string)
    (setq local-begin (point-marker))

    ;; set end to top staff line
    (goto-char local-end)
    (unless (tablature-check-in-tab)
      (goto-char placemark)
      (error "Mark not in tablature"))
    (setq temporary-goal-column (current-column))
    (previous-line tablature-current-string)
    (setq local-end (point-marker))

    ;; check begin and end in same tab staff
    (goto-char local-begin)
    (if (< local-end local-begin)
        (progn
          (goto-char placemark)
          (error "Dot and mark must be in same tab staff")))
    (re-search-forward "$" local-end 2 1)
    (if (/= local-end (point-marker))
        (progn
          (goto-char placemark)
          (error "Dot and mark must be in same tab staff")))

    ;; return values
    (set caller-begin local-begin)
    (set caller-end local-end)
    (setq dot-before-mark dot-before-mark)))


(defun tablature-kill-internal (delete)
  "Delete region of tab, putting in rectangle-kill ring if DELETE is t."
  (let ((placemark (point-marker))
        (begin) (end)
        (begin-col) (end-col)
        (index 0)
        (dot-before-mark)
        (original-string tablature-current-string))

    ;; figure rectangle beginning and end (inclusive these notes)
    (setq dot-before-mark (tablature-begin-end-region 'begin 'end))
    (goto-char begin)
    (backward-char 2)
    (setq begin (point-marker))
    (setq begin-col (current-column))
    (goto-char end)
    (setq temporary-goal-column (current-column))
    (next-line 5)
    (forward-char 1)
    (setq end (point-marker))
    (setq end-col (current-column))

    ;; do it
    (setq tablature-killed-width (- end-col begin-col))
    (kill-rectangle begin end)
    (goto-char begin)

    (if delete
        (progn
          ;; extend staff
          (while (< index 6)
            (end-of-line)
            (insert-char ?- tablature-killed-width)
            (forward-line)
            (setq index (1+ index)))
          (goto-char begin)
          (forward-char 2)
          (setq tablature-current-string 0))
      ;; else
      (yank-rectangle)
      (setq tablature-current-string original-string)
      (if dot-before-mark
          (progn
            (goto-char begin)
            (forward-char 2)
            (setq temporary-goal-column (current-column))
            (if (/= tablature-current-string 0)
                (next-line tablature-current-string)))
        ;; else
        (backward-char 1)
        (setq temporary-goal-column (current-column))
        (previous-line (- 5 tablature-current-string))))))


(defun tablature-kill-region ()
  "Kill region of tab to rectangle kill ring."
  (interactive)
  (if (tablature-check-in-tab)
      (tablature-kill-internal t)
    (kill-region (point-marker) (mark-marker))))


(defun tablature-copy-region-as-kill ()
  "Copy region of tab to rectangle kill ring."
  (interactive)
  (if (tablature-check-in-tab)
      (tablature-kill-internal nil)
    (copy-region-as-kill (point-marker) (mark-marker))))


(defun tablature-yank ()
  "Insert region of tab from rectangle kill ring."
  (interactive)
  (if (tablature-check-in-tab)
      (let ((placemark (point-marker)) (top-line) (index 0))
        (setq temporary-goal-column (current-column))
        (previous-line tablature-current-string)
        (backward-char 2)
        (setq top-line (point-marker))
        (while (< index 6)
          (end-of-line)
          (delete-backward-char tablature-killed-width)
          (forward-line)
          (setq index (1+ index)))
        (goto-char top-line)
        (yank-rectangle)
        (goto-char placemark))
    (yank)))


(defun tablature-transpose (frets)
  "Transpose notes in region up or down by FRETS (prompt if nil)."
  (interactive "P")

  (if (tablature-check-in-tab)
      (let ((input-string)
            (fret-array [0 0 0 0 0 0])
            (begin)
            (end))

        (unless frets
          (setq input-string
                (read-string "Transpose region by N frets: "))
          (setq frets (string-to-number input-string)))

        (fillarray fret-array frets)
        (message "Transposing region by %d frets ..." frets)

        (tablature-begin-end-region 'begin 'end)
        (goto-char begin)

        (while (<= (point-marker) end)
          (progn (tablature-transpose-chord fret-array)
                 (if (< (current-column) (- (line-end-position) 3))
                     (forward-char 3)
                   (end-of-line))))

        (setq tablature-current-string 0)
        (message "Finished transposing region by %d frets." frets))
    (insert (this-command-keys))))


(defun tablature-copy-retune ()
  "If cursor is on top line of tab staff, copy staff and change into current tuning."
  (interactive)
  (let ((old-cursor)
        (new-cursor)
        (old-tuning	[0 0 0 0 0 0])
        (diff)
        (tuning-diff	[0 0 0 0 0 0])
        (ndx)
        (placemark))

    (message "Copying this staff and converting to current tuning ...")

    ;; make new staff
    (setq old-cursor (point-marker))
    (forward-line 6)
    ;; find blank line, or end of file
    (while (not (looking-at "^$")) (forward-line 1))
    (newline 1)
    (tablature-make-staff)
    (beginning-of-line)
    (setq new-cursor (point-marker))

    ;; learn tunings
    (goto-char old-cursor)
    (tablature-analyze-tuning old-tuning)
    (goto-char new-cursor)
    (setq ndx 0)
    (while (< ndx 6)
      (progn
        (setq diff (- (aref old-tuning ndx) (aref tablature-current-tuning ndx)))
        (if (> diff  6) (setq diff (- diff 12)))
        (if (< diff -6) (setq diff (+ diff 12)))
        (aset tuning-diff ndx diff)
        (setq ndx (1+ ndx))))

    ;; copy old staff to new
    ;; delete new staff past tuning signature
    (goto-char new-cursor)
    (forward-char 3)
    (setq new-cursor (point-marker))
    (forward-line 5)
    (end-of-line)
    (kill-rectangle new-cursor (point-marker))
    (goto-char new-cursor)

    ;; memorize old staff past tuning signature
    (goto-char old-cursor)
    (forward-char 3)
    (setq old-cursor (point-marker))
    (forward-line 5)
    (end-of-line)
    (kill-rectangle old-cursor (point-marker))
    (goto-char old-cursor)
    (yank-rectangle)

    ;; copy
    (goto-char new-cursor)
    (yank-rectangle)
    (goto-char new-cursor)
    (forward-char 2)

    ;; change tuning
    (while (< (current-column) (- (line-end-position) 2))
      (progn
        (tablature-transpose-chord tuning-diff)
        (if (< (current-column) (- (line-end-position) 3))
            (forward-char 3)
          (end-of-line))))

    (message "Finished copying into current tuning.")))


(defun tablature-analyze-tuning (tuning)
  "Fill array TUNING with numbers representing tuning of current tab line."
  (when (tablature-check-in-tab)
    (save-excursion
      (tablature-move-staff-start)
      (let ((ndx 0)
            (numeric))

        (while (< ndx 6)
          (progn
            (beginning-of-line)
            (cond
             ((looking-at "[Ee]") (setq numeric  0))
             ((looking-at "[Ff]") (setq numeric  1))
             ((looking-at "[Gg]") (setq numeric  3))
             ((looking-at "[Aa]") (setq numeric  5))
             ((looking-at "[Bb]") (setq numeric  7))
             ((looking-at "[Cc]") (setq numeric  8))
             ((looking-at "[Dd]") (setq numeric 10))
             (t		   (setq numeric  0)))
            (forward-char 1)
            (if (looking-at "#") (setq numeric (1+ numeric)))
            (if (looking-at "b") (setq numeric (1- numeric)))

            (if (< numeric 0) (setq numeric (+ 12 numeric)))
            (aset tuning ndx numeric)

            (forward-line 1)
            (setq ndx (1+ ndx))))))))


(defun tablature-transpose-chord (transpositions)
  "Transpose chord at cursor by fret offsets in TRANSPOSITIONS."
  (let ((note))

    (setq tablature-current-string 0)
    (while (< tablature-current-string 6)
      (progn (setq note (tablature-analyze-fret))
             (when note
               (setq note (+ note (aref transpositions tablature-current-string)))
               (if (< note 0) (setq note (+ 12 note)))
               (tablature-string (int-to-string note) tablature-current-string)
               (if (bound-and-true-p lead-mode) (backward-char 3)))

             (setq temporary-goal-column (current-column))
             (if (< tablature-current-string 5)
                 (next-line 1)
               (previous-line 5))
             (setq tablature-current-string (1+ tablature-current-string))))))


(defun tablature-get-string-prefix-symbol (index)
  "Get the prefix symbol for string INDEX."
  (cond
   ((= index 0) 'tablature-0-string-prefix)
   ((= index 1) 'tablature-1-string-prefix)
   ((= index 2) 'tablature-2-string-prefix)
   ((= index 3) 'tablature-3-string-prefix)
   ((= index 4) 'tablature-4-string-prefix)
   ((= index 5) 'tablature-5-string-prefix)))


(defun tablature-get-string-prefix (index)
  "Get the prefix string for string INDEX."
  (symbol-value (tablature-get-string-prefix-symbol index)))


(defun tablature-learn-tuning ()
  "Memorize beginning of current plus next 5 screen lines as new tuning.
The first 3 characters of each line are considered, and must be unique."
  (interactive)

  (tablature-analyze-tuning tablature-current-tuning)

  (cl-loop for index from 0 to 5
           do (tablature-learn-string (tablature-get-string-prefix index)))
  (forward-line -6))


(defun tablature-relabel-string (new-tuning)
  "Retune the current string on the current staff to NEW-TUNING."
  (save-excursion
    (beginning-of-line)
    (delete-char 2)
    (insert (if (= (length new-tuning) 1) (concat new-tuning "-") new-tuning))))


(defun tablature-relabel-all-strings (string new-tuning)
  "Relabel STRING on all staffs to NEW-TUNING."
  (save-excursion
    ;; Go to the beginning of the first staff
    (beginning-of-buffer)
    (tablature-move-staff 1)
    (cl-loop do (progn
                  ;; Note: 4 is just to put us in the staff
                  (tablature-restore-staff-location string 4)
                  (tablature-relabel-string new-tuning))
             while (tablature-move-staff 1))))


(defun tablature-retune-string ()
  (interactive)

  (when (tablature-check-in-tab)
    (let ((new-tuning (read-string "New tuning for string: ")))
      (unless (string-match-p "^[aAbBcCdDeEfFgG][#b]?$" new-tuning)
        (error "New tuning isn't a valid note name!"))
      (tablature-relabel-all-strings tablature-current-string new-tuning)
      (when (tablature-check-in-tab)
        (tablature-learn-string (tablature-get-string-prefix-symbol tablature-current-string))
        (tablature-analyze-tuning tablature-current-tuning)))))


(defun tablature-learn-string (string)
  "Copy first three characters of line into STRING."
  (save-excursion
    (let ((begin))
      (beginning-of-line)
      (setq begin (point-marker))
      (forward-char 3)
      (set string (buffer-substring begin (point-marker)))
      (forward-line 1))))


(defun tablature-note-name ()
  "Change names for printing chords (e.g. A# vs. Bb). First enter current name
of note, then new name."
  (interactive)

  (let ((old)
        (new)
        (ndx 0)
        (searching t))

    (setq old (read-string (format "Old note (one of %s): " tablature-note-names)))
    (while (and searching (< ndx 12))
      (progn (if (string= old (aref tablature-note-names ndx))
                 (setq searching nil))
             (setq ndx (1+ ndx))))

    (if searching
        (error "Must enter one of %s" tablature-note-names)
      (setq ndx (1- ndx)))

    (setq new (read-string (format "New note name for %s: "
                                   (aref tablature-note-names ndx))))
    (aset tablature-note-names ndx new)))


(defun tablature-goto-chord-label ()
  (interactive)

  ;; go to appropriate column, and to line above tab
  (let ((chord-column)
        (name-begin))

    (backward-char 1)
    (setq chord-column (current-column))
    (setq temporary-goal-column chord-column)
    (previous-line (1+ tablature-current-string))

    ;; insert spaces if necessary
    (when (< (current-column) chord-column)
      (indent-to-column chord-column)
      (setq name-begin (point-marker))
      (beginning-of-line)
      (untabify (point-marker) name-begin)
      (move-to-column chord-column))))


(defun tablature-delete-chord-label ()
  (interactive)

  (save-excursion
    (tablature-goto-chord-label)
      ;; delete previous chord (replace with spaces)
      (save-excursion
        (while (looking-at "\\S-") (progn (delete-char 1) (insert " "))))))


(defun tablature-label-chord ()
  "Insert previously analyzed chord above current tab staff.  Can only be
used immediately after `\\[tablature-analyze-chord]' (tablature-analyze-chord)"
  (interactive)

  (save-excursion
    (let ((name-width (length tablature-last-chord))
          (chord-column)
          (name-begin)
          (name-end))

      (unless (equal last-command 'tablature-analyze-chord)
        (error "Use only immediately after `%s' (tablature-analyze-chord)"
               (car (where-is-internal 'tablature-analyze-chord tablature-mode-map))))

      (tablature-delete-chord-label)

      ;; insert chord name
      (tablature-goto-chord-label)
      (insert tablature-last-chord)

      ;; remove spaces equal to inserted name
      (while (and (> name-width 0) (looking-at " " ))
        (progn
          (delete-char 1)
          (setq name-width (1- name-width)))))))



(defun tablature-analyze-chord ()
  "Analyze chord.  Note cursor is on is assumed to be root.  Repeat usage
moves root to next chord note.  Use `\\[tablature-label-chord]' (tablature-label-chord)
immediately afterwards to insert chord into tab."

  (interactive)

  (if (tablature-check-in-tab)
      (let ((root-note-marker)
            (root-string)
            (root)
            (note)
            (bass-note)
            (bass-note-name)
            (bass-note-pos)
            (chord [12 12 12 12 12 12]) ; "no note"
            (chord-notes [0 0 0 0 0 0 0 0 0 0 0 0])
            (root-name)
            (chord-name)
            (chord-disclaimer)
            (chord-spelling)
            (number-of-notes 0))

        (fillarray chord 12) ; "no note"
        (fillarray chord-notes 0)

                                        ; get root
        (if (or (equal last-command this-command)
                (not (looking-at "[0-9]")))
            (tablature-next-chord-note))
        (setq root-note-marker (point-marker))
        (setq root-string tablature-current-string)
        (setq root (tablature-analyze-note))
        (setq root-name (aref tablature-note-names root))

                                        ; get chord notes
        (setq temporary-goal-column (current-column))
        (previous-line tablature-current-string)
        (setq tablature-current-string 0)
        (while (< tablature-current-string 6)
          (progn (setq note (tablature-analyze-note))
                 (when note
                   (setq bass-note	note)

                   (setq note (- note root))
                   (if (< note 0)  (setq note (+ note 12)))
                   (if (> note 11) (setq note (- note 12)))

                   (if (= (aref chord-notes note) 0)
                       (setq number-of-notes (1+ number-of-notes)))

                   (aset chord tablature-current-string note)
                   (aset chord-notes note (1+ (aref chord-notes note)))

                   (setq bass-note-name (aref tablature-note-names bass-note))
                   (setq bass-note-pos note))
                 (setq temporary-goal-column (current-column))
                 (next-line 1)
                 (setq tablature-current-string (1+ tablature-current-string))))
        (goto-char root-note-marker)
        (setq tablature-current-string root-string)

        ;; analyze chord
        (tablature-analyze-chord-internal chord
                                    chord-notes
                                    'chord-name
                                    'chord-disclaimer
                                    'chord-spelling)

        ;; if unknown, and root != bass, and bass unique, try without
        (when (and (string= chord-name "??")
                   (/= root bass-note)
                   (= 1 (aref chord-notes bass-note-pos)))
          ;; remove bass note from chord and try again
          (aset chord-notes bass-note-pos 0)
          (setq number-of-notes (1- number-of-notes))
          (tablature-analyze-chord-internal chord
                                      chord-notes
                                      'chord-name
                                      'chord-disclaimer
                                      'chord-spelling)
          (unless (string= chord-name "??")
            (setq chord-name
                  (concat chord-name "/" bass-note-name))))

        (setq tablature-last-chord (concat root-name chord-name))
        (message "chord: %s%s ... %s"
                 tablature-last-chord
                 chord-disclaimer
                 chord-spelling))
    ;; else
    (insert (this-command-keys))))



(defun tablature-analyze-chord-internal (chord
                                   chord-notes
                                   chord-name-arg
                                   chord-disclaimer-arg
                                   chord-spelling-arg)
  "Given a 6-element CHORD array, with one note per string, low-to-high,
with 0=root and -1==no_note; a 12-element CHORD-NOTES array containing
occurrances of notes 0-11, 0=root.  Will fill in CHORD-NAME with name
of chord (`m7b5', etc.) or `??' if unknown, CHORD-DISCLAIMER with `,no5'
info, and CHORD-SPELLING with strings (`root', `5th', `X', etc.) describing
each note in chord."

  (let ((number-of-notes)
        (ndx 1)
        (chord-description [])
        (local-chord-name)
        (local-chord-disclaimer)
        (local-chord-spelling))

    (while (< ndx 12)
      (progn (if (> (aref chord-notes ndx) 0)
                 (setq chord-description
                       (vconcat chord-description (list ndx))))
             (setq ndx (1+ ndx))))
    (setq number-of-notes (1+ (length chord-description)))

    (defmacro tc (notes specials name disclaimer)
      (list 'tablature-chordtest notes
            specials
            name
            disclaimer
            'chord-description
            'chord
            ''local-chord-name
            ''local-chord-disclaimer
            ''local-chord-spelling))

    (cond
     ((= number-of-notes 1)
      (tc [] []	 "" ",no3,no5"))
     ((= number-of-notes 2)
      (cond
       ((tc [ 3] []		"m"	",no5"	))
       ((tc [ 4] []		""	",no5"	))
       ((tc [ 7] []		"5"	""	))
       ((tc [10] []		"7"	",no3,5"))
       ((tc [11] []		"maj7"	",no3,5"))

       ((tc []   []		"??"	""	))))
     ((= number-of-notes 3)
      (cond
       ((tc [2  7] []		"sus2"	""	))

       ((tc [3  5] [5 "11"]	"m11"	",no5,7"))
       ((tc [3  6] []		"mb5"	""	))
       ((tc [3  7] []		"m"	""	))
       ((tc [3  8] [8 "+5"]	"m+"	""	))
       ((tc [3  9] []		"m6"	",no5"	))
       ((tc [3 10] []		"m7"	",no5"	))

       ((tc [4  5] [5 "11"]	"11"	",no5,7"))
       ((tc [4  6] []		"-5"	""	))
       ((tc [4  7] []		""	""	))
       ((tc [4  8] [8 "+5"]	"+"	""	))
       ((tc [4  9] []		"6"	",no5"	))
       ((tc [4 10] []		"7"	",no5"	))
       ((tc [4 11] []		"maj7"	",no5"	))

       ((tc [5  7] [5 "sus4"]	"sus4"	""	))
       ((tc [5 10] [5 "sus4"]	"7sus4"	",no5"	))

       ((tc [7 10] []		"7"	",no3"	))
       ((tc [7 11] []		"maj7"	",no3"	))

       ((tc []     []			"??"	""	))))
     ((= number-of-notes 4)
      (cond
       ((tc [2  3  7] [2 "9"]		"madd9"		""	))
       ((tc [2  3 10] [2 "9"]		"m9"		",no5"	))
       ((tc [2  4  7] [2 "9"]		"add9"		""	))
       ((tc [2  4 10] [2 "9"]		"9"		",no5"	))
       ((tc [2  7 10] [2 "sus2"]	"7sus2"		""	))
       ((tc [2  7 11] [2 "sus2"]	"maj7sus2"	""	))

       ((tc [3  4 10] [3 "#9"]		"7#9"		",no5"	))
       ((tc [3  5  7] [5 "11"]		"madd11"	""	))
       ((tc [3  6  9] [9 "bb7"]	"dim"		""	))
       ((tc [3  6 10] []		"m7b5"		""	))
       ((tc [3  7  9] []		"m6"		""	))
       ((tc [3  7 10] []		"m7"		""	))
       ((tc [3  8 10] [8 "+5"]		"m7+5"		""	))

       ((tc [4  5  7] [5 "11"]		"add11"		""	))
       ((tc [4  6  7] [6 "+11"]	"add+11"	""	))
       ((tc [4  6  9] []		"add6b5"	""	))
       ((tc [4  6 10] []		"7b5"		""	))
       ((tc [4  6 11] []		"maj7b5"	""	))
       ((tc [4  7  9] []		"6"		""	))
       ((tc [4  7 10] []		"7"		""	))
       ((tc [4  7 11] []		"maj7"		""	))
       ((tc [4  8 10] [8 "+5"]		"7+5"		""	))
       ((tc [4  8 11] [8 "+5"]		"maj7+5"	""	))

       ((tc [5  7 10] [5 "sus4"]	"7sus4"		""	))
       ((tc [5  7 11] [5 "sus4"]	"maj7sus4"	""	))

       ((tc []        []		"??"		""	))))
     ((= number-of-notes 5)
      (cond
       ((tc [1  3  7 10] [1 "b9"]		"m7b9"		""	))
       ((tc [1  4  7 10] [1 "b9"]		"7b9"		""	))

       ((tc [2  3  5  7] [5 "11"]		"m11"		",no7"	))
       ((tc [2  3  5 10] [5 "11"]		"m11"		",no5"	))
       ((tc [2  3  6  9] [2 "9" 9 "bb7"]	"dim9"		""	))
       ((tc [2  3  6 10] [2 "9"]		"m9b5"		""	))
       ((tc [2  3  7  9] [2 "9"]		"m6add9"	""	))
       ((tc [2  3  7 10] [2 "9"]		"m9"		""	))
       ((tc [2  4  5  7] [2 "9" 5 "11"]	"11"		",no7"	))
       ((tc [2  4  5 10] [2 "9" 5 "11"]	"11"		",no5"	))
       ((tc [2  4  6 10] [2 "9"]		"9b5"		""	))
       ((tc [2  4  7  9] [2 "9"]		"6add9"		""	))
       ((tc [2  4  7 10] [2 "9"]		"9"		""	))
       ((tc [2  4  7 11] [2 "9"]		"maj7add9"	""	))
       ((tc [2  5  7 10] [2 "9" 5 "sus4"]	"9sus4"		""	))

       ((tc [3  4  7 10] [3 "#9"]		"7#9"		""	))
       ((tc [3  5  7 10] [5 "11"]		"m11"		",no9"	))
                                        ; m11,no9 == m7add11

       ((tc [4  5  7 10] [5 "11"]		"11"		",no9"	))
                                        ; 11,no9 == 7add11
       ((tc [4  6  7 10] [6 "+11"]		"7add+11"	""	))

       ((tc []		  []			"??"		""	))))
     ((= number-of-notes 6)
      (cond
       ((tc [1  3  5  7 10] [1 "b9" 5 "11"]		"m11b9"	""	))
       ((tc [1  4  5  7 10] [1 "b9" 5 "11"]		"11b9"	""	))

       ((tc [2  3  5  6  9] [2 "9" 5 "11" 9 "bb7"]	"dim11" ""	))
       ((tc [2  3  5  6 10] [2 "9" 5 "11"]		"m11b5"	""	))
       ((tc [2  3  5  7  9] [2 "9" 5 "11" 9 "13"]	"m13"	",no7"	))
       ((tc [2  3  5  7 10] [2 "9" 5 "11"]		"m11"	""	))
       ((tc [2  3  5  9 10] [2 "9" 5 "11" 9 "13"]	"m13"	",no5"	))
       ((tc [2  4  5  6 10] [2 "9" 5 "11"]		"11b5"	""	))
       ((tc [2  4  5  7  9] [2 "9" 5 "11" 9 "13"]	"13"	",no7"	))
       ((tc [2  4  5  7 10] [2 "9" 5 "11"]		"11"	""	))
       ((tc [2  4  5  9 10] [2 "9" 5 "11" 9 "13"]	"13"	",no5"	))
       ((tc [2  5  7  9 10] [2 "9" 5 "11"]		"13"	"no3"	))

       ((tc [3  5  7  9 10] [5 "11" 9 "13"]		"m13"	",no9"	))
       ((tc [4  5  7  9 10] [5 "11" 9 "13"]		"13"	",no9"	))

       ((tc []		     []				"??"	""	)))))

    ;; 0     1    2    3     4    5        6       7     8    9     10      11
    ;; root  b2   2nd  min3  3rd  4th      b5      5th   b6   6th   7th     maj7th
    ;; 8th   b9   9th  b3         11th     +11           +    13th  dom7th  7th
    ;;            sus2            sus4                   aug
    (set chord-name-arg       local-chord-name)
    (set chord-disclaimer-arg local-chord-disclaimer)
    (set chord-spelling-arg   local-chord-spelling)))



(defun tablature-chordtest (notes
                      degree-names
                      name
                      disclaimer
                      chord-description
                      chord
                      chord-name
                      chord-disclaimer
                      chord-spelling)
  "Given an n-element NOTES array, modified DEGREE_NAMES for them, NAME and
DISCLAIMER strings, and an n-element CHORD_DESCRIPTION, if notes and
chord-description match: use 6-element CHORD array and fill in
CHORD-NAME with name, CHORD-DISCLAIMER with disclaimer, and CHORD-SPELLING
and return t. Otherwise, leave all alone and returns nil."
  (let ((normal-names ["rt" "b2" "2" "b3" "3" "4" "b5"
                       "5" "b6" "6" "7" "maj7" "x"])
        (names)
        (ndx 0))

    (if (or (equal notes chord-description) (= (length notes) 0))
        (progn (set chord-name name)
               (set chord-disclaimer disclaimer)

               (setq names (copy-sequence normal-names))
               (while (< ndx (length degree-names))
                 (progn (aset names
                              (aref degree-names ndx)
                              (aref degree-names (1+ ndx)))

                        (setq ndx (+ ndx 2))))

               (set chord-spelling
                    (format "%s %s %s %s %s %s  (%s to %s)"
                            (aref names (aref chord 5))
                            (aref names (aref chord 4))
                            (aref names (aref chord 3))
                            (aref names (aref chord 2))
                            (aref names (aref chord 1))
                            (aref names (aref chord 0))
                            tablature-5-string-prefix
                            tablature-0-string-prefix))

               (if tablature-12-tone-chords
                   (let ((adjusted-chord [0 0 0 0 0 0]) (ndx 0))

                     (while (< ndx 6)
                       (let ((note (aref chord (- 5 ndx))))
                         (if (= note 12)
                             (aset adjusted-chord ndx 'x)
                           (aset adjusted-chord ndx note))
                         (setq ndx (1+ ndx))))

                     (set chord-spelling
                          (format "%s  %s" (eval chord-spelling) adjusted-chord))))

               (eval t)))))


(defun tablature-analyze-fret ()
  "Return numeric fret value of note cursor is on, or nil if no note."
  (let ((digits 1)
        (fret nil)
        (end))

    (when (looking-at "[0-9]")
      (forward-char 1)
      (setq end (point-marker))
      (backward-char 2)
      (unless (looking-at "[12]")
        (forward-char 1)
        (setq digits 0))

      (setq fret (string-to-number (buffer-substring (point-marker) end)))
      (forward-char digits))

    (setq fret fret)))


(defun tablature-analyze-note ()
  "Return numeric note value of note cursor is on, or nil if no note"
  (let ((fret) (note nil))
    (setq fret (tablature-analyze-fret))
    (when fret
      (setq note (+ fret (aref tablature-current-tuning tablature-current-string)))
      (if (>= note 12) (setq note (% note 12))))
    (eval note)))


(defun tablature-next-chord-note ()
  (let ((strings-checked 0) (searching t))

    (while (and searching (< strings-checked 6))
      (progn (setq temporary-goal-column (current-column))
             (if (= tablature-current-string 5)
                 (progn (previous-line 5)
                        (setq tablature-current-string 0))
               (next-line 1)
               (setq tablature-current-string (1+ tablature-current-string)))

             (if (looking-at "[0-9]") (setq searching nil))
             (setq strings-checked (1+ strings-checked))))

    (when searching (error "No notes in chord"))))


(defun tablature-higher-string ()
  "Move note to next-higher string, recursively with wrap-around until blank
string found or all six strings done."
  (interactive)
  (if (tablature-check-in-tab)
      (tablature-higher-lower-string t)
    (insert (this-command-keys))))


(defun tablature-lower-string ()
  "Move note to next-lower string, recursively with wrap-around until blank
string found or all six strings done."
  (interactive)
  (if (tablature-check-in-tab)
      (tablature-higher-lower-string nil)
    (insert (this-command-keys))))


(defun tablature-higher-lower-string (higher)
  "Internal routine to do work of 'tablature-higher-string if ARG is t, else
'tablature-lower-string'"

  (let ((notes-to-move t)
        (moving-note nil)
        (moving-fret nil)
        (in-way-note (tablature-analyze-note))
        (in-way-fret (tablature-analyze-fret))
        (moves -1))

    (if (null in-way-note)
        (error "Must be on note to move to higher/lower string"))

    (setq tablature-pending-embellishment nil)

    (while notes-to-move
      ;; erase note in way
      (progn (delete-char 1)
             (delete-backward-char 2)
             (insert "---")
             (backward-char 1)

             ;; transpose moving note (if any) to this new string
             (when moving-note
               (let ((new-fret)
                     (old-fret))

                 (setq new-fret
                       (- moving-note (aref tablature-current-tuning
                                            tablature-current-string)))
                 (setq old-fret moving-fret)

                 (if (< new-fret 0) (setq new-fret (+ new-fret 12)))

                 (cond
                  ((and (> new-fret old-fret) (> new-fret 12))
                   (if (> (- new-fret old-fret) 6)
                       (setq new-fret (- new-fret 12))))
                  ((and (> old-fret new-fret) (<= new-fret 12))
                   (if (> (- old-fret new-fret) 6)
                       (setq new-fret (+ new-fret 12)))))

                 ;; put transposed note on new line
                 (tablature-string (int-to-string new-fret) tablature-current-string)))

             ;; note in the way will now move
             (setq moving-note in-way-note)
             (setq moving-fret in-way-fret)

             ;; set flag to exit
             (setq notes-to-move moving-note)

             ;; goto next string and get note in the way (if any)
             (if higher
                 (tablature-move-string -1)
               (tablature-move-string  1))
             (setq in-way-note (tablature-analyze-note))
             (setq in-way-fret (tablature-analyze-fret))

             ;; count how many notes moved
             (setq moves (1+ moves))))

    ;; get back to note cursor on at beginning
    (if (< moves 6)
        (if higher
            (tablature-move-string moves)
          (tablature-move-string (- 0 moves))))))


(defun tablature-move-string (strings)
  "Move absolute value of STRINGS, down if positive, up if negative."

  (setq temporary-goal-column (current-column))

  (cond
   ((> strings 0)
    (if (<= (+ strings tablature-current-string) 5)
        (progn (next-line strings)
               (setq tablature-current-string (+ tablature-current-string strings)))
      (setq strings (- 6 strings))
      (previous-line strings)
      (setq tablature-current-string (- tablature-current-string strings))))

   ((< strings 0)
    (if (>= (+ strings tablature-current-string) 0)
        (progn (next-line strings)
               (setq tablature-current-string (+ tablature-current-string strings)))
      (setq strings (+ 6 strings))
      (next-line strings)
      (setq tablature-current-string (+ tablature-current-string strings))))))


(defun tablature-goto-string (string)
  "Go to STRING string, where 0<=string<=5.  Reset tablature-current-string"
  (setq temporary-goal-column (current-column))
  (next-line (- string tablature-current-string))
  (setq tablature-current-string string))


(defun tablature-up-12 ()
  "Move current note up 12 frets"
  (interactive)
  (if (tablature-check-in-tab)
      (let ((fret (tablature-analyze-fret)))
        (when (and (/= fret -1) (<= fret 12))
          (setq fret (+ fret 12))
          (tablature-string (int-to-string fret) tablature-current-string)))
    ;; else
    (insert (this-command-keys))))


(defun tablature-down-12 ()
  "Move current note down 12 frets."
  (interactive)
  (if (tablature-check-in-tab)
      (let ((fret (tablature-analyze-fret)))
        (when (and (/= fret -1) (>= fret 12))
          (setq fret (- fret 12))
          (tablature-string (int-to-string fret) tablature-current-string)))
    ;; else
    (insert (this-command-keys))))


(defun tablature-unused-key ()
  "Ignore keypress if on tab staff; insert normally otherwise."
  (interactive)
  (if (not (tablature-check-in-tab)) (insert (this-command-keys))))


(defun tablature-toggle-embellishment-char (prev-char new-char)
  (if (string= prev-char new-char) "-" new-char))


(defun tablature-embellishment (special-character)
  "Mark current note with SPECIAL-CHARACTER embellishment."
  (if (tablature-check-in-tab)
      (if (looking-at "-")
          (progn (setq tablature-pending-embellishment
                       (tablature-toggle-embellishment-char tablature-pending-embellishment
                                                      special-character))
                 (set-buffer-modified-p (buffer-modified-p)))
        (backward-char 1)
        (if (looking-at "[12]") (backward-char 1))
        (let ((new-embellishment (tablature-toggle-embellishment-char
                                  (string (char-after))
                                  special-character)))
          (delete-char 1)
          (insert new-embellishment))
        (forward-char 1)
        (if (not (looking-at "[0-9]")) (backward-char 1)))
    (insert (this-command-keys))))


(defun tablature-hammer ()
  "Add a hammer-on embellishment to the current note."
  (interactive)
  (tablature-embellishment "h"))

(defun tablature-pull ()
  (interactive)
  (tablature-embellishment "p"))

(defun tablature-bend ()
  (interactive)
  (tablature-embellishment "b"))

(defun tablature-release ()
  (interactive)
  (tablature-embellishment "r"))

(defun tablature-slide-up ()
  (interactive)
  (tablature-embellishment "/"))

(defun tablature-slide-down ()
  (interactive)
  (tablature-embellishment "\\"))

(defun tablature-vibrato ()
  (interactive)
  (tablature-embellishment "~"))

(defun tablature-ghost ()
  (interactive)
  (tablature-embellishment "("))

(defun tablature-normal ()
  (interactive)
  (tablature-embellishment "-"))

(defun tablature-muffled ()
  (interactive)
  (tablature-embellishment "X"))


(defun tablature-string (symbol string)
  "Place first arg note on second arg string."
  (setq temporary-goal-column (current-column))
  (previous-line (- tablature-current-string string))
  (delete-char 1)
  (backward-char 1)
  (if (looking-at "[-12]")
      (delete-char 1)
    ;; else
    (delete-backward-char 1)
    (forward-char 1))

  (when (< (length symbol) 2)
    (backward-char 1)
    (insert "-")
    (forward-char 1))

  (insert symbol)

  (when tablature-pending-embellishment
    (backward-char (length symbol))
    (delete-backward-char 1)
    (insert tablature-pending-embellishment)
    (forward-char (length symbol))
    (setq tablature-pending-embellishment nil)
    (set-buffer-modified-p (buffer-modified-p)))

  (if (bound-and-true-p chord-mode) (backward-char 1))
  (if (bound-and-true-p lead-mode) (forward-char 2))

  (setq tablature-current-string string))


(defun tablature-E (symbol)
(tablature-string symbol 5))

(defun tablature-A (symbol)
(tablature-string symbol 4))

(defun tablature-D (symbol)
(tablature-string symbol 3))

(defun tablature-G (symbol)
(tablature-string symbol 2))

(defun tablature-B (symbol)
(tablature-string symbol 1))

(defun tablature-e (symbol)
(tablature-string symbol 0))


(defun tablature-E-fret (fret)
  (if (tablature-check-in-tab)
      (tablature-E (int-to-string fret))
    (insert (this-command-keys))))

(defun tablature-A-fret (fret)
  (if (tablature-check-in-tab)
      (tablature-A (int-to-string fret))
    (insert (this-command-keys))))

(defun tablature-D-fret (fret)
  (if (tablature-check-in-tab)
      (tablature-D (int-to-string fret))
    (insert (this-command-keys))))

(defun tablature-G-fret (fret)
  (if (tablature-check-in-tab)
      (tablature-G (int-to-string fret))
    (insert (this-command-keys))))

(defun tablature-B-fret (fret)
  (if (tablature-check-in-tab)
      (tablature-B (int-to-string fret))
    (insert (this-command-keys))))

(defun tablature-e-fret (fret)
  (if (tablature-check-in-tab)
      (tablature-e (int-to-string fret))
    (insert (this-command-keys))))


(defun tablature-E-open ()
(interactive)
(tablature-E-fret 0))

(defun tablature-A-open ()
(interactive)
(tablature-A-fret 0))

(defun tablature-D-open ()
(interactive)
(tablature-D-fret 0))

(defun tablature-G-open ()
(interactive)
(tablature-G-fret 0))

(defun tablature-B-open ()
(interactive)
(tablature-B-fret 0))

(defun tablature-e-open ()
(interactive)
(tablature-e-fret 0))


(defun tablature-E-1 ()
(interactive)
	(if (> tablature-position 0)
	(tablature-E-fret (- tablature-position 1))
	(tablature-E-fret tablature-position)))

(defun tablature-A-1 ()
(interactive)
	(if (> tablature-position 0)
	(tablature-A-fret (- tablature-position 1))
	(tablature-A-fret tablature-position)))

(defun tablature-D-1 ()
(interactive)
	(if (> tablature-position 0)
	(tablature-D-fret (- tablature-position 1))
	(tablature-D-fret tablature-position)))

(defun tablature-G-1 ()
(interactive)
	(if (> tablature-position 0)
	(tablature-G-fret (- tablature-position 1))
	(tablature-G-fret tablature-position)))

(defun tablature-B-1 ()
(interactive)
	(if (> tablature-position 0)
	(tablature-B-fret (- tablature-position 1))
	(tablature-B-fret tablature-position)))

(defun tablature-e-1 ()
(interactive)
	(if (> tablature-position 0)
	(tablature-e-fret (- tablature-position 1))
	(tablature-e-fret tablature-position)))


(defun tablature-E0 ()
  (interactive)
  (tablature-E-fret tablature-position))

(defun tablature-A0 ()
  (interactive)
  (tablature-A-fret tablature-position))

(defun tablature-D0 ()
  (interactive)
  (tablature-D-fret tablature-position))

(defun tablature-G0 ()
  (interactive)
  (tablature-G-fret tablature-position))

(defun tablature-B0 ()
  (interactive)
  (tablature-B-fret tablature-position))

(defun tablature-e0 ()
  (interactive)
  (tablature-e-fret tablature-position))


(defun tablature-E1 ()
  (interactive)
  (tablature-E-fret (+ tablature-position 1)))

(defun tablature-A1 ()
  (interactive)
  (tablature-A-fret (+ tablature-position 1)))

(defun tablature-D1 ()
  (interactive)
  (tablature-D-fret (+ tablature-position 1)))

(defun tablature-G1 ()
  (interactive)
  (tablature-G-fret (+ tablature-position 1)))

(defun tablature-B1 ()
  (interactive)
  (tablature-B-fret (+ tablature-position 1)))

(defun tablature-e1 ()
  (interactive)
  (tablature-e-fret (+ tablature-position 1)))


(defun tablature-E2 ()
  (interactive)
  (tablature-E-fret (+ tablature-position 2)))

(defun tablature-A2 ()
  (interactive)
  (tablature-A-fret (+ tablature-position 2)))

(defun tablature-D2 ()
  (interactive)
  (tablature-D-fret (+ tablature-position 2)))

(defun tablature-G2 ()
  (interactive)
  (tablature-G-fret (+ tablature-position 2)))

(defun tablature-B2 ()
  (interactive)
  (tablature-B-fret (+ tablature-position 2)))

(defun tablature-e2 ()
  (interactive)
  (tablature-e-fret (+ tablature-position 2)))


(defun tablature-E3 ()
  (interactive)
  (tablature-E-fret (+ tablature-position 3)))

(defun tablature-A3 ()
  (interactive)
  (tablature-A-fret (+ tablature-position 3)))

(defun tablature-D3 ()
  (interactive)
  (tablature-D-fret (+ tablature-position 3)))

(defun tablature-G3 ()
  (interactive)
  (tablature-G-fret (+ tablature-position 3)))

(defun tablature-B3 ()
  (interactive)
  (tablature-B-fret (+ tablature-position 3)))

(defun tablature-e3 ()
  (interactive)
  (tablature-e-fret (+ tablature-position 3)))


(defun tablature-E4 ()
  (interactive)
  (tablature-E-fret (+ tablature-position 4)))

(defun tablature-A4 ()
  (interactive)
  (tablature-A-fret (+ tablature-position 4)))

(defun tablature-D4 ()
  (interactive)
  (tablature-D-fret (+ tablature-position 4)))

(defun tablature-G4 ()
  (interactive)
  (tablature-G-fret (+ tablature-position 4)))

(defun tablature-B4 ()
  (interactive)
  (tablature-B-fret (+ tablature-position 4)))

(defun tablature-e4 ()
  (interactive)
  (tablature-e-fret (+ tablature-position 4)))


(defun tablature-E5 ()
  (interactive)
  (tablature-E-fret (+ tablature-position 5)))

(defun tablature-A5 ()
  (interactive)
  (tablature-A-fret (+ tablature-position 5)))

(defun tablature-D5 ()
  (interactive)
  (tablature-D-fret (+ tablature-position 5)))

(defun tablature-G5 ()
  (interactive)
  (tablature-G-fret (+ tablature-position 5)))

(defun tablature-B5 ()
  (interactive)
  (tablature-B-fret (+ tablature-position 5)))

(defun tablature-e5 ()
  (interactive)
  (tablature-e-fret (+ tablature-position 5)))


(defun tablature-E6 ()
  (interactive)
  (tablature-E-fret (+ tablature-position 6)))

(defun tablature-A6 ()
  (interactive)
  (tablature-A-fret (+ tablature-position 6)))

(defun tablature-D6 ()
  (interactive)
  (tablature-D-fret (+ tablature-position 6)))

(defun tablature-G6 ()
  (interactive)
  (tablature-G-fret (+ tablature-position 6)))

(defun tablature-B6 ()
  (interactive)
  (tablature-B-fret (+ tablature-position 6)))

(defun tablature-e6 ()
  (interactive)
  (tablature-e-fret (+ tablature-position 6)))

(provide 'tablature-mode)
;;; tablature-mode.el ends here

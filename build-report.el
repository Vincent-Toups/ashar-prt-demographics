#!/usr/bin/emacs --script

(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
  ;; and `package-pinned-packages`. Most users will not need or want to do this.
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  )
(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(light-blue))
 '(package-selected-packages
   '(magit citeproc citeproc-org web-mode web-mode-edit-element dumb-jump god-mode ts paredit paredit-everywhere smartparens ob-ada-spark ob-applescript ob-async ob-axiom ob-bitfield ob-blockdiag ob-browser ob-cfengine3 ob-clojurescript ob-coffee ob-coffeescript ob-compile ob-crystal ob-cypher ob-dao ob-dart ob-deno ob-diagrams ob-dsq ob-elixir ob-elm ob-elvish ob-ess-julia ob-fsharp ob-go ob-graphql ob-haxe ob-html-chrome ob-http ob-hy ob-ipython ob-julia-vterm ob-kotlin ob-latex-as-png ob-lfe ob-mermaid ob-ml-marklogic ob-mongo ob-napkin ob-nim ob-php ob-powershell ob-prolog ob-redis ob-restclient ob-reticulate ob-rust ob-sagemath ob-smiles ob-sml ob-solidity ob-spice ob-sql-mode ob-svgbob ob-swift ob-swiftui ob-tmux ob-translate ob-typescript ob-uart company company-statistics dockerfile-mode dracula-theme ess ess-R-data-view ess-r-insert-obj ess-smart-equals ess-smart-underscore ess-view-data fold-this poly-R poly-ansible poly-erb poly-markdown poly-noweb poly-org poly-rst poly-ruby poly-slim poly-wdl polymode python-mode python-x smex)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(setq org-image-actual-width nil)

(require 'ob-js)

(org-babel-do-load-languages
 'org-babel-load-languages
 '(
   (shell . t)
   (sqlite . t)
   (python . t)
   (emacs-lisp . t)
   (sqlite . t)
   (R . t)
   (python . t)
   (gnuplot . t)
   (js . t)
   ;; Include other languages here...
   ))

(add-to-list 'org-babel-tangle-lang-exts '("js" . "js"))
(setq org-src-fontify-natively t)
;; Don't prompt before running code in org
(setq org-confirm-babel-evaluate nil)
;; Fix an incompatibility between the ob-async and ob-ipython packages
(setq ob-async-no-async-languages-alist '("ipython"))
(require 's)

(require 'shadchen)

(require 'org-latex-impatient)

(setq org-latex-impatient-tex2svg-bin
        ;; location of tex2svg executable
      "/home/toups/.local/bin/tex2svg")

(require 'org-drill)

(setq max-lisp-eval-depth 10000)
(setq debug-on-error t)
(require 'oc-csl)

(with-current-buffer (find-file "writeup.org")
  (org-latex-export-to-pdf))




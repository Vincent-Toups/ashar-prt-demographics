#!emacs --script
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
;; and `package-pinned-packages`. Most users will not need or want to do this.
;;(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(package-list-packages)
(package-refresh-contents)

(setq package-selected-packages '(nodejs-repl magit citeproc citeproc-org web-mode web-mode-edit-element dumb-jump god-mode ts paredit paredit-everywhere smartparens ob-ada-spark ob-applescript ob-async ob-axiom ob-bitfield ob-blockdiag ob-browser ob-cfengine3 ob-clojurescript ob-coffee ob-coffeescript ob-compile ob-crystal ob-cypher ob-dao ob-dart ob-deno ob-diagrams ob-dsq ob-elixir ob-elm ob-elvish ob-ess-julia ob-fsharp ob-go ob-graphql ob-haxe ob-html-chrome ob-http ob-hy ob-ipython ob-julia-vterm ob-kotlin ob-latex-as-png ob-lfe ob-mermaid ob-ml-marklogic ob-mongo ob-napkin ob-nim ob-php ob-powershell ob-prolog ob-redis ob-restclient ob-reticulate ob-rust ob-sagemath ob-smiles ob-sml ob-solidity ob-spice ob-sql-mode ob-svgbob ob-swift ob-swiftui ob-tmux ob-translate ob-typescript ob-uart company company-statistics dockerfile-mode dracula-theme ess ess-R-data-view ess-r-insert-obj ess-smart-equals ess-smart-underscore ess-view-data fold-this poly-R poly-ansible poly-erb poly-markdown poly-noweb poly-org poly-rst poly-ruby poly-slim poly-wdl polymode python-mode python-x smex shadchen));

(package-install-selected-packages t);




(message "Done setting up emacs packages.")

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)
(unless (package-installed-p 'scala-mode2)
  (package-refresh-contents) (package-install 'scala-mode2))
(put 'erase-buffer 'disabled nil)

(setq-default indent-tabs-mode nil)
(setq js-indent-level 2)


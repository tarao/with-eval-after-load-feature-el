;;; with-eval-after-load-feature.el --- Eval after loading feature with fine compilation

;; Author: INA Lintaro <tarao.gnn at gmail.com>
;; URL: https://github.com/tarao/with-eval-after-load-feature-el
;; Version: 0.1
;; Keywords: emacs compile
;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary
;;
;; Compiling a form passed to `with-eval-after-load' have a problem
;; that it causes "free variable" warnings during the compilation to
;; access a variable defined in the feature you are waiting for
;; loading.  To avoid this, `with-eval-after-load-feature' `require's
;; or `load's the feature before the compilation and behaves the same
;; what `with-eval-after-load' does.

;;; Acknowledgment
;;
;; - The original implementation
;;   https://github.com/tarao/bundle-el/blob/original/eval-after-load-compile.el
;; - An idea to suppress warnings
;;   https://github.com/lunaryorn/blog/blob/master/posts/introducing-with-eval-after-load.md

;;; Code:

(eval-when-compile (require 'cl))
(eval '(eval-when-compile (require 'cl)))

(unless (fboundp 'with-eval-after-load)
  (defmacro with-eval-after-load (file &rest body)
    "Execute BODY after FILE is loaded.
FILE is normally a feature name, but it can also be a file name,
in case that file does not provide any feature."
    (declare (indent 1) (debug t))
    ;; This definition is a bit different from that in Emacs 24.4; An
    ;; extra `funcall' is needed for an older Emacs.
    `(eval-after-load ,file `(funcall (function ,(lambda () ,@body))))))

(defun with-eval-after-load-feature-preload-1 (feature)
  (let ((after-load-alist nil))
    (unless (or (and (stringp feature)
                     (load feature :no-message :no-error))
                (and (symbolp feature)
                     (require feature nil :no-error)))
      (message "Cannot find %s" feature)
      'fail)))

(defun with-eval-after-load-feature-preload (feature-list)
  (loop for f in feature-list
        for fail = (with-eval-after-load-feature-preload-1 f)
        when fail
        collect fail))

(defun with-eval-after-load-feature-transform (feature-list body)
  (if (null feature-list)
      body
    (let ((feature (car feature-list)) (rest (cdr feature-list)))
    `((with-eval-after-load ',feature
       ,@(with-eval-after-load-feature-transform rest body))))))

;;;###autoload
(defmacro with-eval-after-load-feature (feature &rest body)
  (declare (indent 1) (debug t))
  (let* ((feature (if (and (listp feature) (eq (car-safe feature) 'quote))
                      (cdr feature) feature))
         (fs (if (listp feature) feature (list feature)))
         (form (or (and (eval '(eval-when (compile)
                                 (with-eval-after-load-feature-preload fs)))
                        'with-no-warnings)
                   'progn)))
    `(,form ,@(with-eval-after-load-feature-transform fs body))))

(provide 'with-eval-after-load-feature)
;;; eval-after-load-feature.el ends here

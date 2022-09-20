(defun build-excluding-table (list)
  (let ((tbl (cl-make-hash-table :test 'equal)))
    (cl-loop for item in list do
             (cl-puthash item t tbl))
    tbl))
(defun get-file-list (excluding)
  (let ((excluding-table (build-excluding-table excluding)))
    (cl-loop for file-or-directory in (directory-files ".")
             when (and (not (cl-gethash file-or-directory excluding-table nil))
                       (not (file-directory-p file-or-directory)))
             collect file-or-directory)))

(defun slurp-lines (filename)
  (with-temp-buffer
    (insert-file filename)
    (goto-char (point-min))
    (cl-loop collect
             (replace-regexp-in-string (regexp-quote (format "\n")) "" (thing-at-point 'line t))
             while (= 0 (forward-line 1)))))

(get-file-list (slurp-lines "keep-these-files"))
(".#tidy-up.el"
"README.md"
"bpi_intesity_by_group.R"
"build-doc.el"
"delta-histogram.R"
"demo-to-predicted-outcome.py"
"example-j-code.ijs"
"exploration.R"
"hello.sl"
"histograms.js"
"prep-for-corels.R"
"reduce-dims-nn.py"
"reduce-dims-pca.py"
"reduce-dims-tsne.py"
"responder-analysis.R"
"schedule.org"
"scilab.Dockerfile"
"scilab2.Dockerfile"
"scratch.py"
"script.org"
"script.pdf"
"sd-plots.R"
"workshop-description.html"
"workshop-description.odt"
"workshop-description.org"
"writeup.pdf")

(let ((files (get-file-list (slurp-lines "keep-these-files"))))
  (cl-mapcar (lambda (file)
               (delete-file file))
             files))


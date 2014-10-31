;;;; git.lisp

(in-package #:quicklisp-controller)

;;; Stuff for automatically committing */source.txt files with
;;; appropriate github messages.

(defun call-in-projects-directory (fun)
  (with-posix-cwd
      (translate-logical-pathname "quicklisp-controller:projects;")
    (funcall fun)))

(defmacro in-projects-directory (&body body)
  `(call-in-projects-directory (lambda () ,@body)))

(defun clean-stage-p ()
  (in-projects-directory
    (null (run-output-lines "git" "status" "--porcelain"
                            "--untracked-files=no"))))

(defun commit-message (source)
  (setf source (source-designator source))
  (let ((issue-number (github-issue-number source)))
    (unless issue-number
      (error "No github issue info for substring ~S" (name source)))
    (format nil "Added ~A per issue #~A"
            (name source)
            issue-number)))

(defun commit-source (source &key commit-message unclean)
  (let* ((source (source-designator source))
         (file (source-file source))
         (message (or commit-message
                      (commit-message source))))
    (unless (or unclean (clean-stage-p))
      (error "Stage isn't clean"))
    (in-projects-directory
      (run "git" "add" (pathname file))
      (run "git" "commit" "-m" message))
    (list :committed (name source) :with message)))

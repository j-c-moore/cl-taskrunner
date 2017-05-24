;;;; System definiation for task-runner

(asdf:defsystem #:task-runner
  :description "Simple task runner written in common lisp"
  :author "Clint Moore <john.clint.moore@gmail.com>"
  :license "MIT"
  :depends-on (#:graph
               #:log4cl
               #:cl-yaclyaml
               #:alexandria
               #:inferior-shell
               #:unix-options
               #:cl-ppcre)
  :serial t
  :components ((:file "package")
               (:file "task-runner")))

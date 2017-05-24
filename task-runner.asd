;;;; System definiation for task-runner

(asdf:defsystem #:task-runner
  :description "Simple task runner written in common lisp"
  :author "Clint Moore <john.clint.moore@gmail.com>"
  :maintainer "Clint Moore <john.clint.moore@gmail.com"
  :version "0.1"
  :license "MIT"
  :depends-on (#:graph
               #:log4cl
               #:cl-yaclyaml
               #:alexandria
               #:inferior-shell
               #:unix-options
               #:cl-ppcre)
 :components ((:module "src"
                :serial t
                :components ((:file "package")
                             (:file "task-runner"))))
  :long-description
  #.(uiop:read-file-string
     (uiop:subpathname *load-pathname* "README.md")))

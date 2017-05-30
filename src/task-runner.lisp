;;;; Execute a task specified by a YAML task specification.
(in-package :task-runner)

(log:config :debug)

;;--------------------------------------------------------------------------------------------------
(defun generate-task-graph (tasks)
  "Generate a graph of tasks from a given task hash-map."
  (let ((task-graph (make-instance 'graph:digraph)))
    (loop for task in (alexandria:hash-table-keys tasks) do
      (let ((deps (gethash "deps" (gethash task tasks))))
        (unless (listp deps) (setf deps (list deps)))
        (loop for dep in deps do
          (graph:add-edge task-graph (list
                                      (alexandria:symbolicate task)
                                      (alexandria:symbolicate dep))))))
    (values task-graph)))

;;--------------------------------------------------------------------------------------------------
(defun get-execution-order (task task-graph)
  "Generate an execution order based on a topological sort of connected graph edges"
  (let* ((connected-components (graph:connected-component task-graph (alexandria:symbolicate task)))
         (subgraph (graph:subgraph task-graph connected-components)))
    (mapcar #'symbol-name (reverse (graph:topological-sort subgraph)))))

;;--------------------------------------------------------------------------------------------------
(defun execute-tasks (task-list task-collection)
  "Execute a list of tasks."
  (loop for task in task-list do
        (execute-task (gethash task task-collection))))

;;--------------------------------------------------------------------------------------------------
(defun execute-task (task)
  "Execute a list of commands from a single task."
  (let ((current-cmd (gethash "cmds" task)))
    (unless (listp current-cmd) (setf current-cmd (list current-cmd)))
    (loop for cmd in current-cmd do
      (log:debug "Executing ~a" cmd)
      (inferior-shell:run cmd
                          :on-error (lambda (run-error)
                                      (format t "~A~%" run-error) (terminate 1))))))

;;--------------------------------------------------------------------------------------------------
(defun find-longest-string (strings)
  "Find the longest string in a list of strings."
  (first (stable-sort strings (lambda (a b) (> (length a) (length b))))))

;;--------------------------------------------------------------------------------------------------
(defun print-help-text (tasks)
  "Print the desc slot of all the tasks in a give task hash-map."
  (let* ((keys (alexandria:hash-table-keys tasks))
         (longest-name (write-to-string (length (find-longest-string keys))))
         (display-string (concatenate 'string "~" longest-name "<~a~; ~>~1,4@T~a~%")))
    (loop for task in (stable-sort keys #'string-lessp) do
      (format t display-string task (gethash "desc" (gethash task tasks))))))

;;--------------------------------------------------------------------------------------------------
(defun select-task (task-name tasks task-graph)
  "Calculate the task ordering for a given task, then execute it."
  (if (nth-value 1 (gethash task-name tasks))
      (execute-tasks (get-execution-order task-name task-graph) tasks)
      (format t "Task ~a does not exist~%" task-name)))

;;--------------------------------------------------------------------------------------------------
(defun main ()
  "Entry point to the application."
  (when (not (probe-file #p"./Taskfile.yaml"))
    (format t "Taskfile.yaml not found.~%")
    (terminate 1))
  (let ((tasks (cl-yy:yaml-load-file #p"./Taskfile.yaml")))
    (unix-options:with-cli-options () ()
      (if (not unix-options:free)
          (print-help-text tasks)
          (select-task (car unix-options:free) tasks (generate-task-graph tasks))))))

;;--------------------------------------------------------------------------------------------------
(defun make-windows-binary (&key
                              (binary-name "task_runner.exe")
                              (debug-level :debug))
  "Produce a binary for the windows platform."
  (log:config debug-level)
  (sb-ext:save-lisp-and-die binary-name
                            :executable t
                            :purify t
                            :toplevel 'main))

;;--------------------------------------------------------------------------------------------------
(defun make-linux-binary (&key
                            (binary-name "task-runner")
                            (compression-level -1)
                            (debug-level :debug))
  "Produce a binary for the Linux or macOS platforms."
  (log:config debug-level)
  (sb-ext:save-lisp-and-die binary-name
                            :executable t
                            :compression compression-level
                            :purify t
                            :toplevel 'main))

;;--------------------------------------------------------------------------------------------------
(defun terminate (status)
  (sb-ext:exit :code status))

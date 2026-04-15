(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Body parser middleware
;;;
;;; Parses request body based on Content-Type and merges into conn params.
;;;
;;; Supported:
;;;   application/json
;;;   application/x-www-form-urlencoded
;;; --------------------------------------------------------------------------

(defun body-parser-middleware (conn next)
  "Parse request body and merge into conn params."
  (let* ((env (conn-env conn))
         (content-type (or (getf env :content-type) ""))
         (body-stream (getf env :raw-body)))
    (when body-stream
      (let ((body-string (read-body-stream body-stream)))
        (when (and body-string (> (length body-string) 0))
          (cond
            ((search "application/json" content-type)
             (merge-json-params conn body-string))
            ((search "application/x-www-form-urlencoded" content-type)
             (merge-form-params conn body-string))))))
    (funcall next conn)))

(defun read-body-stream (stream)
  "Read the entire body stream as a string."
  (when stream
    (let ((buf (make-string-output-stream)))
      (handler-case
          (loop for char = (read-char stream nil nil)
                while char do (write-char char buf))
        (error () nil))
      (get-output-stream-string buf))))

(defun merge-json-params (conn body)
  "Parse JSON body and merge into conn params."
  (handler-case
      (let ((data (yason:parse body :object-as :hash-table)))
        (when (hash-table-p data)
          (maphash (lambda (k v)
                     (setf (gethash k (conn-params conn)) v))
                   data)))
    (error () nil)))

(defun merge-form-params (conn body)
  "Parse URL-encoded form body and merge into conn params."
  (dolist (pair (split-query-string body))
    (destructuring-bind (key . val) pair
      (setf (gethash key (conn-params conn)) val))))

(defun split-query-string (qs)
  "Parse \"foo=bar&baz=qux\" into ((\"foo\" . \"bar\") (\"baz\" . \"qux\"))."
  (when (and qs (> (length qs) 0))
    (loop for part in (uiop:split-string qs :separator "&")
          for eq-pos = (position #\= part)
          when eq-pos
            collect (cons (url-decode (subseq part 0 eq-pos))
                          (url-decode (subseq part (1+ eq-pos)))))))

(defun url-decode (string)
  "Decode a percent-encoded string."
  (with-output-to-string (out)
    (let ((i 0) (len (length string)))
      (loop while (< i len) do
        (let ((c (char string i)))
          (cond
            ((char= c #\+)
             (write-char #\Space out)
             (incf i))
            ((and (char= c #\%) (< (+ i 2) len))
             (write-char (code-char
                          (parse-integer string :start (+ i 1) :end (+ i 3)
                                               :radix 16))
                         out)
             (incf i 3))
            (t (write-char c out)
               (incf i))))))))

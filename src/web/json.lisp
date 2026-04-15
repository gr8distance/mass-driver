(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; JSON support
;;;
;;; Provides JSON response helpers. Uses yason for encoding.
;;; --------------------------------------------------------------------------

(defun respond-json (conn data &key (status 200))
  "Respond with JSON. DATA can be a plist, alist, hash-table, or list."
  (setf (conn-status conn) status
        (conn-response-headers conn) '(:content-type "application/json; charset=utf-8")
        (conn-response-body conn) (encode-json data))
  conn)

(defun encode-json (data)
  "Encode DATA to a JSON string."
  (with-output-to-string (s)
    (cond
      ;; Hash table
      ((hash-table-p data)
       (yason:encode data s))
      ;; plist (:key val :key2 val2)
      ((and (listp data) (keywordp (first data)))
       (yason:encode (plist-to-hash data) s))
      ;; alist ((key . val) ...)
      ((and (listp data) (consp (first data)) (not (listp (cdr (first data)))))
       (yason:encode (alist-to-hash data) s))
      ;; List (encode as JSON array)
      ((listp data)
       (yason:encode data s))
      ;; Anything else
      (t (yason:encode data s)))))

(defun plist-to-hash (plist)
  "Convert a plist to a hash table with string keys."
  (let ((ht (make-hash-table :test 'equal)))
    (loop for (k v) on plist by #'cddr
          do (setf (gethash (string-downcase (symbol-name k)) ht)
                   (if (and (listp v) (keywordp (first v)))
                       (plist-to-hash v)
                       v)))
    ht))

(defun alist-to-hash (alist)
  "Convert an alist to a hash table with string keys."
  (let ((ht (make-hash-table :test 'equal)))
    (loop for (k . v) in alist
          do (setf (gethash (if (symbolp k)
                                (string-downcase (symbol-name k))
                                k)
                            ht)
                   v))
    ht))

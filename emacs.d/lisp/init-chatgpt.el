(defun fav/read-openai-key ()
  (with-temp-buffer
    (insert-file-contents "~/key.txt")
    (string-trim (buffer-string))))

(straight-use-package 'gptel)

(setq-default gptel-model "gpt-3.5-turbo"
                gptel-playback t
                gptel-default-mode 'org-mode
                gptel-api-key #'fav/read-openai-key)

(provide 'init-chatgpt)

+++
title = "evilでnormal-modeのキーバインドを変更"
 [taxonomies]
 tags = ["spacemacs"]
+++

MacBook Proにspacemacsをいれてみたものの、EscがTouch barにあったためnormal-modeへのスイッチがしっくりこなかったので、vimと同じように `C-c` でできるように設定。

```lisp
  (define-key evil-insert-state-map (kbd "C-c") 'evil-normal-state)
  (define-key evil-normal-state-map (kbd "C-c") 'evil-insert-state)
```

[https://github.com/noctuid/evil-guide/blob/master/README.org#use-some-emacs-keybindings](https://github.com/noctuid/evil-guide/blob/master/README.org#use-some-emacs-keybindings) を参考にした。

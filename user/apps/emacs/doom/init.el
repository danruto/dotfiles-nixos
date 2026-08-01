;;; init.el -*- lexical-binding: t; -*-

(doom! :completion
       vertico

       :ui
       doom
       modeline
       (popup +defaults)

       :editor
       (evil +everywhere); come to the dark side, we have cookies


       :emacs
       undo

       :term
       vterm

       :lang
       (go +lsp)
       (rust +lsp)
       (javascript +lsp)
       markdown
       org
       odin

       :tools
       (lsp +eglot)
       magit

       :config
       (default +bindings +smartparens))

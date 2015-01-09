with-eval-after-load-feature.el --- Eval after loading feature with fine compilation
====================================================================================

Compiling a form passed to `with-eval-after-load` have a problem that
it causes "free variable" warnings during the compilation to access a
variable defined in the feature you are waiting for loading.  To avoid
this, `with-eval-after-load-feature` `require`s or `load`s the feature
before the compilation and behaves the same what
`with-eval-after-load` does.

## Macros

- `with-eval-after-load` ( *package* *body*... )

  This macro is defined as a core functionality in Emacs 24.4 and
  later.  It does the same as `eval-after-load` except that the *body*
  is not be quoted.

- `with-eval-after-load-feature` ( *package* *body*... )

  Arrange that if *package* is loaded, *body* will be run immediately
  afterwards.  This is equivalent to `with-eval-after-load` except two
  additional features: the *package* is automatically loaded when
  *body* is compiled, and, *package* can be a list form.

  Note that *body* is compiled as a function body by the following
  code.  Don't put anything which should not be in a function body.

  ```lisp
  (byte-compile `(lambda () ,@body))
  ```

## Example

Consider to compile the following code.  You will get *"Warning:
reference to free variable `anything-map'"* warning.
```lisp
(with-eval-after-load 'anything
  (define-key anything-map (kbd "M-n") #'anything-next-source)
  (define-key anything-map (kbd "M-p") #'anything-previous-source))
```

Using `with-eval-after-load-feature` instead of `with-eval-after-load`
suppresses the warning since the feature is automatically loaded at
compile time.
```lisp
(with-eval-after-load-feature 'anything
  (define-key anything-map (kbd "M-n") #'anything-next-source)
  (define-key anything-map (kbd "M-p") #'anything-previous-source))
```

If you need to wait loading multiple features, you can pass a list
form.
```lisp
(with-eval-after-load-feature (evil anything-config)
  (define-key evil-motion-state-map (kbd ":") #'anything-for-files))
```

This is equivalent to the following code.
```lisp
(with-eval-after-load-feature 'evil
  (with-eval-after-load-feature 'anything-config
    (define-key evil-motion-state-map (kbd ":") #'anything-for-files)))
```

## Acknowledgment

- The original implementation

  https://github.com/tarao/bundle-el/blob/original/eval-after-load-compile.el

- An idea to suppress warnings when `requre` or `load` failed

  https://github.com/lunaryorn/blog/blob/master/posts/introducing-with-eval-after-load.md

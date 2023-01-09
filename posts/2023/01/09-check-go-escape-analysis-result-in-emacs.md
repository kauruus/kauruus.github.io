+++
title = "Check Go Escape Analysis Result in Emacs"
+++

# {{title}}

Sometimes, you may need zero heap allocation in extreamly critical code path (which is rare).

To do that, you can run benchmark with `-benchmem` or check Go compiler's escape analysis result.

Showing the result in Emacs is easy, you simply define a flycheck checker:


```
(flycheck-define-checker goescape
  "Check Go escape analysis result"
  :command ("go" "build" "-gcflags=-m" "./...")
  :modes go-mode
  :error-patterns
  ((error line-start
          (file-name) ":" line ":" column ": "
          (message (+? nonl) " escapes to heap")
          line-end)))
```

Then you can get the result like this:

![](/assets/images/go-escape-in-emacs.png)


You can also do this in [VS Code](https://github.com/microsoft/vscode-go/issues/1948#issuecomment-466293994).


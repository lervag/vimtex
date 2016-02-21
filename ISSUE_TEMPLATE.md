### Explain the issue

Most issues are related to bugs or problems. In these cases, you should include
a minimal working example and a minimal vimrc file (see below), as well as:

1. Steps to reproduce
2. Expected behaviour
3. Observed behaviour

If your issue is instead a feature request or anything else, please consider if
minimal examples and vimrc files might still be relevant.

### Minimal working example

Please provide a minimal working LaTeX example, e.g.

```tex
\documentclass{minimal}
\begin{document}

Hello World!

\end{document}
```

### Minimal vimrc file

Please provide a minimal vimrc file that reproduces the issue. The following
should often suffice:

```vim
set nocompatible

" Load Vimtex
let &rtp  = '~/.vim/bundle/vimtex,' . &rtp
let &rtp .= ',~/.vim/bundle/vimtex/after'

" Load other plugins, if necessary
" let &rtp = '~/path/to/other/plugin,' . &rtp

filetype plugin indent on
syntax enable

" Vimtex options go here
```

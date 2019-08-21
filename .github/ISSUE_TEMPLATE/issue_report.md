---
name: General issue
about: Report a bug, a problem or any kind of issue
labels: bug
---

<!-- Tips for debugging and issue reporting
- Make sure to search for a solution in old issues before posting a new one
- Run `:chechhealth` (if available, e.g. on neovim)
- Inspect output of `:VimtexCompileOutput`
- Formatting guide: https://guides.github.com/features/mastering-markdown/
-->

**Describe the issue**
A clear and concise description of the issue.

**Steps to reproduce**

- Create a minimal vimrc file, e.g.:

  ```vim
  set nocompatible
  let &runtimepath  = '~/.vim/bundle/vimtex,' . &runtimepath
  let &runtimepath .= ',~/.vim/bundle/vimtex/after'
  filetype plugin indent on
  syntax enable
  ```

- Create a minimal LaTeX file, e.g.:

  ```tex
  \documentclass{minimal}
  \begin{document}
  Hello world!
  \end{document}
  ```

- Start vim with `vim --servername VIM -u minivimrc minimal.tex`

- Start neovim with `nvim -u minivimrc minimal.tex`

- Provide set of keys or command to reproduce the issue

- Describe both the expected and the observed behaviour

- *Note*: if relevant, include the content of your `.latexmkrc` file

**Output from VimtexInfo**
<!-- Run `:VimtexInfo` and paste the content here -->


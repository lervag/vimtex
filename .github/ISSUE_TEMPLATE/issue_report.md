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
- Include files inline (don't attach them as links)
-->

**Issue**
<!--A clear and concise description of the issue in a few sentences. Try to stick to simple english, to make easier for others to understand.-->

<!-- Provide the following files and commands in detail, so everybody can reproduce the issue-->

**minimal.vim**
<!-- Create a minimal vimrc file, e.g.:

  ```vim
  set nocompatible
  let &runtimepath  = '~/.vim/bundle/vimtex,' . &runtimepath
  let &runtimepath .= ',~/.vim/bundle/vimtex/after'
  filetype plugin indent on
  syntax enable
  ```
-->

**minimal.tex**
<!-- Create a minimal LaTeX file, e.g.:

  ```tex
  \documentclass{minimal}
  \begin{document}
  Hello world!
  \end{document}
  ```
-->

<!--
- If you are a vim user, start vim with `vim --servername VIM -u minimal.vim minimal.tex`

- If you are a neovim user, start neovim with `nvim -u minimal.vim minimal.tex`
-->

**Commands/Input**
<!-- Provide set of keys or command to reproduce the issue-->

**Observed Behaviour**
<!-- Describe the observed behaviour-->

**Expected Behaviour**
<!-- Describe both the expected and the observed behaviour-->

<!-- *Note*: if relevant, include the content of your `.latexmkrc` file -->

**Output from VimtexInfo**
<!-- Run `:VimtexInfo` and paste the content here -->


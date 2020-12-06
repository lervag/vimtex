---
name: General issue
about: Report a bug, a problem or any kind of issue
---

NB! Before posting an issue:

* Make sure to search for a solution in old issues before posting a new one.
* Learn at least a minimum of Markdown formatting (https://guides.github.com/features/mastering-markdown).

Note, the following can be useful tips to try before posting the issue:
* Run `:checkhealth` (if available, e.g. on neovim).
* Inspect output of `:VimtexCompileOutput`.

Finally, please remove any boilerplate template content that is not relevant!

**Issue**
Provide a clear and short description of the issue. Use simple english.

Provide relevant files and commands in detail, so everybody can reproduce the issue! The following are _examples_ of minimal input files. To use the minimal vimrc files:

* Regular Vim: `vim --servername VIM -u minimal.vim minimal.tex`
* neovim: `nvim -u minimal.vim minimal.tex`

**minimal.vim**
```vim
set nocompatible
let &runtimepath  = '~/.vim/bundle/vimtex,' . &runtimepath
let &runtimepath .= ',~/.vim/bundle/vimtex/after'
filetype plugin indent on
syntax enable
```

**minimal.tex**
```tex
\documentclass{minimal}
\begin{document}
Hello world!
\end{document}
```

NB: If relevant, include the content of your `.latexmkrc` file!

**Commands/Input**
Provide set of keys or command to reproduce the issue.

**Observed Behaviour**
Describe the observed behaviour.

**Expected Behaviour**
Describe both the expected and the observed behaviour.

**Output from VimtexInfo**
Run `:VimtexInfo` and paste the content here.


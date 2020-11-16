" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#array#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('tabularx')

  " Change inline math to improve column specifiers, e.g.
  "
  "   \begin{tabular}{*{3}{>{$}c<{$}}}
  "
  " See: https://en.wikibooks.org/wiki/LaTeX/Tables#Column_specification_using_.3E.7B.5Ccmd.7D_and_.3C.7B.5Ccmd.7D
  execute 'syntax region texMathRegionX matchgroup=texDelim'
        \ 'start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" end="\$"'
        \ 'contains=@texClusterMath'
        \ (&encoding ==# 'utf-8'
        \     && g:vimtex_syntax_conceal.math_delimiters
        \   ? 'concealends' : '')
endfunction

" }}}1

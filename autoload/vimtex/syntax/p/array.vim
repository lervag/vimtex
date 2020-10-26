" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#array#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'array') | return | endif
  let b:vimtex_syntax.array = 1

  call vimtex#syntax#p#tabularx#load()

  let l:concealends = &encoding ==# 'utf-8'
        \ && g:vimtex_syntax_config.conceal.math_delimiters
        \ ? 'concealends' : ''

  " Change inline math to improve column specifiers, e.g.
  "
  "   \begin{tabular}{*{3}{>{$}c<{$}}}
  "
  " See: https://en.wikibooks.org/wiki/LaTeX/Tables#Column_specification_using_.3E.7B.5Ccmd.7D_and_.3C.7B.5Ccmd.7D
  syntax clear texRegionMathX
  execute 'syntax region texRegionMathX'
        \ 'matchgroup=Delimiter'
        \ 'start="\([<>]{\)\@<!\$"'
        \ 'skip="\%(\\\\\)*\\\$"'
        \ 'end="\$"'
        \ 'end="%stopzone\>"'
        \ 'contains=@texClusterMath'
        \ l:concealends
endfunction

" }}}1

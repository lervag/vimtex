" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#array#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'array') | return | endif
  let b:vimtex_syntax.array = 1

  call vimtex#syntax#p#tabularx#load()
  if !get(g:, 'tex_fast', 'M') =~# 'M' | return | endif

  "
  " The following code changes inline math so as to support the column
  " specifiers [0], e.g.
  "
  "   \begin{tabular}{*{3}{>{$}c<{$}}}
  "
  " [0]: https://en.wikibooks.org/wiki/LaTeX/Tables#Column_specification_using_.3E.7B.5Ccmd.7D_and_.3C.7B.5Ccmd.7D
  "

  syntax clear texMathZoneX
  if has('conceal') && &enc ==# 'utf-8' && get(g:, 'tex_conceal', 'd') =~# 'd'
    syntax region texMathZoneX matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$" end="%stopzone\>" concealends contains=@texMathZoneGroup
  else
    syntax region texMathZoneX matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$" end="%stopzone\>" contains=@texMathZoneGroup
  endif
endfunction

" }}}1

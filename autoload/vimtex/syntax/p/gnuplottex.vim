" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#gnuplottex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'gnuplottex') | return | endif
  let b:vimtex_syntax.gnuplottex = 1

  call vimtex#syntax#nested#include('gnuplot')
  syntax region texRegionGnuplot
        \ start='\\begin{gnuplot}'
        \ end='\\end{gnuplot}'
        \ keepend
        \ transparent
        \ contains=texCmdEnv,texOptEnvModifier,@vimtex_nested_gnuplot
endfunction

" }}}1

" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#gnuplottex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'gnuplottex') | return | endif
  let b:vimtex_syntax.gnuplottex = 1

  call vimtex#syntax#misc#include('gnuplot')
  syntax region texRegionGnuplot
        \ start='\\begin{gnuplot}\(\_s*\[\_[\]]\{-}\]\)\?'rs=s
        \ end='\\end{gnuplot}'re=e
        \ keepend
        \ transparent
        \ contains=texCmdEnv,texEnvModifier,@vimtex_nested_gnuplot
endfunction

" }}}1

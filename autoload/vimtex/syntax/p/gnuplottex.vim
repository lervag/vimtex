" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#gnuplottex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'gnuplottex') | return | endif
  let b:vimtex_syntax.gnuplottex = 1

  unlet b:current_syntax
  syntax include @GNUPLOT syntax/gnuplot.vim
  let b:current_syntax = 'tex'

  call vimtex#syntax#add_to_clusters('texZoneGnuplot')
  syntax region texZoneGnuplot
        \ start='\\begin{gnuplot}\(\_s*\[\_[\]]\{-}\]\)\?'rs=s
        \ end='\\end{gnuplot}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@GNUPLOT
endfunction

" }}}1

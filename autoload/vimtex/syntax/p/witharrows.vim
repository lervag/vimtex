" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#witharrows#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_math('DispWithArrows')

  syntax match texMathCmdText "\\Arrow\>"
        \ contained skipwhite nextgroup=texMathTextArg
endfunction

" }}}1

" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#beamer#load(cfg) abort " {{{1
  syntax match texBeamerDelim '<\|>' contained
  syntax match texBeamerOpt '<[^>]*>' contained contains=texBeamerDelim

  syntax match texCmdBeamer '\\only\(<[^>]*>\)\?' contains=texBeamerOpt
  syntax match texCmdItem '\\item<[^>]*>' contains=texBeamerOpt

  syntax match texCmdInput "\\includegraphics<[^>]*>"
        \ contains=texBeamerOpt
        \ nextgroup=texFileOpt,texFileArg

  highlight link texCmdBeamer texCmd
  highlight link texBeamerOpt texOpt
  highlight link texBeamerDelim texDelim
endfunction

" }}}1

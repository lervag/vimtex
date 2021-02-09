" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#babel#load(cfg) abort " {{{1
  if !a:cfg.conceal | return | endif

  syntax match texSpecialChar '\\glq\>'  conceal cchar=‚
  syntax match texSpecialChar '\\grq\>'  conceal cchar=‘
  syntax match texSpecialChar '\\glqq\>' conceal cchar=„
  syntax match texSpecialChar '\\grqq\>' conceal cchar=“
  syntax match texSpecialChar '\\hyp\>'  conceal cchar=-
endfunction

" }}}1

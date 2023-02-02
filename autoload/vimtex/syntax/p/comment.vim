" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#comment#load(cfg) abort " {{{1
  syntax region texComment
        \ start="\\begin{comment}"
        \ end="\\end{comment}"
        \ contains=texCommentEnv
        \ keepend
  syntax match texCommentEnv "\\\%(begin\|end\){comment}"
        \ contained
        \ contains=texCmdEnv
endfunction

" }}}1

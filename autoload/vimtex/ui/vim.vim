" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#ui#vim#confirm(prompt) abort " {{{1
  return vimtex#ui#legacy#confirm(a:prompt)
endfunction

" }}}1
function! vimtex#ui#vim#input(options) abort " {{{1
  return vimtex#ui#legacy#input(a:options)
endfunction

" }}}1
function! vimtex#ui#vim#select(options, list) abort " {{{1
  return vimtex#ui#legacy#select(a:options, a:list)
endfunction

" }}}1

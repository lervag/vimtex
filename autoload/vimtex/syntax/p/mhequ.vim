" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#mhequ#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'equs\?',
        \ 'starred': v:true,
        \ 'math': v:true
        \})
endfunction

" }}}1


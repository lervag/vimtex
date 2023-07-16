" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#cases#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': '\(sub\)\?numcases',
        \ 'math': v:true,
        \})
endfunction

" }}}1

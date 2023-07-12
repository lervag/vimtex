" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#optidef#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': '\(arg\)\?\(mini\|maxi\)',
        \ 'starred': v:true,
        \ 'math': v:true,
        \})
  call vimtex#syntax#core#new_env({
        \ 'name': '\(arg\)\?\(mini[e!]\|maxi\!\)',
        \ 'math': v:true,
        \})
endfunction

" }}}1

" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#optidef#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_math('\(arg\)\?mini')
  call vimtex#syntax#core#new_region_math('\(arg\)\?mini[e!]', {'starred': 0})
  call vimtex#syntax#core#new_region_math('\(arg\)\?maxi')
  call vimtex#syntax#core#new_region_math('\(arg\)\?maxi\!', {'starred': 0})
endfunction

" }}}1
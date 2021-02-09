" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_env('texVerbZone', 'verbatimtab')
  call vimtex#syntax#core#new_region_env('texVerbZone', 'verbatimwrite')
  call vimtex#syntax#core#new_region_env('texVerbZone', 'boxedverbatim')
endfunction

" }}}1

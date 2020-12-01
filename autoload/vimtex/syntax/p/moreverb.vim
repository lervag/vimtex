" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'verbatimtab')
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'verbatimwrite')
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'boxedverbatim')
endfunction

" }}}1

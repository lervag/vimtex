" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'verbatimtab', {'transparent': 0})
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'verbatimwrite', {'transparent': 0})
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'boxedverbatim', {'transparent': 0})
endfunction

" }}}1

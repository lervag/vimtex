" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'moreverb') | return | endif
  let b:vimtex_syntax.moreverb = 1

  call vimtex#syntax#core#new_region_env('texVerbRegion', 'verbatimtab')
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'verbatimwrite')
  call vimtex#syntax#core#new_region_env('texVerbRegion', 'boxedverbatim')
endfunction

" }}}1

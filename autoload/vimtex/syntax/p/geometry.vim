" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#geometry#load(cfg) abort " {{{1
  syntax match texCmdGeometry nextgroup=texGeometryArg skipwhite "\\geometry\>"
  call vimtex#syntax#core#new_arg('texGeometryArg', {'contains': 'texGeometryArg,@texClusterOpt'})

  highlight def link texCmdGeometry texCmd
  highlight def link texGeometryArg texOpt
endfunction

" }}}1

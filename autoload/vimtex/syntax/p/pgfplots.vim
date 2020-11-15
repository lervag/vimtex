" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pgfplots#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pgfplots') | return | endif
  let b:vimtex_syntax.pgfplots = 1

  call vimtex#syntax#p#tikz#load()

  syntax cluster texClusterTikz add=texCmdAxis

  syntax match texCmdTikzset nextgroup=texTikzsetArg skipwhite "\\pgfplotsset\>"

  syntax match texTikzEnvBgn contains=texCmdEnv nextgroup=texTikzOpt skipwhite skipnl "\\begin{\%(log\)*axis}"
  syntax match texTikzEnvBgn contains=texCmdEnv nextgroup=texTikzOpt skipwhite skipnl "\\begin{groupplot}"
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'axis', {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'logaxis', {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'loglogaxis', {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'groupplot', {'contains': '@texClusterTikz'})


  syntax match texCmdAxis contained nextgroup=texTikzOpt skipwhite skipnl "\\nextgroupplot\>"
  syntax match texCmdAxis contained nextgroup=texPgfAddplotOpt,texPgfType,texPgfFunc skipwhite skipnl "\\addplot3\?\>+\?"

  call vimtex#syntax#core#new_opt('texPgfAddplotOpt', {'contains': '@texClusterTikzset', 'next': 'texPgfType,texPgfFunc'})
  call vimtex#syntax#core#new_arg('texPgfFunc', {'contains': '', 'opts': 'transparent'})


  syntax match texPgfType "table" contained nextgroup=texPgfTableOpt,texPgfTableArg skipwhite skipnl
  call vimtex#syntax#core#new_opt('texPgfTableOpt', {'contains': '@texClusterTikzset'})
  call vimtex#syntax#core#new_arg('texPgfTableArg', {'contains': '@NoSpell,texComment'})


  syntax match texPgfType "gnuplot" contained nextgroup=texPgfGnuplotArg skipwhite skipnl
  call vimtex#syntax#nested#include('gnuplot')
  call vimtex#syntax#core#new_arg('texPgfGnuplotArg', {'contains': '@vimtex_nested_gnuplot', 'next': 'texPgfNode'})


  syntax match texPgfType "coordinates" contained nextgroup=texPgfCoordinates skipwhite skipnl
  call vimtex#syntax#core#new_arg('texPgfCoordinates', {'contains': ''})


  syntax match texPgfNode "node" contained nextgroup=texTikzNodeOpt skipwhite skipnl


  highlight def link texCmdAxis     texCmd
  highlight def link texPgfNode     texCmd
  highlight def link texPgfType     texMathDelim
  highlight def link texPgfFunc     texArg
  highlight def link texPgfTableArg texFileArg
  highlight def link texPgfCoordinates texOpt
endfunction

" }}}1

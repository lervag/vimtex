" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pgfplots#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('tikz')

  syntax cluster texClusterTikz add=texCmdAxis

  syntax match texCmdTikzset nextgroup=texTikzsetArg skipwhite "\\pgfplotsset\>"

  syntax match texTikzEnvBgn contains=texCmdEnv nextgroup=texTikzOpt skipwhite skipnl "\\begin{\%(log\)*axis}"
  syntax match texTikzEnvBgn contains=texCmdEnv nextgroup=texTikzOpt skipwhite skipnl "\\begin{groupplot}"
  for l:env in ['axis', 'logaxis', 'loglogaxis', 'groupplot']
    call vimtex#syntax#core#new_region_env('texTikzZone', l:env, {
          \ 'contains': '@texClusterTikz',
          \ 'transparent': 1,
          \})
  endfor


  syntax match texCmdAxis contained nextgroup=texTikzOpt skipwhite skipnl "\\nextgroupplot\>"
  syntax match texCmdAxis contained nextgroup=texPgfAddplotOpt,texPgfType,texPgfFunc skipwhite skipnl "\\addplot3\?\>+\?"

  call vimtex#syntax#core#new_opt('texPgfAddplotOpt', {'contains': '@texClusterTikzset', 'next': 'texPgfType,texPgfFunc'})
  call vimtex#syntax#core#new_arg('texPgfFunc', {'contains': '', 'opts': 'contained transparent'})


  syntax match texPgfType "table" contained nextgroup=texPgfTableOpt,texPgfTableArg skipwhite skipnl
  call vimtex#syntax#core#new_opt('texPgfTableOpt', {'contains': '@texClusterTikzset'})
  call vimtex#syntax#core#new_arg('texPgfTableArg', {'contains': '@NoSpell,texComment'})


  syntax match texPgfType "gnuplot" contained nextgroup=texPgfGnuplotArg skipwhite skipnl
  call vimtex#syntax#nested#include('gnuplot')
  call vimtex#syntax#core#new_arg('texPgfGnuplotArg', {'contains': '@vimtex_nested_gnuplot', 'next': 'texPgfNode'})


  syntax match texPgfType "coordinates" contained nextgroup=texPgfCoordinates skipwhite skipnl
  call vimtex#syntax#core#new_arg('texPgfCoordinates', {'contains': ''})


  syntax match texPgfNode "node" contained nextgroup=texTikzNodeOpt skipwhite skipnl


  highlight def link texCmdAxis        texCmd
  highlight def link texPgfNode        texCmd
  highlight def link texPgfType        texMathDelim
  highlight def link texPgfFunc        texArg
  highlight def link texPgfTableArg    texFileArg
  highlight def link texPgfCoordinates texOpt
  highlight def link texPgfAddplotOpt  texOpt
  highlight def link texPgfTableOpt    texOpt
endfunction

" }}}1

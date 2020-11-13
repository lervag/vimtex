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

  syntax match texCmdAxis contained nextgroup=texTikzOpt skipwhite "\\addplot3\?\>"
  syntax match texCmdAxis contained nextgroup=texTikzOpt skipwhite "\\nextgroupplot\>"

  syntax match texTikzEnvBgn contains=texCmdEnv nextgroup=texTikzOpt skipwhite skipnl "\\begin{\%(log\)*axis}"
  syntax match texTikzEnvBgn contains=texCmdEnv nextgroup=texTikzOpt skipwhite skipnl "\\begin{groupplot}"
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'axis', {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'logaxis', {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'loglogaxis', {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'groupplot', {'contains': '@texClusterTikz'})

  highlight def link texCmdAxis texCmd
endfunction

" }}}1

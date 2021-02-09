" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tikz#load(cfg) abort " {{{1
  syntax cluster texClusterTikz    contains=texCmdTikz,texTikzEnvBgn,texTikzSemicolon,texTikzDraw,texTikzCycle,texCmd,texGroup,texComment
  syntax cluster texClusterTikzset contains=texTikzsetArg,texMathZoneX,texTypeSize,@texClusterOpt

  syntax match texCmdTikzset "\\tikzset\>"
        \ nextgroup=texTikzsetArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texTikzsetArg',
        \ {'contains': '@texClusterTikzset'})

  syntax match texTikzEnvBgn "\\begin{tikzpicture}"
        \ nextgroup=texTikzOpt skipwhite skipnl
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_region_env('texTikzZone', 'tikzpicture', {
        \ 'contains': '@texClusterTikz',
        \ 'transparent': 1
        \})
  call vimtex#syntax#core#new_opt('texTikzOpt',
        \ {'contains': '@texClusterTikzset'})

  syntax keyword texTikzCycle cycle contained
  syntax match texTikzSemicolon ";"  contained
  syntax match texTikzDraw      "--" contained
  syntax match texTikzDraw      "|-" contained
  syntax match texTikzDraw      "-|" contained

  syntax match texCmdTikz "\\node\>" contained nextgroup=texTikzNodeOpt skipwhite skipnl
  call vimtex#syntax#core#new_opt('texTikzNodeOpt', {'contains': '@texClusterTikzset'})

  highlight def link texCmdTikz       texCmd
  highlight def link texCmdTikzset    texCmd
  highlight def link texTikzNodeOpt   texOpt
  highlight def link texTikzSemicolon texDelim
  highlight def link texTikzDraw      texDelim
  highlight def link texTikzCycle     texMathDelim
  highlight def link texTikzsetArg    texOpt
  highlight def link texTikzOpt       texOpt
endfunction

" }}}1

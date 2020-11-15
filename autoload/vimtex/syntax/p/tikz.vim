" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tikz#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'tikz') | return | endif
  let b:vimtex_syntax.tikz = 1

  syntax cluster texClusterTikz    contains=texCmdTikz,texTikzEnvBgn,texTikzSemicolon,texTikzDraw,texTikzCycle,texCmd,texGroup,texComment
  syntax cluster texClusterTikzset contains=texTikzsetArg,texMathRegionX,texTypeSize,@texClusterOpt

  syntax match texCmdTikzset "\\tikzset\>"
        \ nextgroup=texTikzsetArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texTikzsetArg',
        \ {'contains': '@texClusterTikzset'})

  syntax match texTikzEnvBgn "\\begin{tikzpicture}"
        \ nextgroup=texTikzOpt skipwhite skipnl
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_region_env('texTikzRegion', 'tikzpicture',
        \ {'contains': '@texClusterTikz'})
  call vimtex#syntax#core#new_opt('texTikzOpt',
        \ {'contains': '@texClusterTikzset'})

  syntax keyword texTikzCycle cycle contained
  syntax match texTikzSemicolon ";"  contained
  syntax match texTikzDraw      "--" contained
  syntax match texTikzDraw      "|-" contained

  syntax match texCmdTikz "\\node\>" contained nextgroup=texTikzNodeOpt skipwhite skipnl
  call vimtex#syntax#core#new_opt('texTikzNodeOpt', {'contains': '@texClusterTikzset'})

  highlight def link texCmdTikzset    texCmd
  highlight def link texTikzSemicolon texDelim
  highlight def link texTikzDraw      texDelim
  highlight def link texTikzCycle     texMathDelim
endfunction

" }}}1

" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tikz#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'tikz') | return | endif
  let b:vimtex_syntax.tikz = 1

  syntax cluster texClusterTikz contains=texTikzEnvBgn,texTikzSemicolon,texCmd,texGroup,texComment
  syntax cluster texClusterTikzset contains=texTikzsetArg,texMathRegionX,texTypeSize,@texClusterOpt

  syntax match texCmdTikzset "\\tikzset\>" skipwhite skipnl nextgroup=texTikzsetArg
  call vimtex#syntax#core#new_arg('texTikzsetArg', {'contains': '@texClusterTikzset'})

  syntax match texTikzEnvBgn "\\begin{tikzpicture}"
        \ nextgroup=texTikzOpt skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_region_env(
        \ 'texTikzRegion', 'tikzpicture', '@texClusterTikz')
  call vimtex#syntax#core#new_opt('texTikzOpt', {'contains': '@texClusterTikzset'})

  syntax match texTikzSemicolon /;/ contained

  highlight def link texCmdTikzset texCmd
  highlight def link texTikzSemicolon texDelim
endfunction

" }}}1

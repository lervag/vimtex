" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#amsthm#load(cfg) abort " {{{1
  syntax match texCmdNewthm "\\newtheorem\*"
        \ nextgroup=texNewthmArgName skipwhite skipnl

  syntax match texProofEnvBgn "\\begin{proof}"
        \ nextgroup=texProofEnvOpt skipwhite skipnl
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texProofEnvOpt', {
        \ 'contains': 'TOP,@NoSpell'
        \})

  syntax match texCmdThmStyle "\\theoremstyle\>"
        \ nextgroup=texThmStyleArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texThmStyleArg', {
        \ 'contains': 'TOP,@Spell'
        \})

  highlight def link texCmdThmStyle texCmd
  highlight def link texProofEnvOpt texEnvOpt
  highlight def link texThmStyleArg texArg
endfunction

" }}}1

" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#amsthm#load(cfg) abort " {{{1
  syntax match texCmdNewthm "\\newtheorem\*"
        \ nextgroup=texNewthmArgName skipwhite skipnl

  syntax match texProofEnvBegin "\\begin{proof}"
        \ nextgroup=texProofEnvOpt
        \ skipwhite
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texProofEnvOpt', {
        \ 'contains': 'TOP,@NoSpell'
        \})

  highlight def link texProofEnvOpt texEnvOpt
endfunction

" }}}1

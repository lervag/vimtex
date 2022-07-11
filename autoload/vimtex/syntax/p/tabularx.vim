" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('array')

  " The format is \begin{tabularx}{WIDTH}[POS]{PREAMBLE}
  syntax match texCmdTabularx "\\begin{tabularx}"
        \ skipwhite skipnl
        \ nextgroup=texTabularxWidth
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_arg('texTabularxWidth', {
        \ 'next': 'texTabularxPreamble,texTabularxOpt,',
        \})
  call vimtex#syntax#core#new_opt('texTabularxOpt', {
        \ 'next': 'texTabularxPreamble',
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texTabularxPreamble', {
        \ 'contains': '@texClusterTabular'
        \})

  highlight def link texTabularxPreamble    texOpt
  highlight def link texTabularxWidth       texLength
  highlight def link texTabularxOpt         texEnvOpt
endfunction

" }}}1

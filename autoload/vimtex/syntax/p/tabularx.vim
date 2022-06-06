" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('array')

  syntax match texCmdTabularx "\\begin{tabularx}"
        \ skipwhite skipnl
        \ nextgroup=texTabularxOpt,texTabularxWidth
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texTabularxOpt', {
        \ 'next': 'texTabularxWidth',
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texTabularxWidth', {
        \ 'next': 'texTabularxArg',
        \})
  call vimtex#syntax#core#new_arg('texTabularxArg', {
        \ 'contains': '@texClusterTabular'
        \})

  highlight def link texTabularxArg         texOpt
  highlight def link texTabularxWidth       texOpt
  highlight def link texTabularxOpt         texEnvOpt
endfunction

" }}}1

" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#apacite#load(cfg) abort " {{{1
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\v\\citeA[pt]?>\*?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\v\\Cite[pt]?>\*?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\v\\[cC]iteal[tp]>\*?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\v\\cite%(num|text|url)>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\v\\[Cc]ite%(title|author|year%(par)?|date)?%(NP)?>\*?"

  call vimtex#syntax#core#new_arg('texRefOpt', {
        \ 'matcher': 'start="<" end=">"',
        \ 'next': 'texRefOpt,texRefArg',
        \})
endfunction

" }}}1

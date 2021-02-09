" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#csquotes#load(cfg) abort " {{{1
  syntax match texCmdQuote nextgroup=texQuoteArg skipwhite skipnl "\\\%(foreign\|hyphen\)textcquote\>\*\?"
  syntax match texCmdQuote nextgroup=texQuoteArg skipwhite skipnl "\\\%(foreign\|hyphen\)blockcquote\>"
  syntax match texCmdQuote nextgroup=texQuoteArg skipwhite skipnl "\\hybridblockcquote\>"
  call vimtex#syntax#core#new_arg('texQuoteArg', {'next': 'texRefOpt,texRefArg', 'opts': 'contained transparent'})

  highlight def link texCmdQuote texCmd
endfunction

" }}}1

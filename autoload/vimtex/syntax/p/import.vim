" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#import#load(cfg) abort " {{{1
  syntax match texCmdImport "\%#=1\\\%(sub\)\?import\>"
        \ nextgroup=texImportFileArg skipwhite skipnl

  call vimtex#syntax#core#new_arg('texImportFileArg', #{
        \ contains: '@NoSpell,texCmd,texComment',
        \ next: 'texFileArg',
        \})

  highlight def link texCmdImport texCmdInput
  highlight def link texImportFileArg texFileArg
endfunction

" }}}1

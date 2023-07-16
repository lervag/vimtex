" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#markdown#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'markdown',
        \ 'region': 'texMarkdownZone',
        \ 'contains': 'texCmd',
        \ 'nested': 'markdown',
        \})

  syntax match texCmdInput "\\markdownInput\>"
        \ nextgroup=texFileArg skipwhite skipnl
endfunction

" }}}1

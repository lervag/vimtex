" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#cleveref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'cleveref') | return | endif
  let b:vimtex_syntax.cleveref = 1

  syntax match texCmd '\\\(\(label\)\?c\(page\)\?\|C\)ref\>'
        \ nextgroup=texCRefZone

  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texCmd '\\c\(page\)\?refrange\>'
        \ nextgroup=texCRefZoneRange skipwhite skipnl

  " \label[xxx]{asd}
  syntax match texCmd '\\label\[.\{-}\]'
        \ nextgroup=texCRefZone skipwhite skipnl
        \ contains=texCRefLabelOpts

  syntax region texCRefZone contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texClusterRef,texRegionRef
  syntax region texCRefZoneRange contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texClusterRef,texRegionRef
        \ nextgroup=texCRefZone skipwhite skipnl
  syntax region texCRefLabelOpts contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texClusterRef,texRegionRef

  highlight link texCRefZone      texRegionRef
  highlight link texCRefZoneRange texRegionRef
  highlight link texCRefLabelOpts texOptNewcmd
endfunction

" }}}1

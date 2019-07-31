" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#cleveref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'cleveref') | return | endif
  let b:vimtex_syntax.cleveref = 1
  if get(g:, 'tex_fast', 'r') !~# 'r' | return | endif

  syntax match texStatement '\\\(\(label\)\?c\(page\)\?\|C\|auto\)ref\>'
        \ nextgroup=texCRefZone

  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texStatement '\\c\(page\)\?refrange\>'
        \ nextgroup=texCRefZoneRange skipwhite skipnl

  " \label[xxx]{asd}
  syntax match texStatement '\\label\[.\{-}\]'
        \ nextgroup=texCRefZone skipwhite skipnl
        \ contains=texCRefLabelOpts

  syntax region texCRefZone contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texRefGroup,texRefZone
  syntax region texCRefZoneRange contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texRefGroup,texRefZone
        \ nextgroup=texCRefZone skipwhite skipnl
  syntax region texCRefLabelOpts contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texRefGroup,texRefZone

  highlight link texCRefZone      texRefZone
  highlight link texCRefZoneRange texRefZone
  highlight link texCRefLabelOpts texCmdArgs
endfunction

" }}}1

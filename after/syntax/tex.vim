" Add support for cleverref package
" \Cref, \cref, \cpageref, \labelcref, \labelcpageref
syn region texRefZone matchgroup=texStatement
      \ start="\\\(\(label\)\?c\(page\)\?\|C\)ref{"
      \ end="}\|%stopzone\>"
      \ contains=@texRefGroup

" \crefrange, \cpagerefrange (these commands expect two arguments)
syn match texStatement
      \ '\\c\(page\)\?refrange\>'
      \ nextgroup=texRefRangeStart
syn region texRefRangeStart matchgroup=texStatement
      \ start='{' end='}'
      \ contains=texRefZone
      \ nextgroup=texRefRangeEnd
syn region texRefRangeEnd matchgroup=texStatement
      \ start='{' end='}'
      \ contains=texRefZone
hi link texRefRangeStart texRefZone
hi link texRefRangeEnd   texRefZone

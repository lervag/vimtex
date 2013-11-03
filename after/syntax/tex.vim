" Better support for cite commands
" \cite, \citep, \citet, \citeauthor, ...
syn match texRefZone
      \ "\\cite\%([tp]\*\=\|author\)\="
      \ nextgroup=texRefOption,texCite

" Add support for cleverref package
" \Cref, \cref, \cpageref, \labelcref, \labelcpageref
syn region texRefZone matchgroup=texStatement
      \ start="\\\(\(label\)\?c\(page\)\?\|C\)ref{"
      \ end="}\|%stopzone\>"
      \ contains=@texRefGroup

" \crefrange, \cpagerefrange (these commands expect two arguments)
syn match texStatement
      \ '\\c\(page\)\?refrange\>'
      \ nextgroup=texRefRangeStart skipwhite skipnl
syn region texRefRangeStart
      \ start="{"rs=s+1  end="}"
      \ matchgroup=Delimiter
      \ contained contains=texRefZone
      \ nextgroup=texRefRangeEnd skipwhite skipnl
syn region texRefRangeEnd
      \ start="{"rs=s+1 end="}"
      \ matchgroup=Delimiter
      \ contained contains=texRefZone
hi link texRefRangeStart texRefZone
hi link texRefRangeEnd   texRefZone

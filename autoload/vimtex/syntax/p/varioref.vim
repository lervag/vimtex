" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#varioref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'varioref') | return | endif
  let b:vimtex_syntax.varioref = 1
  if get(g:, 'tex_fast', 'r') !~# 'r' | return | endif

  syntax match texStatement '\\Vref\>' nextgroup=texRegionVarioref

  syntax region texRegionVarioref contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texClusterRef,texRegionRef

  highlight link texRegionVarioref texRegionRef
endfunction

" }}}1

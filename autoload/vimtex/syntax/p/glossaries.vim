" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#glossaries#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'glossaries') | return | endif
  let b:vimtex_syntax.glossaries = 1

  syntax match texStatement '\\gls\>' nextgroup=texGls
  syntax region texGls matchgroup=Delimiter
        \ start='{' end='}'
        \ contained
        \ contains=@NoSpell
endfunction

" }}}1

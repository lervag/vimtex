" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#hyperref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'hyperref') | return | endif
  let b:vimtex_syntax.hyperref = 1

  syntax match texCmd "\\url\>" nextgroup=texArgUrl skipwhite
  syntax region texArgUrl matchgroup=texDelim
        \ contained contains=@NoSpell,texComment
        \ start="\z([^\ta-zA-Z]\)" end="\z1"
  call vimtex#syntax#core#new_cmd_arg('texArgUrl', '', 'texComment,@NoSpell')

  syntax match texCmd '\\href\>' nextgroup=texArgHrefLink
  call vimtex#syntax#core#new_cmd_arg('texArgHrefLink', 'texArgHrefText', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texArgHrefText', '', 'TOP')

  syntax match texCmd '\\hyperref\>' nextgroup=texOptRef,texArgRef
  syntax match texCmd '\\autoref\>' nextgroup=texOptRef,texArgRef

  highlight link texArgUrl      texOpt
  highlight link texArgHrefLink texOpt
endfunction

" }}}1

" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#babel#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'babel') | return | endif
  let b:vimtex_syntax.babel = 1

  if g:vimtex_syntax_packages.babel.conceal
    syntax match texSpecialChar '\\glq\>'  conceal cchar=‚
    syntax match texSpecialChar '\\grq\>'  conceal cchar=‘
    syntax match texSpecialChar '\\glqq\>' conceal cchar=„
    syntax match texSpecialChar '\\grqq\>' conceal cchar=“
    syntax match texSpecialChar '\\hyp\>'  conceal cchar=-
  endif
endfunction

" }}}1

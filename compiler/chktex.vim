if exists('current_compiler') | finish | endif
let current_compiler = 'chktex'

let s:cpo_save = &cpo
set cpo&vim

" Ensure VimTeX options are loaded
call vimtex#options#init()

let &l:makeprg = printf('chktex --quiet --verbosity=4 %s %s',
      \ s:compiler,
      \ g:vimtex_lint_chktex_parameters,
      \ g:vimtex_lint_chktex_ignore_warnings)
let &l:errorformat = '%A"%f"\, line %l: %m'
      \ . ',%-Z%p^'
      \ . ',%-C%.%#'

let &cpo = s:cpo_save
unlet s:cpo_save

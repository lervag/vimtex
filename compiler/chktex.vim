if exists('current_compiler') | finish | endif
let current_compiler = 'chktex'

let s:cpo_save = &cpo
set cpo&vim

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:compiler = 'chktex'

let s:chktexrc = (empty($XDG_CONFIG_HOME)
      \ ? $HOME . '/.config'
      \ : $XDG_CONFIG_HOME) . '/chktexrc'
let g:vimtex_lint_chktex_parameters = get(g:, 'vimtex_lint_chktex_parameters',
      \ filereadable(s:chktexrc) ? '--localrc ' . shellescape(s:chktexrc) : '')

let g:vimtex_lint_chktex_ignore_warnings = get(g:, 'vimtex_lint_chktex_ignore_warnings', '-n1 -n3 -n8 -n25 -n36')

let &l:makeprg = s:compiler . ' --quiet --verbosity=4 ' . g:vimtex_lint_chktex_parameters . ' ' . g:vimtex_lint_chktex_ignore_warnings
let &l:errorformat = '%A"%f"\, line %l: %m,' .
      \ '%-Z%p^,' .
      \ '%-C%.%#'
silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save

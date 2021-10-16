if exists('current_compiler') | finish | endif
let current_compiler = 'chktex'

if exists(':CompilerSet') != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

let s:compiler = 'chktex'

if empty($XDG_CONFIG_HOME)
  let $XDG_CONFIG_HOME = $HOME . '/.config'
endif
let s:chktexrc = $XDG_CONFIG_HOME . '/chktexrc'
let g:chktex_parameters = get(g:, 'chktex_parameters',
      \ filereadable(s:chktexrc) ? '--localrc ' . shellescape(s:chktexrc) : '')

let g:chktex_ignore_warnings = get(g:, 'chktex_ignore_warnings', '-n1 -n3 -n8 -n25 -n36')

let &l:makeprg = s:compiler . ' --quiet --verbosity=4 ' . g:chktex_parameters . ' ' . g:chktex_ignore_warnings
let &l:errorformat = '%A"%f"\, line %l: %m,' .
      \ '%-Z%p^,' .
      \ '%-C%.%#'
silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save

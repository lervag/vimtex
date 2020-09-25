if exists('current_compiler') | finish | endif
let current_compiler = 'textidote'

let s:cpo_save = &cpo
set cpo&vim

let s:cfg = g:vimtex_grammar_textidote

if empty(s:cfg.jar) || !filereadable(fnamemodify(s:cfg.jar, ':p'))
  call vimtex#log#error([
        \ 'g:vimtex_grammar_textidote is not properly configured!',
        \ 'Please see ":help vimtex-grammar-textidote" for more details.'
        \])
  finish
endif

let &l:makeprg = 'java -jar ' . shellescape(fnamemodify(s:cfg.jar, ':p'))
      \ . (exists(s:cfg.args) ? ' ' . s:cfg.args : '')
      \ . ' --no-color --output singleline --check '
      \ . <SID>GetTextidoteLang(&spelllang) . ' %:S'

setlocal errorformat=
setlocal errorformat+=%f(L%lC%c-L%\\d%\\+C%\\d%\\+):\ %m
setlocal errorformat+=%-G%.%#

silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save

function! s:GetTextidoteLang(lang)
  if a:lang is# 'en_gb'
    return 'en_UK'
  endif

  let l:start = matchstr(a:lang, '^\a\a')
  return len(a:lang) == 2 ? l:start
        \ : l:start . '_' . toupper(matchstr(a:lang, '\a\a$'))
endfunction

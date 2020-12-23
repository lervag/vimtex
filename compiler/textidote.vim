if exists('current_compiler') | finish | endif
let current_compiler = 'textidote'

let s:cpo_save = &cpo
set cpo&vim

function! s:get_textidote_lang(lang) " {{{1
  " Match specific language(s)
  if a:lang ==# 'en_gb'
    return 'en_UK'
  endif

  " Convert normal lang strings to textidote format
  let l:matched = matchlist(a:lang, '^\v(\a\a)%(_(\a\a))?')
  let l:string = l:matched[1]
  if !empty(l:matched[2])
    let l:string .= toupper(l:matched[2])
  endif
  return l:string
endfunction

" }}}1

let s:cfg = g:vimtex_grammar_textidote

if empty(s:cfg.jar) || !filereadable(fnamemodify(s:cfg.jar, ':p'))
  call vimtex#log#error([
        \ 'g:vimtex_grammar_textidote is not properly configured!',
        \ 'Please see ":help vimtex-grammar-textidote" for more details.'
        \])
  finish
endif

let s:language = vimtex#ui#choose(split(&spelllang, ','), {
      \ 'prompt': 'Multiple spelllang languages detected, please select one:',
      \ 'abort': v:false,
      \})
let &l:makeprg = 'java -jar ' . shellescape(fnamemodify(s:cfg.jar, ':p'))
      \ . (has_key(s:cfg, 'args') ? ' ' . s:cfg.args : '')
      \ . ' --no-color --output singleline --check '
      \ . s:get_textidote_lang(s:language) . ' %:S'

setlocal errorformat=
setlocal errorformat+=%f(L%lC%c-L%\\d%\\+C%\\d%\\+):\ %m
setlocal errorformat+=%-G%.%#

silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save

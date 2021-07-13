" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#nested#include(name) abort " {{{1
  let l:inc_name = 'vimtex_nested_' . a:name

  if !has_key(s:included, l:inc_name)
    let s:included[l:inc_name] = s:include(l:inc_name, a:name)
  endif

  return s:included[l:inc_name] ? l:inc_name : ''
endfunction

" }}}1
function! vimtex#syntax#nested#reset() abort " {{{1
  let s:included = {'vimtex_nested_tex': 0}
endfunction

let s:included = {'vimtex_nested_tex': 0}

" }}}1

function! s:include(cluster, name) abort " {{{1
  let l:name = get(g:vimtex_syntax_nested.aliases, a:name, a:name)
  let l:path = 'syntax/' . l:name . '.vim'

  if empty(globpath(&runtimepath, l:path)) | return 0 | endif

  try
    call s:hooks_{l:name}_before()
  catch /E117/
  endtry

  unlet b:current_syntax
  execute 'syntax include @' . a:cluster l:path
  let b:current_syntax = 'tex'

  for l:ignored_group in get(g:vimtex_syntax_nested.ignored, l:name, [])
    execute 'syntax cluster' a:cluster 'remove=' . l:ignored_group
  endfor

  try
    call s:hooks_{l:name}_after()
  catch /E117/
  endtry

  return 1
endfunction

" }}}1

function! s:hooks_dockerfile_before() abort " {{{1
  " $VIMRUNTIME/syntax/dockerfile.vim does something it should not do - it sets
  " the commentstring option (which should rather be done within
  " a filetype-plugin). We use the hooks to save then restore the option here.
  let s:commentstring = &l:commentstring
endfunction

" }}}1
function! s:hooks_dockerfile_after() abort " {{{1
  let &l:commentstring = s:commentstring
  syntax cluster vimtex_nested_dockerfile remove=dockerfileLinePrefix
endfunction

" }}}1

" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#misc#add_to_section_clusters(group) abort " {{{1
  for l:cluster in [
        \ 'texPartGroup',
        \ 'texChapterGroup',
        \ 'texSectionGroup',
        \ 'texSubSectionGroup',
        \ 'texSubSubSectionGroup',
        \ 'texParaGroup',
        \]
    execute printf('syntax cluster %s add=%s', l:cluster, a:group)
  endfor

  execute printf('syntax cluster texVimtexGlobal add=%s', a:group)
endfunction

" }}}1
function! vimtex#syntax#misc#include(name) abort " {{{1
  let l:inc_name = 'vimtex_nested_' . a:name

  if !has_key(s:included, l:inc_name)
    let s:included[l:inc_name] = s:include(l:inc_name, a:name)
  endif

  return s:included[l:inc_name] ? l:inc_name : ''
endfunction

" }}}1
function! vimtex#syntax#misc#include_reset() abort " {{{1
  let s:included = {'vimtex_nested_tex': 0}
endfunction

let s:included = {'vimtex_nested_tex': 0}

" }}}1
function! vimtex#syntax#misc#new_math_zone(sfx, mathzone, starred) abort " {{{1
  " This function is based on Charles E. Campbell's amsmath.vba file 2018-06-29

  if get(g:, 'tex_fast', 'M') !~# 'M' | return | endif

  let foldcmd = get(g:, 'tex_fold_enabled') ? ' fold' : ''

  let grp = 'texMathZone' . a:sfx
  execute 'syntax cluster texMathZones add=' . grp
  execute 'syntax region ' . grp
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\s*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\s*}'''
        \ . foldcmd . ' keepend contains=@texMathZoneGroup'
  execute 'highlight def link '.grp.' texMath'

  if a:starred
    let grp .= 'S'
    execute 'syntax cluster texMathZones add=' . grp
    execute 'syntax region ' . grp
          \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\*\s*}'''
          \ . ' end=''\\end\s*{\s*' . a:mathzone . '\*\s*}'''
          \ . foldcmd . ' keepend contains=@texMathZoneGroup'
    execute 'highlight def link '.grp.' texMath'
  endif

  execute 'syntax match texBadMath ''\\end\s*{\s*' . a:mathzone . '\*\=\s*}'''
endfunction

" }}}1

function! s:include(cluster, name) abort " {{{1
  let l:name = get(g:vimtex_syntax_nested.aliases, a:name, a:name)
  let l:path = 'syntax/' . l:name . '.vim'

  if empty(globpath(&runtimepath, l:path)) | return 0 | endif

  unlet b:current_syntax
  execute 'syntax include @' . a:cluster l:path
  let b:current_syntax = 'tex'

  for l:ignored_group in get(g:vimtex_syntax_nested.ignored, l:name, [])
    execute 'syntax cluster' a:cluster 'remove=' . l:ignored_group
  endfor

  return 1
endfunction

" }}}1

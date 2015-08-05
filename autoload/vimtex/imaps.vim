" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#imaps#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_imaps_enabled', 1)
  call vimtex#util#set_default('g:vimtex_imaps_leader', '`')
endfunction

" }}}1
function! vimtex#imaps#init_script() " {{{1
  let s:has_ultisnips = exists('*UltiSnips#Anon')
endfunction

" }}}1
function! vimtex#imaps#init_buffer() " {{{1
  if !g:vimtex_imaps_enabled | return | endif

  let b:vimtex.imap_collections = []

  "
  " Create predefined imaps
  "
  for collection in s:default_collections()
    if get(g:, 'vimtex_imaps_' . collection.title, 1)
      call s:parse_collection(collection)
    endif
  endfor

  "
  " Create custom imaps if defined
  "
  for collection in get(g:, 'vimtex_imaps_custom', [])
    call s:parse_collection(collection)
  endfor
endfunction

" }}}1

function! s:default_collections() " {{{1
  return [
    \ {
    \   'title' : 'miscellaneous',
    \   'leader' : '',
    \   'mode' : '',
    \   'mappings' : [
    \     ['...', '\dots'],
    \     ['<m-i>', '\item '],
    \   ],
    \ },
    \ {
    \   'title' : 'math',
    \   'leader' : '',
    \   'mode' : 'm',
    \   'mappings' : [
    \     ['__', '_\{$1\}'],
    \     ['^^', '^\{$1\}'],
    \     ['((', '\left($1\right)'],
    \     ['[[', '\left[$1\right]'],
    \     ['{{', '\left\{$1\right\}'],
    \     ['exp', '\exp\left($1\right)'],
    \     ['cos', '\cos'],
    \     ['sin', '\sin'],
    \     ['tan', '\tan'],
    \     ['log', '\log'],
    \     ['in', '\in'],
    \     ['to', '\to'],
    \     ['lim', '\lim_{$1}'],
    \     ['qj', '\downarrow'],
    \     ['ql', '\leftarrow'],
    \     ['qh', '\rightarrow'],
    \     ['qk', '\uparrow'],
    \     ['qJ', '\Downarrow'],
    \     ['qL', '\Leftarrow'],
    \     ['qH', '\Rightarrow'],
    \     ['qK', '\Uparrow'],
    \   ],
    \ },
    \ {
    \   'title' : 'math_leader',
    \   'mode' : 'm',
    \   'mappings' : [
    \     ['i', '\int_{$1}^{$2}'],
    \     ['S', '\sum_{$1}^{$2}'],
    \     ['/', '\frac{$1}{$2}'],
    \     ['0', '\emptyset'],
    \     ['6', '\partial'],
    \     ['8', '\infty'],
    \     ['=', '\equiv'],
    \     ['\', '\setminus'],
    \     ['.', '\cdot'],
    \     ['*', '\times'],
    \     ['<', '\leq'],
    \     ['>', '\geq'],
    \     ['~', '\tilde{$1}'],
    \     ['^', '\hat{$1}'],
    \     [';', '\dot{$1}'],
    \     ['_', '\bar{$1}'],
    \   ],
    \ },
    \ { 
    \   'title' : 'greek',
    \   'mode' : 'm',
    \   'mappings' : [
    \     ['a', '\alpha'],
    \     ['b', '\beta'],
    \     ['c', '\chi'],
    \     ['d', '\delta'],
    \     ['e', '\varepsilon'],
    \     ['f', '\varphi'],
    \     ['g', '\gamma'],
    \     ['h', '\eta'],
    \     ['k', '\kappa'],
    \     ['l', '\lambda'],
    \     ['m', '\mu'],
    \     ['n', '\nu'],
    \     ['o', '\omega'],
    \     ['p', '\pi'],
    \     ['q', '\theta'],
    \     ['r', '\rho'],
    \     ['s', '\sigma'],
    \     ['t', '\tau'],
    \     ['u', '\upsilon'],
    \     ['z', '\zeta'],
    \     ['D', '\Delta'],
    \     ['F', '\Phi'],
    \     ['G', '\Gamma'],
    \     ['L', '\Lambda'],
    \     ['N', '\nabla'],
    \     ['O', '\Omega'],
    \     ['Q', '\Theta'],
    \     ['R', '\varrho'],
    \     ['T', '\Tau'],
    \     ['U', '\Upsilon'],
    \     ['X', '\Xi'],
    \     ['Y', '\Psi'],
    \   ],
    \ },
    \]
endfunction

" }}}1
function! s:parse_collection(collection) " {{{1
  "
  " Extract some collection metadata
  "
  let l:leader = get(a:collection, 'leader', g:vimtex_imaps_leader)
  let l:mode = get(a:collection, 'mode', '')
  let l:math = l:mode =~# 'm'

  "
  " Create mappings
  "
  for [lhs, rhs] in a:collection.mappings
    let l:ultisnips = match(rhs, '$1') > 0
    if l:ultisnips && !s:has_ultisnips | continue | endif

    " Generate RHS
    if l:math && l:ultisnips
      let rhs = s:wrap_math_ultisnips(lhs, rhs)
    elseif l:math
      let rhs = s:wrap_math(lhs, rhs)
    elseif l:ultisnips
      let rhs = s:wrap_ultisnips(lhs, rhs)
    endif

    silent execute 'inoremap <silent><buffer>' l:leader . lhs rhs
  endfor

  "
  " Escape leader if it exists
  "
  if l:leader !=# '' && !hasmapto(l:leader, 'i')
    silent execute 'inoremap <silent><buffer>' l:leader . l:leader l:leader
  endif

  let b:vimtex.imap_collections += [a:collection.title]
endfunction

" }}}1

"
" Helper functions
"
function! s:wrap_math_ultisnips(lhs, rhs) " {{{1
  return a:lhs . '<c-r>=<sid>is_math() ? UltiSnips#Anon('''
        \ . a:rhs . ''', ''' . a:lhs . ''', '''', ''i'') : ''''<cr>'
endfunction

" }}}1
function! s:wrap_math(lhs, rhs) " {{{1
  return '<c-r>=<sid>is_math() ? ' . string(a:rhs)
        \ . ' : ' . string(a:lhs) . '<cr>'
endfunction

" }}}1
function! s:wrap_ultisnips(lhs, rhs) " {{{1
  return a:lhs . '<c-r>=UltiSnips#Anon('''
        \ . a:rhs . ''', ''' . a:lhs . ''', '''', ''i'')<cr>'
endfunction

" }}}1
function! s:is_math() " {{{1
  return match(map(synstack(line('.'), max([col('.') - 1, 1])),
        \ 'synIDattr(v:val, ''name'')'), '^texMathZone[A-Z]$') >= 0
endfunction

" }}}1

" vim: fdm=marker sw=2

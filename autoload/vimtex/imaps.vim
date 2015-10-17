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
    \   'mappings' : [
    \     ['...', '\dots'],
    \     ['<m-i>', '\item '],
    \   ],
    \ },
    \ {
    \   'title' : 'math',
    \   'leader' : '',
    \   'wrapper' : 's:wrap_math_ultisnips',
    \   'mappings' : [
    \     ['__', '_\{$1\}'],
    \     ['^^', '^\{$1\}'],
    \     ['((', '\left($1\right)'],
    \     ['[[', '\left[$1\right]'],
    \     ['{{', '\left\{$1\right\}'],
    \     ['exp', '\exp'],
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
    \   'wrapper' : 's:wrap_math_ultisnips',
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
    \   'wrapper' : 's:wrap_math',
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
    \     ['o', '\omicron'],
    \     ['p', '\pi'],
    \     ['q', '\theta'],
    \     ['r', '\rho'],
    \     ['s', '\sigma'],
    \     ['t', '\tau'],
    \     ['u', '\upsilon'],
    \     ['w', '\omega'],
    \     ['z', '\zeta'],
    \     ['A', '\Alpha'],
    \     ['B', '\Beta'],
    \     ['G', '\Gamma'],
    \     ['D', '\Delta'],
    \     ['E', '\Epsilon'],
    \     ['Z', '\Zeta'],
    \     ['Y', '\Eta'],
    \     ['F', '\Phi'],
    \     ['G', '\Gamma'],
    \     ['L', '\Lambda'],
    \     ['N', '\Nabla'],
    \     ['O', '\Omicron'],
    \     ['Q', '\Theta'],
    \     ['R', '\varrho'],
    \     ['T', '\Tau'],
    \     ['U', '\Upsilon'],
    \     ['W', '\Omega'],
    \     ['X', '\Xi'],
    \     ['Y', '\Psi'],
    \   ],
    \ },
    \]
endfunction

" }}}1
function! s:parse_collection(collection) " {{{1
  let l:leader = get(a:collection, 'leader', g:vimtex_imaps_leader)
  let l:wrapper = get(a:collection, 'wrapper', '')

  " Create mappings
  for [lhs, rhs] in a:collection.mappings
    if match(rhs, '$1') > 0 && !s:has_ultisnips | continue | endif

    if l:wrapper !=# '' && exists('*' . l:wrapper)
      let rhs = call(l:wrapper, [lhs, rhs])
    endif

    silent execute 'inoremap <silent><buffer>' l:leader . lhs rhs
  endfor

  " Escape leader if it exists
  if l:leader !=# '' && !hasmapto(l:leader, 'i')
    silent execute 'inoremap <silent><buffer>' l:leader . l:leader l:leader
  endif

  let b:vimtex.imap_collections += [a:collection.title]
endfunction

" }}}1

"
" Wrappers
"
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
function! s:wrap_math_ultisnips(lhs, rhs) " {{{1
  return a:lhs . '<c-r>=<sid>is_math() ? '
        \ . 'UltiSnips#Anon(''' . a:rhs . ''', ''' . a:lhs . ''', '''', ''i'')'
        \ . ': ''''<cr>'
endfunction

" }}}1

"
" Helper functions
"
function! s:is_math() " {{{1
  return match(map(synstack(line('.'), max([col('.') - 1, 1])),
        \ 'synIDattr(v:val, ''name'')'), '^texMathZone[A-Z]$') >= 0
endfunction

" }}}1

" vim: fdm=marker sw=2

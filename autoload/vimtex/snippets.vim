" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#snippets#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_snippets_enabled', 1)
  call vimtex#util#set_default('g:vimtex_snippets_leader', '`')
endfunction

" }}}1
function! vimtex#snippets#init_script() " {{{1
  "
  " Define default lists of snippets
  "
  let s:snippets = {
        \ 'miscellaneous' : {
        \   'list' : [
        \     ['...', '\dots'],
        \     ['<m-i>', '\item '],
        \   ],
        \ },
        \ 'math' : {
        \   'math' : 1,
        \   'list' : [
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
        \ 'math_leader' : {
        \   'leader' : 1,
        \   'math' : 1,
        \   'list' : [
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
        \ 'greek' : { 
        \   'leader' : 1,
        \   'math' : 1,
        \   'list' : [
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
        \     ['U', '\Upsilon'],
        \     ['X', '\Xi'],
        \     ['Y', '\Psi'],
        \   ],
        \ },
        \}
endfunction

" }}}1
function! vimtex#snippets#init_buffer() " {{{1
  if !g:vimtex_snippets_enabled | return | endif

  "
  " Create predefined snippets
  "
  for [name, snippets] in items(s:snippets)
    if get(g:, 'vimtex_snippets_' . name, 1)
      echom 'Snippets created: ' . name
      call s:create_snippets(snippets)
    endif
  endfor

  "
  " Create custom snippets if defined
  "
  for snippets in get(g:, 'vimtex_snippets_custom', [])
    call s:create_snippets(snippets)
  endfor

  "
  " Escape the leader
  "
  silent execute 'inoremap <silent><buffer>'
        \ g:vimtex_snippets_leader . g:vimtex_snippets_leader
        \ g:vimtex_snippets_leader
endfunction

" }}}1

"
" Functions to create the snippets
"
function! s:create_snippets(snippets) " {{{1
  let l:leader = get(a:snippets, 'leader', 0)
  let l:math = get(a:snippets, 'math', 0)

  for [lhs, rhs] in a:snippets.list
    let l:ultisnips = match(rhs, '$1') > 0

    "
    " Generate RHS
    "
    if l:math && l:ultisnips
      let rhs = s:wrap_math_ultisnips(lhs, rhs)
    elseif l:math
      let rhs = s:wrap_math(lhs, rhs)
    elseif l:ultisnips
      let rhs = s:wrap_ultisnips(lhs, rhs)
    endif

    "
    " Add leader
    "
    let lhs = l:leader ? g:vimtex_snippets_leader . lhs : lhs

    silent execute 'inoremap <silent><buffer>' lhs rhs
  endfor
endfunction

" }}}1
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
  return match(map(synstack(line('.'), col('.')),
        \ 'synIDattr(v:val, ''name'')'), '^texMathZone[A-Z]$') >= 0
endfunction

" }}}1

" vim: fdm=marker sw=2

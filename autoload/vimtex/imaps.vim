" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#imaps#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_imaps_enabled', 1)
  call vimtex#util#set_default('g:vimtex_imaps_leader', '`')
  call vimtex#util#set_default('g:vimtex_imaps_default', [
        \ { 'map' : ['...',   '\dots'],               'leader' : '' },
        \ { 'map' : ['<m-i>', '\item '],              'leader' : '' },
        \ { 'map' : ['__',    '_\{$1\}'],             'leader' : '',   'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['^^',    '^\{$1\}'],             'leader' : '',   'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['((',    '\left($1\right)'],     'leader' : '',   'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['[[',    '\left[$1\right]'],     'leader' : '',   'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['{{',    '\left\\{$1\right\\}'], 'leader' : '',   'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['i',     '\int_{$1}^{$2}'],      'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['S',     '\sum_{$1}^{$2}'],      'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['/',     '\frac{$1}{$2}'],       'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['0',     '\emptyset'],           'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['6',     '\partial'],            'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['8',     '\infty'],              'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['=',     '\equiv'],              'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['\',     '\setminus'],           'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['.',     '\cdot'],               'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['*',     '\times'],              'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['<',     '\leq'],                'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['>',     '\geq'],                'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['~',     '\tilde{$1}'],          'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['^',     '\hat{$1}'],            'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : [':',     '\dot{$1}'],            'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['_',     '\bar{$1}'],            'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['lim',   '\lim_{$1}'],           'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qj',    '\downarrow'],          'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['ql',    '\leftarrow'],          'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qh',    '\rightarrow'],         'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qk',    '\uparrow'],            'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qJ',    '\Downarrow'],          'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qL',    '\Leftarrow'],          'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qH',    '\Rightarrow'],         'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['qK',    '\Uparrow'],            'wrapper' : 's:wrap_math_ultisnips'},
        \ { 'map' : ['a',     '\alpha'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['b',     '\beta'],               'wrapper' : 's:wrap_math'},
        \ { 'map' : ['c',     '\chi'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['d',     '\delta'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['e',     '\varepsilon'],         'wrapper' : 's:wrap_math'},
        \ { 'map' : ['f',     '\varphi'],             'wrapper' : 's:wrap_math'},
        \ { 'map' : ['g',     '\gamma'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['h',     '\eta'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['k',     '\kappa'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['l',     '\lambda'],             'wrapper' : 's:wrap_math'},
        \ { 'map' : ['m',     '\mu'],                 'wrapper' : 's:wrap_math'},
        \ { 'map' : ['n',     '\nu'],                 'wrapper' : 's:wrap_math'},
        \ { 'map' : ['p',     '\pi'],                 'wrapper' : 's:wrap_math'},
        \ { 'map' : ['q',     '\theta'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['r',     '\rho'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['s',     '\sigma'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['t',     '\tau'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['u',     '\upsilon'],            'wrapper' : 's:wrap_math'},
        \ { 'map' : ['w',     '\omega'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['z',     '\zeta'],               'wrapper' : 's:wrap_math'},
        \ { 'map' : ['A',     '\Alpha'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['B',     '\Beta'],               'wrapper' : 's:wrap_math'},
        \ { 'map' : ['G',     '\Gamma'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['D',     '\Delta'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['E',     '\Epsilon'],            'wrapper' : 's:wrap_math'},
        \ { 'map' : ['Z',     '\Zeta'],               'wrapper' : 's:wrap_math'},
        \ { 'map' : ['Y',     '\Eta'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['F',     '\Phi'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['G',     '\Gamma'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['L',     '\Lambda'],             'wrapper' : 's:wrap_math'},
        \ { 'map' : ['N',     '\Nabla'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['Q',     '\Theta'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['R',     '\varrho'],             'wrapper' : 's:wrap_math'},
        \ { 'map' : ['T',     '\Tau'],                'wrapper' : 's:wrap_math'},
        \ { 'map' : ['U',     '\Upsilon'],            'wrapper' : 's:wrap_math'},
        \ { 'map' : ['W',     '\Omega'],              'wrapper' : 's:wrap_math'},
        \ { 'map' : ['X',     '\Xi'],                 'wrapper' : 's:wrap_math'},
        \ { 'map' : ['Y',     '\Psi'],                'wrapper' : 's:wrap_math'},
        \])
endfunction

" }}}1
function! vimtex#imaps#init_script() " {{{1
  let s:has_ultisnips = exists('*UltiSnips#Anon')
endfunction

" }}}1
function! vimtex#imaps#init_buffer() " {{{1
  if !g:vimtex_imaps_enabled | return | endif

  for l:map in g:vimtex_imaps_default
    call vimtex#imaps#add_map(l:map)
  endfor
endfunction

" }}}1

function! vimtex#imaps#add_map(map) " {{{1
  let l:lhs = a:map.map[0]
  let l:rhs = a:map.map[1]
  if match(l:rhs, '$1') > 0 && !s:has_ultisnips | return | endif

  let l:leader = get(a:map, 'leader', g:vimtex_imaps_leader)
  let l:wrapper = get(a:map, 'wrapper', '')

  " Escape leader if it exists
  if l:leader !=# '' && !hasmapto(l:leader, 'i')
    silent execute 'inoremap <silent><buffer>' l:leader . l:leader l:leader
  endif

  " Apply wrapper
  if l:wrapper !=# '' && exists('*' . l:wrapper)
    let l:rhs = call(l:wrapper, [l:lhs, l:rhs])
  endif

  " Add mapping
  silent execute 'inoremap <silent><buffer>' l:leader . l:lhs l:rhs
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

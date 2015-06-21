" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#mappings#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_mappings_enabled', 1)
  call vimtex#util#set_default('g:vimtex_mappings_math_mode', 1)
  call vimtex#util#set_default('g:vimtex_mappings_leader', '`')
endfunction

" }}}1
function! vimtex#mappings#init_script() " {{{1
  "
  " Define default lists of mappings
  "
  let s:mappings = {
        \ 'list' : [
        \   ['...', '\dots'],
        \   ['<m-i>', '\item '],
        \ ],
        \}

  let s:mappings_math = {
        \ 'math' : 1,
        \ 'list' : [
        \   ['__', '_\{$1\}'],
        \   ['^^', '^\{$1\}'],
        \   ['((', '\left($1\right)'],
        \   ['[[', '\left[$1\right]'],
        \   ['{{', '\left\{$1\right\}'],
        \   ['exp', '\exp\left($1\right)'],
        \   ['cos', '\cos'],
        \   ['sin', '\sin'],
        \   ['tan', '\tan'],
        \   ['log', '\log'],
        \   ['in', '\in'],
        \   ['to', '\to'],
        \   ['lim', '\lim_{$1}'],
        \   ['qj', '\downarrow'],
        \   ['ql', '\leftarrow'],
        \   ['qh', '\rightarrow'],
        \   ['qk', '\uparrow'],
        \   ['qJ', '\Downarrow'],
        \   ['qL', '\Leftarrow'],
        \   ['qH', '\Rightarrow'],
        \   ['qK', '\Uparrow'],
        \ ]
        \}

  let s:mappings_math_leader = {
        \ 'leader' : 1,
        \ 'math' : 1,
        \ 'list' : [
        \   ['a', '\alpha'],
        \   ['b', '\beta'],
        \   ['c', '\chi'],
        \   ['d', '\delta'],
        \   ['e', '\varepsilon'],
        \   ['f', '\varphi'],
        \   ['g', '\gamma'],
        \   ['h', '\eta'],
        \   ['k', '\kappa'],
        \   ['l', '\lambda'],
        \   ['m', '\mu'],
        \   ['n', '\nu'],
        \   ['o', '\omega'],
        \   ['p', '\pi'],
        \   ['q', '\theta'],
        \   ['r', '\rho'],
        \   ['s', '\sigma'],
        \   ['t', '\tau'],
        \   ['u', '\upsilon'],
        \   ['z', '\zeta'],
        \   ['D', '\Delta'],
        \   ['F', '\Phi'],
        \   ['G', '\Gamma'],
        \   ['L', '\Lambda'],
        \   ['N', '\nabla'],
        \   ['O', '\Omega'],
        \   ['Q', '\Theta'],
        \   ['R', '\varrho'],
        \   ['U', '\Upsilon'],
        \   ['X', '\Xi'],
        \   ['Y', '\Psi'],
        \   ['i', '\int_{$1}^{$2}'],
        \   ['S', '\sum_{$1}^{$2}'],
        \   ['/', '\frac{$1}{$2}'],
        \   ['0', '\emptyset'],
        \   ['6', '\partial'],
        \   ['8', '\infty'],
        \   ['=', '\equiv'],
        \   ['\', '\setminus'],
        \   ['.', '\cdot'],
        \   ['*', '\times'],
        \   ['<', '\leq'],
        \   ['>', '\geq'],
        \   ['~', '\tilde{$1}'],
        \   ['^', '\hat{$1}'],
        \   [';', '\dot{$1}'],
        \   ['_', '\bar{$1}'],
        \ ]
        \}
endfunction

" }}}1
function! vimtex#mappings#init_buffer() " {{{1
  if !g:vimtex_mappings_enabled | return | endif

  nmap <silent><buffer> <localleader>li <plug>(vimtex-info)

  nmap <silent><buffer> dse  <plug>(vimtex-delete-env)
  nmap <silent><buffer> dsc  <plug>(vimtex-delete-cmd)
  nmap <silent><buffer> cse  <plug>(vimtex-change-env)
  nmap <silent><buffer> csc  <plug>(vimtex-change-cmd)
  nmap <silent><buffer> tse  <plug>(vimtex-toggle-star)
  nmap <silent><buffer> tsd  <plug>(vimtex-toggle-delim)
  nmap <silent><buffer> <F7> <plug>(vimtex-create-cmd)
  imap <silent><buffer> <F7> <plug>(vimtex-create-cmd)
  imap <silent><buffer> ]]   <plug>(vimtex-close-env)

  if g:vimtex_latexmk_enabled
    nmap <silent><buffer> <localleader>ll <plug>(vimtex-compile-toggle)
    nmap <silent><buffer> <localleader>lo <plug>(vimtex-compile-output)
    nmap <silent><buffer> <localleader>lk <plug>(vimtex-stop)
    nmap <silent><buffer> <localleader>lK <plug>(vimtex-stop-all)
    nmap <silent><buffer> <localleader>le <plug>(vimtex-errors)
    nmap <silent><buffer> <localleader>lc <plug>(vimtex-clean)
    nmap <silent><buffer> <localleader>lC <plug>(vimtex-clean-full)
    nmap <silent><buffer> <localleader>lg <plug>(vimtex-status)
    nmap <silent><buffer> <localleader>lG <plug>(vimtex-status-all)
  endif

  if g:vimtex_motion_enabled
    nmap <silent><buffer> %  <plug>(vimtex-%)
    xmap <silent><buffer> %  <plug>(vimtex-%)
    omap <silent><buffer> %  <plug>(vimtex-%)
    nmap <silent><buffer> ]] <plug>(vimtex-]])
    nmap <silent><buffer> ][ <plug>(vimtex-][)
    nmap <silent><buffer> [] <plug>(vimtex-[])
    nmap <silent><buffer> [[ <plug>(vimtex-[[)
    xmap <silent><buffer> ]] <plug>(vimtex-]])
    xmap <silent><buffer> ][ <plug>(vimtex-][)
    xmap <silent><buffer> [] <plug>(vimtex-[])
    xmap <silent><buffer> [[ <plug>(vimtex-[[)
    omap <silent><buffer> ]] <plug>(vimtex-]])
    omap <silent><buffer> ][ <plug>(vimtex-][)
    omap <silent><buffer> [] <plug>(vimtex-[])
    omap <silent><buffer> [[ <plug>(vimtex-[[)
    xmap <silent><buffer> ie <plug>(vimtex-ie)
    xmap <silent><buffer> ae <plug>(vimtex-ae)
    omap <silent><buffer> ie <plug>(vimtex-ie)
    omap <silent><buffer> ae <plug>(vimtex-ae)
    xmap <silent><buffer> i$ <plug>(vimtex-i$)
    xmap <silent><buffer> a$ <plug>(vimtex-a$)
    omap <silent><buffer> i$ <plug>(vimtex-i$)
    omap <silent><buffer> a$ <plug>(vimtex-a$)
    xmap <silent><buffer> id <plug>(vimtex-id)
    xmap <silent><buffer> ad <plug>(vimtex-ad)
    omap <silent><buffer> id <plug>(vimtex-id)
    omap <silent><buffer> ad <plug>(vimtex-ad)
  endif

  if g:vimtex_toc_enabled
    nmap <silent><buffer> <localleader>lt <plug>(vimtex-toc-open)
    nmap <silent><buffer> <localleader>lT <plug>(vimtex-toc-toggle)
  endif

  if g:vimtex_labels_enabled
    nmap <silent><buffer> <localleader>ly <plug>(vimtex-labels-open)
    nmap <silent><buffer> <localleader>lY <plug>(vimtex-labels-toggle)
  endif

  if g:vimtex_view_enabled
    nmap <silent><buffer> <localleader>lv <plug>(vimtex-view)
    if has_key(b:vimtex, 'rsearch')
      nmap <silent><buffer> <localleader>lr <plug>(vimtex-reverse-search)
    endif
  endif

  if g:vimtex_mappings_math_mode
    call s:init_math_mappings(s:mappings)
    call s:init_math_mappings(s:mappings_math)
    call s:init_math_mappings(s:mappings_math_leader)
    silent execute 'inoremap <silent><buffer>'
          \ g:vimtex_mappings_leader . g:vimtex_mappings_leader
          \ g:vimtex_mappings_leader
  endif
endfunction

" }}}1

"
" Math mode functions
"
function! s:init_math_mappings(mappings) " {{{1
  let l:leader = get(a:mappings, 'leader', 0)
  let l:math = get(a:mappings, 'math', 0)

  for [lhs, rhs] in a:mappings.list
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
    let lhs = l:leader ? g:vimtex_mappings_leader . lhs : lhs

    silent execute 'inoremap <silent><buffer>' lhs rhs
  endfor
endfunction

" }}}1
function! s:wrap_math_ultisnips(lhs, rhs) " {{{1
  return a:lhs . '<c-r>=<sid>is_math() ? ' . 'UltiSnips#Anon('''
        \ . a:rhs . ''', ''' . a:lhs . ''', '''', ''i'')' . ' : ''''<cr>'
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

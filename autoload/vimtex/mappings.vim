" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#mappings#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_mappings_enabled', 1)

  call vimtex#util#set_default('g:vimtex_mappings_leader', '`')
  call vimtex#util#set_default('g:vimtex_mappings_container', {})
endfunction

" }}}1
function! vimtex#mappings#init_script() " {{{1
  "
  " List of mappings
  "
  let g:mappings = {
        \ 'math' : [
        \   { 'lhs' : '__', 'rhs' : '_\{$1\}' },
        \   { 'lhs' : '^^', 'rhs' : '^\{$1\}' },
        \   { 'lhs' : '((', 'rhs' : '\left($1\right)' },
        \   { 'lhs' : '[[', 'rhs' : '\left[$1\right]' },
        \   { 'lhs' : '{{', 'rhs' : '\left\{$1\right\}' },
        \  ],
        \ 'all'  : [],
        \}

  "
  " List of mappings with leader key
  "
  let l:mappings_math_leader = [
          \ { 'lhs' : 'a', 'rhs' : '\alpha' },
          \ { 'lhs' : 'b', 'rhs' : '\beta' },
          \ { 'lhs' : 'c', 'rhs' : '\chi' },
          \ { 'lhs' : 'd', 'rhs' : '\delta' },
          \ { 'lhs' : 'e', 'rhs' : '\varepsilon' },
          \ { 'lhs' : 'f', 'rhs' : '\varphi' },
          \ { 'lhs' : 'g', 'rhs' : '\gamma' },
          \ { 'lhs' : 'h', 'rhs' : '\eta' },
          \ { 'lhs' : 'k', 'rhs' : '\kappa' },
          \ { 'lhs' : 'l', 'rhs' : '\lambda' },
          \ { 'lhs' : 'm', 'rhs' : '\mu' },
          \ { 'lhs' : 'n', 'rhs' : '\nu' },
          \ { 'lhs' : 'o', 'rhs' : '\omega' },
          \ { 'lhs' : 'p', 'rhs' : '\pi' },
          \ { 'lhs' : 'q', 'rhs' : '\theta' },
          \ { 'lhs' : 'r', 'rhs' : '\rho' },
          \ { 'lhs' : 's', 'rhs' : '\sigma' },
          \ { 'lhs' : 't', 'rhs' : '\tau' },
          \ { 'lhs' : 'u', 'rhs' : '\upsilon' },
          \ { 'lhs' : 'z', 'rhs' : '\zeta' },
          \ { 'lhs' : 'D', 'rhs' : '\Delta' },
          \ { 'lhs' : 'F', 'rhs' : '\Phi' },
          \ { 'lhs' : 'G', 'rhs' : '\Gamma' },
          \ { 'lhs' : 'L', 'rhs' : '\Lambda' },
          \ { 'lhs' : 'N', 'rhs' : '\nabla' },
          \ { 'lhs' : 'O', 'rhs' : '\Omega' },
          \ { 'lhs' : 'Q', 'rhs' : '\Theta' },
          \ { 'lhs' : 'R', 'rhs' : '\varrho' },
          \ { 'lhs' : 'U', 'rhs' : '\Upsilon' },
          \ { 'lhs' : 'X', 'rhs' : '\Xi' },
          \ { 'lhs' : 'Y', 'rhs' : '\Psi' },
          \]
  let g:mappings.math += map(l:mappings_math_leader,
        \ '{  ''lhs'' : g:vimtex_mappings_leader . v:val.lhs,'
        \  . '''rhs'' : v:val.rhs }')

" i             \int_{}^{}
" I             \int_{}^{}
" S             \sum_{}^{}
" /             \frac{}{}
" %             \frac{}{}
" v             \vee
" w             \wedge
" 0             \emptyset
" 6             \partial
" 8             \infty
" @             \circ
" \|            \Big\|
" =             \equiv
" \             \setminus
" .             \cdot
" *             \times
" &             \wedge
" -             \bigcap
" +             \bigcup
" (             \subset
" )             \supset
" <             \leq
" >             \geq
" ,             \nonumber
" :             \dots
" ~             \tilde{}
" ^             \hat{}
" ;             \dot{}
" _             \bar{}
" <M-c>         \cos
" <C-E>         \exp\left(\right)
" <C-I>         \in
" <C-J>         \downarrow
" <C-L>         \log
" <C-P>         \uparrow
" <Up>          \uparrow
" <C-N>         \downarrow
" <Down>        \downarrow
" <C-F>         \to
" <Right>       \lim_{}
" <C-S>         \sin
" <C-T>         \tan
" <M-l>         \ell
" <CR>          \nonumber\\

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

  " call s:init_math_mappings()
endfunction

" }}}1

function! s:init_math_mappings() " {{{1
  for map in s:mappings
    if map.type ==# 'map'
      silent execute 'inoremap <buffer><silent>' map.lhs
            \ map.lhs . '<c-r>=UltiSnips#Anon(''' . map.rhs . ''', ''' . map.lhs
            \ . ''', '''', ''i'')<cr>'
    elseif map.type ==# 'abbrev'
      silent execute 'inoremap <silent><buffer> ' . map.lhs
            \ . ' <c-r>=<sid>is_math() ?'
            \ string(map.rhs) ':' string(map.lhs) '<cr>'
    endif
  endfor
endfunction

" }}}1
function! s:is_math() " {{{1
  return match(map(synstack(line('.'), col('.')),
        \ 'synIDattr(v:val, ''name'')'), '^texMathZone[EX]$') >= 0
endfunction

" }}}1

" vim: fdm=marker sw=2

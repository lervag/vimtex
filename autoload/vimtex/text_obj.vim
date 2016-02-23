" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_text_obj_enabled', 1)
endfunction

" }}}1
function! vimtex#text_obj#init_script() " {{{1
endfunction

" }}}1
function! vimtex#text_obj#init_buffer() " {{{1
  if !g:vimtex_text_obj_enabled | return | endif

  for [l:map, l:name] in [
        \ ['c', 'commands'],
        \ ['d', 'delimiters'],
        \ ['e', 'environments'],
        \ ['$', 'inline_math'],
        \ ['p', 'paragraphs'],
        \]
    let l:p1 = 'noremap <silent><buffer> <plug>(vimtex-'
    let l:p2 = l:map . ') :<c-u>call vimtex#text_obj#' . l:name
    execute 'x' . l:p1 . 'i' . l:p2 . '(1)<cr>'
    execute 'x' . l:p1 . 'a' . l:p2 . '(0)<cr>'
    execute 'o' . l:p1 . 'i' . l:p2 . '(1)<cr>'
    execute 'o' . l:p1 . 'a' . l:p2 . '(0)<cr>'
  endfor
endfunction

" }}}1

function! vimtex#text_obj#commands(is_inner) " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let [l1, c1] = [l:cmd.pos_start.lnum, l:cmd.pos_start.cnum]
  let [l2, c2] = [l:cmd.pos_end.lnum, l:cmd.pos_end.cnum]

  if a:is_inner
    let l2 = l1
    let c2 = c1 + strlen(l:cmd.name) - 1
    let c1 += 1
  endif

  call cursor(l1, c1)
  normal! v
  call cursor(l2, c2)
endfunction

" }}}1
function! vimtex#text_obj#delimiters(is_inner) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('delim_all')
  if empty(l:open) | return | endif
  call s:text_obj_delim(l:open, l:close, a:is_inner)
endfunction

" }}}1
function! vimtex#text_obj#environments(is_inner) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env')
  if empty(l:open) | return | endif

  " Fix for options and extra arguments to environments, e.g.
  "
  "   \begin{frame}[asd]{title} ...
  "
  let l:open.match .= matchstr(join(getline(l:open.lnum, l:close.lnum), ''),
        \                      '^\v%(\s*\[[^]]*\])?%(\s*\{[^}]*\})*',
        \                      l:open.cnum + strlen(l:open.match) - 1)

  call s:text_obj_delim(l:open, l:close, a:is_inner)
endfunction

" }}}1
function! vimtex#text_obj#inline_math(is_inner) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_math')
  if empty(l:open) | return | endif
  call s:text_obj_delim(l:open, l:close, a:is_inner)
endfunction
" }}}1
function! vimtex#text_obj#paragraphs(is_inner) " {{{1
  " Define selection
  normal! 0j
  call vimtex#motion#next_paragraph(1,0)
  normal! jV
  call vimtex#motion#next_paragraph(0,0)

  " Go back one line for inner objects
  if a:is_inner
    normal! k
  endif
endfunction

" }}}1

function! s:text_obj_delim(open, close, is_inner) " {{{1
  let [l1, c1, l2, c2] = [a:open.lnum, a:open.cnum, a:close.lnum, a:close.cnum]

  if a:is_inner
    let c1 += len(a:open.match)
    let c2 -= 1

    let l:adjust_c1 = (c1 >= len(getline(l1)))
    let l:adjust_c2 = (c2 == 0) || (l:adjust_c1 &&
            \ len(substitute(strpart(getline(l2), 0, c2-1), '^\s*', '', '')) == 0)
    let l:adjust_both = l:adjust_c1 && l:adjust_c2

    if l:adjust_both
      let l1 += 1
      let c1 = strlen(matchstr(getline(l1), '^\s*')) + 1
    elseif l:adjust_c1
      let c1 += 1
    endif

    if l:adjust_c2
      let l2 -= 1
      let c2 = len(getline(l2)) + (l:adjust_both ? 0 : 1)
    endif
  else
    let c2 += len(a:close.match) - 1
  endif

  if l1 < l2 || (l1 == l2 && c1 < c2)
    execute 'normal!' visualmode() ==# 'V' ? 'V' : 'v'
    call cursor(l1, c1)
    normal! o
    call cursor(l2, c2)
  endif
endfunction
" }}}1

" vim: fdm=marker sw=2

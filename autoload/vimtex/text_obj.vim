" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#init_buffer() " {{{1
  if !g:vimtex_text_obj_enabled | return | endif

  for [l:map, l:name, l:opt] in [
        \ ['c', 'commands', ''],
        \ ['d', 'delimited', 'delim_all'],
        \ ['e', 'delimited', 'env_tex'],
        \ ['$', 'delimited', 'env_math'],
        \]
    let l:p1 = 'noremap <silent><buffer> <plug>(vimtex-'
    let l:p2 = l:map . ') :<c-u>call vimtex#text_obj#' . l:name
    let l:p3 = empty(l:opt) ? ')<cr>' : ',''' . l:opt . ''')<cr>'
    execute 'x' . l:p1 . 'i' . l:p2 . '(1, 1' . l:p3
    execute 'x' . l:p1 . 'a' . l:p2 . '(0, 1' . l:p3
    execute 'o' . l:p1 . 'i' . l:p2 . '(1, 0' . l:p3
    execute 'o' . l:p1 . 'a' . l:p2 . '(0, 0' . l:p3
  endfor
endfunction

" }}}1

function! vimtex#text_obj#commands(is_inner, mode) " {{{1
  if a:mode
    call cursor(getpos("'>")[1:])
  endif

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
function! vimtex#text_obj#delimited(is_inner, mode, type) " {{{1
  if a:mode
    call cursor(getpos("'>")[1:])
  endif

  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open)
    if a:mode
      normal! gv
    endif
    return
  endif

  let [l1, c1, l2, c2] = [l:open.lnum, l:open.cnum, l:close.lnum, l:close.cnum]

  " Determine if operator is linewise
  let l:linewise = index(g:vimtex_text_obj_linewise_operators, v:operator) >= 0

  " Adjust the borders
  if a:is_inner
    if has_key(l:open, 'env_cmd') && !empty(l:open.env_cmd)
      let l1 = l:open.env_cmd.pos_end.lnum
      let c1 = l:open.env_cmd.pos_end.cnum+1
    else
      let c1 += len(l:open.match)
    endif
    let c2 -= 1

    let l:is_inline = (l2 - l1) > 1
          \ && match(strpart(getline(l1),    c1), '^\s*$') >= 0
          \ && match(strpart(getline(l2), 0, c2), '^\s*$') >= 0

    if l:is_inline
      let l1 += 1
      let c1 = strlen(matchstr(getline(l1), '^\s*')) + 1
      let l2 -= 1
      let c2 = strlen(getline(l2))
      if c2 == 0 && ! l:linewise
        let l2 -= 1
        let c2 = len(getline(l2)) + 1
      endif
    elseif c2 == 0
      let l2 -= 1
      let c2 = len(getline(l2)) + 1
    endif
  else
    let c2 += len(l:close.match) - 1

    let l:is_inline = (l2 - l1) > 1
          \ && match(strpart(getline(l1), 0, c1-1), '^\s*$') >= 0
          \ && match(strpart(getline(l2), 0, c2),   '^\s*$') >= 0
  endif

  " Determine the select mode
  let l:select_mode = l:is_inline && l:linewise ? 'V'
        \ : (v:operator ==# ':') ? visualmode() : 'v'

  " Apply selection
  execute 'normal!' l:select_mode
  call cursor(l1, c1)
  normal! o
  call cursor(l2, c2)
endfunction

" }}}1


" {{{1 Initialize options

call vimtex#util#set_default('g:vimtex_text_obj_enabled', 1)
call vimtex#util#set_default('g:vimtex_text_obj_linewise_operators',
      \ ['d', 'y'])

" }}}1

" vim: fdm=marker sw=2

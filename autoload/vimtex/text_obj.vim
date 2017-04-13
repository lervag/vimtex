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
        \ ['P', 'sections', ''],
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
    call vimtex#pos#cursor(getpos("'>"))
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

  call vimtex#pos#cursor(l1, c1)
  normal! v
  call vimtex#pos#cursor(l2, c2)
endfunction

" }}}1
function! vimtex#text_obj#delimited(is_inner, mode, type) " {{{1
  if a:mode
    let l:selection = getpos("'<")[1:2] + getpos("'>")[1:2]
    call vimtex#pos#cursor(getpos("'>"))
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

    " Select next pair if we reached the same selection
    if a:mode && l:selection == [l1, c1, l2, c2]
      call vimtex#pos#cursor(vimtex#pos#next([l2, c2]))
      let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
      if empty(l:open)
        normal! gv
        return
      endif
      let [l1, c1, l2, c2] = [l:open.lnum, l:open.cnum,
            \ l:close.lnum, l:close.cnum + len(l:close.match) - 1]
    endif

    let l:is_inline = (l2 - l1) > 1
          \ && match(strpart(getline(l1), 0, c1-1), '^\s*$') >= 0
          \ && match(strpart(getline(l2), 0, c2),   '^\s*$') >= 0
  endif

  " Determine the select mode
  let l:select_mode = l:is_inline && l:linewise ? 'V'
        \ : (v:operator ==# ':') ? visualmode() : 'v'

  " Apply selection
  execute 'normal!' l:select_mode
  call vimtex#pos#cursor(l1, c1)
  normal! o
  call vimtex#pos#cursor(l2, c2)
endfunction

" }}}1
function! vimtex#text_obj#sections(is_inner, mode) " {{{1
  let l:pos_save = getpos('.')
  call vimtex#pos#cursor(vimtex#pos#next(l:pos_save))

  " Get section border positions
  let [l:pos_start, l:pos_end, l:type]
        \ = s:get_sections_positions(a:is_inner, '')
  if empty(l:pos_start)
    call vimtex#pos#cursor(l:pos_save)
    return
  endif

  " Increase visual area
  if a:mode
        \ && visualmode() ==# 'V'
        \ && getpos("'<")[1] == l:pos_start[0]
        \ && getpos("'>")[1] == l:pos_end[0]
    let [l:pos_start_new, l:pos_end_new, l:type]
          \ = s:get_sections_positions(a:is_inner, l:type)
    if !empty(l:pos_start_new)
      let l:pos_start = l:pos_start_new
      let l:pos_end = l:pos_end_new
    endif
  endif

  " Apply selection
  call vimtex#pos#cursor(l:pos_start)
  normal! V
  call vimtex#pos#cursor(l:pos_end)
endfunction

" }}}1

function! s:get_sections_positions(is_inner, type) " {{{1
  let l:pos_save = getpos('.')
  let l:min_val = get(s:section_to_val, a:type)

  " Get the position of the section start
  while 1
    let l:pos_start = searchpos(s:section_search, 'bcnW')
    if l:pos_start == [0, 0] | return [[], [], ''] | endif

    let l:sec_type = matchstr(getline(l:pos_start[0]), s:section_search)
    let l:sec_val = s:section_to_val[l:sec_type]

    if !empty(a:type)
      if l:sec_val >= l:min_val
        call vimtex#pos#cursor(vimtex#pos#prev(l:pos_start))
      else
        call vimtex#pos#cursor(l:pos_save)
        break
      endif
    else
      break
    endif
  endwhile

  " Get the position of the section end
  while 1
    let l:pos_end = searchpos(s:section_search, 'nW')
    if l:pos_end == [0, 0]
      let l:pos_end = [line('$')+1, 1]
      break
    endif

    let l:cur_val = s:section_to_val[
          \ matchstr(getline(l:pos_end[0]), s:section_search)]
    if l:cur_val <= l:sec_val
      let l:pos_end[0] -= 1
      break
    endif

    call vimtex#pos#cursor(l:pos_end)
  endwhile

  " Adjust for inner text object
  if a:is_inner
    call vimtex#pos#cursor(l:pos_start[0]+1, l:pos_start[1])
    let l:pos_start = searchpos('\S', 'cnW')
  elseif l:sec_val ==# 'document'
    let l:pos_start = [l:pos_start[0]+1, l:pos_start[1]]
  endif

  return [l:pos_start, l:pos_end, l:sec_type]
endfunction

" }}}1


" {{{1 Initialize module

" Pattern to match section/chapter/...
let s:section_search = '\v%(%(\\<!%(\\\\)*)@<=\%.*)@<!\s*\\\zs('
      \ . join([
      \   '%(sub)?paragraph\\>',
      \   '%(sub)*section\\>',
      \   'chapter\\>',
      \   'part\\>',
      \   'appendix\\>',
      \   '%(front|back|main)matter\\>',
      \   '%(begin|end)\{\zsdocument\ze\}'
      \  ], '|')
      \ .')'

" Dictionary to give values to sections in order to compare them
let s:section_to_val = {
      \ 'document':        0,
      \ 'frontmatter':     1,
      \ 'mainmatter':      1,
      \ 'appendix':        1,
      \ 'backmatter':      1,
      \ 'part':            1,
      \ 'chapter':         2,
      \ 'section':         3,
      \ 'subsection':      4,
      \ 'subsubsection':   5,
      \ 'paragraph':       6,
      \ 'subparagraph':    7,
      \}

" }}}1

" vim: fdm=marker sw=2

" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#init_buffer() abort " {{{1
  if !g:vimtex_text_obj_enabled | return | endif

  " Note: I've permitted myself long lines here to make this more readable.
  for [l:map, l:name, l:opt] in [
        \ ['c', 'commands', ''],
        \ ['d', 'delimited', 'delim_all'],
        \ ['e', 'delimited', 'env_tex'],
        \ ['$', 'delimited', 'env_math'],
        \ ['P', 'sections', ''],
        \ ['m', 'items', ''],
        \]
    let l:optional = empty(l:opt) ? '' : ',''' . l:opt . ''''
    execute printf('xnoremap <silent><buffer> <plug>(vimtex-i%s) :<c-u>call vimtex#text_obj#%s(1, 1%s)<cr>', l:map, l:name, l:optional)
    execute printf('xnoremap <silent><buffer> <plug>(vimtex-a%s) :<c-u>call vimtex#text_obj#%s(0, 1%s)<cr>', l:map, l:name, l:optional)
    execute printf('onoremap <silent><buffer> <plug>(vimtex-i%s) :<c-u>call vimtex#text_obj#%s(1, 0%s)<cr>', l:map, l:name, l:optional)
    execute printf('onoremap <silent><buffer> <plug>(vimtex-a%s) :<c-u>call vimtex#text_obj#%s(0, 0%s)<cr>', l:map, l:name, l:optional)
  endfor
endfunction

" }}}1

function! vimtex#text_obj#commands(is_inner, mode) abort " {{{1
  let l:obj = {}
  let l:pos_save = vimtex#pos#get_cursor()
  if a:mode
    call vimtex#pos#set_cursor(getpos("'>"))
  endif

  " Get the delimited text object positions
  for l:count in range(v:count1)
    if !empty(l:obj)
      call vimtex#pos#set_cursor(vimtex#pos#prev(l:obj.cmd_start))
    endif

    let l:obj_prev = l:obj
    let l:obj = {}

    let l:cmd = vimtex#cmd#get_current()
    if empty(l:cmd) | break | endif

    let l:pos_start = copy(l:cmd.pos_start)
    let l:pos_end = l:cmd.pos_end

    if a:is_inner
      let l:pos_end.lnum = l:pos_start.lnum
      let l:pos_end.cnum = l:pos_start.cnum + strlen(l:cmd.name) - 1
      let l:pos_start.cnum += 1
    endif

    if a:mode
          \ && vimtex#pos#equal(l:pos_start, getpos("'<"))
          \ && vimtex#pos#equal(l:pos_end, getpos("'>"))
      let l:pos_old = l:cmd.pos_start
      call vimtex#pos#set_cursor(vimtex#pos#prev(l:pos_old))

      let l:cmd = vimtex#cmd#get_current()
      if empty(l:cmd) | break | endif

      if vimtex#pos#smaller(l:pos_old, l:cmd.pos_end)
        let l:pos_start = l:cmd.pos_start
        let l:pos_end = l:cmd.pos_end

        if a:is_inner
          let l:pos_end.lnum = l:pos_start.lnum
          let l:pos_end.cnum = l:pos_start.cnum + strlen(l:cmd.name) - 1
          let l:pos_start.cnum += 1
        endif
      endif
    endif

    let l:obj = {
          \ 'pos_start' : l:pos_start,
          \ 'pos_end' : l:pos_end,
          \ 'cmd_start' : l:cmd.pos_start,
          \}
  endfor

  if empty(l:obj)
    if empty(l:obj_prev) || g:vimtex_text_obj_variant ==# 'targets'
      if a:mode
        normal! gv
      else
        call vimtex#pos#set_cursor(l:pos_save)
      endif
      return
    endif
    let l:obj = l:obj_prev
  endif

  call vimtex#pos#set_cursor(l:pos_start)
  normal! v
  call vimtex#pos#set_cursor(l:pos_end)
endfunction

" }}}1
function! vimtex#text_obj#delimited(is_inner, mode, type) abort " {{{1
  let l:object = {}
  let l:prev_object = {}
  let l:pos_save = vimtex#pos#get_cursor()
  let l:startpos = getpos("'>")

  " Get the delimited text object positions
  for l:count in range(v:count1)
    if !empty(l:object)
      let l:pos_next = vimtex#pos#prev(
            \ a:is_inner ? l:object.open : l:object.pos_start)

      if a:mode
        let l:startpos = l:pos_next
      else
        call vimtex#pos#set_cursor(l:pos_next)
      endif
    endif

    if a:mode
      let l:object = s:get_sel_delimited_visual(a:is_inner, a:type, l:startpos)
    else
      let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
      let l:object = empty(l:open)
            \ ? {} : s:get_sel_delimited(l:open, l:close, a:is_inner)
    endif

    if empty(l:object)
      if !empty(l:prev_object) && g:vimtex_text_obj_variant !=# 'targets'
        let l:object = l:prev_object
        break
      endif

      if a:mode
        normal! gv
      else
        call vimtex#pos#set_cursor(l:pos_save)
      endif
      return
    endif

    let l:prev_object = l:object
  endfor

  " Handle empty inner objects
  if vimtex#pos#smaller(l:object.pos_end, l:object.pos_start)
    if v:operator ==# 'y' && !a:mode
      return
    endif

    if index(['c', 'd'], v:operator) >= 0
      call vimtex#pos#set_cursor(l:object.pos_start)
      normal! ix
    endif

    let l:object.pos_end = l:object.pos_start
  endif

  " Apply selection
  execute 'normal!' l:object.select_mode
  call vimtex#pos#set_cursor(l:object.pos_start)
  normal! o
  call vimtex#pos#set_cursor(l:object.pos_end)
endfunction

" }}}1
function! vimtex#text_obj#sections(is_inner, mode) abort " {{{1
  let l:pos_save = vimtex#pos#get_cursor()
  call vimtex#pos#set_cursor(vimtex#pos#next(l:pos_save))

  " Get section border positions
  let [l:pos_start, l:pos_end, l:type]
        \ = s:get_sel_sections(a:is_inner, '')
  if empty(l:pos_start)
    call vimtex#pos#set_cursor(l:pos_save)
    return
  endif

  " Increase visual area if applicable
  if a:mode
        \ && visualmode() ==# 'V'
        \ && getpos("'<")[1] == l:pos_start[0]
        \ && getpos("'>")[1] == l:pos_end[0]
    let [l:pos_start_new, l:pos_end_new, l:type]
          \ = s:get_sel_sections(a:is_inner, l:type)
    if !empty(l:pos_start_new)
      let l:pos_start = l:pos_start_new
      let l:pos_end = l:pos_end_new
    endif
  endif

  " Repeat for count
  for l:count in range(v:count1 - 1)
    let [l:pos_start_new, l:pos_end_new, l:type]
          \ = s:get_sel_sections(a:is_inner, l:type)

    if empty(l:pos_start_new) | break | endif
    let l:pos_start = l:pos_start_new
    let l:pos_end = l:pos_end_new
  endfor

  " Apply selection
  call vimtex#pos#set_cursor(l:pos_start)
  normal! V
  call vimtex#pos#set_cursor(l:pos_end)
endfunction

" }}}1
function! vimtex#text_obj#items(is_inner, mode) abort " {{{1
  let l:pos_save = vimtex#pos#get_cursor()

  " Get section border positions
  let [l:pos_start, l:pos_end] = s:get_sel_items(a:is_inner)
  if empty(l:pos_start)
    call vimtex#pos#set_cursor(l:pos_save)
    return
  endif

  " Apply selection
  execute 'normal!' (v:operator ==# ':') ? visualmode() : 'v'
  call vimtex#pos#set_cursor(l:pos_start)
  normal! o
  call vimtex#pos#set_cursor(l:pos_end)
endfunction

" }}}1

function! s:get_sel_delimited_visual(is_inner, type, startpos) abort " {{{1
  if a:is_inner
    call vimtex#pos#set_cursor(vimtex#pos#next(a:startpos))
    let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
    if !empty(l:open)
      let l:object = s:get_sel_delimited(l:open, l:close, a:is_inner)

      " Select next pair if we reached the same selection
      if (l:object.select_mode ==# 'v'
          \ && getpos("'<")[1:2] == l:object.pos_start
          \ && getpos("'>")[1:2] == l:object.pos_end)
          \ || (l:object.select_mode ==# 'V'
          \     && getpos("'<")[1] == l:object.pos_start[0]
          \     && getpos("'>")[1] == l:object.pos_end[0])
        call vimtex#pos#set_cursor(vimtex#pos#prev(l:open.lnum, l:open.cnum))
        let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
        if empty(l:open) | return {} | endif
        return s:get_sel_delimited(l:open, l:close, a:is_inner)
      endif
    endif
  endif

  call vimtex#pos#set_cursor(a:startpos)
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return {} | endif
  let l:object = s:get_sel_delimited(l:open, l:close, a:is_inner)
  if a:is_inner | return l:object | endif

  " Select next pair if we reached the same selection
  if (l:object.select_mode ==# 'v'
      \ && getpos("'<")[1:2] == l:object.pos_start
      \ && getpos("'>")[1:2] == l:object.pos_end)
      \ || (l:object.select_mode ==# 'V'
      \     && getpos("'<")[1] == l:object.pos_start[0]
      \     && getpos("'>")[1] == l:object.pos_end[0])
    call vimtex#pos#set_cursor(vimtex#pos#prev(l:open.lnum, l:open.cnum))
    let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
    if empty(l:open) | return {} | endif
    return s:get_sel_delimited(l:open, l:close, a:is_inner)
  endif

  return l:object
endfunction

" }}}1
function! s:get_sel_delimited(open, close, is_inner) abort " {{{1
  " Determine if operator is linewise
  let l:linewise = index(g:vimtex_text_obj_linewise_operators, v:operator) >= 0

  let [l1, c1, l2, c2] = [a:open.lnum, a:open.cnum, a:close.lnum, a:close.cnum]

  " Adjust the borders
  if a:is_inner
    if has_key(a:open, 'env_cmd') && !empty(a:open.env_cmd)
      let l1 = a:open.env_cmd.pos_end.lnum
      let c1 = a:open.env_cmd.pos_end.cnum+1
    else
      let c1 += len(a:open.match)
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
      if c2 == 0 && !l:linewise
        let l2 -= 1
        let c2 = len(getline(l2)) + 1
      endif
    elseif c2 == 0
      let l2 -= 1
      let c2 = len(getline(l2)) + 1
    endif
  else
    let c2 += len(a:close.match) - 1

    let l:is_inline = (l2 - l1) > 1
          \ && match(strpart(getline(l1), 0, c1-1), '^\s*$') >= 0
          \ && match(strpart(getline(l2), 0, c2),   '^\s*$') >= 0
  endif

  return {
        \ 'open' : a:open,
        \ 'close' : a:close,
        \ 'pos_start' : [l1, c1],
        \ 'pos_end' : [l2, c2],
        \ 'is_inline' : l:is_inline,
        \ 'select_mode' : l:is_inline && l:linewise
        \      ? 'V' : (v:operator ==# ':') ? visualmode() : 'v',
        \}
endfunction

" }}}1
function! s:get_sel_sections(is_inner, type) abort " {{{1
  let l:pos_save = vimtex#pos#get_cursor()
  let l:min_val = get(s:section_to_val, a:type)

  " Get the position of the section start
  while 1
    let l:pos_start = searchpos(s:section_search, 'bcnW')
    if l:pos_start == [0, 0] | return [[], [], ''] | endif

    let l:sec_type = matchstr(getline(l:pos_start[0]), s:section_search)
    let l:sec_val = s:section_to_val[l:sec_type]

    if !empty(a:type)
      if l:sec_val >= l:min_val
        call vimtex#pos#set_cursor(vimtex#pos#prev(l:pos_start))
      else
        call vimtex#pos#set_cursor(l:pos_save)
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

    call vimtex#pos#set_cursor(l:pos_end)
  endwhile

  " Adjust for inner text object
  if a:is_inner
    call vimtex#pos#set_cursor(l:pos_start[0]+1, l:pos_start[1])
    let l:pos_start = searchpos('\S', 'cnW')
    call vimtex#pos#set_cursor(l:pos_end)
    let l:pos_end = searchpos('\S', 'bcnW')
  elseif l:sec_val ==# 'document'
    let l:pos_start = [l:pos_start[0]+1, l:pos_start[1]]
  endif

  return [l:pos_start, l:pos_end, l:sec_type]
endfunction

" }}}1
function! s:get_sel_items(is_inner) abort " {{{1
  let l:pos_cursor = vimtex#pos#get_cursor()

  " Find previous \item
  call vimtex#pos#set_cursor(l:pos_cursor[0], 1)
  let l:pos_start = searchpos('^\s*\\item\S*', 'bcnWz')
  if l:pos_start == [0, 0] | return [[], []] | endif

  " Find end of current \item
  call vimtex#pos#set_cursor(l:pos_start)
  let l:pos_end = searchpos('\ze\n\s*\%(\\item\|\\end{itemize}\)', 'nW')
  if l:pos_end == [0, 0]
        \ || vimtex#pos#val(l:pos_cursor) > vimtex#pos#val(l:pos_end)
    return [[], []]
  endif

  " Adjust for outer text object
  if a:is_inner
    let l:pos_start[1] = searchpos('^\s*\\item\S*\s\?', 'cne')[1] + 1
    let l:pos_end[1] = col([l:pos_end[0], '$']) - 1
  endif

  return [l:pos_start, l:pos_end]
endfunction

" }}}1


" {{{1 Initialize module

" Pattern to match section/chapter/...
let s:section_search = '\v%(%(\\@<!%(\\\\)*)@<=\%.*)@<!\s*\\\zs('
      \ . join([
      \   '%(sub)?paragraph>',
      \   '%(sub)*section>',
      \   'chapter>',
      \   'part>',
      \   'appendix>',
      \   '%(front|back|main)matter>',
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

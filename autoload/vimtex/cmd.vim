" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cmd#init_options() " {{{1
endfunction

" }}}1
function! vimtex#cmd#init_script() " {{{1
endfunction

" }}}1
function! vimtex#cmd#init_buffer() " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-cmd-delete)
        \ :call vimtex#cmd#delete()<cr>

  nnoremap <silent><buffer> <plug>(vimtex-cmd-change)
        \ :call vimtex#cmd#change()<cr>

  nnoremap <silent><buffer> <plug>(vimtex-cmd-create)
        \ :call vimtex#cmd#create()<cr>i

  inoremap <silent><buffer> <plug>(vimtex-cmd-create)
        \ <c-r>=vimtex#cmd#create()<cr>
endfunction

" }}}1

function! vimtex#cmd#change() " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let l:old_name = l:cmd.name
  let l:lnum = l:cmd.pos_start.lnum
  let l:cnum = l:cmd.pos_start.cnum

  " Get new command name
  call vimtex#echo#status(['Change command: ', ['VimtexWarning', l:old_name]])
  echohl VimtexMsg
  let l:new_name = input('> ')
  echohl None
  let l:new_name = substitute(l:new_name, '^\\', '', '')
  if empty(l:new_name) | return | endif

  " Update current position
  let l:save_pos = getpos('.')
  let l:save_pos[2] += strlen(l:new_name) - strlen(l:old_name) + 1

  " Perform the change
  let l:line = getline(l:lnum)
  call setline(l:lnum,
        \   strpart(l:line, 0, l:cnum)
        \ . l:new_name
        \ . strpart(l:line, l:cnum + strlen(l:old_name) - 1))

  " Restore cursor position and create repeat hook
  cal setpos('.', l:save_pos)
  silent! call repeat#set("\<plug>(vimtex-cmd-change)" . l:new_name . '', v:count)
endfunction

function! vimtex#cmd#delete() " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let l:old_name = l:cmd.name
  let l:lnum = l:cmd.pos_start.lnum
  let l:cnum = l:cmd.pos_start.cnum

  " Update current position
  let l:save_pos = getpos('.')
  let l:save_pos[2] += 1 - strlen(l:old_name)

  " Perform the change
  let l:line = getline(l:lnum)
  call setline(l:lnum,
        \   strpart(l:line, 0, l:cnum - 1)
        \ . strpart(l:line, l:cnum + strlen(l:old_name) - 1))

  " Restore cursor position and create repeat hook
  cal setpos('.', l:save_pos)
  silent! call repeat#set("\<plug>(vimtex-cmd-delete)", v:count)
endfunction

function! vimtex#cmd#create() " {{{1
  " Get current line
  let line = getline('.')

  " Get cursor position
  let pos = getpos('.')

  " Return if there is no word at cursor
  if mode() ==# 'n'
    let column = pos[2] - 1
  else
    let column = pos[2] - 2
  endif
  if column <= 1 || line[column] =~# '\s'
    return ''
  endif

  " Prepend a backslash to beginning of the current word
  normal! B
  let column = getpos('.')[2]
  if line[column - 1] !=# '\'
    let line = strpart(line, 0, column - 1) . '\' . strpart(line, column - 1)
    call setline('.', line)
  endif

  " Append opening braces to the end of the current word
  normal! E
  let column = getpos('.')[2]
  let pos[2] = column + 1
  if line[column - 1] !=# '{'
    let line = strpart(line, 0, column) . '{' . strpart(line, column)
    call setline('.', line)
    let pos[2] += 1
  endif

  " Restore cursor position
  call setpos('.', pos)
  return ''
endfunction

" }}}1

function! vimtex#cmd#get_next() " {{{1
  return s:get_cmd('next')
endfunction

" }}}1
function! vimtex#cmd#get_prev() " {{{1
  return s:get_cmd('prev')
endfunction

" }}}1
function! vimtex#cmd#get_current() " {{{1
  let pos = getpos('.')

  let depth = 3
  while depth > 0
    let depth -= 1
    let cmd = s:get_cmd('prev')
    if empty(cmd) | break | endif

    if 10000*pos[1] + pos[2] <= 10000*cmd.pos_end.lnum + cmd.pos_end.cnum
      return cmd
    endif
  endwhile

  return {}
endfunction

" }}}1

function! s:get_cmd(direction) " {{{1
  let [lnum, cnum, match] = s:get_cmd_name(a:direction ==# 'next')
  if lnum == 0 | return {} | endif

  let res = {
        \ 'name' : match,
        \ 'pos_start' : { 'lnum' : lnum, 'cnum' : cnum },
        \ 'pos_end' : { 'lnum' : lnum, 'cnum' : cnum + strlen(match) - 1 },
        \}

  " Get options
  let res.opt = s:get_cmd_part('[', res.pos_end)
  if !empty(res.opt)
    let res.pos_end.lnum = res.opt.close.lnum
    let res.pos_end.cnum = res.opt.close.cnum
  endif

  " Get arguments
  let arg = s:get_cmd_part('{', res.pos_end)
  let res.args = []
  while !empty(arg)
    call add(res.args, arg)
    let res.pos_end.lnum = arg.close.lnum
    let res.pos_end.cnum = arg.close.cnum
    let arg = s:get_cmd_part('{', res.pos_end)
  endwhile

  " Include entire cmd text
  let res.text = s:text_between(res.pos_start, res.pos_end, 1)

  return res
endfunction

" }}}1
function! s:get_cmd_name(next) " {{{1
  let [l:lnum, l:cnum] = searchpos('\\\a\+', a:next ? 'nW' : 'cbnW')
  let l:match = matchstr(getline(l:lnum), '^\\\a*', l:cnum-1)
  return [l:lnum, l:cnum, l:match]
endfunction

" }}}1
function! s:get_cmd_part(part, start_pos) " {{{1
  let l:save_pos = getpos('.')
  call setpos('.', [0, a:start_pos.lnum, a:start_pos.cnum, 0])
  let l:open = vimtex#delim#get_next('delim_tex', 'open')
  call setpos('.', l:save_pos)

  "
  " Ensure that the delimiter
  " 1) exists,
  " 2) is of the right type,
  " 3) and is the next non-whitespace character.
  "
  if empty(l:open)
        \ || l:open.match !=# a:part
        \ || strlen(substitute(
        \             s:text_between(a:start_pos, l:open), ' ', '', 'g')) != 0
    return {}
  endif

  let l:close = vimtex#delim#get_matching(l:open)
  if empty(l:close)
    return {}
  endif

  return {
        \ 'open' : l:open,
        \ 'close' : l:close,
        \ 'text' : s:text_between(l:open, l:close),
        \}
endfunction

" }}}1

function! s:text_between(p1, p2, ...) " {{{1
  let [l1, c1] = [a:p1.lnum, a:p1.cnum - (a:0 > 0)]
  let [l2, c2] = [a:p2.lnum, a:p2.cnum - (a:0 <= 0)]

  let lines = getline(l1, l2)
  let lines[0] = strpart(lines[0], c1)
  let lines[-1] = strpart(lines[-1], 0,
        \ l1 == l2 ? c2 - c1 : c2)
  return join(lines, '')
endfunction

" }}}1

" vim: fdm=marker sw=2

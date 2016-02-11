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

function! vimtex#cmd#get_command(...) " {{{1
  let l:position = a:0 > 0 ? a:1 : searchpos('\S', 'bcn')
  let l:line = getline(l:position[0])
  let l:char = l:line[l:position[1]-1]

  " Lists of relevant syntax regions
  let l:commands = [
        \ 'texStatement',
        \ 'texTypeSize',
        \ 'texTypeStyle',
        \ 'texBeginEnd',
        \ ]
  let l:argument = [
        \ 'texMatcher',
        \ 'texItalStyle',
        \ 'texRefZone',
        \ 'texBeginEndName',
        \ ]

  for l:syntax in reverse(map(call('synstack', l:position),
        \ 'synIDattr(v:val, ''name'')'))
    if index(l:commands, l:syntax) >= 0
      let l:p = searchpos('\\', 'bcn')
      let l:c = matchstr(l:line, '\\\zs\w\+', l:p[1]-1)
      return [l:c] + l:p
    elseif index(l:argument, l:syntax) >= 0
          \ || (l:syntax ==# 'Delimiter' && l:char =~# '{\|}')
      let l:curpos = exists('*getcurpos') ? getcurpos() : getpos('.')
      keepjumps normal! vaBoh
      let l:result = vimtex#cmd#get_command()
      call setpos('.', l:curpos)
      return l:result
    endif
  endfor

  return ['', 0, 0]
endfunction

" }}}1
function! vimtex#cmd#change() " {{{1
  " Get old command
  let [l:old, l:line, l:col] = vimtex#cmd#get_command()
  if l:old ==# '' | return | endif

  " Get new command
  let l:new = input('Change ' . old . ' for: ')
  let l:new = empty(l:new) ? l:old : l:new

  " Store current cursor position
  let l:curpos = exists('*getcurpos') ? getcurpos() : getpos('.')
  if l:line == l:curpos[1]
    let l:curpos[2] += len(l:new) - len(l:old)
  endif

  " This is a hack to make undo restore the correct position
  normal! ix
  normal! x

  " Perform the change
  let l:tmppos = copy(l:curpos)
  let l:tmppos[1:2] = [l:line, l:col+1]
  cal setpos('.', l:tmppos)
  let l:savereg = @a
  let @a = l:new
  normal! cea
  let @a = l:savereg

  " Restore cursor position and create repeat hook
  call setpos('.', l:curpos)
  silent! call repeat#set("\<plug>(vimtex-cmd-change)" . new . '', v:count)
endfunction

function! vimtex#cmd#delete() " {{{1
  " Get old command
  let [l:old, l:line, l:col] = vimtex#cmd#get_command()
  if l:old ==# '' | return | endif

  " Store current cursor position
  let l:curpos = exists('*getcurpos') ? getcurpos() : getpos('.')
  if l:line == l:curpos[1]
    let l:curpos[2] -= len(l:old)+1
  endif

  " Save selection
  let l:vstart = [l:curpos[0], line("'<"), col("'<"), l:curpos[3]]
  let l:vstop = [l:curpos[0], line("'<"), col("'>"), l:curpos[3]]

  " This is a hack to make undo restore the correct position
  normal! ix
  normal! x

  " Use temporary cursor position
  let l:tmppos = copy(l:curpos)
  let l:tmppos[1:2] = [l:line, l:col]
  call setpos('.', l:tmppos)
  normal! de

  " Delete surrounding braces if present
  if getline('.')[l:col-1 :] =~# '^\s*{'
    call searchpos('{', 'c')
    keepjumps normal! vaBomzoxg`zx
    if l:line == l:curpos[1]
      let l:curpos[2] -= 1
      if l:curpos[2] < 0
        let l:curpos[2] = 0
      endif
    endif
  endif

  " Restore cursor position and visual selection
  call setpos('.', l:curpos)
  call setpos("'<", l:vstart)
  call setpos("'>", l:vstop)

  " Create repeat hook
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

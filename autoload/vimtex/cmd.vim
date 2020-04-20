" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cmd#init_buffer() abort " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-cmd-delete)
        \ :<c-u>call <sid>operator_setup('delete')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-cmd-change)
        \ :<c-u>call <sid>operator_setup('change')<bar>normal! g@l<cr>

  inoremap <silent><buffer> <plug>(vimtex-cmd-create)
        \ <c-r>=vimtex#cmd#create_insert()<cr>

  nnoremap <silent><buffer> <plug>(vimtex-cmd-create)
        \ :<c-u>call <sid>operator_setup('create')<bar>normal! g@l<cr>

  xnoremap <silent><buffer> <plug>(vimtex-cmd-create)
        \ :<c-u>call vimtex#cmd#create_visual()<cr>

  nnoremap <silent><buffer> <plug>(vimtex-cmd-toggle-star)
        \ :<c-u>call <sid>operator_setup('toggle_star')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-cmd-toggle-frac)
        \ :<c-u>call <sid>operator_setup('toggle_frac')<bar>normal! g@l<cr>

  xnoremap <silent><buffer> <plug>(vimtex-cmd-toggle-frac)
        \ :<c-u>call vimtex#cmd#toggle_frac_visual()<cr>
endfunction

" }}}1

function! vimtex#cmd#change(new_name) abort " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let l:old_name = l:cmd.name
  let l:lnum = l:cmd.pos_start.lnum
  let l:cnum = l:cmd.pos_start.cnum

  " Get new command name
  let l:new_name = substitute(a:new_name, '^\\', '', '')
  if empty(l:new_name) | return | endif

  " Update current position
  let l:save_pos = vimtex#pos#get_cursor()
  if strlen(l:new_name) < strlen(l:old_name)
    let l:col = searchpos('\\\k', 'bcnW')[1] + strlen(l:new_name)
    if l:col < l:save_pos[2]
      let l:save_pos[2] = l:col
    endif
  endif

  " Perform the change
  let l:line = getline(l:lnum)
  call setline(l:lnum,
        \   strpart(l:line, 0, l:cnum)
        \ . l:new_name
        \ . strpart(l:line, l:cnum + strlen(l:old_name) - 1))

  " Restore cursor position
  cal vimtex#pos#set_cursor(l:save_pos)
endfunction

function! vimtex#cmd#delete(...) abort " {{{1
  if a:0 > 0
    let l:cmd = call('vimtex#cmd#get_at', a:000)
  else
    let l:cmd = vimtex#cmd#get_current()
  endif
  if empty(l:cmd) | return | endif

  " Save current position
  let l:save_pos = vimtex#pos#get_cursor()
  let l:lnum_cur = l:save_pos[1]
  let l:cnum_cur = l:save_pos[2]

  " Remove closing bracket (if exactly one argument)
  if len(l:cmd.args) == 1
    let l:lnum = l:cmd.args[0].close.lnum
    let l:cnum = l:cmd.args[0].close.cnum
    let l:line = getline(l:lnum)
    call setline(l:lnum,
          \   strpart(l:line, 0, l:cnum - 1)
          \ . strpart(l:line, l:cnum))

    let l:cnum2 = l:cmd.args[0].open.cnum
  endif

  " Remove command (and possibly the opening bracket)
  let l:lnum = l:cmd.pos_start.lnum
  let l:cnum = l:cmd.pos_start.cnum
  let l:cnum2 = get(l:, 'cnum2', l:cnum + strlen(l:cmd.name) - 1)
  let l:line = getline(l:lnum)
  call setline(l:lnum,
        \   strpart(l:line, 0, l:cnum - 1)
        \ . strpart(l:line, l:cnum2))

  " Restore appropriate cursor position
  if l:lnum_cur == l:lnum
    if l:cnum_cur > l:cnum2
      let l:save_pos[2] -= l:cnum2 - l:cnum + 1
    else
      let l:save_pos[2] -= l:cnum_cur - l:cnum
    endif
  endif
  cal vimtex#pos#set_cursor(l:save_pos)
endfunction

function! vimtex#cmd#delete_all(...) abort " {{{1
  if a:0 > 0
    let l:cmd = call('vimtex#cmd#get_at', a:000)
  else
    let l:cmd = vimtex#cmd#get_current()
  endif
  if empty(l:cmd) | return | endif

  call vimtex#pos#set_cursor(l:cmd.pos_start)
  normal! v
  call vimtex#pos#set_cursor(l:cmd.pos_end)
  normal! d
endfunction

function! vimtex#cmd#create_insert() abort " {{{1
  if mode() !=# 'i' | return | endif

  let l:re = '\v%(^|\A)\zs\a+\ze%(\A|$)'
  let l:c0 = col('.') - 1

  let [l:l1, l:c1] = searchpos(l:re, 'bcn', line('.'))
  let l:c1 -= 1
  let l:line = getline(l:l1)
  let l:match = matchstr(l:line, l:re, l:c1)
  let l:c2 = l:c1 + strlen(l:match)

  if l:c0 > l:c2
    call vimtex#log#warning('Could not create command')
    return ''
  endif

  let l:strpart1 = strpart(l:line, 0, l:c1)
  let l:strpart2 = '\' . strpart(l:match, 0, l:c0 - l:c1) . '{'
  let l:strpart3 = strpart(l:line, l:c0)
  call setline(l:l1, l:strpart1 . l:strpart2 . l:strpart3)

  call vimtex#pos#set_cursor(l:l1, l:c2+3)
  return ''
endfunction

" }}}1
function! vimtex#cmd#create(cmd, visualmode) abort " {{{1
  if empty(a:cmd) | return | endif

  " Avoid autoindent (disable indentkeys)
  let l:save_indentkeys = &l:indentkeys
  setlocal indentkeys=

  if a:visualmode
    let l:pos_start = getpos("'<")
    let l:pos_end = getpos("'>")

    if visualmode() ==# ''
      normal! gvA}
      execute 'normal! gvI\' . a:cmd . '{'

      let l:pos_end[2] += strlen(a:cmd) + 3
    else
      normal! `>a}
      normal! `<
      execute 'normal! i\' . a:cmd . '{'

      let l:pos_end[2] +=
            \ l:pos_end[1] == l:pos_start[1] ? strlen(a:cmd) + 3 : 1
    endif

    call vimtex#pos#set_cursor(l:pos_end)
  else
    let l:pos = vimtex#pos#get_cursor()
    let l:save_reg = getreg('"')
    let l:pos[2] += strlen(a:cmd) + 2
    execute 'normal! ciw\' . a:cmd . '{"}'
    call setreg('"', l:save_reg)
    call vimtex#pos#set_cursor(l:pos)
  endif

  " Restore indentkeys setting
  let &l:indentkeys = l:save_indentkeys
endfunction

" }}}1
function! vimtex#cmd#create_visual() abort " {{{1
  let l:cmd = vimtex#echo#input({
        \ 'info' :
        \   ['Create command: ', ['VimtexWarning', '(empty to cancel)']],
        \})
  let l:cmd = substitute(l:cmd, '^\\', '', '')
  call vimtex#cmd#create(l:cmd, 1)
endfunction

" }}}1
function! vimtex#cmd#toggle_star() abort " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let l:old_name = l:cmd.name
  let l:lnum = l:cmd.pos_start.lnum
  let l:cnum = l:cmd.pos_start.cnum

  " Set new command name
  if match(l:old_name, '\*$') == -1
    let l:new_name = l:old_name.'*'
  else
    let l:new_name = strpart(l:old_name, 0, strlen(l:old_name)-1)
  endif
  let l:new_name = substitute(l:new_name, '^\\', '', '')
  if empty(l:new_name) | return | endif

  " Update current position
  let l:save_pos = vimtex#pos#get_cursor()
  let l:save_pos[2] += strlen(l:new_name) - strlen(l:old_name) + 1

  " Perform the change
  let l:line = getline(l:lnum)
  call setline(l:lnum,
        \   strpart(l:line, 0, l:cnum)
        \ . l:new_name
        \ . strpart(l:line, l:cnum + strlen(l:old_name) - 1))

  " Restore cursor position
  cal vimtex#pos#set_cursor(l:save_pos)
endfunction

" }}}1
function! vimtex#cmd#toggle_frac() abort " {{{1
  let l:frac = s:get_frac_cmd()
  if empty(l:frac)
    let l:frac = s:get_frac_inline()
  endif
  if empty(l:frac) | return | endif

  let l:lnum = line('.')
  let l:line = getline(l:lnum)
  call setline(l:lnum,
        \ strpart(l:line, 0, l:frac.col_start)
        \ . l:frac.text_toggled
        \ . strpart(l:line, l:frac.col_end+1))
endfunction

" }}}1
function! vimtex#cmd#toggle_frac_visual() abort " {{{1
  let l:save_reg = getreg('a')
  normal! gv"ay
  let l:selected = substitute(getreg('a'), '\n\s*', ' ', '')
  call setreg('a', l:save_reg)

  let l:frac = s:get_frac_inline_visual(l:selected)
  if empty(l:frac)
    let l:frac = s:get_frac_cmd_visual(l:selected)
  endif

  if empty(l:frac) | return | endif

  let l:save_reg = getreg('a')
  call setreg('a', l:frac.text_toggled)
  normal! gv"ap
  call setreg('a', l:save_reg)
endfunction

" }}}1

function! s:get_frac_cmd() abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  while v:true
    let l:cmd = s:get_cmd('prev')
    if empty(l:cmd) || l:cmd.pos_start.lnum < line('.')
      call vimtex#pos#set_cursor(l:save_pos)
      return {}
    endif

    if l:cmd.name ==# '\frac'
      break
    endif

    call vimtex#pos#set_cursor(vimtex#pos#prev(l:cmd.pos_start))
  endwhile
  call vimtex#pos#set_cursor(l:save_pos)

  let l:frac = {
        \ 'type': 'cmd',
        \ 'col_start': l:cmd.pos_start.cnum - 1,
        \ 'col_end': l:cmd.pos_end.cnum - 1,
        \}

  if len(l:cmd.args) >= 2
    let l:consume = []
    let l:frac.denominator = l:cmd.args[0].text
    let l:frac.numerator = l:cmd.args[1].text
  elseif len(l:cmd.args) == 1
    let l:consume = ['numerator']
    let l:frac.denominator = l:cmd.args[0].text
    let l:frac.numerator = ''
  else
    let l:consume = ['denominator', 'numerator']
    let l:frac.denominator = ''
    let l:frac.numerator = ''
  endif

  " Handle unfinished cases
  let l:line = getline('.')
  let l:pos = l:frac.col_end + 1
  for l:key in l:consume
    let l:part = strpart(l:line, l:frac.col_end + 1)

    let l:blurp = matchstr(l:part, '^\s*{[^}]*}')
    if !empty(l:blurp)
      let l:frac[l:key] = vimtex#util#trim(l:blurp)[1:-2]
      let l:frac.col_end += len(l:blurp)
      continue
    endif

    let l:blurp = matchstr(l:part, '^\s*\w')
    if !empty(l:blurp)
      let l:frac[l:key] = vimtex#util#trim(l:blurp)
      let l:frac.col_end += len(l:blurp)
    endif
  endfor

  " Abort if \frac region does not cover cursor
  if l:frac.col_end < col('.') | return {} | endif

  let l:frac.text = strpart(getline('.'),
        \ l:frac.col_start, l:frac.col_end - l:frac.col_start + 1)

  return s:get_frac_cmd_aux(l:frac)
endfunction

" }}}1
function! s:get_frac_cmd_visual(selected) abort " {{{1
  let l:matches = matchlist(a:selected, '^\s*\\frac\s*{\(.*\)}\s*{\(.*\)}\s*$')
  if empty(l:matches) | return {} | endif

  let l:frac = {
        \ 'type': 'cmd',
        \ 'text': a:selected,
        \ 'denominator': l:matches[1],
        \ 'numerator': l:matches[2],
        \}

  return s:get_frac_cmd_aux(l:frac)
endfunction

" }}}1
function! s:get_frac_cmd_aux(frac) abort " {{{1
  let l:denominator = (a:frac.denominator =~# '^\\\?\w*$')
        \ ? a:frac.denominator
        \ : '(' . a:frac.denominator . ')'

  let l:numerator = (a:frac.numerator =~# '^\\\?\w*$')
        \ ? a:frac.numerator
        \ : '(' . a:frac.numerator . ')'

  let a:frac.text_toggled = l:denominator . '/' . l:numerator

  return a:frac
endfunction

" }}}1
function! s:get_frac_inline() abort " {{{1
  let l:line = getline('.')
  let l:col = col('.') - 1

  let l:pos_after = -1
  let l:pos_before = -1
  while v:true
    let l:pos_before = l:pos_after
    let l:pos_after = match(l:line, '\/', l:pos_after+1)
    if l:pos_after < 0 || l:pos_after >= l:col | break | endif
  endwhile

  if l:pos_after == -1 && l:pos_before == -1
    return {}
  endif

  let l:positions = []
  if l:pos_before > 0
    let l:positions += [l:pos_before]
  endif
  if l:pos_after > 0
    let l:positions += [l:pos_after]
  endif

  for l:pos in l:positions
    let l:frac = {'type': 'inline'}

    "
    " Parse numerator
    "
    let l:before = strpart(l:line, 0, l:pos)
    if l:before =~# ')\s*$'
      let l:pos_before = s:get_inline_limit(l:before, -1) - 1
      let l:parens = strpart(l:before, l:pos_before)
    else
      let l:pos_before = match(l:before, '\s*$')
      let l:parens = ''
    endif

    let l:before = strpart(l:line, 0, l:pos_before)
    let l:atoms = matchstr(l:before, '\(\\(\)\?\zs[^-$(){} ]*$')
    let l:pos_before = l:pos_before - strlen(l:atoms)
    let l:frac.numerator = s:get_inline_trim(l:atoms . l:parens)
    let l:frac.col_start = l:pos_before

    "
    " Parse denominator
    "
    let l:after = strpart(l:line, l:pos+1)
    let l:atoms = l:after =~# '^\s*[^$()} ]*\\)'
          \ ? matchstr(l:after, '^\s*[^$()} ]*\ze\\)')
          \ : matchstr(l:after, '^\s*[^$()} ]*')
    let l:pos_after = l:pos + strlen(l:atoms)
    let l:after = strpart(l:line, l:pos_after+1)
    if l:after =~# '^('
      let l:index = s:get_inline_limit(l:after, 1)
      let l:pos_after = l:pos_after + l:index + 1
      let l:parens = strpart(l:after, 0, l:index+1)
    else
      let l:parens = ''
    endif
    let l:frac.denominator = s:get_inline_trim(l:atoms . l:parens)
    let l:frac.col_end = l:pos_after

    "
    " Combine/Parse inline and frac expressions
    "
    let l:frac.text = strpart(l:line,
          \ l:frac.col_start,
          \ l:frac.col_end - l:frac.col_start + 1)
    let l:frac.text_toggled  = printf('\frac{%s}{%s}',
          \ l:frac.numerator, l:frac.denominator)

    "
    " Accept result if the range contains the cursor column
    "
    if l:col >= l:frac.col_start && l:col <= l:frac.col_end
      return l:frac
    endif
  endfor

  return {}
endfunction

" }}}1
function! s:get_frac_inline_visual(selected) abort " {{{1
  let l:parts = split(a:selected, '/')
  if len(l:parts) != 2 | return {} | endif

  let l:frac = {
        \ 'type': 'inline',
        \ 'text': a:selected,
        \ 'numerator': s:get_inline_trim(l:parts[0]),
        \ 'denominator': s:get_inline_trim(l:parts[1]),
        \}

  let l:frac.text_toggled  = printf('\frac{%s}{%s}',
        \ l:frac.numerator, l:frac.denominator)

  return l:frac
endfunction

" }}}1
function! s:get_inline_limit(str, dir) abort " {{{1
  if a:dir > 0
    let l:open = '('
    let l:string = a:str
  else
    let l:open = ')'
    let l:string = join(reverse(split(a:str, '\zs')), '')
  endif

  let idx = -1
  let depth = 0

  while idx < len(l:string)
    let idx = match(l:string, '[()]', idx + 1)
    if idx < 0
      let idx = len(l:string)
    endif
    if idx >= len(l:string) || l:string[idx] ==# l:open
      let depth += 1
    else
      let depth -= 1
      if depth == 0
        return a:dir < 0 ? len(a:str) - idx : idx
      endif
    endif
  endwhile

  return -1
endfunction

" }}}1
function! s:get_inline_trim(str) abort " {{{1
  let l:str = vimtex#util#trim(a:str)
  return substitute(l:str, '^(\(.*\))$', '\1', '')
endfunction

" }}}1

function! vimtex#cmd#get_next() abort " {{{1
  return s:get_cmd('next')
endfunction

" }}}1
function! vimtex#cmd#get_prev() abort " {{{1
  return s:get_cmd('prev')
endfunction

" }}}1
function! vimtex#cmd#get_current() abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  let l:pos_val_cursor = vimtex#pos#val(l:save_pos)

  let l:depth = 3
  while l:depth > 0
    let l:depth -= 1
    let l:cmd = s:get_cmd('prev')
    if empty(l:cmd) | break | endif

    let l:pos_val = vimtex#pos#val(l:cmd.pos_end)
    if l:pos_val >= l:pos_val_cursor
      call vimtex#pos#set_cursor(l:save_pos)
      return l:cmd
    else
      call vimtex#pos#set_cursor(vimtex#pos#prev(l:cmd.pos_start))
    endif
  endwhile

  call vimtex#pos#set_cursor(l:save_pos)

  return {}
endfunction

" }}}1
function! vimtex#cmd#get_at(...) abort " {{{1
  let l:pos_saved = vimtex#pos#get_cursor()
  call call('vimtex#pos#set_cursor', a:000)
  let l:cmd = vimtex#cmd#get_current()
  call vimtex#pos#set_cursor(l:pos_saved)
  return l:cmd
endfunction

" }}}1

function! s:operator_setup(operator) abort " {{{1
  let s:operator = a:operator
  let &opfunc = s:snr() . 'operator_function'

  " Ask for user input if necessary/relevant
  if s:operator ==# 'change'
    let l:current = vimtex#cmd#get_current()
    if empty(l:current) | return | endif

    let s:operator_cmd_name = substitute(vimtex#echo#input({
          \ 'info' : ['Change command: ', ['VimtexWarning', l:current.name]],
          \}), '^\\', '', '')
  elseif s:operator ==# 'create'
    let s:operator_cmd_name = substitute(vimtex#echo#input({
          \ 'info' : ['Create command: ', ['VimtexWarning', '(empty to cancel)']],
          \}), '^\\', '', '')
  endif
endfunction

" }}}1
function! s:operator_function(_) abort " {{{1
  let l:name = get(s:, 'operator_cmd_name', '')

  execute 'call vimtex#cmd#' . {
        \   'change': 'change(l:name)',
        \   'create': 'create(l:name, 0)',
        \   'delete': 'delete()',
        \   'toggle_star': 'toggle_star()',
        \   'toggle_frac': 'toggle_frac()',
        \ }[s:operator]
endfunction

" }}}1
function! s:snr() abort " {{{1
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" }}}1

function! s:get_cmd(direction) abort " {{{1
  let [lnum, cnum, match] = s:get_cmd_name(a:direction ==# 'next')
  if lnum == 0 | return {} | endif

  let res = {
        \ 'name' : match,
        \ 'text' : '',
        \ 'pos_start' : { 'lnum' : lnum, 'cnum' : cnum },
        \ 'pos_end' : { 'lnum' : lnum, 'cnum' : cnum + strlen(match) - 1 },
        \ 'args' : [],
        \}

  " Environments always start with environment name and allows option
  " afterwords
  if res.name ==# '\begin'
    let arg = s:get_cmd_part('{', res.pos_end)
    if empty(arg) | return res | endif

    call add(res.args, arg)
    let res.pos_end.lnum = arg.close.lnum
    let res.pos_end.cnum = arg.close.cnum
  endif

  " Get overlay specification
  let res.overlay = s:get_cmd_overlay(res.pos_end.lnum, res.pos_end.cnum)
  if !empty(res.overlay)
    let res.pos_end.lnum = res.overlay.close.lnum
    let res.pos_end.cnum = res.overlay.close.cnum
  endif

  " Get options
  let res.opt = s:get_cmd_part('[', res.pos_end)
  if !empty(res.opt)
    let res.pos_end.lnum = res.opt.close.lnum
    let res.pos_end.cnum = res.opt.close.cnum
  endif

  " Get arguments
  let arg = s:get_cmd_part('{', res.pos_end)
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
function! s:get_cmd_name(next) abort " {{{1
  let [l:lnum, l:cnum] = searchpos('\v\\\a+\*?', a:next ? 'nW' : 'cbnW')
  let l:match = matchstr(getline(l:lnum), '^\v\\\a*\*?', l:cnum-1)
  return [l:lnum, l:cnum, l:match]
endfunction

" }}}1
function! s:get_cmd_part(part, start_pos) abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  call vimtex#pos#set_cursor(a:start_pos)
  let l:open = vimtex#delim#get_next('delim_tex', 'open')
  call vimtex#pos#set_cursor(l:save_pos)

  "
  " Ensure that the delimiter
  " 1) exists,
  " 2) is of the right type,
  " 3) and is the next non-whitespace character.
  "
  if empty(l:open)
        \ || l:open.match !=# a:part
        \ || strlen(substitute(
        \        s:text_between(a:start_pos, l:open), '\_s', '', 'g')) != 0
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
function! s:get_cmd_overlay(lnum, cnum) abort " {{{1
  let l:match = matchstr(getline(a:lnum), '^\s*[^>]*>', a:cnum)

  return empty(l:match)
        \ ? {}
        \ : {
        \    'open' : {'lnum' : a:lnum, 'cnum' : a:cnum + 1},
        \    'close' : {'lnum' : a:lnum, 'cnum' : a:cnum + strlen(l:match)},
        \    'text' : l:match
        \   }
endfunction

" }}}1

function! s:text_between(p1, p2, ...) abort " {{{1
  let [l1, c1] = [a:p1.lnum, a:p1.cnum - (a:0 > 0)]
  let [l2, c2] = [a:p2.lnum, a:p2.cnum - (a:0 <= 0)]

  let lines = getline(l1, l2)
  if !empty(lines)
    let lines[0] = strpart(lines[0], c1)
    let lines[-1] = strpart(lines[-1], 0,
          \ l1 == l2 ? c2 - c1 : c2)
  endif
  return join(lines, "\n")
endfunction

" }}}1

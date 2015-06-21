" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#util#init_options() " {{{1
endfunction

" }}}1
function! vimtex#util#init_script() " {{{1
  let s:delimiters_open = [
        \ '(',
        \ '\[',
        \ '\\{',
        \ '\\\Cleft\s*\%([^\\a-zA-Z0-9]\|\\.\|\\\a*\)',
        \ '\\\cbigg\?\((\|\[\|\\{\)',
        \ ]

  let s:delimiters_close = [
        \ ')',
        \ '\]',
        \ '\\}',
        \ '\\\Cright\s*\%([^\\a-zA-Z0-9]\|\\.\|\\\a*\)',
        \ '\\\cbigg\?\()\|\]\|\\}\)',
        \ ]
endfunction

" }}}1
function! vimtex#util#init_buffer() " {{{1
endfunction

" }}}1

function! vimtex#util#execute(exe) " {{{1
  " Execute the given command on the current system.  Wrapper function to make
  " it easier to run on both windows and unix.
  "
  " The command is given in the argument exe, which should be a dictionary with
  " the following entries:
  "
  "   exe.cmd     String          String that contains the command to run
  "   exe.bg      0 or 1          Run in background or not
  "   exe.silent  0 or 1          Show output or not
  "   exe.null    0 or 1          Send output to /dev/null
  "   exe.wd      String          Run command in provided working directory
  "
  " Only exe.cmd is required.
  "

  " Check and parse arguments
  if !has_key(a:exe, 'cmd')
    echoerr 'Error in vimtex#util#execute!'
    echoerr 'Argument error, exe.cmd does not exist!'
    return
  endif
  let bg     = has_key(a:exe, 'bg')     ? a:exe.bg     : 1
  let silent = has_key(a:exe, 'silent') ? a:exe.silent : 1
  let null   = has_key(a:exe, 'null')   ? a:exe.null   : 1
  let system = has_key(a:exe, 'system') ? a:exe.system : 0

  " Change directory if wanted
  if has_key(a:exe, 'wd')
    let pwd = getcwd()
    execute 'lcd ' . fnameescape(a:exe.wd)
  endif

  " Set up command string based on the given system
  let cmd = a:exe.cmd
  if has('win32')
    if null
      let cmd .= ' >nul'
    endif
    if bg
      let cmd = 'start /b "' . cmd . '"'
    endif
  else
    if null
      let cmd .= ' >/dev/null 2>&1'
    endif
    if bg
      let cmd .= ' &'
    endif
  endif

  if has('win32') && &shell !~? 'cmd'
    let savedShell=[&shell, &shellcmdflag, &shellxquote, &shellxescape,
          \ &shellquote, &shellpipe, &shellredir, &shellslash]
    set shell& shellcmdflag& shellxquote& shellxescape&
    set shellquote& shellpipe& shellredir& shellslash&
  endif

  if system
    if silent
      silent call system(cmd)
    else
      call system(cmd)
    endif
  else
    if silent
      silent execute '!' . cmd
    else
      execute '!' . cmd
    endif

    if !has('gui_running')
      redraw!
    endif
  endif

  if has('win32') && exists('savedShell')
    let [&shell, &shellcmdflag, &shellxquote, &shellxescape,
          \ &shellquote, &shellpipe, &shellredir, &shellslash] = savedShell
  endif

  " Return to previous working directory
  if has_key(a:exe, 'wd')
    execute 'lcd ' . fnameescape(pwd)
  endif
endfunction

" }}}1
function! vimtex#util#fnameescape(path) " {{{1
  "
  " In a Windows environment, a path used in "cmd" only needs to be enclosed by
  " double quotes. shellscape() on Windows with "shellslash" set will produce
  " a path enclosed by single quotes, which "cmd" does not recognize and
  " reports an error.  Any path that goes into vimtex#util#execute() should be
  " processed through this function.
  "
  return has('win32') ? '"' . a:path . '"' : shellescape(a:path)
endfunction

" }}}1
function! vimtex#util#get_env(...) " {{{1
  " vimtex#util#get_env([with_pos])
  " Returns:
  " - environment
  "         if with_pos is not given
  " - [environment, lnum_begin, cnum_begin, lnum_end, cnum_end]
  "         if with_pos is nonzero
  let with_pos = a:0 > 0 ? a:1 : 0

  let begin_pat = '\C\\begin\_\s*{[^}]*}\|\\\@<!\\\[\|\\\@<!\\('
  let end_pat = '\C\\end\_\s*{[^}]*}\|\\\@<!\\\]\|\\\@<!\\)'
  let saved_pos = getpos('.')

  " move to the left until on a backslash
  let [bufnum, lnum, cnum, off] = getpos('.')
  let line = getline(lnum)
  while cnum > 1 && line[cnum - 1] !=# '\'
    let cnum -= 1
  endwhile
  call cursor(lnum, cnum)

  " match begin/end pairs but skip comments
  let flags = 'bnW'
  if strpart(getline('.'), col('.') - 1) =~ '^\%(' . begin_pat . '\)'
    let flags .= 'c'
  endif
  let [lnum1, cnum1] = searchpairpos(begin_pat, '', end_pat, flags,
        \ 'vimtex#util#in_comment()')

  let env = ''

  if lnum1
    let line = strpart(getline(lnum1), cnum1 - 1)

    if empty(env)
      let env = matchstr(line, '^\C\\begin\_\s*{\zs[^}]*\ze}')
    endif
    if empty(env)
      let env = matchstr(line, '^\\\[')
    endif
    if empty(env)
      let env = matchstr(line, '^\\(')
    endif
  endif

  if with_pos == 1
    let flags = 'nW'
    if !(lnum1 == lnum && cnum1 == cnum)
      let flags .= 'c'
    endif

    let [lnum2, cnum2] = searchpairpos(begin_pat, '', end_pat, flags,
          \ 'vimtex#util#in_comment()')

    call setpos('.', saved_pos)
    return [env, lnum1, cnum1, lnum2, cnum2]
  else
    call setpos('.', saved_pos)
    return env
  endif
endfunction

" }}}1
function! vimtex#util#get_delim() " {{{1
  " Save position in order to restore before finishing
  let pos_original = getpos('.')

  " Save position for more work later
  let pos_save = getpos('.')

  " Check if the cursor is on top of a closing delimiter
  let close_pats = '\(' . join(s:delimiters_close, '\|') . '\)'
  let lnum = pos_save[1]
  let cnum = pos_save[2]
  let [lnum, cnum] = searchpos(close_pats, 'cbnW', lnum)
  let delim = matchstr(getline(lnum), '^'. close_pats, cnum-1)
  if pos_save[2] <= (cnum + len(delim) - 1)
    let pos_save[1] = lnum
    let pos_save[2] = cnum
    call setpos('.', pos_save)
  endif

  let d1=''
  let d2=''
  let l1=1000000
  let l2=1000000
  let c1=1000000
  let c2=1000000
  for i in range(len(s:delimiters_open))
    call setpos('.', pos_save)
    let open  = s:delimiters_open[i]
    let close = s:delimiters_close[i]
    let flags = 'W'

    " Check if the cursor is on top of an opening delimiter.  If it is not,
    " then we want to include matches at cursor position to match closing
    " delimiters.
    if searchpos(open, 'cn') != pos_save[1:2]
      let flags .= 'c'
    endif

    " Search for closing delimiter
    let pos = searchpairpos(open, '', close, flags, 'vimtex#util#in_comment()')

    " Check if the current is pair is the closest pair
    if pos[0] && pos[0]*1000 + pos[1] < l2*1000 + c2
      let l2=pos[0]
      let c2=pos[1]
      let d2=matchstr(strpart(getline(l2), c2 - 1), close)

      let pos = searchpairpos(open,'',close,'bW', 'vimtex#util#in_comment()')
      let l1=pos[0]
      let c1=pos[1]
      let d1=matchstr(strpart(getline(l1), c1 - 1), open)
    endif
  endfor

  " Restore cursor position and return delimiters and positions
  call setpos('.', pos_original)
  return [d1,l1,c1,d2,l2,c2]
endfunction

" }}}1
function! vimtex#util#get_os() " {{{1
  if has('win32')
    return 'win'
  elseif has('unix')
    if system('uname') =~# 'Darwin'
      return 'mac'
    else
      return 'linux'
    endif
  endif
endfunction

" }}}1
function! vimtex#util#has_syntax(name, ...) " {{{1
  " Usage: vimtex#util#has_syntax(name, [line], [col])
  let line = a:0 >= 1 ? a:1 : line('.')
  let col  = a:0 >= 2 ? a:2 : col('.')
  return 0 <= index(map(synstack(line, col),
        \ 'synIDattr(v:val, "name") == "' . a:name . '"'), 1)
endfunction

" }}}1
function! vimtex#util#in_comment(...) " {{{1
  return synIDattr(synID(line('.'), col('.'), 0), 'name') =~# '^texComment'
endfunction

" }}}1
function! vimtex#util#kpsewhich(file, ...) " {{{1
  let cmd  = 'kpsewhich '
  let cmd .= a:0 > 0 ? a:1 : ''
  let cmd .= ' "' . a:file . '"'
  let out = system(cmd)

  " If kpsewhich has found something, it returns a non-empty string with a
  " newline at the end; otherwise the string is empty
  if len(out)
    " Remove the trailing newline
    let out = fnamemodify(out[:-2], ':p')
  endif

  return out
endfunction

" }}}1
function! vimtex#util#set_default(variable, default) " {{{1
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

" }}}1
function! vimtex#util#set_default_os_specific(variable, default) " {{{1
  if !exists(a:variable)
    let {a:variable} = get(a:default, vimtex#util#get_os(), '')
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2

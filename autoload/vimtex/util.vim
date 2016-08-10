" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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
      if fnamemodify(&shell, ':t') ==# 'tcsh'
        let cmd .= ' >/dev/null |& cat'
      else
        let cmd .= ' >/dev/null 2>&1'
      endif
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
function! vimtex#util#command(cmd) " {{{1
  let l:a = @a
  try
    silent! redir @a
    silent! execute a:cmd
    redir END
  finally
    let l:res = @a
    let @a = l:a
    return split(l:res, "\n")
  endtry
endfunction

" }}}1
function! vimtex#util#shellescape(cmd) " {{{1
  if has('win32')
    "
    " Path used in "cmd" only needs to be enclosed by double quotes.
    " shellescape() on Windows with "shellslash" set will produce a path
    " enclosed by single quotes, which "cmd" does not recognize and reports an
    " error.
    "
    " Blackslashes in path must be escaped to be correctly parsed by the
    " substitute() function.
    "
    return '"' . escape(a:cmd, '\') . '"'
  else
    return shellescape(a:cmd)
  endif
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
function! vimtex#util#in_comment(...) " {{{1
  return call('vimtex#util#in_syntax', ['texComment'] + a:000)
endfunction

" }}}1
function! vimtex#util#in_mathzone(...) " {{{1
  return call('vimtex#util#in_syntax', ['texMathZone'] + a:000)
endfunction

" }}}1
function! vimtex#util#in_syntax(name, ...) " {{{1

  " Usage: vimtex#util#in_syntax(name, [line, col])

  " Get position and correct it if necessary
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  if mode() ==# 'i'
    let l:pos[1] -= 1
  endif
  call map(l:pos, 'max([v:val, 1])')

  " Check syntax at position
  return match(map(synstack(l:pos[0], l:pos[1]),
        \          "synIDattr(v:val, 'name')"),
        \      '^' . a:name) >= 0
endfunction

" }}}1
function! vimtex#util#kpsewhich(file, ...) " {{{1
  execute 'lcd' . fnameescape(b:vimtex.root)
  let cmd  = 'kpsewhich '
  let cmd .= a:0 > 0 ? a:1 : ''
  let cmd .= ' "' . a:file . '"'
  let output = split(system(cmd), '\n')
  lcd -

  if empty(output) | return '' | endif
  let filename = output[0]

  " If path is already absolute, return it
  return filename[0] ==# '/'
        \ ? filename
        \ : simplify(b:vimtex.root . '/' . filename)
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
function! vimtex#util#set_highlight(name, target) " {{{1
  if !hlexists(a:name)
    silent execute 'highlight link' a:name a:target
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2

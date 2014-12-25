" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"
" Utility functions sorted by name
"

function! latex#util#convert_back(line) " {{{1
  "
  " Substitute stuff like '\IeC{\"u}' to corresponding unicode symbols
  "
  let line = a:line
  for [pat, symbol] in s:convert_back_list
    let line = substitute(line, pat, symbol, 'g')
  endfor

  "
  " There might be some missing conversions, which might be fixed by the last
  " substitution
  "
  return substitute(line, '\C\(\\IeC\s*{\)\?\\.\(.\)}', '\1', 'g')
endfunction

let s:convert_back_list = map([
      \ ['\\''A}'        , 'Á'],
      \ ['\\`A}'         , 'À'],
      \ ['\\^A}'         , 'À'],
      \ ['\\¨A}'         , 'Ä'],
      \ ['\\"A}'         , 'Ä'],
      \ ['\\''a}'        , 'á'],
      \ ['\\`a}'         , 'à'],
      \ ['\\^a}'         , 'à'],
      \ ['\\¨a}'         , 'ä'],
      \ ['\\"a}'         , 'ä'],
      \ ['\\''E}'        , 'É'],
      \ ['\\`E}'         , 'È'],
      \ ['\\^E}'         , 'Ê'],
      \ ['\\¨E}'         , 'Ë'],
      \ ['\\"E}'         , 'Ë'],
      \ ['\\''e}'        , 'é'],
      \ ['\\`e}'         , 'è'],
      \ ['\\^e}'         , 'ê'],
      \ ['\\¨e}'         , 'ë'],
      \ ['\\"e}'         , 'ë'],
      \ ['\\''I}'        , 'Í'],
      \ ['\\`I}'         , 'Î'],
      \ ['\\^I}'         , 'Ì'],
      \ ['\\¨I}'         , 'Ï'],
      \ ['\\"I}'         , 'Ï'],
      \ ['\\''i}'        , 'í'],
      \ ['\\`i}'         , 'î'],
      \ ['\\^i}'         , 'ì'],
      \ ['\\¨i}'         , 'ï'],
      \ ['\\"i}'         , 'ï'],
      \ ['\\''{\?\\i }'  , 'í'],
      \ ['\\''O}'        , 'Ó'],
      \ ['\\`O}'         , 'Ò'],
      \ ['\\^O}'         , 'Ô'],
      \ ['\\¨O}'         , 'Ö'],
      \ ['\\"O}'         , 'Ö'],
      \ ['\\''o}'        , 'ó'],
      \ ['\\`o}'         , 'ò'],
      \ ['\\^o}'         , 'ô'],
      \ ['\\¨o}'         , 'ö'],
      \ ['\\"o}'         , 'ö'],
      \ ['\\o }'         , 'ø'],
      \ ['\\''U}'        , 'Ú'],
      \ ['\\`U}'         , 'Ù'],
      \ ['\\^U}'         , 'Û'],
      \ ['\\¨U}'         , 'Ü'],
      \ ['\\"U}'         , 'Ü'],
      \ ['\\''u}'        , 'ú'],
      \ ['\\`u}'         , 'ù'],
      \ ['\\^u}'         , 'û'],
      \ ['\\¨u}'         , 'ü'],
      \ ['\\"u}'         , 'ü'],
      \ ['\\`N}'         , 'Ǹ'],
      \ ['\\\~N}'        , 'Ñ'],
      \ ['\\''n}'        , 'ń'],
      \ ['\\`n}'         , 'ǹ'],
      \ ['\\\~n}'        , 'ñ'],
      \], '[''\C\(\\IeC\s*{\)\?'' . v:val[0], v:val[1]]')

function! latex#util#error_deprecated(variable) " {{{1
  if exists(a:variable)
    echoerr "Deprecation error: " . a:variable
    echoerr "Please red docs for more info!"
    echoerr ":h vim-latex-changelog"
  endif
endfunction

function! latex#util#execute(exe) " {{{1
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
    echoerr "Error in latex#util#execute!"
    echoerr "Argument error, exe.cmd does not exist!"
    return
  endif
  let bg     = has_key(a:exe, 'bg')     ? a:exe.bg     : 1
  let silent = has_key(a:exe, 'silent') ? a:exe.silent : 1
  let null   = has_key(a:exe, 'null')   ? a:exe.null   : 1

  " Change directory if wanted
  if has_key(a:exe, 'wd')
    let pwd = getcwd()
    execute 'lcd ' . fnameescape(a:exe.wd)
  endif

  " Set up command string based on the given system
  if has('win32')
    let cmd = a:exe.cmd
    if null
      let cmd .= ' >nul'
    endif
    if bg
      let cmd = '!start /b "' . cmd . '"'
    else
      let cmd = '!' . cmd
    endif
  else
    let cmd = '!' . a:exe.cmd
    if null
      let cmd .= ' &>/dev/null'
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

  if silent
    silent execute cmd
  else
    execute cmd
  endif

  if has('win32') && exists('savedShell')
    let [&shell, &shellcmdflag, &shellxquote, &shellxescape,
          \ &shellquote, &shellpipe, &shellredir, &shellslash] = savedShell
  endif

  " Return to previous working directory
  if has_key(a:exe, 'wd')
    execute 'lcd ' . fnameescape(pwd)
  endif

  if !has("gui_running")
    redraw!
  endif
endfunction
" }}}1
function! latex#util#get_env(...) " {{{1
  " latex#util#get_env([with_pos])
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
  while cnum > 1 && line[cnum - 1] != '\'
    let cnum -= 1
  endwhile
  call cursor(lnum, cnum)

  " match begin/end pairs but skip comments
  let flags = 'bnW'
  if strpart(getline('.'), col('.') - 1) =~ '^\%(' . begin_pat . '\)'
    let flags .= 'c'
  endif
  let [lnum1, cnum1] = searchpairpos(begin_pat, '', end_pat, flags,
        \ 'latex#util#in_comment()')

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
          \ 'latex#util#in_comment()')

    call setpos('.', saved_pos)
    return [env, lnum1, cnum1, lnum2, cnum2]
  else
    call setpos('.', saved_pos)
    return env
  endif
endfunction

function! latex#util#get_delim() " {{{1
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
    let pos = searchpairpos(open, '', close, flags, 'latex#util#in_comment()')

    " Check if the current is pair is the closest pair
    if pos[0] && pos[0]*1000 + pos[1] < l2*1000 + c2
      let l2=pos[0]
      let c2=pos[1]
      let d2=matchstr(strpart(getline(l2), c2 - 1), close)

      let pos = searchpairpos(open,'',close,'bW', 'latex#util#in_comment()')
      let l1=pos[0]
      let c1=pos[1]
      let d1=matchstr(strpart(getline(l1), c1 - 1), open)
    endif
  endfor

  " Restore cursor position and return delimiters and positions
  call setpos('.', pos_original)
  return [d1,l1,c1,d2,l2,c2]
endfunction

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

function! latex#util#has_syntax(name, ...) " {{{1
  " Usage: latex#util#has_syntax(name, [line], [col])
  let line = a:0 >= 1 ? a:1 : line('.')
  let col  = a:0 >= 2 ? a:2 : col('.')
  return 0 <= index(map(synstack(line, col),
        \ 'synIDattr(v:val, "name") == "' . a:name . '"'), 1)
endfunction

function! latex#util#in_comment(...) " {{{1
  return synIDattr(synID(line('.'), col('.'), 0), "name") =~# '^texComment'
endfunction

function! latex#util#kpsewhich(file, ...) " {{{1
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

function! latex#util#set_default(variable, default) " {{{1
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

function! latex#util#set_vim_executable() " {{{1
  if exists('g:latex_vim_executable') | return | endif

  if has('macunix') || has('gui_mac')
    let g:latex_vim_executable = 'mvim'
  else
    let g:latex_vim_executable = 'vim'
  endif
endfunction

function! latex#util#tex2tree(str) " {{{1
  let tree = []
  let i1 = 0
  let i2 = -1
  let depth = 0
  while i2 < len(a:str)
    let i2 = match(a:str, '[{}]', i2 + 1)
    if i2 < 0
      let i2 = len(a:str)
    endif
    if i2 >= len(a:str) || a:str[i2] == '{'
      if depth == 0
        let item = substitute(strpart(a:str, i1, i2 - i1),
              \ '^\s*\|\s*$', '', 'g')
        if !empty(item)
          call add(tree, item)
        endif
        let i1 = i2 + 1
      endif
      let depth += 1
    else
      let depth -= 1
      if depth == 0
        call add(tree, latex#util#tex2tree(strpart(a:str, i1, i2 - i1)))
        let i1 = i2 + 1
      endif
    endif
  endwhile
  return tree
endfunction

function! latex#util#tree2tex(tree) " {{{1
  if type(a:tree) == type('')
    return a:tree
  else
    return '{' . join(map(a:tree, 'latex#util#tree2tex(v:val)'), '') . '}'
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2

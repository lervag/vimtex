" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#util#command(cmd) abort " {{{1
  return split(execute(a:cmd, 'silent!'), "\n")
endfunction

" }}}1
function! vimtex#util#count(line, pattern) abort " {{{1
  if empty(a:pattern) | return 0 | endif

  let l:count = 1
  while match(a:line, a:pattern, 0, l:count) >= 0
    let l:count += 1
  endwhile

  return l:count - 1
endfunction

" }}}1
function! vimtex#util#count_open(line, re_open, re_close) abort " {{{1
  " Counts the number of unclosed opening patterns in the given line.
  let l:i = match(a:line, a:re_open)
  if l:i < 0 | return 0 | endif

  let l:sum = 0
  let l:imin_last = l:i
  while l:i >= 0
    let l:sum += 1
    let l:i += len(matchstr(a:line, a:re_open, l:i))
    let l:i = match(a:line, a:re_open, l:i)
  endwhile

  let l:i = match(a:line, a:re_close, l:imin_last)
  while l:i >= 0
    let l:sum -= 1
    let l:i += len(matchstr(a:line, a:re_close, l:i))
    let l:i = match(a:line, a:re_close, l:i)
  endwhile

  return max([l:sum, 0])
endfunction

" }}}1
function! vimtex#util#count_close(line, re_open, re_close) abort " {{{1
  " Counts the number of unopened closing patterns in the given line.
  let l:i = match(a:line, a:re_close)
  if l:i < 0 | return 0 | endif

  let l:sum = 0
  while l:i >= 0
    let l:sum += 1
    let l:imax_first = l:i
    let l:i += len(matchstr(a:line, a:re_close, l:i))
    let l:i = match(a:line, a:re_close, l:i)
  endwhile

  let l:i = match(a:line, a:re_open)
  while l:i >= 0 && l:i < l:imax_first
    let l:sum -= 1
    let l:i += len(matchstr(a:line, a:re_open, l:i))
    let l:i = match(a:line, a:re_open, l:i)
  endwhile

  return max([l:sum, 0])
endfunction

" }}}1
function! vimtex#util#flatten(list) abort " {{{1
  let l:result = []

  for l:element in a:list
    if type(l:element) == v:t_list
      call extend(l:result, vimtex#util#flatten(l:element))
    else
      call add(l:result, l:element)
    endif
    unlet l:element
  endfor

  return l:result
endfunction

" }}}1
function! vimtex#util#get_os() abort " {{{1
  if vimtex#util#is_win()
    return 'win'
  elseif has('unix')
    if has('mac') || has('ios') || vimtex#jobs#cached('uname')[0] =~# 'Darwin'
      return 'mac'
    else
      return 'linux'
    endif
  endif
endfunction

" }}}1
function! vimtex#util#is_win() abort " {{{1
  return has('win32') || has('win32unix')
endfunction

" }}}1
function! vimtex#util#win_clean_output(lines) abort " {{{1
  return map(a:lines, {_, x -> substitute(x, '\r$', '', '')})
endfunction

" }}}1
function! vimtex#util#extend_recursive(dict1, dict2, ...) abort " {{{1
  let l:option = a:0 > 0 ? a:1 : 'force'
  if index(['force', 'keep', 'error'], l:option) < 0
    throw 'E475: Invalid argument: ' . l:option
  endif

  for [l:key, l:value] in items(a:dict2)
    if !has_key(a:dict1, l:key)
      let a:dict1[l:key] = l:value
    elseif type(l:value) == v:t_dict
      call vimtex#util#extend_recursive(a:dict1[l:key], l:value, l:option)
    elseif l:option ==# 'error'
      throw 'E737: Key already exists: ' . l:key
    elseif l:option ==# 'force'
      let a:dict1[l:key] = l:value
    endif
    unlet l:value
  endfor

  return a:dict1
endfunction

" }}}1
function! vimtex#util#materialize_property(dict, name) abort " {{{1
  if type(get(a:dict, a:name)) != v:t_func | return | endif

  try
    let a:dict[a:name] = a:dict[a:name]()
  catch
    call vimtex#log#error(
          \ 'Could not materialize property: ' . a:name,
          \ v:exception)
    let a:dict[a:name] = ''
  endtry
endfunction

" }}}1
function! vimtex#util#shellescape(cmd) abort " {{{1
  "
  " Path used in "cmd" only needs to be enclosed by double quotes.
  " shellescape() on Windows with "shellslash" set will produce a path
  " enclosed by single quotes, which "cmd" does not recognize and reports an
  " error.
  "
  if has('win32')
    let l:shellslash = &shellslash
    set noshellslash
    let l:cmd = escape(shellescape(a:cmd), '\')
    let &shellslash = l:shellslash
    return l:cmd
  else
    return escape(shellescape(a:cmd), '\')
  endif
endfunction

" }}}1
function! vimtex#util#tex2unicode(line) abort " {{{1
  " Convert compositions to unicode
  let l:line = a:line
  for [l:pat, l:symbol] in s:tex2unicode_list
    let l:line = substitute(l:line, l:pat, l:symbol, 'g')
  endfor

  " Remove the \IeC macro
  let l:line = substitute(l:line, '\C\\IeC\s*{\s*\([^}]\{-}\)\s*}', '\1', 'g')

  return l:line
endfunction

"
" Define list for converting compositions like \"u to unicode ű
let s:tex2unicode_list = map([
      \ ['\\"A',                'Ä'],
      \ ['\\"E',                'Ë'],
      \ ['\\"I',                'Ï'],
      \ ['\\"O',                'Ö'],
      \ ['\\"U',                'Ü'],
      \ ['\\"Y',                'Ÿ'],
      \ ['\\"\\i',              'ï'],
      \ ['\\"a',                'ä'],
      \ ['\\"e',                'ë'],
      \ ['\\"i',                'ï'],
      \ ['\\"o',                'ö'],
      \ ['\\"u',                'ü'],
      \ ['\\"y',                'ÿ'],
      \ ['\\''A',               'Á'],
      \ ['\\''C',               'Ć'],
      \ ['\\''E',               'É'],
      \ ['\\''G',               'Ǵ'],
      \ ['\\''I',               'Í'],
      \ ['\\''L',               'Ĺ'],
      \ ['\\''N',               'Ń'],
      \ ['\\''O',               'Ó'],
      \ ['\\''R',               'Ŕ'],
      \ ['\\''S',               'Ś'],
      \ ['\\''U',               'Ú'],
      \ ['\\''Y',               'Ý'],
      \ ['\\''Z',               'Ź'],
      \ ['\\''\\i',             'í'],
      \ ['\\''a',               'á'],
      \ ['\\''c',               'ć'],
      \ ['\\''e',               'é'],
      \ ['\\''g',               'ǵ'],
      \ ['\\''i',               'í'],
      \ ['\\''i',               'í'],
      \ ['\\''l',               'ĺ'],
      \ ['\\''n',               'ń'],
      \ ['\\''o',               'ó'],
      \ ['\\''r',               'ŕ'],
      \ ['\\''s',               'ś'],
      \ ['\\''u',               'ú'],
      \ ['\\''y',               'ý'],
      \ ['\\''z',               'ź'],
      \ ['\\=A',                'Ā'],
      \ ['\\=E',                'Ē'],
      \ ['\\=I',                'Ī'],
      \ ['\\=O',                'Ō'],
      \ ['\\=U',                'Ū'],
      \ ['\\=a',                'ā'],
      \ ['\\=e',                'ē'],
      \ ['\\=i',                'ī'],
      \ ['\\=o',                'ō'],
      \ ['\\=u',                'ū'],
      \ ['\\HO',                'Ő'],
      \ ['\\HU',                'Ű'],
      \ ['\\Ho',                'ő'],
      \ ['\\Hu',                'ű'],
      \ ['\\\%(\~\|tilde\)A',   'Ã'],
      \ ['\\\%(\~\|tilde\)E',   'Ẽ'],
      \ ['\\\%(\~\|tilde\)I',   'Ĩ'],
      \ ['\\\%(\~\|tilde\)N',   'Ñ'],
      \ ['\\\%(\~\|tilde\)O',   'Õ'],
      \ ['\\\%(\~\|tilde\)U',   'Ũ'],
      \ ['\\\%(\~\|tilde\)Y',   'Ỹ'],
      \ ['\\\%(\~\|tilde\)\\i', 'ĩ'],
      \ ['\\\%(\~\|tilde\)a',   'ã'],
      \ ['\\\%(\~\|tilde\)e',   'ẽ'],
      \ ['\\\%(\~\|tilde\)i',   'ĩ'],
      \ ['\\\%(\~\|tilde\)n',   'ñ'],
      \ ['\\\%(\~\|tilde\)o',   'õ'],
      \ ['\\\%(\~\|tilde\)u',   'ũ'],
      \ ['\\\%(\~\|tilde\)y',   'ỹ'],
      \ ['\\\.A',               'Ȧ'],
      \ ['\\\.C',               'Ċ'],
      \ ['\\\.E',               'Ė'],
      \ ['\\\.G',               'Ġ'],
      \ ['\\\.I',               'İ'],
      \ ['\\\.O',               'Ȯ'],
      \ ['\\\.Z',               'Ż'],
      \ ['\\\.\\i',             'į'],
      \ ['\\\.a',               'ȧ'],
      \ ['\\\.c',               'ċ'],
      \ ['\\\.e',               'ė'],
      \ ['\\\.g',               'ġ'],
      \ ['\\\.i',               'į'],
      \ ['\\\.o',               'ȯ'],
      \ ['\\\.z',               'ż'],
      \ ['\\^A',                'Â'],
      \ ['\\^C',                'Ĉ'],
      \ ['\\^E',                'Ê'],
      \ ['\\^G',                'Ĝ'],
      \ ['\\^I',                'Î'],
      \ ['\\^L',                'Ľ'],
      \ ['\\^O',                'Ô'],
      \ ['\\^S',                'Ŝ'],
      \ ['\\^U',                'Û'],
      \ ['\\^W',                'Ŵ'],
      \ ['\\^Y',                'Ŷ'],
      \ ['\\^\\i',              'î'],
      \ ['\\^a',                'â'],
      \ ['\\^c',                'ĉ'],
      \ ['\\^e',                'ê'],
      \ ['\\^g',                'ĝ'],
      \ ['\\^h',                'ĥ'],
      \ ['\\^i',                'î'],
      \ ['\\^l',                'ľ'],
      \ ['\\^o',                'ô'],
      \ ['\\^s',                'ŝ'],
      \ ['\\^u',                'û'],
      \ ['\\^w',                'ŵ'],
      \ ['\\^y',                'ŷ'],
      \ ['\\`A',                'À'],
      \ ['\\`E',                'È'],
      \ ['\\`I',                'Ì'],
      \ ['\\`N',                'Ǹ'],
      \ ['\\`O',                'Ò'],
      \ ['\\`U',                'Ù'],
      \ ['\\`Y',                'Ỳ'],
      \ ['\\`\\i',              'ì'],
      \ ['\\`a',                'à'],
      \ ['\\`e',                'è'],
      \ ['\\`i',                'ì'],
      \ ['\\`n',                'ǹ'],
      \ ['\\`o',                'ò'],
      \ ['\\`y',                'ỳ'],
      \ ['\\cC',                'Ç'],
      \ ['\\cE',                'Ȩ'],
      \ ['\\cG',                'Ģ'],
      \ ['\\cK',                'Ķ'],
      \ ['\\cL',                'Ļ'],
      \ ['\\cN',                'Ņ'],
      \ ['\\cR',                'Ŗ'],
      \ ['\\cS',                'Ş'],
      \ ['\\cT',                'Ţ'],
      \ ['\\cc',                'ç'],
      \ ['\\ce',                'ȩ'],
      \ ['\\cg',                'ģ'],
      \ ['\\ck',                'ķ'],
      \ ['\\cl',                'ļ'],
      \ ['\\cn',                'ņ'],
      \ ['\\cr',                'ŗ'],
      \ ['\\cs',                'ş'],
      \ ['\\ct',                'ţ'],
      \ ['\\kA',                'Ą'],
      \ ['\\kE',                'Ę'],
      \ ['\\kI',                'Į'],
      \ ['\\kO',                'Ǫ'],
      \ ['\\kU',                'Ų'],
      \ ['\\ka',                'ą'],
      \ ['\\ke',                'ę'],
      \ ['\\ki',                'į'],
      \ ['\\ko',                'ǫ'],
      \ ['\\ks',                'ȿ'],
      \ ['\\ku',                'ų'],
      \ ['\\o',                 'ø'],
      \ ['\\rA',                'Å'],
      \ ['\\rU',                'Ů'],
      \ ['\\ra',                'å'],
      \ ['\\ru',                'ů'],
      \ ['\\uA',                'Ă'],
      \ ['\\uE',                'Ĕ'],
      \ ['\\uG',                'Ğ'],
      \ ['\\uI',                'Ĭ'],
      \ ['\\uO',                'Ŏ'],
      \ ['\\uU',                'Ŭ'],
      \ ['\\u\\i',              'ĭ'],
      \ ['\\ua',                'ă'],
      \ ['\\ue',                'ĕ'],
      \ ['\\ug',                'ğ'],
      \ ['\\ui',                'ĭ'],
      \ ['\\uo',                'ŏ'],
      \ ['\\uu',                'ŭ'],
      \ ['\\vA',                'Ǎ'],
      \ ['\\vC',                'Č'],
      \ ['\\vD',                'Ď'],
      \ ['\\vE',                'Ě'],
      \ ['\\vG',                'Ǧ'],
      \ ['\\vH',                'Ȟ'],
      \ ['\\vI',                'Ǐ'],
      \ ['\\vJ',                'ǰ'],
      \ ['\\vK',                'Ǩ'],
      \ ['\\vL',                'Ľ'],
      \ ['\\vN',                'Ň'],
      \ ['\\vO',                'Ǒ'],
      \ ['\\vR',                'Ř'],
      \ ['\\vS',                'Š'],
      \ ['\\vT',                'Ť'],
      \ ['\\vU',                'Ǔ'],
      \ ['\\vZ',                'Ž'],
      \ ['\\va',                'ǎ'],
      \ ['\\vc',                'č'],
      \ ['\\vd',                'ď'],
      \ ['\\ve',                'ě'],
      \ ['\\vg',                'ǧ'],
      \ ['\\vh',                'ȟ'],
      \ ['\\vi',                'ǐ'],
      \ ['\\vk',                'ǩ'],
      \ ['\\vl',                'ľ'],
      \ ['\\vn',                'ň'],
      \ ['\\vo',                'ǒ'],
      \ ['\\vr',                'ř'],
      \ ['\\vs',                'š'],
      \ ['\\vt',                'ť'],
      \ ['\\vu',                'ǔ'],
      \ ['\\vz',                'ž'],
      \ ['\\¨A',                'Ä'],
      \ ['\\¨E',                'Ë'],
      \ ['\\¨I',                'Ï'],
      \ ['\\¨O',                'Ö'],
      \ ['\\¨U',                'Ü'],
      \ ['\\¨a',                'ä'],
      \ ['\\¨e',                'ë'],
      \ ['\\¨i',                'ï'],
      \ ['\\¨o',                'ö'],
      \ ['\\¨u',                'ü'],
      \], {_, x -> ['\C' . x[0], x[1]]})

" }}}1
function! vimtex#util#tex2tree(str) abort " {{{1
  let tree = []
  let i1 = 0
  let i2 = -1
  let depth = 0
  while i2 < len(a:str)
    let i2 = match(a:str, '[{}]', i2 + 1)
    if i2 < 0
      let i2 = len(a:str)
    endif
    if i2 >= len(a:str) || a:str[i2] ==# '{'
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
        call add(tree, vimtex#util#tex2tree(strpart(a:str, i1, i2 - i1)))
        let i1 = i2 + 1
      endif
    endif
  endwhile
  return tree
endfunction

" }}}1
function! vimtex#util#texsplit(str) abort " {{{1
  " Splits "str", but respect TeX groups ({...})
  if empty(a:str) | return [] | endif

  let parts = []
  let i1 = 0
  let i2 = -1
  let depth = 0

  while v:true
    let i2 = match(a:str, '[,{}]', i2 + 1)

    if i2 < 0
      call add(parts, strpart(a:str, i1))
      break
    endif

    if a:str[i2] ==# '{'
      let depth += 1
    elseif a:str[i2] ==# '}'
      let depth -= 1
    elseif depth == 0
      call add(parts, strpart(a:str, i1, i2 - i1))
      let i1 = i2 + 1
    endif
  endwhile

  return parts
endfunction

" }}}1
function! vimtex#util#trim(str) abort " {{{1
  if exists('*trim') | return trim(a:str) | endif

  let l:str = substitute(a:str, '^\s*', '', '')
  let l:str = substitute(l:str, '\s*$', '', '')

  return l:str
endfunction

" }}}1
function! vimtex#util#uniq_unsorted(list) abort " {{{1
  if len(a:list) <= 1 | return deepcopy(a:list) | endif

  let l:visited = {}
  let l:result = []
  for l:x in a:list
    let l:key = string(l:x)
    if !has_key(l:visited, l:key)
      let l:visited[l:key] = 1
      call add(l:result, l:x)
    endif
  endfor

  return l:result
endfunction

" }}}1
function! vimtex#util#undostore() abort " {{{1
  " This is a hack to make undo restore the correct position
  if mode() !=# 'i'
    normal! ix
    normal! x
  endif
endfunction

" }}}1
function! vimtex#util#www(url) abort " {{{1
  let l:os = vimtex#util#get_os()

  silent execute (l:os ==# 'linux'
        \         ? '!xdg-open'
        \         : (l:os ==# 'mac'
        \            ? '!open'
        \            : '!start'))
        \ . ' ' . a:url
        \ . (l:os ==# 'win' ? '' : ' &')
endfunction

" }}}1

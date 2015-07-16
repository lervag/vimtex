" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#complete#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_complete_enabled', 1)
  if !g:vimtex_complete_enabled | return | endif

  call vimtex#util#set_default('g:vimtex_complete_close_braces', 0)
  call vimtex#util#set_default('g:vimtex_complete_recursive_bib', 0)
  call vimtex#util#set_default('g:vimtex_complete_patterns',
        \ {
        \ 'ref' : '\C\\v\?\(auto\|eq\|page\|[cC]\|labelc\)\?ref\*\?\_\s*{[^{}]*',
        \ 'bib' : '\C\\\a*cite\a*\*\?\(\[[^\]]*\]\)*\_\s*{[^{}]*',
        \ })
endfunction

" }}}1
function! vimtex#complete#init_script() " {{{1
  if !g:vimtex_complete_enabled | return | endif

  " Check if bibtex is available
  let s:bibtex = 1
  if !executable('bibtex')
    call vimtex#echo#warning('vimtex warning')
    call vimtex#echo#warning('  bibtex completion is not available!',
          \ 'None')
    call vimtex#echo#warning('  bibtex is not executable', 'None')
    let s:bibtex = 0
  endif

  " Check if kpsewhich is required and available
  if s:bibtex && g:vimtex_complete_recursive_bib && !executable('kpsewhich')
    call vimtex#echo#warning('vimtex warning')
    call vimtex#echo#warning('  bibtex completion is not available!',
          \ 'None')
    call vimtex#echo#warning('  recursive bib search requires kpsewhich',
          \ 'None')
    call vimtex#echo#warning('  kpsewhich is not executable', 'None')
    let s:bibtex = 0
  endif

  " Define auxiliary variable for completion
  let s:completion_type = ''
  let s:type_length = 0

  " Define some regular expressions
  let s:nocomment = '\v%(%(\\@<!%(\\\\)*)@<=\%.*)@<!'
  let s:re_bibs  = '''' . s:nocomment
  let s:re_bibs .= '\\(bibliography|add(bibresource|globalbib|sectionbib))'
  let s:re_bibs .= '\m\s*{\zs[^}]\+\ze}'''
  let s:re_incsearch  = '''' . s:nocomment
  let s:re_incsearch .= '\\%(input|include)'
  let s:re_incsearch .= '\m\s*{\zs[^}]\+\ze}'''

  "
  " s:label_cache is a dictionary that maps filenames to tuples of the form
  "
  "   [time, labels, inputs]
  "
  " where time is modification time of the cache entry, labels is a list like
  " returned by extract_labels, and inputs is a list like returned by
  " s:extract_inputs.
  "
  let s:label_cache = {}

  "
  " Define list for converting stuff like '\IeC{\"u}' to corresponding unicode
  " symbols (with s:tex2unicode()).
  "
  let s:tex2unicode_list = map([
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
        \ ['\\\~a}'        , 'ã'],
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
endfunction

" The variable s:bstfile must be defined in script level in order to expand
" into the script file name.
let s:bstfile = expand('<sfile>:p:h') . '/vimcomplete'

" }}}1
function! vimtex#complete#init_buffer() " {{{1
  if !g:vimtex_complete_enabled | return | endif

  setlocal omnifunc=vimtex#complete#omnifunc
endfunction

" }}}1

function! vimtex#complete#omnifunc(findstart, base) " {{{1
  if a:findstart
    "
    " First call:  Find start of text to be completed
    "
    " Note: g:vimtex_complete_patterns is a dictionary where the keys are the
    " types of completion and the values are the patterns that must match for
    " the given type.  Currently, it completes labels (e.g. \ref{...), bibtex
    " entries (e.g. \cite{...) and commands (e.g. \...).
    "
    let pos  = col('.') - 1
    let line = getline('.')[:pos-1]
    for [type, pattern] in items(g:vimtex_complete_patterns)
      if line =~ pattern . '$'
        let s:completion_type = type
        while pos > 0
          if line[pos - 1] =~# '{\|,' || line[pos-2:pos-1] ==# ', '
            return pos
          else
            let pos -= 1
          endif
        endwhile
        return -2
      endif
    endfor
    return -3
  else
    "
    " Second call:  Find list of matches
    "
    if s:completion_type ==# 'ref'
      return vimtex#complete#labels(a:base)
    elseif s:completion_type ==# 'bib' && s:bibtex
      return vimtex#complete#bibtex(a:base)
    endif
  endif
endfunction

" }}}1
function! vimtex#complete#labels(regex) " {{{1
  let labels = s:labels_get(b:vimtex.aux())
  let matches = filter(copy(labels), 'v:val[0] =~ ''' . a:regex . '''')

  " Try to match label and number
  if empty(matches)
    let regex_split = split(a:regex)
    if len(regex_split) > 1
      let base = regex_split[0]
      let number = escape(join(regex_split[1:], ' '), '.')
      let matches = filter(copy(labels),
            \ 'v:val[0] =~ ''' . base   . ''' &&' .
            \ 'v:val[1] =~ ''' . number . '''')
    endif
  endif

  " Try to match number
  if empty(matches)
    let matches = filter(copy(labels), 'v:val[1] =~ ''' . a:regex . '''')
  endif

  let suggestions = []
  for m in matches
    let entry = {
          \ 'word': m[0],
          \ 'menu': printf('%7s [p. %s]', '('.m[1].')', m[2])
          \ }
    if g:vimtex_complete_close_braces && !s:next_chars_match('^\s*[,}]')
      let entry = copy(entry)
      let entry.abbr = entry.word
      let entry.word = entry.word . '}'
    endif
    call add(suggestions, entry)
  endfor

  return suggestions
endfunction

" }}}1
function! vimtex#complete#bibtex(regexp) " {{{1
  let res = []

  let s:type_length = 4
  for m in s:bibtex_search(a:regexp)
    let type = m['type']   ==# '' ? '[-]' : '[' . m['type']   . '] '
    let auth = m['author'] ==# '' ? ''    :       m['author'][:20] . ' '
    let year = m['year']   ==# '' ? ''    : '(' . m['year']   . ')'

    " Align the type entry and fix minor annoyance in author list
    let type = printf('%-' . s:type_length . 's', type)
    let auth = substitute(auth, '\~', ' ', 'g')
    let auth = substitute(auth, ',.*\ze', ' et al. ', '')

    let w = {
          \ 'word': m['key'],
          \ 'abbr': type . auth . year,
          \ 'menu': m['title']
          \ }

    " Close braces if desired
    if g:vimtex_complete_close_braces && !s:next_chars_match('^\s*[,}]')
      let w.word = w.word . '}'
    endif

    call add(res, w)
  endfor

  return res
endfunction

" }}}1

"
" Bibtex completion
"
function! s:bibtex_search(regexp) " {{{1
  let res = []

  " The bibtex completion seems to require that we are in the project root
  let l:save_pwd = getcwd()
  execute 'lcd ' . fnameescape(b:vimtex.root)

  " Find data from external bib files
  let bibfiles = join(s:bibtex_find_bibs(), ',')
  if bibfiles !=# ''
    " Define temporary files
    let tmp = {
          \ 'aux' : 'tmpfile.aux',
          \ 'bbl' : 'tmpfile.bbl',
          \ 'blg' : 'tmpfile.blg',
          \ }

    " Write temporary aux file
    call writefile([
          \ '\citation{*}',
          \ '\bibstyle{' . s:bstfile . '}',
          \ '\bibdata{' . bibfiles . '}',
          \ ], tmp.aux)

    " Create the temporary bbl file
    let exe = {}
    let exe.cmd = 'bibtex -terse ' . tmp.aux
    let exe.bg = 0
    let exe.system = 1
    call vimtex#util#execute(exe)

    " Parse temporary bbl file
    let lines = map(readfile(tmp.bbl), 's:tex2unicode(v:val)')
    let lines = split(substitute(join(lines, "\n"),
          \ '\n\n\@!\(\s\=\)\s*\|{\|}', '\1', 'g'), "\n")

    for line in filter(lines, 'v:val =~ a:regexp')
      let matches = matchlist(line,
            \ '^\(.*\)||\(.*\)||\(.*\)||\(.*\)||\(.*\)')
      if !empty(matches) && !empty(matches[1])
        let s:type_length = max([s:type_length, len(matches[2]) + 3])
        call add(res, {
              \ 'key':    matches[1],
              \ 'type':   matches[2],
              \ 'author': matches[3],
              \ 'year':   matches[4],
              \ 'title':  matches[5],
              \ })
      endif
    endfor

    " Clean up
    call delete(tmp.aux)
    call delete(tmp.bbl)
    call delete(tmp.blg)
  endif

  " Return to previous working directory
  execute 'lcd ' . fnameescape(l:save_pwd)

  " Find data from 'thebibliography' environments
  let lines = readfile(b:vimtex.tex)
  if match(lines, '\C\\begin{thebibliography}') >= 0
    for line in filter(filter(lines, 'v:val =~# ''\C\\bibitem'''),
          \ 'v:val =~ a:regexp')
      let match = matchlist(line, '\\bibitem{\([^}]*\)')[1]
      call add(res, {
            \ 'key': match,
            \ 'type': '',
            \ 'author': '',
            \ 'year': '',
            \ 'title': match,
            \ })
    endfor
  endif

  return res
endfunction

" }}}1
function! s:bibtex_find_bibs(...) " {{{1
  if a:0
    let file = a:1
  else
    let file = b:vimtex.tex
  endif

  if !filereadable(file)
    return []
  endif
  let lines = readfile(file)
  let bibfiles = []

  "
  " Search for added bibliographies
  " * Parse commands such as \bibliography{file1,file2.bib,...}
  " * This also removes the .bib extensions
  "
  for entry in map(filter(copy(lines),
          \ 'v:val =~ ' . s:re_bibs),
        \ 'matchstr(v:val, ' . s:re_bibs . ')')
    let bibfiles += map(split(entry, ','), 'fnamemodify(v:val, '':r'')')
  endfor

  "
  " Recursively search included files
  "
  if g:vimtex_complete_recursive_bib
    for entry in map(filter(lines,
          \ 'v:val =~ ' . s:re_incsearch),
          \ 'matchstr(v:val, ' . s:re_incsearch . ')')
      let bibfiles += s:bibtex_find_bibs(vimtex#util#kpsewhich(entry))
    endfor
  endif

  return bibfiles
endfunction

" }}}1

"
" Label completion
"
function! s:labels_get(file) " {{{1
  "
  " s:labels_get compares modification time of each entry in the label cache
  " and updates it if necessary.  During traversal of the label cache, all
  " current labels are collected and returned.
  "
  if !filereadable(a:file)
    return []
  endif

  " Open file in temporary split window for label extraction.
  if !has_key(s:label_cache , a:file)
        \ || s:label_cache[a:file][0] != getftime(a:file)
    let s:label_cache[a:file] = [
          \ getftime(a:file),
          \ s:labels_extract(a:file),
          \ s:labels_extract_inputs(a:file),
          \ ]
  endif

  " We need to create a copy of s:label_cache[fid][1], otherwise all inputs'
  " labels would be added to the current file's label cache upon each
  " completion call, leading to duplicates/triplicates/etc. and decreased
  " performance.  Also, because we don't anything with the list besides
  " matching copies, we can get away with a shallow copy for now.
  let labels = copy(s:label_cache[a:file][1])

  for input in s:label_cache[a:file][2]
    let labels += s:labels_get(input)
  endfor

  return labels
endfunction

" }}}1
function! s:labels_extract(file) " {{{1
  "
  " Searches file for commands of the form
  "
  "   \newlabel{name}{{number}{page}.*}.*
  "
  " or
  "
  "   \newlabel{name}{{text {number}}{page}.*}.*
  "
  " and returns a list of [name, number, page] tuples.
  "
  let matches = []
  let lines = readfile(a:file)
  let lines = filter(lines, 'v:val =~# ''\\newlabel{''')
  let lines = filter(lines, 'v:val !~# ''@cref''')
  let lines = filter(lines, 'v:val !~# ''sub@''')
  let lines = filter(lines, 'v:val !~# ''tocindent-\?[0-9]''')
  let lines = map(lines, 's:tex2unicode(v:val)')
  for line in lines
    let tree = s:tex2tree(line)[1:]
    let name = remove(tree, 0)[0]
    if type(tree[0]) == type([]) && !empty(tree[0])
      let number = s:labels_parse_number(tree[0][0])
      let page = tree[0][1][0]
      call add(matches, [name, number, page])
    endif
  endfor
  return matches
endfunction

" }}}1
function! s:labels_extract_inputs(file) " {{{1
  let matches = []
  let root = fnamemodify(a:file, ':p:h') . '/'
  for input in filter(readfile(a:file), 'v:val =~# ''\\@input{''')
    let input = matchstr(input, '{\zs.*\ze}')
    let input = substitute(input, '"', '', 'g')
    let input = root . input
    call add(matches, input)
  endfor
  return matches
endfunction

" }}}1
function! s:labels_parse_number(num_tree) " {{{1
  if len(a:num_tree) == 0
    return '-'
  elseif len(a:num_tree) == 1
    if type(a:num_tree) == type([])
      return s:labels_parse_number(a:num_tree[0])
    else
      let l:num = str2nr(a:num_tree[0])
      return l:num > 0 ? l:num : '-'
    endif
  else
    return s:labels_parse_number(a:num_tree[1])
  endif
endfunction

" }}}1

"
" Utility functions
"
function! s:next_chars_match(regex) " {{{1
  return strpart(getline('.'), col('.') - 1) =~ a:regex
endfunction

" }}}1
function! s:tex2tree(str) " {{{1
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
        call add(tree, s:tex2tree(strpart(a:str, i1, i2 - i1)))
        let i1 = i2 + 1
      endif
    endif
  endwhile
  return tree
endfunction

" }}}1
function! s:tex2unicode(line) " {{{1
  "
  " Substitute stuff like '\IeC{\"u}' to corresponding unicode symbols
  "
  let line = a:line
  for [pat, symbol] in s:tex2unicode_list
    let line = substitute(line, pat, symbol, 'g')
  endfor

  "
  " There might be some missing conversions, which might be fixed by the last
  " substitution
  "
  return substitute(line, '\C\(\\IeC\s*{\)\?\\.\(.\)}', '\1', 'g')
endfunction

" }}}1

" vim: fdm=marker sw=2

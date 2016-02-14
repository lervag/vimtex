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
  call vimtex#util#set_default('g:vimtex_complete_img_use_tail', 0)
endfunction

" }}}1
function! vimtex#complete#init_script() " {{{1
  if !g:vimtex_complete_enabled | return | endif

  let s:completers = [s:bib, s:ref, s:img, s:inc, s:glc]
endfunction

" }}}1
function! vimtex#complete#init_buffer() " {{{1
  if !g:vimtex_complete_enabled | return | endif

  for l:completer in s:completers
    if has_key(l:completer, 'init')
      call l:completer.init()
    endif
  endfor

  setlocal omnifunc=vimtex#complete#omnifunc
endfunction

" }}}1

function! vimtex#complete#omnifunc(findstart, base) " {{{1
  if a:findstart
    let pos  = col('.') - 1
    let line = getline('.')[:pos-1]
    for l:completer in s:completers
      if !get(l:completer, 'enabled', 0) | return -3 | endif

      if line =~# l:completer.pattern . '$'
        let s:completer = l:completer
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
    return s:close_braces(s:completer.complete(a:base))
  endif
endfunction

" }}}1

"
" Completers
"
" {{{1 Bibtex

let s:bib = {
      \ 'pattern' : '\v\\\a*cite\a*%(\s*\[[^]]*\])?\s*\{[^{}]*',
      \ 'enabled' : 1,
      \ 'bibs' : '''\v%(%(\\@<!%(\\\\)*)@<=\%.*)@<!'
      \          . '\\(bibliography|add(bibresource|globalbib|sectionbib))'
      \          . '\m\s*{\zs[^}]\+\ze}''',
      \ 'type_length' : 0,
      \ 'bstfile' :  expand('<sfile>:p:h') . '/vimcomplete',
      \}

function! s:bib.init() dict " {{{2
  " Check if bibtex is executable
  if !executable('bibtex')
    let self.enabled = 0
    call vimtex#echo#warning('vimtex warning')
    call vimtex#echo#warning('  bibtex completion is not available!', 'None')
    call vimtex#echo#warning('  bibtex is not executable', 'None')
    return
  endif

  " Check if kpsewhich is required and available
  if g:vimtex_complete_recursive_bib && !executable('kpsewhich')
    let self.enabled = 0
    call vimtex#echo#warning('vimtex warning')
    call vimtex#echo#warning('  bibtex completion is not available!', 'None')
    call vimtex#echo#warning('  recursive bib search requires kpsewhich', 'None')
    call vimtex#echo#warning('  kpsewhich is not executable', 'None')
  endif
endfunction

function! s:bib.complete(regexp) dict " {{{2
  let self.candidates = []

  let self.type_length = 4
  for m in self.search(a:regexp)
    let type = m['type']   ==# '' ? '[-]' : '[' . m['type']   . '] '
    let auth = m['author'] ==# '' ? ''    :       m['author'][:20] . ' '
    let year = m['year']   ==# '' ? ''    : '(' . m['year']   . ')'

    " Align the type entry and fix minor annoyance in author list
    let type = printf('%-' . self.type_length . 's', type)
    let auth = substitute(auth, '\~', ' ', 'g')
    let auth = substitute(auth, ',.*\ze', ' et al. ', '')

    call add(self.candidates, {
          \ 'word': m['key'],
          \ 'abbr': type . auth . year,
          \ 'menu': m['title']
          \ })
  endfor

  return self.candidates
endfunction

function! s:bib.search(regexp) dict " {{{2
  let res = []

  " The bibtex completion seems to require that we are in the project root
  let l:save_pwd = getcwd()
  execute 'lcd ' . fnameescape(b:vimtex.root)

  " Find data from external bib files
  let bibfiles = join(self.find_bibs(), ',')
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
          \ '\bibstyle{' . self.bstfile . '}',
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
        let self.type_length = max([self.type_length, len(matches[2]) + 3])
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

function! s:bib.find_bibs() dict " {{{2
  "
  " Search for added bibliographies
  " * Parse commands such as \bibliography{file1,file2.bib,...}
  " * This also removes the .bib extensions
  "
  "
  let l:lines = vimtex#parser#tex(b:vimtex.tex, 0,
        \ g:vimtex_complete_recursive_bib)

  let l:bibfiles = []
  for l:entry in map(filter(l:lines, 'v:val =~ ' . self.bibs),
        \            'matchstr(v:val, ' . self.bibs . ')')
    let l:bibfiles += map(split(l:entry, ','), 'fnamemodify(v:val, '':r'')')
  endfor

  return l:bibfiles
endfunction

" }}}1
" {{{1 Labels

let s:ref = {
      \ 'pattern' : '\v\\v?%(auto|eq|page|[cC]|labelc)?ref\s*\{[^{}]*',
      \ 'enabled' : 1,
      \}

function! s:ref.complete(regex) dict " {{{2
  let self.candidates = []

  for m in self.get_matches(a:regex)
    call add(self.candidates, {
          \ 'word' : m[0],
          \ 'abbr' : m[0],
          \ 'menu' : printf('%7s [p. %s]', '('.m[1].')', m[2])
          \ })
  endfor

  return self.candidates
endfunction

function! s:ref.get_matches(regex) dict " {{{2
  call self.parse_labels(b:vimtex.aux())

  " Match label
  let self.matches = filter(copy(self.labels), 'v:val[0] =~ ''' . a:regex . '''')

  " Match label and number
  if empty(self.matches)
    let l:regex_split = split(a:regex)
    if len(l:regex_split) > 1
      let l:base = l:regex_split[0]
      let l:number = escape(join(l:regex_split[1:], ' '), '.')
      let self.matches = filter(copy(self.labels),
            \ 'v:val[0] =~ ''' . l:base   . ''' &&' .
            \ 'v:val[1] =~ ''' . l:number . '''')
    endif
  endif

  " Match number
  if empty(self.matches)
    let self.matches = filter(copy(self.labels), 'v:val[1] =~ ''' . a:regex . '''')
  endif

  return self.matches
endfunction

function! s:ref.parse_labels(file) dict " {{{2
  "
  " Searches aux files recursively for commands of the form
  "
  "   \newlabel{name}{{number}{page}.*}.*
  "   \newlabel{name}{{text {number}}{page}.*}.*
  "
  " Returns a list of [name, number, page] tuples.
  "
  if !filereadable(a:file)
    let self.labels = []
    return []
  endif

  if get(self, 'labels_created', 0) != getftime(a:file)
    let self.labels_created = getftime(a:file)
    let self.labels = []
    let lines = vimtex#parser#aux(a:file)
    let lines = filter(lines, 'v:val =~# ''\\newlabel{''')
    let lines = filter(lines, 'v:val !~# ''@cref''')
    let lines = filter(lines, 'v:val !~# ''sub@''')
    let lines = filter(lines, 'v:val !~# ''tocindent-\?[0-9]''')
    for line in lines
      let line = s:tex2unicode(line)
      let tree = s:tex2tree(line)[1:]
      let name = remove(tree, 0)[0]
      if type(tree[0]) == type([]) && !empty(tree[0])
        let number = self.parse_number(tree[0][0])
        let page = tree[0][1][0]
        call add(self.labels, [name, number, page])
      endif
    endfor
  endif

  return self.labels
endfunction

function! s:ref.parse_number(num_tree) dict " {{{2
  if type(a:num_tree) == type([])
    if len(a:num_tree) == 0
      return '-'
    else
      let l:index = len(a:num_tree) == 1 ? 0 : 1
      return self.parse_number(a:num_tree[l:index])
    endif
  else
    return str2nr(a:num_tree) > 0 ? a:num_tree : '-'
  endif
endfunction

" }}}1
" {{{1 Filenames (\includegraphics)

let s:img = {
      \ 'pattern' : '\v\\includegraphics%(\s*\[[^]]*\])?\s*\{[^{}]*',
      \ 'enabled' : 1,
      \}

function! s:img.complete(regex) dict " {{{2
  let self.candidates = []
  for l:ext in ['png', 'eps', 'pdf', 'jpg']
    let self.candidates += split(globpath(b:vimtex.root, '**/*.' . l:ext), '\n')
  endfor

  let l:output = b:vimtex.out()
  call filter(self.candidates, 'v:val !=# l:output')

  call map(self.candidates, 'strpart(v:val, len(b:vimtex.root)+1)')
  call map(self.candidates, '{
        \ ''abbr'' : v:val,
        \ ''word'' : fnamemodify(v:val, '':t''),
        \ ''menu'' : '' [graphics]'',
        \ }')

  if g:vimtex_complete_img_use_tail
    for l:cand in self.candidates
      let l:cand.word = fnamemodify(l:cand.word, ':t')
    endfor
  endif

  return self.candidates
endfunction

" }}}1
" {{{1 Filenames (\input and \include)

let s:inc = {
      \ 'pattern' : '\v\\%(include%(only)?|input)\s*\{[^\{\}]*',
      \ 'enabled' : 1,
      \}

function! s:inc.complete(regex) dict " {{{2
  let self.candidates = split(globpath(b:vimtex.root, '**/*.tex'), '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  let self.candidates = map(self.candidates, '{
        \ ''word'' : v:val,
        \ ''abbr'' : v:val,
        \ ''menu'' : '' [input/include]'',
        \}')
  return self.candidates
endfunction

" }}}1
" {{{1 Glossary

let s:glc = {
      \ 'pattern' : '\v\\glc\s*\{[^{}]*',
      \ 'enabled' : 1,
      \}

function! s:glc.complete(regex) dict " {{{2
  return self.parse_glossaries()
endfunction

function! s:glc.parse_glossaries() dict " {{{2
  let self.candidates = []

  for l:line in filter(vimtex#parser#tex(b:vimtex.tex, 0),
        \ 'v:val =~# ''\\newglossaryentry''')
    let l:entries = matchstr(l:line, '\\newglossaryentry\s*{\zs[^{}]*')
    call add(self.candidates, {
          \ 'word' : l:entries,
          \ 'abbr' : l:entries,
          \ 'menu' : ' [glc]',
          \})
  endfor

  return self.candidates
endfunction


" }}}1

"
" Utility functions
"
function! s:close_braces(candidates) " {{{1
  if g:vimtex_complete_close_braces
        \ && strpart(getline('.'), col('.') - 1) !~# '^\s*[,}]'
    let l:candidates = a:candidates
    for l:cand in l:candidates
      let l:cand.word .= '}'
    endfor
    return l:candidates
  else
    return a:candidates
  endif
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
  let l:line = a:line
  for [l:pat, l:symbol] in s:tex2unicode_list
    let l:line = substitute(l:line, l:pat, l:symbol, 'g')
  endfor

  return l:line
endfunction

"
" Define list for converting '\IeC{\"u}' to corresponding unicode symbols
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

" }}}1

" vim: fdm=marker sw=2

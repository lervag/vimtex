" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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
    if exists('s:completer') | unlet s:completer | endif

    let l:pos  = col('.') - 1
    let l:line = getline('.')[:l:pos-1]
    for l:completer in s:completers
      if !get(l:completer, 'enabled', 1) | continue | endif

      for l:pattern in l:completer.patterns
        if l:line =~# l:pattern
          let s:completer = l:completer
          while l:pos > 0
            if l:line[l:pos - 1] =~# '{\|,\|\['
                  \ || l:line[l:pos-2:l:pos-1] ==# ', '
              let s:completer.context = matchstr(l:line, '\S*$')
              return l:pos
            else
              let l:pos -= 1
            endif
          endwhile
          return -2
        endif
      endfor
    endfor
    return -3
  else
    return exists('s:completer')
          \ ? s:close_braces(s:completer.complete(a:base))
          \ : []
  endif
endfunction

" }}}1

"
" Completers
"
" {{{1 Bibtex

let s:completer_bib = {
      \ 'patterns' : [
      \   '\v\\\a*cite\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*$',
      \   '\v\\bibentry\s*\{[^}]*$',
      \  ],
      \ 'bibs' : '''\v%(%(\\@<!%(\\\\)*)@<=\%.*)@<!'
      \          . '\\(%(no)?bibliography|add(bibresource|globalbib|sectionbib))'
      \          . '\m\s*{\zs[^}]\+\ze}''',
      \ 'type_length' : 0,
      \ 'bstfile' :  expand('<sfile>:p:h') . '/vimcomplete',
      \}

function! s:completer_bib.init() dict " {{{2
  " Check if bibtex is executable
  if !executable('bibtex')
    let self.enabled = 0
    call vimtex#echo#warning('bibtex is not executable')
    call vimtex#echo#echo('- bibtex completion is not available!')
    call vimtex#echo#wait()
    return
  endif

  " Check if kpsewhich is required and available
  if g:vimtex_complete_recursive_bib && !executable('kpsewhich')
    let self.enabled = 0
    call vimtex#echo#warning('kpsewhich is not executable')
    call vimtex#echo#echo('- recursive bib search requires kpsewhich!')
    call vimtex#echo#echo('- bibtex completion is not available!')
    call vimtex#echo#wait()
  endif

  " Check if bstfile contains whitespace (not handled by vimtex)
  if stridx(self.bstfile, ' ') >= 0
    let l:oldbst = self.bstfile . '.bst'
    let self.bstfile = tempname()
    call writefile(readfile(l:oldbst), self.bstfile . '.bst')
  endif
endfunction

function! s:completer_bib.complete(regexp) dict " {{{2
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

function! s:completer_bib.search(regexp) dict " {{{2
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
    call vimtex#process#run('bibtex -terse ' . tmp.aux, {
          \ 'background' : 0,
          \ 'use_system' : 1,
          \})

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
  execute 'lcd' fnameescape(l:save_pwd)

  " Find data from 'thebibliography' environments
  let lines = readfile(b:vimtex.tex)
  if match(lines, '\C\\begin{thebibliography}') >= 0
    for line in filter(filter(lines,
          \   'v:val =~# ''\C\\bibitem'''),
          \ 'v:val =~ a:regexp')
      let matches = matchlist(line, '\\bibitem\(\[[^]]\]\)\?{\([^}]*\)')
      if len(matches) > 1
        call add(res, {
              \ 'key': matches[2],
              \ 'type': 'thebibliography',
              \ 'author': '',
              \ 'year': '',
              \ 'title': matches[2],
              \ })
      endif
    endfor
  endif

  return res
endfunction

function! s:completer_bib.find_bibs() dict " {{{2
  "
  " Search for added bibliographies
  " * Parse commands such as \bibliography{file1,file2.bib,...}
  " * This also removes the .bib extensions
  "
  "
  let l:lines = vimtex#parser#tex(b:vimtex.tex, {
        \ 'detailed' : 0,
        \ 'recursive' : g:vimtex_complete_recursive_bib,
        \ })

  let l:bibfiles = []
  for l:entry in map(filter(l:lines, 'v:val =~ ' . self.bibs),
        \ 'matchstr(v:val, ' . self.bibs . ')')
    let l:entry = substitute(l:entry, '\\jobname', b:vimtex.name, 'g')
    let l:bibfiles += map(split(l:entry, ','), 'fnamemodify(v:val, '':r'')')
  endfor

  return l:bibfiles
endfunction

" }}}1
" {{{1 Labels

let s:completer_ref = {
      \ 'patterns' : [
      \   '\v\\v?%(auto|eq|[cC]?%(page)?|labelc)?ref%(\s*\{[^}]*|range\s*\{[^,{}]*%(\}\{)?)$',
      \   '\\hyperref\s*\[[^]]*$',
      \   '\\subref\*\?{[^}]*$',
      \ ],
      \ 'cache' : {},
      \ 'labels' : [],
      \}

function! s:completer_ref.complete(regex) dict " {{{2
  let self.candidates = []

  for m in self.get_matches(a:regex)
    call add(self.candidates, {
          \ 'word' : m[0],
          \ 'abbr' : m[0],
          \ 'menu' : printf('%7s [p. %s]', '('.m[1].')', m[2])
          \ })
  endfor

  "
  " If context is 'eqref', then only show eq: labels
  "
  if self.context =~# '\\eqref'
        \ && !empty(filter(copy(self.matches), 'v:val[0] =~# ''eq:'''))
    call filter(self.candidates, 'v:val.word =~# ''eq:''')
  endif

  return self.candidates
endfunction

function! s:completer_ref.get_matches(regex) dict " {{{2
  call self.parse_aux_files()

  " Match number
  let self.matches = filter(copy(self.labels), 'v:val[1] =~# ''^' . a:regex . '''')
  if !empty(self.matches) | return self.matches | endif

  " Match label
  let self.matches = filter(copy(self.labels), 'v:val[0] =~# ''' . a:regex . '''')

  " Match label and number
  if empty(self.matches)
    let l:regex_split = split(a:regex)
    if len(l:regex_split) > 1
      let l:base = l:regex_split[0]
      let l:number = escape(join(l:regex_split[1:], ' '), '.')
      let self.matches = filter(copy(self.labels),
            \ 'v:val[0] =~# ''' . l:base   . ''' &&' .
            \ 'v:val[1] =~# ''' . l:number . '''')
    endif
  endif

  return self.matches
endfunction

function! s:completer_ref.parse_aux_files() dict " {{{2
  let l:aux = b:vimtex.aux()
  if empty(l:aux)
    return self.labels
  endif

  let self.labels = []
  for [l:file, l:prefix] in [[l:aux, '']]
        \ + filter(map(vimtex#parser#get_externalfiles(),
        \   '[v:val.aux, v:val.opt]'),
        \ 'filereadable(v:val[0])')

    let l:cached = get(self.cache, l:file, {})
    if get(l:cached, 'ftime', 0) != getftime(l:file)
      let l:cached.ftime = getftime(l:file)
      let l:cached.labels = self.parse_labels(l:file, l:prefix)
      let self.cache[l:file] = l:cached
    endif

    let self.labels += l:cached.labels
  endfor

  return self.labels
endfunction

function! s:completer_ref.parse_labels(file, prefix) dict " {{{2
  "
  " Searches aux files recursively for commands of the form
  "
  "   \newlabel{name}{{number}{page}.*}.*
  "   \newlabel{name}{{text {number}}{page}.*}.*
  "
  " Returns a list of [name, number, page] tuples.
  "

  let l:labels = []
  let l:lines = vimtex#parser#aux(a:file)
  let l:lines = filter(l:lines, 'v:val =~# ''\\newlabel{''')
  let l:lines = filter(l:lines, 'v:val !~# ''@cref''')
  let l:lines = filter(l:lines, 'v:val !~# ''sub@''')
  let l:lines = filter(l:lines, 'v:val !~# ''tocindent-\?[0-9]''')
  for l:line in l:lines
    let l:line = s:tex2unicode(l:line)
    let l:tree = s:tex2tree(l:line)[1:]
    let l:name = a:prefix . remove(l:tree, 0)[0]
    let l:context = remove(l:tree, 0)
    if type(l:context) == type([]) && len(l:context) > 1
      let l:number = self.parse_number(l:context[0])
      let l:page = l:context[1][0]
      call add(l:labels, [l:name, l:number, l:page])
    endif
  endfor

  return l:labels
endfunction

function! s:completer_ref.parse_number(num_tree) dict " {{{2
  if type(a:num_tree) == type([])
    if len(a:num_tree) == 0
      return '-'
    else
      let l:index = len(a:num_tree) == 1 ? 0 : 1
      return self.parse_number(a:num_tree[l:index])
    endif
  else
    let l:matches = matchlist(a:num_tree, '\v(^|.*\s)((\u|\d+)(\.\d+)*)($|\s.*)')
    return len(l:matches) > 3 ? l:matches[2] : '-'
  endif
endfunction

" }}}1
" {{{1 Filenames (\includegraphics)

let s:completer_img = {
      \ 'patterns' : ['\v\\includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*$'],
      \ 'ext_re' : '\v\.%('
      \   . join(['png', 'jpg', 'eps', 'pdf', 'pgf', 'tikz'], '|')
      \   . ')$',
      \}

function! s:completer_img.complete(regex) dict " {{{2
  call self.gather_candidates()

  call filter(self.candidates, 'v:val.word =~# a:regex')

  return self.candidates
endfunction

function! s:completer_img.graphicspaths() dict " {{{2
  " Get preamble text and remove comments
  let l:preamble = vimtex#parser#tex(b:vimtex.tex, {
        \ 're_stop': '\\begin{document}',
        \ 'detailed': 0,
        \})
  call map(l:preamble, 'substitute(v:val, ''\\\@<!%.*'', '''', '''')')

  " Parse preamble for graphicspaths
  let l:graphicspaths = []
  for l:path in split(matchstr(join(l:preamble, ' '),
        \ '\\graphicspath{\s*{\s*\zs.\{-}\ze\s*}\s*}'), '}\s*{')
    if l:path[0] ==# '/'
      call add(l:graphicspaths, l:path[:-2])
    else
      call add(l:graphicspaths, simplify(b:vimtex.root . '/' . l:path[:-2]))
    endif
  endfor

  " Project root is always valid
  return l:graphicspaths + [b:vimtex.root]
endfunction

" }}}2
function! s:completer_img.gather_candidates() dict " {{{2
  let l:added_files = []
  let l:generated_pdf = b:vimtex.out()

  let self.candidates = []
  for l:path in self.graphicspaths()
    for l:file in split(globpath(l:path, '**/*.*'), '\n')
      if l:file !~? self.ext_re
            \ || l:file ==# l:generated_pdf
            \ || index(l:added_files, l:file) >= 0 | continue | endif

      call add(l:added_files, l:file)

      call add(self.candidates, {
            \ 'abbr': vimtex#paths#shorten_relative(l:file),
            \ 'word': vimtex#paths#relative(l:file, l:path),
            \ 'menu': '[graphics]',
            \})
    endfor
  endfor
endfunction

" }}}1
" {{{1 Filenames (\input and \include)

let s:completer_inc = {
      \ 'patterns' : ['\v\\%(include%(only)?|input|subfile)\s*\{[^}]*$'],
      \}

function! s:completer_inc.complete(regex) dict " {{{2
  let self.candidates = split(globpath(b:vimtex.root, '**/*.tex'), '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  call filter(self.candidates, 'v:val =~# a:regex')
  let self.candidates = map(self.candidates, '{
        \ ''word'' : v:val,
        \ ''abbr'' : v:val,
        \ ''menu'' : '' [input/include]'',
        \}')
  return self.candidates
endfunction

" }}}1
" {{{1 Filenames (\includepdf)

let s:completer_pdf = {
      \ 'patterns' : ['\v\\includepdf%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \}

function! s:completer_pdf.complete(regex) dict " {{{2
  let self.candidates = split(globpath(b:vimtex.root, '**/*.pdf'), '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  call filter(self.candidates, 'v:val =~# a:regex')
  let self.candidates = map(self.candidates, '{
        \ ''word'' : v:val,
        \ ''abbr'' : v:val,
        \ ''menu'' : '' [includepdf]'',
        \}')
  return self.candidates
endfunction

" }}}1
" {{{1 Filenames (\includestandalone)

let s:completer_sta = {
      \ 'patterns' : ['\v\\includestandalone%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \}

function! s:completer_sta.complete(regex) dict " {{{2
  let self.candidates = substitute(globpath(b:vimtex.root, '**/*.tex'), '\.tex', '', 'g')
  let self.candidates = split(self.candidates, '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  call filter(self.candidates, 'v:val =~# a:regex')
  let self.candidates = map(self.candidates, '{
        \ ''word'' : v:val,
        \ ''abbr'' : v:val,
        \ ''menu'' : '' [includestandalone]'',
        \}')
  return self.candidates
endfunction

" }}}1
" {{{1 Glossary

let s:completer_gls = {
      \ 'patterns' : ['\v\\(gls|Gls|GLS)(pl)?\s*\{[^}]*$'],
      \}

function! s:completer_gls.complete(regex) dict " {{{2
  return self.parse_glossaries()
endfunction

function! s:completer_gls.parse_glossaries() dict " {{{2
  let self.candidates = []

  for l:line in filter(vimtex#parser#tex(b:vimtex.tex, {
        \   'detailed' : 0,
        \   'input_re' :
        \     '\v^\s*\\%(input|include|subimport|subfile|loadglsentries)\s*\{',
        \ }), 'v:val =~# ''\\newglossaryentry''')
    let l:entries = matchstr(l:line, '\\newglossaryentry\s*{\zs[^{}]*')
    call add(self.candidates, {
          \ 'word' : l:entries,
          \ 'abbr' : l:entries,
          \ 'menu' : ' [gls]',
          \})
  endfor

  return self.candidates
endfunction


" }}}1
" {{{1 Packages (\usepackage)

let s:completer_pck = {
      \ 'patterns' : ['\v\\usepackage%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \ 'candidates' : [],
      \}

function! s:completer_pck.complete(regex) dict " {{{2
  return filter(copy(self.gather_candidates()),
        \ 'v:val.word =~# a:regex')
endfunction

function! s:completer_pck.gather_candidates() dict " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('sty'), '{
          \ ''word'' : v:val,
          \ ''menu'' : '' [package]'',
          \}')
  endif

  return self.candidates
endfunction

" }}}1
" {{{1 Documentclasses (\documentclass)

let s:completer_doc = {
      \ 'patterns' : ['\v\\documentclass%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \ 'candidates' : [],
      \}

function! s:completer_doc.complete(regex) dict " {{{2
  return filter(copy(self.gather_candidates()),
        \ 'v:val.word =~# a:regex')
endfunction

function! s:completer_doc.gather_candidates() dict " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('cls'), '{
          \ ''word'' : v:val,
          \ ''menu'' : '' [documentclass]'',
          \}')
  endif

  return self.candidates
endfunction

" }}}1

"
" Utility functions
"
function! s:get_texmf_candidates(filetype) " {{{1
  " First add the locally installed candidates
  let l:texmfhome = get(vimtex#kpsewhich#run('--var-value TEXMFHOME'), 0, 'XX')
  let l:candidates = glob(l:texmfhome . '/**/*.' . a:filetype, 0, 1)
  call map(l:candidates, 'fnamemodify(v:val, '':t:r'')')

  " Then add the globally available candidates (based on ls-R files)
  for l:file in vimtex#kpsewhich#run('--all ls-R')
    let l:candidates += map(filter(readfile(l:file),
          \   'v:val =~# ''\.' . a:filetype . ''''),
          \ 'fnamemodify(v:val, '':r'')')
  endfor

  return l:candidates
endfunction

" }}}1
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


" {{{1 Initialize module

let s:completers = map(
      \ filter(items(s:), 'v:val[0] =~# ''^completer_'''),
      \ 'v:val[1]')

" }}}1

" vim: fdm=marker sw=2

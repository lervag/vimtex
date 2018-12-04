" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#complete#init_buffer() abort " {{{1
  if !g:vimtex_complete_enabled | return | endif

  for l:completer in s:completers
    if has_key(l:completer, 'init')
      call l:completer.init()
    endif
  endfor

  setlocal omnifunc=vimtex#complete#omnifunc
endfunction

" }}}1

function! vimtex#complete#omnifunc(findstart, base) abort " {{{1
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
            if l:line[l:pos - 1] =~# '{\|,\|\[\|\\'
                  \ || l:line[l:pos-2:l:pos-1] ==# ', '
              let s:completer.context = matchstr(l:line,
                    \ get(s:completer, 're_context', '\S*$'))
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
    if !exists('s:completer') | return [] | endif

    return g:vimtex_complete_close_braces && get(s:completer, 'inside_braces', 1)
          \ ? s:close_braces(s:completer.complete(a:base))
          \ : s:completer.complete(a:base)
  endif
endfunction

" }}}1
function! vimtex#complete#complete(type, input, context) abort " {{{1
  try
    let s:completer = s:completer_{a:type}
    let s:completer.context = a:context
    return s:completer.complete(a:input)
  catch /E121/
    return []
  endtry
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
      \   '\v\\%(text|block)cquote\*?%(\s*\[[^]]*\]){0,2}\{[^}]*$',
      \   '\v\\%(for|hy)\w+cquote\*?\{[^}]*\}%(\s*\[[^]]*\]){0,2}\{[^}]*$',
      \  ],
      \ 'bibs' : '''\v%(%(\\@<!%(\\\\)*)@<=\%.*)@<!'
      \          . '\\(%(no)?bibliography|add(bibresource|globalbib|sectionbib))'
      \          . '\m\s*{\zs[^}]\+\ze}''',
      \ 'type_length' : 0,
      \ 'bstfile' :  expand('<sfile>:p:h') . '/vimcomplete',
      \}

function! s:completer_bib.init() dict abort " {{{2
  " Check if bibtex is executable
  if !executable('bibtex')
    let self.enabled = 0
    call vimtex#log#warning(
          \ 'bibtex is not executable!',
          \ 'bibtex completion is not available!')
    return
  endif

  " Check if kpsewhich is required and available
  if g:vimtex_complete_recursive_bib && !executable('kpsewhich')
    let self.enabled = 0
    call vimtex#log#warning(
          \ 'kpsewhich is not executable!',
          \ '- recursive bib search requires kpsewhich!',
          \ '- bibtex completion is not available!')
  endif

  " Check if bstfile contains whitespace (not handled by vimtex)
  if stridx(self.bstfile, ' ') >= 0
    let l:oldbst = self.bstfile . '.bst'
    let self.bstfile = tempname()
    call writefile(readfile(l:oldbst), self.bstfile . '.bst')
  endif
endfunction

function! s:completer_bib.complete(regex) dict abort " {{{2
  let self.candidates = []

  let self.type_length = 1
  for m in self.search(a:regex)
    let auth = empty(m['author']) ? 'Unknown' : m['author'][:20]
    let auth = substitute(auth, '\~', ' ', 'g')
    let substitutes = {
          \ '@title' : empty(m['title']) ? 'No title' : m['title'],
          \ '@year' : empty(m['year']) ? '?' : m['year'],
          \ '@author_all' : auth,
          \ '@author_short' : substitute(auth, ',.*\ze', ' et al.', ''),
          \ '@type' : empty(m['type']) ? '-' : m['type'],
          \}

    " Create menu string
    let menu_string = copy(g:vimtex_complete_bib_menu_fmt)
    for [key, val] in items(substitutes)
      let menu_string = substitute(menu_string, key, escape(val, '&'), '')
    endfor

    call add(self.candidates, {
          \ 'word': m['key'],
          \ 'menu': menu_string,
          \ })
  endfor

  if g:vimtex_complete_bib_simple
    call s:filter_with_options(self.candidates, a:regex)
  endif

  return self.candidates
endfunction

function! s:completer_bib.search(regex) dict abort " {{{2
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
    call vimtex#process#run('bibtex -terse ' . fnameescape(tmp.aux), {
          \ 'background' : 0,
          \ 'silent' : 1,
          \})

    " Parse temporary bbl file
    let lines = map(readfile(tmp.bbl), 's:tex2unicode(v:val)')
    let lines = split(substitute(join(lines, "\n"),
          \ '\n\n\@!\(\s\=\)\s*\|{\|}', '\1', 'g'), "\n")

    if !g:vimtex_complete_bib_simple
      call s:filter_with_options(lines, a:regex, {'anchor': 0})
    endif

    for line in lines
      let matches = matchlist(line,
            \ '^\(.*\)||\(.*\)||\(.*\)||\(.*\)||\(.*\)')
      if !empty(matches) && !empty(matches[1])
        let self.type_length = max([self.type_length, len(matches[2])])
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
    call filter(lines, 'v:val =~# ''\C\\bibitem''')

    if !g:vimtex_complete_bib_simple
      call s:filter_with_options(lines, a:regex)
    endif

    for line in lines
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

function! s:completer_bib.find_bibs() dict abort " {{{2
  "
  " Search for added bibliographies
  " * Parse commands such as \bibliography{file1,file2.bib,...}
  " * This also removes the .bib extensions
  "
  "

  " Handle local file editing (e.g. subfiles package)
  let l:id = get(get(b:, 'vimtex_local', {'main_id' : b:vimtex_id}), 'main_id')
  let l:file = vimtex#state#get(l:id).tex

  let l:lines = vimtex#parser#tex(l:file, {
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
      \ 're_context' : '\\\w*{[^}]*$',
      \ 'cache' : {},
      \ 'labels' : [],
      \}

function! s:completer_ref.complete(regex) dict abort " {{{2
  let self.candidates = []

  for m in self.get_matches(a:regex)
    call add(self.candidates, {
          \ 'word' : m[0],
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

function! s:completer_ref.get_matches(regex) dict abort " {{{2
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

function! s:completer_ref.parse_aux_files() dict abort " {{{2
  let l:files = [[b:vimtex.aux(), '']]

  " Handle local file editing (e.g. subfiles package)
  if exists('b:vimtex_local') && b:vimtex_local.active
    let l:files += [[vimtex#state#get(b:vimtex_local.main_id).aux(), '']]
  endif

  " Add externaldocuments (from \externaldocument in preamble)
  let l:files += map(
        \ vimtex#parser#get_externalfiles(),
        \ '[v:val.aux, v:val.opt]')

  let self.labels = []
  for [l:file, l:prefix] in filter(l:files, 'filereadable(v:val[0])')
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

function! s:completer_ref.parse_labels(file, prefix) dict abort " {{{2
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

function! s:completer_ref.parse_number(num_tree) dict abort " {{{2
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
" {{{1 Commands

let s:completer_cmd = {
      \ 'patterns' : [
      \   '\v\\\a*$',
      \ ],
      \ 'candidates_from_packages' : [],
      \ 'candidates_from_newcommands' : [],
      \ 'candidates_from_lets' : [],
      \ 'inside_braces' : 0,
      \}

function! s:completer_cmd.complete(regex) dict abort " {{{2
  let l:candidates = self.gather_candidates()
  let l:mode = vimtex#util#in_mathzone() ? 'm' : 'n'

  call s:filter_with_options(l:candidates, a:regex)
  call filter(l:candidates, 'l:mode =~# v:val.mode')

  return l:candidates
endfunction

function! s:completer_cmd.gather_candidates() dict abort " {{{2
  call self.gather_candidates_from_packages()
  call self.gather_candidates_from_newcommands()
  call self.gather_candidates_from_lets()

  return vimtex#util#uniq_unsorted(
        \   copy(self.candidates_from_newcommands)
        \ + copy(self.candidates_from_lets)
        \ + copy(self.candidates_from_packages))
endfunction

function! s:completer_cmd.gather_candidates_from_packages() dict abort " {{{2
  let l:packages = [
        \ 'default',
        \ 'class-' . get(b:vimtex, 'documentclass', ''),
        \] + keys(b:vimtex.packages)
  call s:load_candidates_from_packages(l:packages)

  let self.candidates_from_packages = []
  for l:p in l:packages
    let self.candidates_from_packages += get(
          \ get(s:candidates_from_packages, l:p, {}), 'commands', [])
  endfor
endfunction

function! s:completer_cmd.gather_candidates_from_newcommands() dict abort " {{{2
  " Simple caching
  if !empty(self.candidates_from_newcommands)
    let l:modified_time = max(map(
          \ copy(get(b:vimtex, 'source_files', [b:vimtex.tex])),
          \ 'getftime(v:val)'))
    if l:modified_time > get(self, 'newcommands_updated')
      let self.newcommands_updated = l:modified_time
    else
      return
    endif
  endif

  let l:candidates = vimtex#parser#tex(b:vimtex.tex, {'detailed' : 0})

  call filter(l:candidates, 'v:val =~# ''\v\\(re)?newcommand''')
  call map(l:candidates, '{
        \ ''word'' : matchstr(v:val, ''\v\\(re)?newcommand\*?\{\\?\zs[^}]*''),
        \ ''mode'' : ''.'',
        \ ''kind'' : ''[cmd: newcommand]'',
        \ }')

  let self.candidates_from_newcommands = l:candidates
endfunction

function! s:completer_cmd.gather_candidates_from_lets() dict abort " {{{2
  let l:preamble = vimtex#parser#tex(b:vimtex.tex, {
        \ 're_stop': '\\begin{document}',
        \ 'detailed': 0,
        \})

  let l:lets = filter(copy(l:preamble), 'v:val =~# ''\\let\>''')
  let l:defs = filter(copy(l:preamble), 'v:val =~# ''\\def\>''')
  let l:candidates = map(l:lets, '{
        \ ''word'' : matchstr(v:val, ''\\let[^\\]*\\\zs\w*''),
        \ ''mode'' : ''.'',
        \ ''kind'' : ''[cmd: \let]'',
        \ }')
        \ + map(l:defs, '{
        \ ''word'' : matchstr(v:val, ''\\def[^\\]*\\\zs\w*''),
        \ ''mode'' : ''.'',
        \ ''kind'' : ''[cmd: \def]'',
        \ }')

  let self.candidates_from_lets = l:candidates
endfunction

" }}}1
" {{{1 Filenames (\includegraphics)

let s:completer_img = {
      \ 'patterns' : ['\v\\includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*$'],
      \ 'ext_re' : '\v\.%('
      \   . join(['png', 'jpg', 'eps', 'pdf', 'pgf', 'tikz'], '|')
      \   . ')$',
      \}

function! s:completer_img.complete(regex) dict abort " {{{2
  call self.gather_candidates()

  return s:filter_with_options(self.candidates, a:regex)
endfunction

function! s:completer_img.gather_candidates() dict abort " {{{2
  let l:added_files = []
  let l:generated_pdf = b:vimtex.out()

  let self.candidates = []
  for l:path in b:vimtex.graphicspath + [b:vimtex.root]
    for l:file in split(globpath(l:path, '**/*.*'), '\n')
      if l:file !~? self.ext_re
            \ || l:file ==# l:generated_pdf
            \ || index(l:added_files, l:file) >= 0 | continue | endif

      call add(l:added_files, l:file)

      call add(self.candidates, {
            \ 'abbr': vimtex#paths#shorten_relative(l:file),
            \ 'word': vimtex#paths#relative(l:file, l:path),
            \ 'kind': '[graphics]',
            \})
    endfor
  endfor
endfunction

" }}}1
" {{{1 Filenames (\input, \include, and \subfile)

let s:completer_inc = {
      \ 'patterns' : [
      \   g:vimtex#re#tex_input . '[^}]*$',
      \   '\v\\includeonly\s*\{[^}]*$',
      \ ],
      \}

function! s:completer_inc.complete(regex) dict abort " {{{2
  let self.candidates = split(globpath(b:vimtex.root, '**/*.tex'), '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  call s:filter_with_options(self.candidates, a:regex)

  if self.context =~# '\\include'
    let self.candidates = map(self.candidates, '{
          \ ''word'' : fnamemodify(v:val, '':r''),
          \ ''kind'' : '' [include]'',
          \}')
  else
    let self.candidates = map(self.candidates, '{
          \ ''word'' : v:val,
          \ ''kind'' : '' [input]'',
          \}')
  endif

  return self.candidates
endfunction

" }}}1
" {{{1 Filenames (\includepdf)

let s:completer_pdf = {
      \ 'patterns' : ['\v\\includepdf%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \}

function! s:completer_pdf.complete(regex) dict abort " {{{2
  let self.candidates = split(globpath(b:vimtex.root, '**/*.pdf'), '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  call s:filter_with_options(self.candidates, a:regex)
  let self.candidates = map(self.candidates, '{
        \ ''word'' : v:val,
        \ ''kind'' : '' [includepdf]'',
        \}')
  return self.candidates
endfunction

" }}}1
" {{{1 Filenames (\includestandalone)

let s:completer_sta = {
      \ 'patterns' : ['\v\\includestandalone%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \}

function! s:completer_sta.complete(regex) dict abort " {{{2
  let self.candidates = substitute(globpath(b:vimtex.root, '**/*.tex'), '\.tex', '', 'g')
  let self.candidates = split(self.candidates, '\n')
  let self.candidates = map(self.candidates,
        \ 'strpart(v:val, len(b:vimtex.root)+1)')
  call s:filter_with_options(self.candidates, a:regex)
  let self.candidates = map(self.candidates, '{
        \ ''word'' : v:val,
        \ ''kind'' : '' [includestandalone]'',
        \}')
  return self.candidates
endfunction

" }}}1
" {{{1 Glossary

let s:completer_gls = {
      \ 'patterns' : ['\v\\(gls|Gls|GLS)(pl)?\s*\{[^}]*$'],
      \ 'candidates' : [],
      \ 'key' : {
      \   'newglossaryentry' : ' [gls]',
      \   'longnewglossaryentry' : ' [gls]',
      \   'newacronym' : ' [acr]',
      \   'newabbreviation' : ' [abbr]',
      \   'glsxtrnewsymbol' : ' [symbol]',
      \ },
      \}

function! s:completer_gls.complete(regex) dict abort " {{{2
  let l:candidates = self.parse_glossaries()

  return s:filter_with_options(l:candidates, a:regex)
endfunction

function! s:completer_gls.parse_glossaries() dict abort " {{{2
  let self.candidates = []

  let l:re_input = g:vimtex#re#tex_input . '|^\s*\\loadglsentries'
  let l:re_commands = '\v\\(' . join(keys(self.key), '|') . ')'
  let l:re_matcher = l:re_commands . '\s*%(\[.*\])=\s*\{([^{}]*)'

  for l:line in filter(vimtex#parser#tex(b:vimtex.tex, {
        \   'detailed' : 0,
        \   'input_re' : l:re_input,
        \ }), 'v:val =~# l:re_commands')
    let l:matches = matchlist(l:line, l:re_matcher)
    call add(self.candidates, {
          \ 'word' : l:matches[2],
          \ 'menu' : self.key[l:matches[1]],
          \})
  endfor

  return self.candidates
endfunction


" }}}1
" {{{1 Packages (\usepackage)

let s:completer_pck = {
      \ 'patterns' : [
      \   '\v\\%(usepackage|RequirePackage|PassOptionsToPackage)'
      \   . '%(\s*\[[^]]*\])?\s*\{[^}]*$'
      \ ],
      \ 'candidates' : [],
      \}

function! s:completer_pck.complete(regex) dict abort " {{{2
  call self.gather_candidates()
  return s:filter_with_options(copy(self.candidates), a:regex)
endfunction

function! s:completer_pck.gather_candidates() dict abort " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('sty'), '{
          \ ''word'' : v:val,
          \ ''kind'' : '' [package]'',
          \}')
  endif
endfunction

" }}}1
" {{{1 Documentclasses (\documentclass)

let s:completer_doc = {
      \ 'patterns' : ['\v\\documentclass%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \ 'candidates' : [],
      \}

function! s:completer_doc.complete(regex) dict abort " {{{2
  return filter(copy(self.gather_candidates()),
        \ 'v:val.word =~# a:regex')
endfunction

function! s:completer_doc.gather_candidates() dict abort " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('cls'), '{
          \ ''word'' : v:val,
          \ ''kind'' : '' [documentclass]'',
          \}')
  endif

  return self.candidates
endfunction

" }}}1
" {{{1 Environments (\begin/\end)

let s:completer_env = {
      \ 'patterns' : ['\v\\%(begin|end)%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \ 'candidates_from_newenvironments' : [],
      \ 'candidates_from_packages' : [],
      \}

function! s:completer_env.complete(regex) dict abort " {{{2
  if self.context =~# '^\\end\>'
    " When completing \end{, search for an unmatched \begin{...}
    let l:matching_env = ''
    let l:save_pos = vimtex#pos#get_cursor()
    let l:pos_val_cursor = vimtex#pos#val(l:save_pos)

    let l:lnum = l:save_pos[1] + 1
    while l:lnum > 1
      let l:open  = vimtex#delim#get_prev('env_tex', 'open')
      if empty(l:open) || get(l:open, 'name', '') ==# 'document'
        break
      endif

      let l:close = vimtex#delim#get_matching(l:open)
      if empty(l:close.match)
        let l:matching_env = l:close.name . (l:close.starred ? '*' : '')
        break
      endif

      let l:pos_val_try = vimtex#pos#val(l:close) + strlen(l:close.match)
      if l:pos_val_try > l:pos_val_cursor
        break
      else
        let l:lnum = l:open.lnum
        call vimtex#pos#set_cursor(vimtex#pos#prev(l:open))
      endif
    endwhile

    call vimtex#pos#set_cursor(l:save_pos)

    if !empty(l:matching_env) && l:matching_env =~# a:regex
      return [{
            \ 'word': l:matching_env,
            \ 'kind': '[env: matching]',
            \}]
    endif
  endif

  return s:filter_with_options(copy(self.gather_candidates()), a:regex)
endfunction

" }}}2
function! s:completer_env.gather_candidates() dict abort " {{{2
  call self.gather_candidates_from_packages()
  call self.gather_candidates_from_newenvironments()

  return vimtex#util#uniq_unsorted(
        \   copy(self.candidates_from_newenvironments)
        \ + copy(self.candidates_from_packages))
endfunction

" }}}2
function! s:completer_env.gather_candidates_from_packages() dict abort " {{{2
  let l:packages = [
        \ 'default',
        \ 'class-' . get(b:vimtex, 'documentclass', ''),
        \] + keys(b:vimtex.packages)
  call s:load_candidates_from_packages(l:packages)

  let self.candidates_from_packages = []
  for l:p in l:packages
    let self.candidates_from_packages += get(
          \ get(s:candidates_from_packages, l:p, {}), 'environments', [])
  endfor
endfunction

" }}}2
function! s:completer_env.gather_candidates_from_newenvironments() dict abort " {{{2
  " Simple caching
  if !empty(self.candidates_from_newenvironments)
    let l:modified_time = max(map(
          \ copy(get(b:vimtex, 'source_files', [b:vimtex.tex])),
          \ 'getftime(v:val)'))
    if l:modified_time > get(self, 'newenvironments_updated')
      let self.newenvironments_updated = l:modified_time
    else
      return
    endif
  endif

  let l:candidates = vimtex#parser#tex(b:vimtex.tex, {'detailed' : 0})

  call filter(l:candidates, 'v:val =~# ''\v\\(re)?newenvironment''')
  call map(l:candidates, '{
        \ ''word'' : matchstr(v:val, ''\v\\(re)?newenvironment\*?\{\\?\zs[^}]*''),
        \ ''mode'' : ''.'',
        \ ''kind'' : ''[env: newenvironment]'',
        \ }')

  let self.candidates_from_newenvironments = l:candidates
endfunction

" }}}1

"
" Utility functions
"
function! s:filter_with_options(input, regex, ...) abort " {{{1
  if empty(a:input) | return a:input | endif

  let l:expression = type(a:input[0]) == type({}) ? 'v:val.word' : 'v:val'
  let l:opts = a:0 > 0 ? a:1 : {}

  if g:vimtex_complete_ignore_case && (!g:vimtex_complete_smart_case || a:regex !~# '\u')
    let l:expression .= ' =~? '
  else
    let l:expression .= ' =~# '
  endif

  if get(l:opts, 'anchor', 1)
    let l:expression .= '''^'' . '
  endif

  let l:expression .= 'a:regex'

  return filter(a:input, l:expression)
endfunction

" }}}1
function! s:get_texmf_candidates(filetype) abort " {{{1
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
function! s:load_candidates_from_packages(packages) abort " {{{1
  let l:packages = filter(copy(a:packages),
        \ '!has_key(s:candidates_from_packages, v:val)')
  if empty(l:packages) | return | endif

  let l:save_pwd = getcwd()
  let l:localdir = exists('*haslocaldir') ? haslocaldir() : 1
  execute l:localdir ? 'lcd' : 'cd' fnameescape(s:complete_dir)

  for l:unreadable in filter(copy(l:packages), '!filereadable(v:val)')
    let s:candidates_from_packages[l:unreadable] = {}
    call remove(l:packages, index(l:packages, l:unreadable))
  endfor

  let l:queue = copy(l:packages)
  while !empty(l:queue)
    let l:current = remove(l:queue, 0)
    let l:includes = filter(readfile(l:current), 'v:val =~# ''^\#\s*include:''')
    if empty(l:includes) | continue | endif

    call map(l:includes, 'matchstr(v:val, ''include:\s*\zs.*\ze\s*$'')')
    call filter(l:includes, 'filereadable(v:val)')
    call filter(l:includes, 'index(l:packages, v:val) < 0')

    let l:packages += l:includes
    let l:queue += l:includes
  endwhile

  for l:package in l:packages
    let s:candidates_from_packages[l:package] = {
          \ 'commands':     [],
          \ 'environments': [],
          \}

    let l:lines = readfile(l:package)

    let l:candidates = filter(copy(l:lines), 'v:val =~# ''^\a''')
    call map(l:candidates, 'split(v:val)')
    call map(l:candidates, '{
          \ ''word'' : v:val[0],
          \ ''mode'' : ''.'',
          \ ''kind'' : ''[cmd: '' . l:package . ''] '',
          \ ''menu'' : (get(v:val, 1, '''')),
          \}')
    let s:candidates_from_packages[l:package].commands += l:candidates

    let l:candidates = filter(copy(l:lines), 'v:val =~# ''^\\begin{''')
    call map(l:candidates, '{
          \ ''word'' : substitute(v:val, ''^\\begin{\|}$'', '''', ''g''),
          \ ''mode'' : ''.'',
          \ ''kind'' : ''[env: '' . l:package . ''] '',
          \}')
    let s:candidates_from_packages[l:package].environments += l:candidates
  endfor

  execute l:localdir ? 'lcd' : 'cd' fnameescape(l:save_pwd)
endfunction

let s:candidates_from_packages = {}

" }}}1
function! s:close_braces(candidates) abort " {{{1
  if strpart(getline('.'), col('.') - 1) !~# '^\s*[,}]'
    for l:cand in a:candidates
      if !has_key(l:cand, 'abbr')
        let l:cand.abbr = l:cand.word
      endif
      let l:cand.word = substitute(l:cand.word, '}*$', '}', '')
    endfor
  endif

  return a:candidates
endfunction

" }}}1
function! s:tex2tree(str) abort " {{{1
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
function! s:tex2unicode(line) abort " {{{1
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

let s:complete_dir = fnamemodify(expand('<sfile>'), ':r') . '/'

" }}}1

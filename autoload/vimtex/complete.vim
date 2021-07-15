" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#complete#init_buffer() abort " {{{1
  if !g:vimtex_complete_enabled | return | endif

  if !has_key(b:vimtex, 'complete')
    let b:vimtex.complete = {}
  endif

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
      \   '\v\\%(\a*cite|Cite)\a*\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*$',
      \   '\v\\%(\a*cites|Cites)%(\s*\([^)]*\)){0,2}'
      \     . '%(%(\s*\[[^]]*\]){0,2}\s*\{[^}]*\})*'
      \     . '%(\s*\[[^]]*\]){0,2}\s*\{[^}]*$',
      \   '\v\\bibentry\s*\{[^}]*$',
      \   '\v\\%(text|block)cquote\*?%(\s*\[[^]]*\]){0,2}\{[^}]*$',
      \   '\v\\%(for|hy)\w+cquote\*?\{[^}]*\}%(\s*\[[^]]*\]){0,2}\{[^}]*$',
      \   '\v\\defbibentryset\{[^}]*\}\{[^}]*$',
      \  ],
      \ 'initialized' : 0,
      \}

function! s:completer_bib.init() dict abort " {{{2
  if self.initialized | return | endif
  let self.initialized = 1

  let self.patterns += g:vimtex_complete_bib.custom_patterns
endfunction

function! s:completer_bib.complete(regex) dict abort " {{{2
  let self.candidates = self.gather_candidates()

  if g:vimtex_complete_bib.simple
    call s:filter(self.candidates, a:regex)
  else
    call s:filter_with_options(self.candidates, a:regex, {
          \ 'anchor': 0,
          \ 'filter_key': 'mstr',
          \})
  endif

  return self.candidates
endfunction

function! s:completer_bib.gather_candidates() dict abort " {{{2
  let l:entries = []

  let l:cache = vimtex#cache#open('bibcomplete', {
        \ 'local': 1,
        \ 'validate': g:vimtex_complete_bib,
        \ 'default': {'result': [], 'ftime': -1}
        \})

  "
  " Find data from external bib files
  "

  " Note: bibtex seems to require that we are in the project root
  call vimtex#paths#pushd(b:vimtex.root)
  for l:file in vimtex#bib#files()
    let l:current = l:cache.get(l:file)
    let l:ftime = getftime(l:file)
    if l:ftime > l:current.ftime
      let l:current.ftime = l:ftime
      let l:current.result = map(
            \ vimtex#parser#bib(l:file),
            \ {_, x -> s:bib_to_candidate(x)})
      let l:cache.modified = 1
    endif
    let l:entries += l:current.result
  endfor

  call vimtex#paths#popd()

  "
  " Find data from 'thebibliography' environments
  "
  let l:ftime = b:vimtex.getftime()
  if l:ftime > 0
    let l:current = l:cache.get(sha256(b:vimtex.tex))

    if l:ftime > l:current.ftime
      let l:current.ftime = l:ftime
      let l:current.result = []

      let l:lines = vimtex#parser#tex(b:vimtex.tex, {'detailed' : 0})
      if match(l:lines, '\C\\begin{thebibliography}') >= 0
        call filter(l:lines, 'v:val =~# ''\C\\bibitem''')

        for l:line in l:lines
          let l:matches = matchlist(l:line, '\\bibitem\(\[[^]]\]\)\?{\([^}]*\)')
          if len(l:matches) > 1
            call add(l:current.result, s:bib_to_candidate({
                  \ 'key': l:matches[2],
                  \ 'type': 'thebibliography',
                  \ 'author': '',
                  \ 'year': '',
                  \ 'title': l:matches[2],
                  \ }))
          endif
        endfor
      endif
    endif

    let l:entries += l:current.result
  endif

  " Write cache to file
  call l:cache.write()

  return l:entries
endfunction

" }}}2

function! s:bib_to_candidate(entry) abort " {{{2
  let auth = substitute(get(a:entry, 'author', 'Unknown'), '\~', ' ', 'g')

  let substitutes = {
        \ '@author_all' : g:vimtex_complete_bib.auth_len > 0
        \     ? strcharpart(auth, 0, g:vimtex_complete_bib.auth_len)
        \     : auth,
        \ '@author_short' : substitute(auth, ',.*\ze', ' et al.', ''),
        \ '@key' : a:entry['key'],
        \ '@title' : get(a:entry, 'title', 'No title'),
        \ '@type' : empty(a:entry['type']) ? '-' : a:entry['type'],
        \ '@year' : get(a:entry, 'year', get(a:entry, 'date', '?')),
        \}

  let cand = {'word': a:entry['key']}

  " Create match and menu strings
  let cand.mstr = copy(g:vimtex_complete_bib.match_str_fmt)
  let cand.menu = copy(g:vimtex_complete_bib.menu_fmt)
  for [key, val] in items(substitutes)
    let val = escape(val, '&')
    let cand.mstr = substitute(cand.mstr, key, val, '')
    let cand.menu = substitute(cand.menu, key, val, '')
  endfor

  " Create abbreviation string (if necessary)
  if !empty(g:vimtex_complete_bib.abbr_fmt)
    let cand.abbr = copy(g:vimtex_complete_bib.abbr_fmt)
    for [key, val] in items(substitutes)
      let cand.abbr = substitute(cand.abbr, key, escape(val, '&'), '')
    endfor
  endif

  return cand
endfunction

" }}}2

" }}}1
" {{{1 Labels

let s:completer_ref = {
      \ 'patterns' : [
      \   '\v\\v?%(auto|eq|[cC]?%(page)?|labelc)?ref%(\s*\{[^}]*|range\s*\{[^,{}]*%(\}\{)?)$',
      \   '\\hyperref\s*\[[^]]*$',
      \   '\\subref\*\?{[^}]*$',
      \ ],
      \ 're_context' : '\\\w*{[^}]*$',
      \ 'initialized' : 0,
      \}

function! s:completer_ref.init() dict abort " {{{2
  if self.initialized | return | endif
  let self.initialized = 1

  " Add custom patterns
  let self.patterns += g:vimtex_complete_ref.custom_patterns
endfunction

function! s:completer_ref.complete(regex) dict abort " {{{2
  let l:candidates = self.get_matches(a:regex)

  if self.context =~# '\\eqref'
        \ && !empty(filter(copy(l:candidates), 'v:val.word =~# ''^eq:'''))
    call filter(l:candidates, 'v:val.word =~# ''^eq:''')
  endif

  return l:candidates
endfunction

function! s:completer_ref.get_matches(regex) dict abort " {{{2
  let l:labels = vimtex#parser#auxiliary#labels()

  " Match number
  let l:matches = filter(copy(l:labels), {_, x -> x.menu =~# a:regex})
  if !empty(l:matches) | return l:matches | endif

  " Match label
  let l:matches = filter(copy(l:labels), {_, x -> x.word =~# a:regex})
  if !empty(l:matches) | return l:matches | endif

  " Match label and number
  let l:regex_split = split(a:regex)
  if len(l:regex_split) > 1
    let l:base = l:regex_split[0]
    let l:number = escape(join(l:regex_split[1:], ' '), '.')
    let l:matches = filter(copy(l:labels),
          \ {_, x -> x.word =~# l:base && x.menu =~# l:number})
  endif

  return l:matches
endfunction

" }}}1
" {{{1 Commands

let s:completer_cmd = {
      \ 'patterns' : [g:vimtex#re#not_bslash . '\\\a*$'],
      \ 'inside_braces' : 0,
      \}

function! s:completer_cmd.complete(regex) dict abort " {{{2
  let l:candidates = self.gather_candidates()
  let l:mode = vimtex#syntax#in_mathzone() ? 'm' : 'n'

  call s:filter(l:candidates, a:regex)
  call filter(l:candidates, 'l:mode =~# v:val.mode')

  return l:candidates
endfunction

function! s:completer_cmd.gather_candidates() dict abort " {{{2
  let l:candidates = s:load_from_document('cmd')
  let l:candidates += self.gather_candidates_from_lets()
  for l:pkg in s:get_packages()
    let l:candidates += s:load_from_package(l:pkg, 'cmd')
  endfor
  let l:candidates += self.gather_candidates_from_glossary_keys()

  return vimtex#util#uniq_unsorted(l:candidates)
endfunction

function! s:completer_cmd.gather_candidates_from_glossary_keys() dict abort " {{{2
  if !has_key(b:vimtex.packages, 'glossaries') | return [] | endif

  let l:preamble = vimtex#parser#preamble(b:vimtex.tex)
  call map(l:preamble, {_, x -> substitute(x, '\s*%.*', '', 'g')})
  let l:glskeys = split(join(l:preamble, "\n"), '\n\s*\\glsaddkey\*\?')[1:]
  call map(l:glskeys, {_, x -> substitute(x, '\n\s*', '', 'g')})
  call map(l:glskeys, 'vimtex#util#tex2tree(v:val)[2:6]')

  let l:candidates = map(vimtex#util#flatten(l:glskeys), {_, x -> {
        \ 'word' : x[1:],
        \ 'mode' : '.',
        \ 'kind' : '[cmd: glossaries]',
        \}})

  return l:candidates
endfunction

function! s:completer_cmd.gather_candidates_from_lets() dict abort " {{{2
  let l:preamble = vimtex#parser#preamble(b:vimtex.tex)

  let l:lets = filter(copy(l:preamble), 'v:val =~# ''\\let\>''')
  let l:defs = filter(copy(l:preamble), 'v:val =~# ''\\def\>''')
  let l:candidates = map(l:lets, {_, x -> {
        \ 'word': matchstr(x, '\\let[^\\]*\\\zs\w*'),
        \ 'mode': '.',
        \ 'kind': '[cmd: \let]',
        \}})
        \ + map(l:defs, {_, x -> {
        \ 'word': matchstr(x, '\\def[^\\]*\\\zs\w*'),
        \ 'mode': '.',
        \ 'kind': '[cmd: \def]',
        \}})

  return l:candidates
endfunction

" }}}1
" {{{1 Environments

let s:completer_env = {
      \ 'patterns' : ['\v\\%(begin|end)%(\s*\[[^]]*\])?\s*\{[^}]*$'],
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

  return s:filter(copy(self.gather_candidates()), a:regex)
endfunction

" }}}2
function! s:completer_env.gather_candidates() dict abort " {{{2
  let l:candidates = s:load_from_document('env')
  for l:pkg in s:get_packages()
    let l:candidates += s:load_from_package(l:pkg, 'env')
  endfor

  return vimtex#util#uniq_unsorted(l:candidates)
endfunction

" }}}2
" }}}1
" {{{1 Filenames (\includegraphics)

let s:completer_img = {
      \ 'patterns' : ['\v\\includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*$'],
      \ 'ext_re' : '\v\.%('
      \   . join(['png', 'jpg', 'eps', 'pdf', 'pgf', 'tikz'], '|')
      \   . ')$',
      \}

function! s:completer_img.complete(regex) dict abort " {{{2
  return s:filter(self.gather_candidates(), a:regex)
endfunction

function! s:completer_img.gather_candidates() dict abort " {{{2
  let l:added_files = []
  let l:generated_pdf = b:vimtex.out()

  let l:candidates = []
  for l:path in b:vimtex.graphicspath + [b:vimtex.root]
    let l:files = globpath(l:path, '**/*.*', 1, 1)

    call filter(l:files,
          \ {_, x ->    x =~? self.ext_re
          \          && x !=# l:generated_pdf
          \          && index(l:added_files, x) < 0})

    let l:added_files += l:files
    let l:candidates += map(l:files, {_, x -> {
            \ 'abbr': vimtex#paths#shorten_relative(x),
            \ 'word': vimtex#paths#relative(x, l:path),
            \ 'kind': '[graphics]',
            \}})
  endfor

  return l:candidates
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
  call s:filter(self.candidates, a:regex)

  if self.context =~# '\\include'
    let self.candidates = map(self.candidates, {_, x -> {
          \ 'word': fnamemodify(x, ':r'),
          \ 'kind': '[include]',
          \}})
  else
    let self.candidates = map(self.candidates, {_, x -> {
          \ 'word': x,
          \ 'kind': '[input]',
          \}})
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
  call s:filter(self.candidates, a:regex)
  let self.candidates = map(self.candidates, {_, x -> {
        \ 'word': x,
        \ 'kind': '[includepdf]',
        \}})
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
  call s:filter(self.candidates, a:regex)
  let self.candidates = map(self.candidates, {_, x -> {
        \ 'word': x,
        \ 'kind': '[includestandalone]',
        \}})
  return self.candidates
endfunction

" }}}1
" {{{1 Glossary (\gls +++)

let s:completer_gls = {
      \ 'patterns' : [
      \   '\v\\([cpdr]?(gls|Gls|GLS)|acr|Acr|ACR)\a*\s*\{[^}]*$',
      \   '\v\\(ac|Ac|AC)\s*\{[^}]*$',
      \ ],
      \ 'key' : {
      \   'newglossaryentry' : ' [gls]',
      \   'longnewglossaryentry' : ' [gls]',
      \   'newacronym' : ' [acr]',
      \   'newabbreviation' : ' [abbr]',
      \   'glsxtrnewsymbol' : ' [symbol]',
      \ },
      \}

function! s:completer_gls.init() dict abort " {{{2
  if !has_key(b:vimtex.packages, 'glossaries-extra') | return | endif

  " Detect stuff like this:
  "  \GlsXtrLoadResources[src=glossary.bib]
  "  \GlsXtrLoadResources[src={glossary.bib}, selection={all}]
  "  \GlsXtrLoadResources[selection={all},src={glossary.bib}]
  "  \GlsXtrLoadResources[
  "    src={glossary.bib},
  "    selection={all},
  "  ]

  let l:do_search = 0
  for l:line in vimtex#parser#preamble(b:vimtex.tex)
    if line =~# '^\s*\\GlsXtrLoadResources\s*\['
      let l:do_search = 1
      let l:line = matchstr(l:line, '^\s*\\GlsXtrLoadResources\s*\[\zs.*')
    endif
    if !l:do_search | continue | endif

    let l:matches = split(l:line, '[=,]')
    if empty(l:matches) | continue | endif

    while !empty(l:matches)
      let l:key = vimtex#util#trim(remove(l:matches, 0))
      if l:key ==# 'src'
        let l:value = vimtex#util#trim(remove(l:matches, 0))
        let l:value = substitute(l:value, '^{', '', '')
        let l:value = substitute(l:value, '[]}]\s*', '', 'g')
        let b:vimtex.complete.glsbib = l:value
        break
      endif
    endwhile
  endfor
endfunction

function! s:completer_gls.complete(regex) dict abort " {{{2
  return s:filter(
        \ self.parse_glsentries() + self.parse_glsbib(), a:regex)
endfunction

function! s:completer_gls.parse_glsentries() dict abort " {{{2
  let l:candidates = []

  let l:re_commands = '\v\\(' . join(keys(self.key), '|') . ')'
  let l:re_matcher = l:re_commands . '\s*%(\[.*\])=\s*\{([^{}]*)'

  for l:line in filter(
        \ vimtex#parser#tex(b:vimtex.tex, {'detailed' : 0}),
        \ 'v:val =~# l:re_commands')
    let l:matches = matchlist(l:line, l:re_matcher)
    call add(l:candidates, {
          \ 'word' : l:matches[2],
          \ 'menu' : self.key[l:matches[1]],
          \})
  endfor

  return l:candidates
endfunction

function! s:completer_gls.parse_glsbib() dict abort " {{{2
  let l:filename = get(b:vimtex.complete, 'glsbib', '')
  if empty(l:filename) | return [] | endif

  let l:candidates = []
  for l:entry in vimtex#parser#bib(l:filename, {'backend': 'bibparse'})
    call add(l:candidates, {
          \ 'word': l:entry.key,
          \ 'menu': get(l:entry, 'name', '--'),
          \})
  endfor

  return l:candidates
endfunction

" }}}1
" {{{1 Packages (\usepackage)

let s:completer_pck = {
      \ 'patterns' : [
      \   '\v\\%(usepackage|RequirePackage)%(\s*\[[^]]*\])?\s*\{[^}]*$',
      \   '\v\\PassOptionsToPackage\s*\{[^}]*\}\s*\{[^}]*$',
      \ ],
      \ 'candidates' : [],
      \}

function! s:completer_pck.complete(regex) dict abort " {{{2
  return s:filter(self.gather_candidates(), a:regex)
endfunction

function! s:completer_pck.gather_candidates() dict abort " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('sty'), {_, x -> {
          \ 'word': x,
          \ 'kind': '[package]',
          \}})
  endif

  return copy(self.candidates)
endfunction

" }}}1
" {{{1 Documentclasses (\documentclass)

let s:completer_doc = {
      \ 'patterns' : ['\v\\documentclass%(\s*\[[^]]*\])?\s*\{[^}]*$'],
      \ 'candidates' : [],
      \}

function! s:completer_doc.complete(regex) dict abort " {{{2
  return s:filter(self.gather_candidates(), a:regex)
endfunction

function! s:completer_doc.gather_candidates() dict abort " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('cls'), {_, x -> {
          \ 'word' : x,
          \ 'kind' : '[documentclass]',
          \}})
  endif

  return copy(self.candidates)
endfunction

" }}}1
" {{{1 Bibliographystyles (\bibliographystyle)

let s:completer_bst = {
      \ 'patterns' : ['\v\\bibliographystyle\s*\{[^}]*$'],
      \ 'candidates' : [],
      \}

function! s:completer_bst.complete(regex) dict abort " {{{2
  return s:filter(self.gather_candidates(), a:regex)
endfunction

function! s:completer_bst.gather_candidates() dict abort " {{{2
  if empty(self.candidates)
    let self.candidates = map(s:get_texmf_candidates('bst'), {_, x -> {
          \ 'word' : x,
          \ 'kind' : '[bst files]',
          \}})
  endif

  return copy(self.candidates)
endfunction

" }}}1

"
" Functions to parse candidates from packages
"
function! s:get_packages() abort " {{{1
  let l:packages = [
        \   'default',
        \   'class-' . get(b:vimtex, 'documentclass', ''),
        \  ] + keys(b:vimtex.packages)

  call vimtex#paths#pushd(s:complete_dir)

  let l:missing = filter(copy(l:packages), '!filereadable(v:val)')
  call filter(l:packages, 'filereadable(v:val)')

  " Parse include statements in complete files
  let l:queue = copy(l:packages)
  while !empty(l:queue)
    let l:current = remove(l:queue, 0)
    let l:includes = filter(readfile(l:current), 'v:val =~# ''^\#\s*include:''')
    if empty(l:includes) | continue | endif

    call map(l:includes, {_, x -> matchstr(x, 'include:\s*\zs.*\ze\s*$')})
    let l:missing += filter(copy(l:includes),
          \ {_, x -> !filereadable(x) && index(l:missing, x) < 0})
    call filter(l:includes,
          \ {_, x -> filereadable(x) && index(l:packages, x) < 0})

    let l:packages += l:includes
    let l:queue += l:includes
  endwhile

  call vimtex#paths#popd()

  return l:packages + l:missing
endfunction

" }}}1
function! s:load_from_package(pkg, type) abort " {{{1
  let s:pkg_cache = get(s:, 'pkg_cache',
        \ vimtex#cache#open('pkgcomplete', {'default': {}}))
  let l:current = s:pkg_cache.get(a:pkg)

  let l:pkg_file = s:complete_dir . '/' . a:pkg
  if filereadable(l:pkg_file)
    if !has_key(l:current, 'candidates')
      let s:pkg_cache.modified = 1
      let l:current.candidates
            \ = s:_load_candidates_from_complete_file(a:pkg, l:pkg_file)
    endif
  else
    if !has_key(l:current, 'candidates')
      let s:pkg_cache.modified = 1
      let l:current.candidates = {'cmd': [], 'env': []}
    endif

    let l:filename = a:pkg =~# '^class-'
          \ ? vimtex#kpsewhich#find(a:pkg[6:] . '.cls')
          \ : vimtex#kpsewhich#find(a:pkg . '.sty')

    let l:ftime = getftime(l:filename)
    if l:ftime > get(l:current, 'ftime', -1)
      let s:pkg_cache.modified = 1
      let l:current.ftime = l:ftime
      let l:current.candidates = s:_load_candidates_from_source(
            \ readfile(l:filename), a:pkg)
    endif
  endif

  " Write cache to file
  call s:pkg_cache.write()

  return copy(l:current.candidates[a:type])
endfunction

" }}}1
function! s:load_from_document(type) abort " {{{1
  let s:pkg_cache = get(s:, 'pkg_cache',
        \ vimtex#cache#open('pkgcomplete', {'default': {}}))

  let l:ftime = b:vimtex.getftime()
  if l:ftime < 0 | return [] | endif

  let l:current = s:pkg_cache.get(sha256(b:vimtex.tex))
  if l:ftime > get(l:current, 'ftime', -1)
    let l:current.ftime = l:ftime
    let l:current.candidates = s:_load_candidates_from_source(
        \ vimtex#parser#tex(b:vimtex.tex, {'detailed' : 0}),
        \ 'local')

    " Write cache to file
    let s:pkg_cache.modified = 1
    call s:pkg_cache.write()
  endif

  return copy(l:current.candidates[a:type])
endfunction

" }}}1
function! s:_load_candidates_from_complete_file(pkg, pkgfile) abort " {{{1
  let l:result = {'cmd': [], 'env': []}
  let l:lines = readfile(a:pkgfile)

  let l:candidates = filter(copy(l:lines), 'v:val =~# ''^\a''')
  call map(l:candidates, 'split(v:val)')
  call map(l:candidates, {_, x -> {
        \ 'word': x[0],
        \ 'mode': '.',
        \ 'kind': '[cmd: ' . a:pkg . '] ',
        \ 'menu': get(x, 1, ''),
        \}})
  let l:result.cmd += l:candidates

  let l:candidates = filter(l:lines, 'v:val =~# ''^\\begin{''')
  call map(l:candidates, {_, x -> {
        \ 'word': substitute(x, '^\\begin{\|}$', '', 'g'),
        \ 'mode': '.',
        \ 'kind': '[env: ' . a:pkg . '] ',
        \}})
  let l:result.env += l:candidates

  return l:result
endfunction

" }}}1
function! s:_load_candidates_from_source(lines, pkg) abort " {{{1
  return {
        \ 'cmd':
        \   s:gather_candidates_from_newcommands(
        \     copy(a:lines), 'cmd: ' . a:pkg),
        \ 'env':
        \   s:gather_candidates_from_newenvironments(
        \     a:lines, 'env: ' . a:pkg)
        \}
endfunction

" }}}1

function! s:gather_candidates_from_newcommands(lines, label) abort " {{{1
  " Arguments:
  "   a:lines   Lines of TeX that may contain \newcommands (or some variant,
  "             e.g. as provided by xparse and standard declaration)
  "   a:label   Label to use in the menu

  let l:re = '\v\\%(%(provide|renew|new)command'
        \ . '|%(New|Declare|Provide|Renew)%(Expandable)?DocumentCommand)'
  let l:re_match = l:re . '\*?\{\\?\zs[^}]*'

  return map(filter(a:lines, 'v:val =~# l:re'), {_, x -> {
        \ 'word': matchstr(x, l:re_match),
        \ 'mode': '.',
        \ 'kind': '[' . a:label . ']',
        \}})
endfunction

" }}}1
function! s:gather_candidates_from_newenvironments(lines, label) abort " {{{1
  " Arguments:
  "   a:lines   Lines of TeX that may contain \newenvironments (or some
  "             variant, e.g. as provided by xparse and standard declaration)
  "   a:label   Label to use in the menu

  let l:re = '\v\\((renew|new)environment'
        \ . '|(New|Renew|Provide|Declare)DocumentEnvironment)'
  let l:re_match = l:re . '\*?\{\\?\zs[^}]*'

  return map(filter(a:lines, 'v:val =~# l:re'), {_, x -> {
        \ 'word': matchstr(x, l:re_match),
        \ 'mode': '.',
        \ 'kind': '[' . a:label . ']',
        \}})
endfunction

" }}}1


"
" Utility functions
"
function! s:filter(input, regex) abort " {{{1
  if empty(a:input) | return a:input | endif

  let l:ignore_case = g:vimtex_complete_ignore_case
        \ && (!g:vimtex_complete_smart_case || a:regex !~# '\u')

  if type(a:input[0]) == v:t_dict
    let l:Filter = l:ignore_case
          \ ? {_, x -> x.word =~? '^' . a:regex}
          \ : {_, x -> x.word =~# '^' . a:regex}
  else
    let l:Filter = l:ignore_case
          \ ? {_, x -> x =~? '^' . a:regex}
          \ : {_, x -> x =~# '^' . a:regex}
  endif

  return filter(a:input, l:Filter)
endfunction

" }}}1
function! s:filter_with_options(input, regex, opts) abort " {{{1
  if empty(a:input) | return a:input | endif

  let l:regex = (get(a:opts, 'anchor', 1) ? '^' : '') . a:regex

  let l:ignore_case = g:vimtex_complete_ignore_case
        \ && (!g:vimtex_complete_smart_case || a:regex !~# '\u')

  if type(a:input[0]) == v:t_dict
    let l:key = get(a:opts, 'filter_key', 'word')
    let l:Filter = l:ignore_case
          \ ? {_, x -> x[l:key] =~? l:regex}
          \ : {_, x -> x[l:key] =~# l:regex}
  else
    let l:Filter = l:ignore_case
          \ ? {_, x -> x =~? l:regex}
          \ : {_, x -> x =~# l:regex}
  endif

  return filter(a:input, l:Filter)
endfunction

" }}}1
function! s:get_texmf_candidates(filetype) abort " {{{1
  let l:candidates = []

  let l:texmfhome = $TEXMFHOME
  if empty(l:texmfhome)
    let l:texmfhome = get(vimtex#kpsewhich#run('--var-value TEXMFHOME'), 0, '')
  endif

  " Add locally installed candidates first
  if !empty(l:texmfhome)
    let l:candidates += glob(l:texmfhome . '/**/*.' . a:filetype, 0, 1)
    call map(l:candidates, "fnamemodify(v:val, ':t:r')")
  endif

  " Then add globally available candidates (based on ls-R files)
  for l:file in vimtex#kpsewhich#run('--all ls-R')
    let l:candidates += map(filter(readfile(l:file),
          \   {_, x -> x =~# '\.' . a:filetype}),
          \ "fnamemodify(v:val, ':r')")
  endfor

  return l:candidates
endfunction

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


"
" Initialize module
"
let s:completers = map(
      \ filter(items(s:), 'v:val[0] =~# ''^completer_'''),
      \ 'v:val[1]')

let s:complete_dir = fnamemodify(expand('<sfile>'), ':r') . '/'

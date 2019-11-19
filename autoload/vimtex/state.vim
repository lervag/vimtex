" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#state#init_buffer() abort " {{{1
  command! -buffer VimtexToggleMain  call vimtex#state#toggle_main()
  command! -buffer VimtexReloadState call vimtex#state#reload()

  nnoremap <buffer> <plug>(vimtex-toggle-main)  :VimtexToggleMain<cr>
  nnoremap <buffer> <plug>(vimtex-reload-state) :VimtexReloadState<cr>
endfunction

" }}}1
function! vimtex#state#init() abort " {{{1
  let l:main = s:get_main()
  let l:id = s:get_main_id(l:main)

  if l:id >= 0
    let b:vimtex_id = l:id
    let b:vimtex = s:vimtex_states[l:id]
  else
    let b:vimtex_id = s:vimtex_next_id
    let b:vimtex = s:vimtex.new(l:main, 0)
    let s:vimtex_next_id += 1
    let s:vimtex_states[b:vimtex_id] = b:vimtex
  endif
endfunction

" }}}1
function! vimtex#state#init_local() abort " {{{1
  let l:filename = expand('%:p')
  let l:preserve_root = get(s:, 'subfile_preserve_root')
  unlet! s:subfile_preserve_root

  if b:vimtex.tex ==# l:filename | return | endif

  let l:vimtex_id = s:get_main_id(l:filename)

  if l:vimtex_id < 0
    let l:vimtex_id = s:vimtex_next_id
    let l:vimtex = s:vimtex.new(l:filename, l:preserve_root)
    let s:vimtex_next_id += 1
    let s:vimtex_states[l:vimtex_id] = l:vimtex

    if !has_key(b:vimtex, 'subids')
      let b:vimtex.subids = []
    endif
    call add(b:vimtex.subids, l:vimtex_id)
    let l:vimtex.main_id = b:vimtex_id
  endif

  let b:vimtex_local = {
        \ 'active' : 0,
        \ 'main_id' : b:vimtex_id,
        \ 'sub_id' : l:vimtex_id,
        \}
endfunction

" }}}1
function! vimtex#state#reload() abort " {{{1
  let l:id = s:get_main_id(expand('%:p'))
  if has_key(s:vimtex_states, l:id)
    let l:vimtex = remove(s:vimtex_states, l:id)
    call l:vimtex.cleanup()
  endif

  if has_key(s:vimtex_states, get(b:, 'vimtex_id', -1))
    let l:vimtex = remove(s:vimtex_states, b:vimtex_id)
    call l:vimtex.cleanup()
  endif

  call vimtex#state#init()
  call vimtex#state#init_local()
endfunction

" }}}1

function! vimtex#state#toggle_main() abort " {{{1
  if exists('b:vimtex_local')
    let b:vimtex_local.active = !b:vimtex_local.active

    let b:vimtex_id = b:vimtex_local.active
          \ ? b:vimtex_local.sub_id
          \ : b:vimtex_local.main_id
    let b:vimtex = vimtex#state#get(b:vimtex_id)

    call vimtex#log#info('Changed to `' . b:vimtex.base . "' "
          \ . (b:vimtex_local.active ? '[local]' : '[main]'))
  endif
endfunction

" }}}1
function! vimtex#state#list_all() abort " {{{1
  return values(s:vimtex_states)
endfunction

" }}}1
function! vimtex#state#exists(id) abort " {{{1
  return has_key(s:vimtex_states, a:id)
endfunction

" }}}1
function! vimtex#state#get(id) abort " {{{1
  return s:vimtex_states[a:id]
endfunction

" }}}1
function! vimtex#state#cleanup(id) abort " {{{1
  if !vimtex#state#exists(a:id) | return | endif

  "
  " Count the number of open buffers for the given blob
  "
  let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:ids = map(l:buffers, 'getbufvar(v:val, ''vimtex_id'', -1)')
  let l:count = count(l:ids, a:id)

  "
  " Don't clean up if there are more than one buffer connected to the current
  " blob
  "
  if l:count > 1 | return | endif
  let l:vimtex = vimtex#state#get(a:id)

  "
  " Handle possible subfiles properly
  "
  if has_key(l:vimtex, 'subids')
    let l:subcount = 0
    for l:sub_id in get(l:vimtex, 'subids', [])
      let l:subcount += count(l:ids, l:sub_id)
    endfor
    if l:count + l:subcount > 1 | return | endif

    for l:sub_id in get(l:vimtex, 'subids', [])
      call remove(s:vimtex_states, l:sub_id).cleanup()
    endfor

    call remove(s:vimtex_states, a:id).cleanup()
  else
    call remove(s:vimtex_states, a:id).cleanup()

    if has_key(l:vimtex, 'main_id')
      let l:main = vimtex#state#get(l:vimtex.main_id)

      let l:count_main = count(l:ids, l:vimtex.main_id)
      for l:sub_id in get(l:main, 'subids', [])
        let l:count_main += count(l:ids, l:sub_id)
      endfor

      if l:count_main + l:count <= 1
        call remove(s:vimtex_states, l:vimtex.main_id).cleanup()
      endif
    endif
  endif
endfunction

" }}}1

function! s:get_main_id(main) abort " {{{1
  for [l:id, l:state] in items(s:vimtex_states)
    if l:state.tex == a:main
      return str2nr(l:id)
    endif
  endfor

  return -1
endfunction

function! s:get_main() abort " {{{1
  if exists('s:disabled_modules')
    unlet s:disabled_modules
  endif

  "
  " Use buffer variable if it exists
  "
  if exists('b:vimtex_main') && filereadable(b:vimtex_main)
    return fnamemodify(b:vimtex_main, ':p')
  endif

  "
  " Search for TEX root specifier at the beginning of file. This is used by
  " several other plugins and editors.
  "
  let l:candidate = s:get_main_from_texroot()
  if !empty(l:candidate)
    return l:candidate
  endif

  "
  " Check if the current file is a main file
  "
  if s:file_is_main(expand('%:p'))
    return expand('%:p')
  endif

  "
  " Support for subfiles package
  "
  let l:candidate = s:get_main_from_subfile()
  if !empty(l:candidate)
    return l:candidate
  endif

  "
  " Search for .latexmain-specifier
  "
  let l:candidate = s:get_main_latexmain(expand('%:p'))
  if !empty(l:candidate)
    return l:candidate
  endif

  "
  " Check if we are class or style file
  "
  if index(['cls', 'sty'], expand('%:e')) >= 0
    let l:id = getbufvar('#', 'vimtex_id', -1)
    if l:id >= 0
      return s:vimtex_states[l:id].tex
    else
      let s:disabled_modules = ['latexmk', 'view', 'toc']
      return expand('%:p')
    endif
  endif

  "
  " Search for main file recursively through include specifiers
  "
  if !get(g:, 'vimtex_disable_recursive_main_file_detection', 0)
    let l:candidate = s:get_main_choose(s:get_main_recurse())
    if !empty(l:candidate)
      return l:candidate
    endif
  endif

  "
  " Use fallback candidate or the current file
  "
  let l:candidate = get(s:, 'cand_fallback', expand('%:p'))
  if exists('s:cand_fallback')
    unlet s:cand_fallback
  endif
  return l:candidate
endfunction

" }}}1
function! s:get_main_from_texroot() abort " {{{1
  for l:line in getline(1, 5)
    let l:file_pattern = matchstr(l:line, g:vimtex#re#tex_input_root)
    if empty(l:file_pattern) | continue | endif

    if !vimtex#paths#is_abs(l:file_pattern)
      let l:file_pattern = simplify(expand('%:p:h') . '/' . l:file_pattern)
    endif

    let l:candidates = glob(l:file_pattern, 0, 1)
    if len(l:candidates) > 1
      return s:get_main_choose(l:candidates)
    elseif len(l:candidates) == 1
      return l:candidates[0]
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:get_main_from_subfile() abort " {{{1
  for l:line in getline(1, 5)
    let l:filename = matchstr(l:line,
          \ '^\C\s*\\documentclass\[\zs.*\ze\]{subfiles}')
    if len(l:filename) > 0
      if l:filename !~# '\.tex$'
        let l:filename .= '.tex'
      endif

      if vimtex#paths#is_abs(l:filename)
        " Specified path is absolute
        if filereadable(l:filename) | return l:filename | endif
      else
        " Try specified path as relative to current file path
        let l:candidate = simplify(expand('%:p:h') . '/' . l:filename)
        if filereadable(l:candidate) | return l:candidate | endif

        " Try specified path as relative to the project main file. This is
        " difficult, since the main file is the one we are looking for. We
        " therefore assume that the main file lives somewhere upwards in the
        " directory tree.
        let l:candidate = fnamemodify(findfile(l:filename, '.;'), ':p')
        if filereadable(l:candidate)
              \ && s:file_reaches_current(l:candidate)
          let s:subfile_preserve_root = 1
          return fnamemodify(candidate, ':p')
        endif

        " Check the alternate buffer. This seems sensible e.g. in cases where one
        " enters an "outer" subfile through a 'gf' motion from the main file.
        let l:vimtex = getbufvar('#', 'vimtex', {})
        for l:file in get(l:vimtex, 'sources', [])
          if expand('%:p') ==# simplify(l:vimtex.root . '/' . l:file)
            let s:subfile_preserve_root = 1
            return l:vimtex.tex
          endif
        endfor
      endif
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:get_main_latexmain(file) abort " {{{1
  for l:cand in s:findfiles_recursive('*.latexmain', expand('%:p:h'))
    let l:cand = fnamemodify(l:cand, ':p:r')
    if s:file_reaches_current(l:cand)
      return l:cand
    else
      let s:cand_fallback = l:cand
    endif
  endfor

  return ''
endfunction

function! s:get_main_recurse(...) abort " {{{1
  " Either start the search from the original file, or check if the supplied
  " file is a main file (or invalid)
  if a:0 == 0
    let l:file = expand('%:p')
    let l:tried = {}
  else
    let l:file = a:1
    let l:tried = a:2

    if s:file_is_main(l:file)
      return [l:file]
    elseif !filereadable(l:file)
      return []
    endif
  endif

  " Create list of candidates that was already tried for the current file
  if !has_key(l:tried, l:file)
    let l:tried[l:file] = [l:file]
  endif

  let l:re_filter = g:vimtex#re#tex_input
        \ . '\s*\f*' . fnamemodify(l:file, ':t:r')

  " Search through candidates found recursively upwards in the directory tree
  let l:results = []
  for l:cand in s:findfiles_recursive('*.tex', fnamemodify(l:file, ':p:h'))
    if index(l:tried[l:file], l:cand) >= 0 | continue | endif
    call add(l:tried[l:file], l:cand)

    if len(filter(readfile(l:cand), 'v:val =~# l:re_filter')) > 0
      let l:results += s:get_main_recurse(fnamemodify(l:cand, ':p'), l:tried)
    endif
  endfor

  return l:results
endfunction

" }}}1
function! s:get_main_choose(list) abort " {{{1
  let l:list = vimtex#util#uniq_unsorted(a:list)

  if empty(l:list) | return '' | endif
  if len(l:list) == 1 | return l:list[0] | endif

  let l:all = map(copy(l:list), '[s:get_main_id(v:val), v:val]')
  let l:new = map(filter(copy(l:all), 'v:val[0] < 0'), 'v:val[1]')
  let l:existing = {}
  for [l:key, l:val] in filter(copy(l:all), 'v:val[0] >= 0')
    let l:existing[l:key] = l:val
  endfor
  let l:alternate_id = getbufvar('#', 'vimtex_id', -1)

  if len(l:existing) == 1
    return values(l:existing)[0]
  elseif len(l:existing) > 1 && has_key(l:existing, l:alternate_id)
    return l:existing[l:alternate_id]
  elseif len(l:existing) < 1 && len(l:new) == 1
    return l:new[0]
  else
    let l:choices = {}
    for l:tex in l:list
      let l:choices[l:tex] = vimtex#paths#relative(l:tex, getcwd())
    endfor

    return vimtex#echo#choose(l:choices,
          \ 'Please select an appropriate main file:')
  endif
endfunction

" }}}1
function! s:file_is_main(file) abort " {{{1
  if !filereadable(a:file) | return 0 | endif

  "
  " Check if a:file is a main file by looking for the \documentclass command,
  " but ignore the following:
  "
  "   \documentclass[...]{subfiles}
  "   \documentclass[...]{standalone}
  "
  let l:lines = readfile(a:file, 0, 50)
  call filter(l:lines, 'v:val =~# ''\C\\documentclass\_\s*[\[{]''')
  call filter(l:lines, 'v:val !~# ''{subfiles}''')
  call filter(l:lines, 'v:val !~# ''{standalone}''')
  return len(l:lines) > 0
endfunction

" }}}1
function! s:file_reaches_current(file) abort " {{{1
  " Note: This function assumes that the input a:file is an absolute path
  if !filereadable(a:file) | return 0 | endif

  for l:line in filter(readfile(a:file), 'v:val =~# g:vimtex#re#tex_input')
    let l:file = matchstr(l:line, g:vimtex#re#tex_input . '\zs\f+')
    if empty(l:file) | continue | endif

    if !vimtex#paths#is_abs(l:file)
      let l:file = fnamemodify(a:file, ':h') . '/' . l:file
    endif

    if l:file !~# '\.tex$'
      let l:file .= '.tex'
    endif

    if expand('%:p') ==# l:file
          \ || s:file_reaches_current(l:file)
      return 1
    endif
  endfor

  return 0
endfunction

" }}}1
function! s:findfiles_recursive(expr, path) abort " {{{1
  let l:path = a:path
  let l:dirs = l:path
  while l:path != fnamemodify(l:path, ':h')
    let l:path = fnamemodify(l:path, ':h')
    let l:dirs .= ',' . l:path
  endwhile
  return split(globpath(fnameescape(l:dirs), a:expr), '\n')
endfunction

" }}}1

let s:vimtex = {}

function! s:vimtex.new(main, preserve_root) abort dict " {{{1
  let l:new = deepcopy(self)
  let l:new.tex  = a:main
  let l:new.root = fnamemodify(l:new.tex, ':h')
  let l:new.base = fnamemodify(l:new.tex, ':t')
  let l:new.name = fnamemodify(l:new.tex, ':t:r')

  if a:preserve_root && exists('b:vimtex')
    let l:new.root = b:vimtex.root
    let l:new.base = vimtex#paths#relative(a:main, l:new.root)
  endif

  if exists('s:disabled_modules')
    let l:new.disabled_modules = s:disabled_modules
  endif

  "
  " The preamble content is used to parse for the engine directive, the
  " documentclass and the package list; we store it as a temporary shared
  " object variable
  "
  let l:new.preamble = vimtex#parser#tex(l:new.tex, {
        \ 'detailed' : 0,
        \ 're_stop' : '\\begin\s*{document}',
        \ 'root' : l:new.root,
        \})

  call l:new.parse_tex_program()
  call l:new.parse_documentclass()
  call l:new.parse_graphicspath()
  call l:new.gather_sources()

  call vimtex#view#init_state(l:new)
  call vimtex#compiler#init_state(l:new)
  call vimtex#qf#init_state(l:new)
  call vimtex#toc#init_state(l:new)
  call vimtex#fold#init_state(l:new)

  " Parsing packages might depend on the compiler setting for build_dir
  call l:new.parse_packages()

  unlet l:new.preamble
  unlet l:new.new
  return l:new
endfunction

" }}}1
function! s:vimtex.cleanup() abort dict " {{{1
  if exists('self.compiler.cleanup')
    call self.compiler.cleanup()
  endif

  if exists('#User#VimtexEventQuit')
    if exists('b:vimtex')
      let b:vimtex_tmp = b:vimtex
    endif
    let b:vimtex = self
    doautocmd <nomodeline> User VimtexEventQuit
    if exists('b:vimtex_tmp')
      let b:vimtex = b:vimtex_tmp
      unlet b:vimtex_tmp
    else
      unlet b:vimtex
    endif
  endif

  " Close quickfix window
  cclose
endfunction

" }}}1
function! s:vimtex.parse_tex_program() abort dict " {{{1
  let l:lines = copy(self.preamble[:20])
  let l:tex_program_re =
        \ '\v^\c\s*\%\s*\!?\s*tex\s+%(TS-)?program\s*\=\s*\zs.*\ze\s*$'
  call map(l:lines, 'matchstr(v:val, l:tex_program_re)')
  call filter(l:lines, '!empty(v:val)')
  let self.tex_program = tolower(get(l:lines, -1, '_'))
endfunction

" }}}1
function! s:vimtex.parse_documentclass() abort dict " {{{1
  let self.documentclass = ''
  for l:line in self.preamble
    let l:class = matchstr(l:line, '^\s*\\documentclass.*{\zs\w*\ze}')
    if !empty(l:class)
      let self.documentclass = l:class
      break
    endif
  endfor
endfunction

" }}}1
function! s:vimtex.parse_graphicspath() abort dict " {{{1
  " Combine the preamble as one long string of commands
  let l:preamble = join(map(copy(self.preamble),
        \ 'substitute(v:val, ''\\\@<!%.*'', '''', '''')'))

  " Extract the graphicspath command from this string
  let l:graphicspath = matchstr(l:preamble,
          \ g:vimtex#re#not_bslash
          \ . '\\graphicspath\s*\{\s*\{\s*\zs.{-}\ze\s*\}\s*\}'
          \)

  " Add all parsed graphicspaths
  let self.graphicspath = []
  for l:path in split(l:graphicspath, '\s*}\s*{\s*')
    let l:path = substitute(l:path, '\/\s*$', '', '')
    call add(self.graphicspath, vimtex#paths#is_abs(l:path)
          \ ? l:path
          \ : simplify(self.root . '/' . l:path))
  endfor
endfunction

" }}}1
function! s:vimtex.parse_packages() abort dict " {{{1
  let self.packages = get(self, 'packages', {})

  " Try to parse .fls file if present, as it is usually more complete. That is,
  " it contains a generated list of all the packages that are used.
  for l:line in vimtex#parser#fls(self.fls())
    let l:package = matchstr(l:line, '^INPUT \zs.\+\ze\.sty$')
    let l:package = fnamemodify(l:package, ':t')
    if !empty(l:package)
      let self.packages[l:package] = {}
    endif
  endfor

  " Now parse preamble as well for usepackage and RequirePackage
  if !has_key(self, 'preamble') | return | endif
  let l:usepackages = filter(copy(self.preamble), 'v:val =~# ''\v%(usep|RequireP)ackage''')
  let l:pat = g:vimtex#re#not_comment . g:vimtex#re#not_bslash
      \ . '\v\\%(usep|RequireP)ackage\s*%(\[[^[\]]*\])?\s*\{\s*\zs%([^{}]+)\ze\s*\}'
  call map(l:usepackages, 'matchstr(v:val, l:pat)')
  call map(l:usepackages, 'split(v:val, ''\s*,\s*'')')

  for l:packages in l:usepackages
    for l:package in l:packages
      let self.packages[l:package] = {}
    endfor
  endfor
endfunction

" }}}1
function! s:vimtex.gather_sources() abort dict " {{{1
  let self.sources = []

  let self.sources = map(vimtex#parser#tex(self.tex, { 'root' : self.root }),
        \ 'v:val[0]')
  call map(vimtex#util#uniq_unsorted(self.sources),
        \ 'vimtex#paths#relative(v:val, self.root)')
endfunction

" }}}1
function! s:vimtex.pprint_items() abort dict " {{{1
  let l:items = [
        \ ['name', self.name],
        \ ['base', self.base],
        \ ['root', self.root],
        \ ['tex', self.tex],
        \ ['out', self.out()],
        \ ['log', self.log()],
        \ ['aux', self.aux()],
        \ ['fls', self.fls()],
        \]

  if self.tex_program !=# '_'
    call add(l:items, ['tex program', self.tex_program])
  endif

  if len(self.sources) >= 2
    call add(l:items, ['source files', self.sources])
  endif

  call add(l:items, ['compiler', get(self, 'compiler', {})])
  call add(l:items, ['viewer', get(self, 'viewer', {})])
  call add(l:items, ['qf', get(self, 'qf', {})])

  if exists('self.documentclass')
    call add(l:items, ['document class', self.documentclass])
  endif

  if !empty(self.packages)
    call add(l:items, ['packages', sort(keys(self.packages))])
  endif

  return [['vimtex project', l:items]]
endfunction

" }}}1
function! s:vimtex.log() abort dict " {{{1
  return self.ext('log')
endfunction

" }}}1
function! s:vimtex.aux() abort dict " {{{1
  return self.ext('aux')
endfunction

" }}}1
function! s:vimtex.fls() abort dict " {{{1
  return self.ext('fls')
endfunction

" }}}1
function! s:vimtex.out(...) abort dict " {{{1
  return call(self.ext, ['pdf'] + a:000, self)
endfunction

" }}}1
function! s:vimtex.ext(ext, ...) abort dict " {{{1
  " First check build dir (latexmk -output_directory option)
  if !empty(get(get(self, 'compiler', {}), 'build_dir', ''))
    let cand = self.compiler.build_dir . '/' . self.name . '.' . a:ext
    if !vimtex#paths#is_abs(self.compiler.build_dir)
      let cand = self.root . '/' . cand
    endif
    if a:0 > 0 || filereadable(cand)
      return fnamemodify(cand, ':p')
    endif
  endif

  " Next check for file in project root folder
  let cand = self.root . '/' . self.name . '.' . a:ext
  if a:0 > 0 || filereadable(cand)
    return fnamemodify(cand, ':p')
  endif

  " Finally return empty string if no entry is found
  return ''
endfunction

" }}}1


" Initialize module
let s:vimtex_states = {}
let s:vimtex_next_id = 0

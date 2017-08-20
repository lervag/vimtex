" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#state#init_buffer() " {{{1
  command! -buffer VimtexToggleMain call vimtex#state#toggle_main()
  nnoremap <buffer> <plug>(vimtex-toggle-main) :VimtexToggleMain<cr>
endfunction

" }}}1
function! vimtex#state#init() " {{{1
  let l:main = s:get_main()
  let l:id   = s:get_main_id(l:main)

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
function! vimtex#state#init_local() " {{{1
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

function! vimtex#state#toggle_main() " {{{1
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
function! vimtex#state#list_all() " {{{1
  return values(s:vimtex_states)
endfunction

" }}}1
function! vimtex#state#exists(id) " {{{1
  return has_key(s:vimtex_states, a:id)
endfunction

" }}}1
function! vimtex#state#get(id) " {{{1
  return s:vimtex_states[a:id]
endfunction

" }}}1
function! vimtex#state#cleanup(id) " {{{1
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

function! s:get_main_id(main) " {{{1
  for [l:id, l:state] in items(s:vimtex_states)
    if l:state.tex == a:main
      return str2nr(l:id)
    endif
  endfor

  return -1
endfunction

function! s:get_main() " {{{1
  if exists('s:disabled_modules')
    unlet s:disabled_modules
  endif

  "
  " Check if the current file is a main file
  "
  if s:file_is_main(expand('%:p'))
    return expand('%:p')
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
      let s:disabled_modules = ['latexmk', 'view', 'toc', 'labels']
      return expand('%:p')
    endif
  endif

  "
  " Search for main file recursively through include specifiers
  "
  if !get(g:, 'vimtex_disable_recursive_main_file_detection', 0)
    let l:candidate = s:get_main_recurse()
    if l:candidate !=# ''
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
function! s:get_main_from_texroot() " {{{1
  for l:line in getline(1, 5)
    let l:filename = matchstr(l:line,
          \ '^\c\s*%\s*!\?\s*tex\s\+root\s*=\s*\zs.*\ze\s*$')
    if len(l:filename) > 0
      if l:filename[0] ==# '/'
        if filereadable(l:filename) | return l:filename | endif
      else
        let l:candidate = simplify(expand('%:p:h') . '/' . l:filename)
        if filereadable(l:candidate) | return l:candidate | endif
      endif
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:get_main_from_subfile() " {{{1
  for l:line in getline(1, 5)
    let l:filename = matchstr(l:line,
          \ '^\C\s*\\documentclass\[\zs.*\ze\]{subfiles}')
    if len(l:filename) > 0
      if l:filename[0] ==# '/'
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
        let l:candidate = findfile(l:filename, '.;')
        if filereadable(l:candidate)
          let s:subfile_preserve_root = 1
          return fnamemodify(candidate, ':p')
        endif
      endif
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:get_main_latexmain(file) " {{{1
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

function! s:get_main_recurse(...) " {{{1
  " Either start the search from the original file, or check if the supplied
  " file is a main file (or invalid)
  if a:0 == 0
    let l:file = expand('%:p')
    let l:tried = {}
  else
    let l:file = a:1
    let l:tried = a:2

    if s:file_is_main(l:file)
      return l:file
    elseif !filereadable(l:file)
      return ''
    endif
  endif

  " Create list of candidates that was already tried for the current file
  if !has_key(l:tried, l:file)
    let l:tried[l:file] = [l:file]
  endif

  " Search through candidates found recursively upwards in the directory tree
  for l:cand in s:findfiles_recursive('*.tex', fnamemodify(l:file, ':p:h'))
    if index(l:tried[l:file], l:cand) >= 0 | continue | endif
    call add(l:tried[l:file], l:cand)

    let l:filter_re = g:vimtex#re#tex_input
          \ . '\s*((.*)\/)?' . fnamemodify(l:file, ':t:r')

    if len(filter(readfile(l:cand), 'v:val =~# l:filter_re')) > 0
      let l:res = s:get_main_recurse(fnamemodify(l:cand, ':p'), l:tried)
      if !empty(l:res) | return l:res | endif
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:file_is_main(file) " {{{1
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
function! s:file_reaches_current(file) " {{{1
  if !filereadable(a:file) | return 0 | endif

  for l:line in readfile(a:file)
    let l:file = matchstr(l:line, g:vimtex#re#tex_input . '\zs\f+')
    if empty(l:file) | continue | endif

    if l:file[0] !=# '/'
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
function! s:findfiles_recursive(expr, path) " {{{1
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
    let l:new.base = strpart(a:main, len(b:vimtex.root) + 1)
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

  call l:new.parse_engine()
  call l:new.parse_documentclass()
  call l:new.gather_sources()

  call vimtex#view#init_state(l:new)
  call vimtex#compiler#init_state(l:new)
  call vimtex#qf#init_state(l:new)
  call vimtex#toc#init_state(l:new)
  call vimtex#labels#init_state(l:new)
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
function! s:vimtex.parse_engine() abort dict " {{{1
  let l:engine_regex =
        \ '\v^\c\s*\%\s*\!?\s*tex\s+%(TS-)?program\s*\=\s*\zs.*\ze\s*$'
  let l:engine_list = {
        \ 'pdflatex'         : '',
        \ 'lualatex'         : '-lualatex',
        \ 'xelatex'          : '-xelatex',
        \ 'context (pdftex)' : '-pdflatex=texexec',
        \ 'context (luatex)' : '-pdflatex=context',
        \ 'context (xetex)'  : '-pdflatex=''texexec --xtx''',
        \}

  let l:engines = copy(self.preamble[:20])
  call map(l:engines, 'matchstr(v:val, l:engine_regex)')
  call filter(l:engines, '!empty(v:val)')

  let self.engine = get(l:engine_list, tolower(get(l:engines, -1, 'pdflatex')),
        \ get(get(b:, 'vimtex', {}), 'engine', ''))
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
function! s:vimtex.parse_packages() abort dict " {{{1
  let self.packages = {}

  call self.parse_packages_from_fls()
  if !empty(self.packages) | return | endif

  let l:pat = g:vimtex#re#not_comment . g:vimtex#re#not_bslash
      \ . '\v\\usepackage\s*%(\[[^[\]]*\])?\s*\{\s*\zs%([^{}]+)\ze\s*\}'

  let l:usepackages = filter(copy(self.preamble), 'v:val =~# ''usepackage''')
  call map(l:usepackages, 'matchstr(v:val, l:pat)')
  call map(l:usepackages, 'split(v:val, ''\s*,\s*'')')

  for l:packages in l:usepackages
    for l:package in l:packages
      let self.packages[l:package] = {}
    endfor
  endfor
endfunction

" }}}1
function! s:vimtex.parse_packages_from_fls() abort dict " {{{1
  "
  " The .fls file contains a generated list of all the packages that are used,
  " and as such it is a better way of parsing for packages then reading the
  " preamble.
  "
  let l:fls = self.fls()
  if empty(l:fls) | return | endif

  let l:fls_packages = {}

  for l:line in vimtex#parser#fls(l:fls)
    let l:package = matchstr(l:line, '^INPUT \zs.\+\ze\.sty$')
    let l:package = fnamemodify(l:package, ':t')
    if !empty(l:package)
      let l:fls_packages[l:package] = {}
    endif
  endfor

  if !empty(l:fls_packages)
    let self.packages = l:fls_packages
  endif
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

  if !empty(self.engine)
    call add(l:items, ['engine', self.engine])
  endif

  if len(self.sources) >= 2
    call add(l:items, ['source files', self.sources])
  endif

  if exists('self.documentclass')
    call add(l:items, ['document class', self.documentclass])
  endif

  if !empty(self.packages)
    call add(l:items, ['packages', sort(keys(self.packages))])
  endif

  call add(l:items, ['compiler', get(self, 'compiler', {})])
  call add(l:items, ['viewer', get(self, 'viewer', {})])
  call add(l:items, ['qf', get(self, 'qf', {})])

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
    if self.compiler.build_dir[0] !=# '/'
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

" vim: fdm=marker sw=2

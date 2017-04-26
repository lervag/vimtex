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
    let b:vimtex = s:vimtex.new(l:main)
    let s:vimtex_next_id += 1
    let s:vimtex_states[b:vimtex_id] = b:vimtex

    call vimtex#view#init_state(b:vimtex)
    call vimtex#compiler#init_state(b:vimtex)
    call vimtex#qf#init_state(b:vimtex)
    call vimtex#toc#init_state(b:vimtex)
  endif
endfunction

" }}}1
function! vimtex#state#init_local() " {{{1
  let l:filename = expand('%:p')
  if b:vimtex.tex ==# l:filename | return | endif

  let l:vimtex_id = s:get_main_id(l:filename)

  if l:vimtex_id < 0
    let l:vimtex_id = s:vimtex_next_id
    let l:vimtex = s:vimtex.new(l:filename)
    let s:vimtex_next_id += 1
    let s:vimtex_states[l:vimtex_id] = l:vimtex

    if get(s:, 'subfile_preserve_root')
      let l:vimtex.root = b:vimtex.root
      let l:vimtex.base = strpart(expand('%:p'), len(b:vimtex.root) + 1)
      unlet s:subfile_preserve_root
    endif

    call vimtex#view#init_state(l:vimtex)
    call vimtex#compiler#init_state(l:vimtex)
    call vimtex#qf#init_state(l:vimtex)
    call vimtex#toc#init_state(l:vimtex)
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

    call vimtex#echo#status(['vimtex: ',
          \ ['Normal', 'Changed to `'],
          \ ['VimtexSuccess', b:vimtex.base],
          \ ['Normal', "' "],
          \ ['VimtexInfo', b:vimtex_local.active ? '[local]' : '[main]' ]])
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
  let l:vimtex = s:vimtex_states[a:id]
  call l:vimtex.cleanup()
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
      let s:disabled_modules = ['latexmk', 'view', 'toc']
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
  " Fallback to the current file
  "
  return expand('%:p')
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
    endif
  endfor

  return ''
endfunction

function! s:get_main_recurse(...) " {{{1
  "
  " Either start the search from the original file, or check if the supplied
  " file is a main file (or invalid)
  "
  if a:0 == 0
    let l:file = expand('%:p')
  else
    let l:file = a:1

    if s:file_is_main(l:file)
      return l:file
    elseif !filereadable(l:file)
      return ''
    endif
  endif

  "
  " Search through candidates found recursively upwards in the directory tree
  "
  for l:cand in s:findfiles_recursive('*.tex', fnamemodify(l:file, ':p:h'))
    " Avoid infinite recursion (checking the same file repeatedly)
    if l:cand == l:file | continue | endif

    let l:file_re = '\s*((.*)\/)?' . fnamemodify(l:file, ':t:r')

    let l:filter  = 'v:val =~# ''\v'
    let l:filter .= '\\%(input|include)\{' . l:file_re
    let l:filter .= '|\\subimport\{[^\}]*\}\{' . l:file_re
    let l:filter .= ''''

    if len(filter(readfile(l:cand), l:filter)) > 0
      return s:get_main_recurse(fnamemodify(l:cand, ':p'))
    endif
  endfor
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
    let l:file = matchstr(l:line,
          \ '\v\\%(input|include|subimport\{[^\}]*\})\s*\{\zs\f+')
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

function! s:vimtex.new(main) abort dict " {{{1
  let l:new = deepcopy(self)
  let l:new.tex  = a:main
  let l:new.root = fnamemodify(l:new.tex, ':h')
  let l:new.base = fnamemodify(l:new.tex, ':t')
  let l:new.name = fnamemodify(l:new.tex, ':t:r')

  if exists('s:disabled_modules')
    let l:new.disabled_modules = s:disabled_modules
  endif

  call l:new.parse_engine()
  call l:new.parse_preamble()
  call l:new.gather_sources()

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
    doautocmd User VimtexEventQuit
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

  let self.engine = ''

  for l:line in vimtex#parser#tex(self.tex, {
        \ 'detailed' : 0,
        \ 're_stop' : '\\begin\s*{document}',
        \ 'root' : self.root,
        \})
    let l:engine = matchstr(l:line, l:engine_regex)
    if !empty(l:engine)
      let self.engine = get(l:engine_list, tolower(l:engine), '')
      continue
    endif
  endfor
endfunction

" }}}1
function! s:vimtex.parse_preamble() abort dict " {{{1
  let self.packages = {}

  for l:line in vimtex#parser#tex(self.tex, {
        \ 'detailed' : 0,
        \ 're_stop' : '\\begin\s*{document}',
        \ 'root' : self.root,
        \})
    let l:class = matchstr(l:line, '^\s*\\documentclass.*{\zs\w*\ze}')
    if !empty(l:class)
      let self.documentclass = l:class
      continue
    endif

    let l:package = matchstr(l:line, '^\s*\\usepackage.*{\zs\w*\ze}')
    if !empty(l:package)
      let self.packages[l:package] = {}
      continue
    endif
  endfor
endfunction

" }}}1
function! s:vimtex.gather_sources() abort dict " {{{1
  let self.sources = []

  for [l:file, l:lnum, l:line] in vimtex#parser#tex(self.tex, {
        \ 'root' : self.root,
        \})
    let l:cand = substitute(l:file, '\M' . self.root, '', '')
    if l:cand[0] ==# '/' | let l:cand = l:cand[1:] | endif

    if index(self.sources, l:cand) < 0
      call add(self.sources, l:cand)
    endif
  endfor
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
        \]

  if !empty(self.engine)
    call add(l:items, ['engine', self.engine])
  endif

  if len(self.sources) >= 2
    call add(l:items, ['source files', self.sources])
  endif

  if !empty(self.packages)
    call add(l:items, ['packages', keys(self.packages)])
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

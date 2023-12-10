" VimTeX - LaTeX plugin for Vim
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
  let [l:main, l:main_parser, l:unsupported_modules] = s:get_main()
  let l:id = s:get_main_id(l:main)

  if exists('s:cand_fallback')
    call vimtex#log#warning(
          \ 'Ignored latexmain specifier which points to: ',
          \ s:cand_fallback,
          \ 'Reason: That main file did not include this file!',
          \)
    unlet s:cand_fallback
  endif

  if l:id >= 0
    let b:vimtex_id = l:id
    let b:vimtex = s:vimtex_states[l:id]
  else
    let b:vimtex_id = s:vimtex_next_id
    let b:vimtex = vimtex#state#class#new({
          \ 'main': l:main,
          \ 'main_parser': l:main_parser,
          \ 'unsupported_modules': l:unsupported_modules
          \})
    let s:vimtex_next_id += 1
    let s:vimtex_states[b:vimtex_id] = b:vimtex
  endif
endfunction

" }}}1
function! vimtex#state#init_local() abort " {{{1
  let l:preserve_root = get(s:, 'subfile_preserve_root')
  unlet! s:subfile_preserve_root

  if &filetype !=# 'tex' || empty(b:vimtex.tex) | return | endif

  let l:filename = expand('%:p')
  if b:vimtex.tex ==# l:filename | return | endif

  let l:vimtex_id = s:get_main_id(l:filename)

  if l:vimtex_id < 0
    let l:vimtex_id = s:vimtex_next_id
    let l:vimtex = vimtex#state#class#new({
          \ 'main': l:filename,
          \ 'main_parser': 'local file',
          \ 'preserve_root': l:preserve_root || s:check_standalone(),
          \})
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

  if b:vimtex.main_parser ==# 'subfiles' && g:vimtex_subfile_start_local
    silent call vimtex#state#toggle_main()
  endif
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
function! vimtex#state#get_all() abort " {{{1
  return s:vimtex_states
endfunction

" }}}1
function! vimtex#state#cleanup(id) abort " {{{1
  if !vimtex#state#exists(a:id) | return | endif

  "
  " Count the number of open buffers for the given blob
  "
  let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:ids = map(l:buffers, "getbufvar(v:val, 'vimtex_id', -1)")
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
  " Use buffer variable if it exists
  if exists('b:vimtex_main') && filereadable(b:vimtex_main)
    return [fnamemodify(b:vimtex_main, ':p'), 'buffer variable', []]
  endif

  " Search for TEX root specifier at the beginning of file. This is used by
  " several other plugins and editors.
  let l:candidate = s:get_main_from_texroot()
  if !empty(l:candidate)
    return [l:candidate, 'texroot specifier', []]
  endif

  if &filetype ==# 'tex'
    " Check if the current file is a main file
    if s:file_is_main(expand('%:p'))
      return [expand('%:p'), 'current file verified', []]
    endif

    " Support for subfiles package
    let l:candidate = s:get_main_from_subfile()
    if !empty(l:candidate)
      return [l:candidate, 'subfiles', []]
    endif
  endif

  " Search for .latexmain-specifier
  let l:candidate = s:get_main_latexmain(expand('%:p'))
  if !empty(l:candidate)
    return [l:candidate, 'latexmain specifier', []]
  endif

  " Search for .latexmkrc @default_files specifier
  let l:candidate = s:get_main_latexmk()
  if !empty(l:candidate)
    return [l:candidate, 'latexmkrc @default_files', []]
  endif

  " Check if we are class or style file
  if index(['cls', 'sty'], expand('%:e')) >= 0
    let l:id = getbufvar('#', 'vimtex_id', -1)
    if l:id >= 0 && has_key(s:vimtex_states, l:id)
      return [
            \ s:vimtex_states[l:id].tex,
            \ 'cls/sty file (inherit from alternate)',
            \ []
            \]
    else
      return [
            \ expand('%:p'),
            \ 'cls/sty file',
            \ ['compiler', 'view', 'toc', 'qf']
            \]
    endif
  endif

  " Search for main file recursively through include specifiers
  if &filetype ==# 'tex'
    let l:candidate = s:get_main_choose(s:get_main_recurse())
    if !empty(l:candidate)
      return [l:candidate, 'recursive search', []]
    endif
  else
    let l:candidate = s:get_main_choose(s:get_main_recurse_from_bib())
    if !empty(l:candidate)
      return [l:candidate, 'recursive search (bib)', []]
    endif
  endif

  " Fallbacks:
  " 1.  fallback candidate from get_main_latexmain
  " 2. a. tex: current file
  "    b. bib: check alternate file or current
  if exists('s:cand_fallback')
    let l:candidate = s:cand_fallback
    unlet s:cand_fallback
    return [l:candidate, 'fallback', []]
  elseif &filetype ==# 'bib'
    let l:id = getbufvar('#', 'vimtex_id', -1)
    if l:id >= 0 && has_key(s:vimtex_states, l:id)
      return [
            \ s:vimtex_states[l:id].tex,
            \ 'bib file (inherit from alternate)',
            \ []
            \]
    else
      return [
            \ expand('%:p'),
            \ 'bib file',
            \ ['compiler', 'view', 'toc', 'qf', 'fold']
            \]
    endif
  else
    return [expand('%:p'), 'fallback current file', []]
  endif
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
  for l:cand in s:globpath_upwards('*.latexmain', expand('%:p:h'))
    let l:cand = fnamemodify(l:cand, ':p:r')
    if s:file_reaches_current(l:cand)
      return l:cand
    else
      let s:cand_fallback = l:cand
    endif
  endfor

  return ''
endfunction

function! s:get_main_latexmk() abort " {{{1
  let l:root = expand('%:p:h')
  let l:results = vimtex#compiler#latexmk#get_rc_opt(
        \ l:root, 'default_files', 2, [])
  if l:results[1] < 1 | return '' | endif

  for l:candidate in l:results[0]
    let l:file = l:root . '/' . l:candidate
    if filereadable(l:file)
      return l:file
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

  " Apply filters successively (minor optimization)
  let l:re_filter1 = fnamemodify(l:file, ':t:r')
  let l:re_filter2 = g:vimtex#re#tex_input . '\s*\f*' . l:re_filter1

  " Search through candidates found upwards in the directory tree
  let l:results = []
  for l:cand in s:globpath_upwards('*.tex', fnamemodify(l:file, ':p:h'))
    if index(l:tried[l:file], l:cand) >= 0 | continue | endif
    call add(l:tried[l:file], l:cand)

    if len(filter(filter(readfile(l:cand),
          \ 'v:val =~# l:re_filter1'),
          \ 'v:val =~# l:re_filter2')) > 0
      let l:results += s:get_main_recurse(fnamemodify(l:cand, ':p'), l:tried)
    endif
  endfor

  return l:results
endfunction

" }}}1
function! s:get_main_recurse_from_bib() abort " {{{1
  let l:file = expand('%:p')
  let l:tried = {}
  let l:tried[l:file] = [l:file]

  " Apply filters successively (minor optimization)
  let l:re_filter1 = fnamemodify(l:file, ':t:r')
  let l:re_filter2 = g:vimtex#re#bib_input . '\s*\f*' . l:re_filter1

  " Search through candidates found upwards in the directory tree
  let l:results = []
  for l:cand in s:globpath_upwards('*.tex', fnamemodify(l:file, ':p:h'))
    if index(l:tried[l:file], l:cand) >= 0 | continue | endif
    call add(l:tried[l:file], l:cand)

    if len(filter(filter(readfile(l:cand),
          \ 'v:val =~# l:re_filter1'),
          \ 'v:val =~# l:re_filter2')) > 0
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

  let l:all = map(copy(l:list), {_, x -> [s:get_main_id(x), x]})
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

    unsilent return vimtex#ui#select(l:choices, {
          \ 'prompt': 'Please select an appropriate main file:',
          \ 'return': 'key',
          \ 'force_choice': v:true,
          \})
  endif
endfunction

" }}}1

function! s:file_is_main(file) abort " {{{1
  if !filereadable(a:file) | return 0 | endif

  let l:preamble = vimtex#parser#preamble(a:file, {
        \ 'root' : fnamemodify(a:file, ':p:h'),
        \})

  " Check if a:file is a main file by looking for the \documentclass command,
  " but ignore the following:
  " * \documentclass[...]{subfiles}
  " * \documentclass[...]{standalone}
  let l:lines = copy(l:preamble)
  call filter(l:lines, 'v:val =~# ''^\s*\\documentclass\_\s*[\[{]''')
  call filter(l:lines, 'v:val !~# ''{subfiles}''')
  call filter(l:lines, 'v:val !~# ''{standalone}''')
  if len(l:lines) == 0 | return 0 | endif

  " A main file must also contain `\begin{document}`
  let l:lines = copy(l:preamble)
  call filter(l:lines, 'v:val =~# ''^\s*\\begin\s*{document}''')
  return len(l:lines) > 0
endfunction

" }}}1
function! s:file_reaches_current(file, ...) abort " {{{1
  let l:visited = a:0 > 0 ? a:1 : []

  " Note: This function assumes that the input a:file is an absolute path
  if !filereadable(a:file) | return 0 | endif

  if index(l:visited, a:file) >= 0 | return 0 | endif
  call add(l:visited, a:file)

  for l:line in filter(readfile(a:file), 'v:val =~# g:vimtex#re#tex_input')
    let l:file = vimtex#parser#tex#input_parser(l:line, a:file, '')
    if empty(l:file) | continue | endif

    if !vimtex#paths#is_abs(l:file)
      let l:file = fnamemodify(a:file, ':h') . '/' . l:file
    endif

    if l:file !~# '\.tex$'
      let l:file .= '.tex'
    endif

    if expand('%:p') ==# l:file || s:file_reaches_current(l:file, l:visited)
      return 1
    endif
  endfor

  return 0
endfunction

" }}}1
function! s:globpath_upwards(expr, path) abort " {{{1
  " Returns the list of files (NOT directories) obtained by globpath(p, a:expr)
  " with p going from a:path and upwards in the directory tree.
  let l:path = a:path
  let l:dirs = l:path
  while l:path != fnamemodify(l:path, ':h')
    let l:path = fnamemodify(l:path, ':h')
    let l:dirs .= ',' . l:path
  endwhile
  return filter(
        \ split(globpath(fnameescape(l:dirs), a:expr), '\n'),
        \ 'filereadable(v:val)')
endfunction

" }}}1

function! s:check_standalone() abort " {{{1
  return match(getline(1, 5),
        \      '\v^\C\s*\\documentclass%(\[.*\])?\{standalone\}') >= 0
endfunction

" }}}1


" Initialize module
let s:vimtex_states = {}
let s:vimtex_next_id = 0

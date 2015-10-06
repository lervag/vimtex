" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" {{{1 Initialization variables

"
" The flag s:initialized is set to 1 after vimtex has been initialized to
" prevent errors if the scripts are loaded more than once (e.g. when opening
" more than one LaTeX buffer in one vim instance).  Thus it allows us to
" distinguish between global initialization and buffer initialization.
"
if !exists('s:initialized')
  let s:initialized = 0
endif

"
" Define list of vimtex modules
"
if !exists('s:modules')
  let s:modules = map(
        \ split(
        \   globpath(
        \     fnamemodify(expand('<sfile>'), ':r'),
        \     '*.vim'),
        \   '\n'),
        \ 'fnamemodify(v:val, '':t:r'')')
endif

" }}}1

"
" Main initialization function
"
function! vimtex#init() " {{{1
  "
  " First initialize buffer options and construct (if necessary) the vimtex
  " data blob.
  "
  call s:init_buffer()

  "
  " Then we initialize the modules.  This is done in three steps:
  "
  " 1. Initialize options (load default options if not otherwise set).  This is
  "    only done once for each vim session.
  "
  " 2. Initialize module scripts (set script variables and similar).  This is
  "    also only done once for each vim session.
  "
  " 3. Initialize module for current buffer.  This is done for each new LaTeX
  "    buffer.
  "
  if !s:initialized
    call s:init_modules('options')
    call s:init_modules('script')
  endif
  call s:init_modules('buffer')

  "
  " Finally we create the mappings
  "
  call s:init_mappings()

  let s:initialized = 1
endfunction

" }}}1

"
" Auxilliary initialization functions
"
function! s:init_buffer() " {{{1
  "
  " First we set some vim options
  "
  let s:save_cpo = &cpo
  set cpo&vim

  " Ensure tex files are prioritized when listing files
  for suf in [
        \ '.log',
        \ '.aux',
        \ '.bbl',
        \ '.out',
        \ '.blg',
        \ '.brf',
        \ '.cb',
        \ '.dvi',
        \ '.fdb_latexmk',
        \ '.fls',
        \ '.idx',
        \ '.ilg',
        \ '.ind',
        \ '.inx',
        \ '.pdf',
        \ '.synctex.gz',
        \ '.toc',
        \ ]
    execute 'set suffixes+=' . suf
  endfor

  setlocal suffixesadd=.tex
  setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
  setlocal commentstring=%%s

  let &l:define  = '\\\([egx]\|char\|mathchar\|count\|dimen\|muskip\|skip'
  let &l:define .= '\|toks\)\=def\|\\font\|\\\(future\)\=let'
  let &l:define .= '\|\\new\(count\|dimen\|skip'
  let &l:define .= '\|muskip\|box\|toks\|read\|write\|fam\|insert\)'
  let &l:define .= '\|\\\(re\)\=new\(boolean\|command\|counter\|environment'
  let &l:define .= '\|font\|if\|length\|savebox'
  let &l:define .= '\|theorem\(style\)\=\)\s*\*\=\s*{\='
  let &l:define .= '\|DeclareMathOperator\s*{\=\s*'

  let &l:include = '\\\(input\|include\){'
  let &l:includeexpr  = 'substitute('
  let &l:includeexpr .=   "substitute(v:fname, '\\\\space', '', 'g'),"
  let &l:includeexpr .=   "'^.\\{-}{\"\\?\\|\"\\?}.*', '', 'g')"

  let &cpo = s:save_cpo
  unlet s:save_cpo

  "
  " Next we initialize the data blob
  "

  " Create container for data blobs if it does not exist
  let g:vimtex_data = get(g:, 'vimtex_data', [])

  " Get main file number and check if data blob already exists
  let main = s:get_main()
  let id   = s:get_id(main)
  if id >= 0
    " Link to existing blob
    let b:vimtex_id = id
    let b:vimtex = g:vimtex_data[id]
  else
    " Create new blob
    let b:vimtex = {}
    let b:vimtex.tex  = main
    let b:vimtex.root = fnamemodify(b:vimtex.tex, ':h')
    let b:vimtex.base = fnamemodify(b:vimtex.tex, ':t')
    let b:vimtex.name = fnamemodify(b:vimtex.tex, ':t:r')
    function b:vimtex.aux() dict
      return s:get_main_ext(self, 'aux')
    endfunction
    function b:vimtex.log() dict
      return s:get_main_ext(self, 'log')
    endfunction
    function b:vimtex.out() dict
      return s:get_main_ext(self, 'pdf')
    endfunction

    call add(g:vimtex_data, b:vimtex)
    let b:vimtex_id = len(g:vimtex_data) - 1
  endif

  "
  " Define commands and mappings
  "

  " Define commands
  command! -buffer -bang VimtexInfo      call vimtex#info(<q-bang> == "!")
  command! -buffer -bang VimtexWordCount call vimtex#wordcount(<q-bang> == "!")

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-info) :call vimtex#info(0)<cr>

  "
  " Attach autocommands
  "

  augroup vimtex
    au!
    au BufFilePre  <buffer> call s:filename_changed_pre()
    au BufFilePost <buffer> call s:filename_changed_post()
  augroup END
endfunction

" }}}1
function! s:init_mappings() " {{{1
  if !get(g:,'vimtex_mappings_enabled', 1) | return | endif

  nmap <silent><buffer> <localleader>li <plug>(vimtex-info)

  nmap <silent><buffer> dse  <plug>(vimtex-delete-env)
  nmap <silent><buffer> dsc  <plug>(vimtex-delete-cmd)
  nmap <silent><buffer> cse  <plug>(vimtex-change-env)
  nmap <silent><buffer> csc  <plug>(vimtex-change-cmd)
  nmap <silent><buffer> tse  <plug>(vimtex-toggle-star)
  nmap <silent><buffer> tsd  <plug>(vimtex-toggle-delim)
  nmap <silent><buffer> <F7> <plug>(vimtex-create-cmd)
  imap <silent><buffer> <F7> <plug>(vimtex-create-cmd)
  imap <silent><buffer> ]]   <plug>(vimtex-close-env)

  if g:vimtex_latexmk_enabled
    nmap <silent><buffer> <localleader>ll <plug>(vimtex-compile-toggle)
    nmap <silent><buffer> <localleader>lo <plug>(vimtex-compile-output)
    nmap <silent><buffer> <localleader>lk <plug>(vimtex-stop)
    nmap <silent><buffer> <localleader>lK <plug>(vimtex-stop-all)
    nmap <silent><buffer> <localleader>le <plug>(vimtex-errors)
    nmap <silent><buffer> <localleader>lc <plug>(vimtex-clean)
    nmap <silent><buffer> <localleader>lC <plug>(vimtex-clean-full)
    nmap <silent><buffer> <localleader>lg <plug>(vimtex-status)
    nmap <silent><buffer> <localleader>lG <plug>(vimtex-status-all)
  endif

  if g:vimtex_motion_enabled
    nmap <silent><buffer> %  <plug>(vimtex-%)
    xmap <silent><buffer> %  <plug>(vimtex-%)
    omap <silent><buffer> %  <plug>(vimtex-%)
    nmap <silent><buffer> }  <plug>(vimtex-})
    nmap <silent><buffer> {  <plug>(vimtex-{)
    xmap <silent><buffer> }  <plug>(vimtex-})
    xmap <silent><buffer> {  <plug>(vimtex-{)
    omap <silent><buffer> }  <plug>(vimtex-})
    omap <silent><buffer> {  <plug>(vimtex-{)
    xmap <silent><buffer> ip <plug>(vimtex-ip)
    xmap <silent><buffer> ap <plug>(vimtex-ap)
    omap <silent><buffer> ip <plug>(vimtex-ip)
    omap <silent><buffer> ap <plug>(vimtex-ap)
    nmap <silent><buffer> ]] <plug>(vimtex-]])
    nmap <silent><buffer> ][ <plug>(vimtex-][)
    nmap <silent><buffer> [] <plug>(vimtex-[])
    nmap <silent><buffer> [[ <plug>(vimtex-[[)
    xmap <silent><buffer> ]] <plug>(vimtex-]])
    xmap <silent><buffer> ][ <plug>(vimtex-][)
    xmap <silent><buffer> [] <plug>(vimtex-[])
    xmap <silent><buffer> [[ <plug>(vimtex-[[)
    omap <silent><buffer> ]] <plug>(vimtex-]])
    omap <silent><buffer> ][ <plug>(vimtex-][)
    omap <silent><buffer> [] <plug>(vimtex-[])
    omap <silent><buffer> [[ <plug>(vimtex-[[)
    xmap <silent><buffer> ie <plug>(vimtex-ie)
    xmap <silent><buffer> ae <plug>(vimtex-ae)
    omap <silent><buffer> ie <plug>(vimtex-ie)
    omap <silent><buffer> ae <plug>(vimtex-ae)
    xmap <silent><buffer> i$ <plug>(vimtex-i$)
    xmap <silent><buffer> a$ <plug>(vimtex-a$)
    omap <silent><buffer> i$ <plug>(vimtex-i$)
    omap <silent><buffer> a$ <plug>(vimtex-a$)
    xmap <silent><buffer> id <plug>(vimtex-id)
    xmap <silent><buffer> ad <plug>(vimtex-ad)
    omap <silent><buffer> id <plug>(vimtex-id)
    omap <silent><buffer> ad <plug>(vimtex-ad)
  endif

  if g:vimtex_toc_enabled
    nmap <silent><buffer> <localleader>lt <plug>(vimtex-toc-open)
    nmap <silent><buffer> <localleader>lT <plug>(vimtex-toc-toggle)
  endif

  if g:vimtex_labels_enabled
    nmap <silent><buffer> <localleader>ly <plug>(vimtex-labels-open)
    nmap <silent><buffer> <localleader>lY <plug>(vimtex-labels-toggle)
  endif

  if g:vimtex_view_enabled
    nmap <silent><buffer> <localleader>lv <plug>(vimtex-view)
    if has_key(b:vimtex.viewer, 'reverse_search')
      nmap <silent><buffer> <localleader>lr <plug>(vimtex-reverse-search)
    endif
  endif
endfunction

" }}}1
function! s:init_modules(initmode) " {{{1
  for module in s:modules
    execute 'call vimtex#' . module . '#init_' . a:initmode . '()'
  endfor
endfunction

" }}}1

function! s:get_id(main) " {{{1
  if exists('g:vimtex_data') && !empty(g:vimtex_data)
    let id = 0
    while id < len(g:vimtex_data)
      if g:vimtex_data[id].tex == a:main
        return id
      endif
      let id += 1
    endwhile
  endif

  return -1
endfunction

function! s:get_main() " {{{1
  "
  " Use buffer variable if it exists
  "
  if exists('b:vimtex_main') && filereadable(b:vimtex_main)
    return fnamemodify(b:vimtex_main, ':p')
  endif

  "
  " Search for main file specifier at the beginning of file.  Recognized
  " specifiers are:
  "
  " 1. The TEX root specifier, which is used by by several other plugins and
  "    editors.
  " 2. Subfiles package specifier.  This parses the main tex file option in the
  "    \documentclass line for the subfiles package.
  "
  for regexp in [
        \ '^\c\s*%\s*!\?\s*tex\s\+root\s*=\s*\zs.*\ze\s*$',
        \ '^\C\s*\\documentclass\[\zs.*\ze\]{subfiles}',
        \ ]
    for line in getline(1, 5)
      let filename = matchstr(line, regexp)
      if len(filename) > 0
        if filename[0] !=# '/'
          let candidates = [
                \ expand('%:h') . '/' . filename,
                \ getcwd() . '/' . filename,
                \ ]
        else
          let candidates = [fnamemodify(filename, ':p')]
        endif
        for main in candidates
          if filereadable(main)
            return main
          endif
        endfor
      endif
    endfor
  endfor

  "
  " Search for .latexmain-specifier
  "
  let main = s:get_main_latexmain(expand('%:p'))
  if filereadable(main)
    return main
  endif

  "
  " Search for main file recursively through \input and \include specifiers
  "
  let main = s:get_main_recurse(expand('%:p'))
  if filereadable(main)
    return main
  endif

  "
  " If not found, use current file
  "
  return expand('%:p')
endfunction

" }}}1
function! s:get_main_latexmain(file) " {{{1
  if !filereadable(a:file) | return | endif

  "
  " Gather candidate files
  "
  let l:path = expand('%:p:h')
  let l:dirs = l:path
  while l:path != fnamemodify(l:path, ':h')
    let l:path = fnamemodify(l:path, ':h')
    let l:dirs .= ',' . l:path
  endwhile
  let l:candidates = split(globpath(fnameescape(l:dirs), '*.latexmain'), '\n')

  "
  " If any candidates found, use the first one (corresponding to the one
  " closest to the current file in the directory tree)
  "
  if len(l:candidates) > 0
    return fnamemodify(l:candidates[0], ':p:r')
  endif
endfunction

function! s:get_main_recurse(file) " {{{1
  if !filereadable(a:file) | return | endif

  "
  " Check if current file is a main file
  "
  if len(filter(readfile(a:file),
        \ 'v:val =~# ''\C\\documentclass\_\s*[\[{]''')) > 0
    return fnamemodify(a:file, ':p')
  endif

  "
  " Gather candidate files
  "
  let l:path = expand('%:p:h')
  let l:dirs = l:path
  while l:path != fnamemodify(l:path, ':h')
    let l:path = fnamemodify(l:path, ':h')
    let l:dirs .= ',' . l:path
  endwhile
  let l:candidates = split(globpath(fnameescape(l:dirs), '*.tex'), '\n')

  "
  " Search through candidates for \include{current file}
  "
  for l:file in l:candidates
    " Avoid infinite recursion (checking the same file repeatedly)
    if l:file == a:file | continue | endif

    if len(filter(readfile(l:file), 'v:val =~ ''\v\\(input|include)\{'
          \ . '\s*((.*)\/)?'
          \ . fnamemodify(a:file, ':t:r') . '(\.tex)?\s*''')) > 0
      return s:get_main_recurse(l:file)
    endif
  endfor
endfunction

function! s:get_main_ext(self, ext) " {{{1
  " First check build dir (latexmk -output_directory option)
  if g:vimtex_latexmk_build_dir !=# ''
    let cand = g:vimtex_latexmk_build_dir . '/' . a:self.name . '.' . a:ext
    if g:vimtex_latexmk_build_dir[0] !=# '/'
      let cand = a:self.root . '/' . cand
    endif
    if filereadable(cand)
      return fnamemodify(cand, ':p')
    endif
  endif

  " Next check for file in project root folder
  let cand = a:self.root . '/' . a:self.name . '.' . a:ext
  if filereadable(cand)
    return fnamemodify(cand, ':p')
  endif

  " Finally return empty string if no entry is found
  return ''
endfunction

" }}}1

"
" Detect file name changes
"
function! s:filename_changed_pre() " {{{1
  let thisfile = fnamemodify(expand('%'), ':p')
  let s:filename_changed = thisfile ==# b:vimtex.tex
  let s:filename_old = b:vimtex.base
endfunction

" }}}1
function! s:filename_changed_post() " {{{1
  if s:filename_changed
    let b:vimtex.tex = fnamemodify(expand('%'), ':p')
    let b:vimtex.base = fnamemodify(b:vimtex.tex, ':t')
    let b:vimtex.name = fnamemodify(b:vimtex.tex, ':t:r')
    let message = ['vimtex: ',
          \ ['VimtexWarning', 'Filename change detected!'],
          \ "\n  Old filename: ", ['VimtexInfo', s:filename_old],
          \ "\n  New filename: ", ['VimtexInfo', b:vimtex.base]]

    if b:vimtex.pid
      let message += ["\n  latexmk process: ",
            \ ['VimtexInfo', b:vimtex.pid],
            \ ['VimtexWarning', ' killed!']]
      call vimtex#latexmk#stop()
    endif

    call vimtex#echo#status(message)
  endif
endfunction

" }}}1

"
" Simple utility features
"
function! vimtex#info(global) " {{{1
  if !s:initialized
    echoerr 'Error: vimtex has not been initialized!'
    return
  endif

  if a:global
    let n = 0
    for data in g:vimtex_data
      let d = deepcopy(data)
      for f in ['aux', 'out', 'log']
        silent execute 'let d.' . f . ' = data.' . f . '()'
      endfor

      call vimtex#echo#formatted([
            \ "\n\ng:vimtex_data[", ['VimtexSuccess', n], '] : ',
            \ ['VimtexSuccess', remove(d, 'name') . "\n"]])
      call s:print_dict(d)
      let n += 1
    endfor
  else
    let d = deepcopy(b:vimtex)
    for f in ['aux', 'out', 'log']
      silent execute 'let d.' . f . ' = b:vimtex.' . f . '()'
    endfor
    call vimtex#echo#formatted([
          \ 'b:vimtex : ',
          \ ['VimtexSuccess', remove(d, 'name') . "\n"]])
    call s:print_dict(d)
  endif
endfunction

" }}}1
function! vimtex#wordcount(detailed) " {{{1
  " Run texcount, save output to lines variable
  let cmd  = 'cd ' . vimtex#util#shellescape(b:vimtex.root)
  let cmd .= '; texcount -nosub -sum '
  let cmd .= a:detailed > 0 ? '-inc ' : '-merge '
  let cmd .= vimtex#util#shellescape(b:vimtex.base)
  let lines = split(system(cmd), '\n')

  " Create wordcount window
  if bufnr('TeXcount') >= 0
    bwipeout TeXcount
  endif
  split TeXcount

  " Add lines to buffer
  for line in lines
    call append('$', printf('%s', line))
  endfor
  0delete _

  " Set mappings
  nnoremap <buffer> <silent> q :bwipeout<cr>

  " Set buffer options
  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal cursorline
  setlocal nobuflisted
  setlocal nolist
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap
  setlocal tabstop=8
  setlocal nomodifiable

  " Set highlighting
  syntax match TexcountText  /^.*:.*/ contains=TexcountValue
  syntax match TexcountValue /.*:\zs.*/
  highlight link TexcountText  VimtexMsg
  highlight link TexcountValue Constant
endfunction

" }}}1

function! s:print_dict(dict, ...) " {{{1
  let level = a:0 > 0 ? a:1 : 0

  for entry in sort(sort(items(a:dict),
        \ 's:print_dict_sort_2'),
        \ 's:print_dict_sort_1')
    let title = repeat(' ', 2 + 2*level) . entry[0]
    if type(entry[1]) == type([])
      call vimtex#echo#echo(title)
      for val in entry[1]
        call vimtex#echo#echo(repeat(' ', 4 + 2*level) . string(val), 'None')
      endfor
    elseif type(entry[1]) == type({})
      call vimtex#echo#echo(title . "\n")
      call s:print_dict(entry[1], level + 1)
    else
      call vimtex#echo#formatted([title . ' : ',
            \ ['None', string(entry[1]) . "\n"]])
    endif
  endfor
endfunction

" }}}1
function! s:print_dict_sort_1(i1, i2) " {{{1
  return type(a:i1[1]) - type(a:i2[1])
endfunction

" }}}1
function! s:print_dict_sort_2(i1, i2) " {{{1
  return string(a:i1[1]) == string(a:i2[1]) ? 0
        \ : string(a:i1[1]) > string(a:i2[1]) ? 1
        \ : -1
endfunction

" }}}1

" vim: fdm=marker sw=2

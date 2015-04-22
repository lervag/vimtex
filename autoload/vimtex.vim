" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" vimtex is not initialized until vimtex#init() has been run once
if !exists('s:initialized')
  let s:initialized = 0
endif

function! vimtex#init() " {{{1
  call s:init_options()
  call s:init_environment()

  call vimtex#toc#init(s:initialized)
  call vimtex#echo#init(s:initialized)
  call vimtex#fold#init(s:initialized)
  call vimtex#view#init(s:initialized)
  call vimtex#index#init(s:initialized)
  call vimtex#motion#init(s:initialized)
  call vimtex#labels#init(s:initialized)
  call vimtex#change#init(s:initialized)
  call vimtex#latexmk#init(s:initialized)
  call vimtex#complete#init(s:initialized)
  call vimtex#mappings#init(s:initialized)

  "
  " This variable is used to allow a distinction between global and buffer
  " initialization
  "
  let s:initialized = 1
endfunction

" }}}1
function! vimtex#info() " {{{1
  if !s:initialized
    echoerr 'Error: vimtex has not been initialized!'
    return
  endif

  " Print buffer data
  call vimtex#echo#echo("b:vimtex\n")
  call s:print_dict(b:vimtex)

  " Print global data
  let n = 0
  for data in g:vimtex#data
    " Prepare for printing
    let d = deepcopy(data)
    for f in ['aux', 'out', 'log']
      silent execute 'let d.' . f . ' = data.' . f . '()'
    endfor

    " Print data blob title line
    call vimtex#echo#formatted([
          \ "\n\ng:vimtex#data[",
          \ ['VimtexSuccess', n],
          \ '] : ',
          \ ['VimtexSuccess', remove(d, 'name') . "\n"]])
    call s:print_dict(d)
    let n += 1
  endfor
endfunction

" }}}1

function! s:init_environment() " {{{1
  " Initialize global and local data blobs
  call vimtex#util#set_default('g:vimtex#data', [])
  call vimtex#util#set_default('b:vimtex', {})

  " Create new or link to existing blob
  let main = s:get_main()
  let id   = s:get_id(main)
  if id >= 0
    let b:vimtex.id = id
  else
    let data = {}
    let data.tex  = main
    let data.root = fnamemodify(data.tex, ':h')
    let data.base = fnamemodify(data.tex, ':t')
    let data.name = fnamemodify(data.tex, ':t:r')
    function data.aux() dict
      return s:get_main_ext(self, 'aux')
    endfunction
    function data.log() dict
      return s:get_main_ext(self, 'log')
    endfunction
    function data.out() dict
      return s:get_main_out(self)
    endfunction

    call add(g:vimtex#data, data)
    let b:vimtex.id = len(g:vimtex#data) - 1
  endif

  " Define commands
  command! -buffer VimtexInfo call vimtex#info()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-info) :call vimtex#info()<cr>
endfunction

function! s:init_options() " {{{1
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
endfunction

" }}}1

function! s:get_id(main) " {{{1
  if exists('g:vimtex#data') && !empty(g:vimtex#data)
    let id = 0
    while id < len(g:vimtex#data)
      if g:vimtex#data[id].tex == a:main
        return id
      endif
      let id += 1
    endwhile
  endif

  return -1
endfunction

function! s:get_main() " {{{1
  "
  " Search for main file specifier at the beginning of file.  This is similar
  " to the method used by several other plugins and editors, such as vim with
  " LaTeX-Box, TextMate, TexWorks, and texmaker.
  "
  for line in getline(1, 5)
    let candidate = matchstr(line,
          \ '^\s*%\s*!\s*[tT][eE][xX]\s\+root\s*=\s*\zs.*\ze\s*$')
    if len(candidate) > 0
      if candidate[0] ==# '/'
        let main = fnamemodify(candidate, ':p')
      else
        " Prepend directory of current file, if candidate is a relative path.
        let main = fnamemodify(expand('%:h') . '/' . candidate, ':p')
      endif
      if filereadable(main)
        return main
      endif
    endif
  endfor

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

function! s:get_main_recurse(file) " {{{1
  "
  " Check if file is readable
  "
  if !filereadable(a:file)
    return 0
  endif

  "
  " Check if current file is a main file
  "
  if len(filter(readfile(a:file),
        \ 'v:val =~# ''\C\\begin\_\s*{document}''')) > 0
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
  let l:candidates = split(globpath(l:dirs, '*.tex'), '\n')

  "
  " Search through candidates for \include{current file}
  "
  for l:file in l:candidates
    if l:file == a:file
      " Avoid checking this file again.
      continue
    endif
    if len(filter(readfile(l:file), 'v:val =~ ''\v\\(input|include)\{'
          \ . '\s*((.*)\/)?'
          \ . fnamemodify(a:file, ':t:r') . '(\.tex)?\s*''')) > 0
      return s:get_main_recurse(l:file)
    endif
  endfor

  "
  " If not found, return 0
  "
  return 0
endfunction

function! s:get_main_ext(texdata, ext) " {{{1
  " Create set of candidates
  let candidates = [
        \ a:texdata.name,
        \ g:vimtex_latexmk_build_dir . '/' . a:texdata.name,
        \ ]

  " Search through the candidates
  for f in map(candidates,
        \ 'a:texdata.root . ''/'' . v:val . ''.'' . a:ext')
    if filereadable(f)
      return fnamemodify(f, ':p')
    endif
  endfor

  " Return empty string if no entry is found
  return ''
endfunction

function! s:get_main_out(texdata) " {{{1
  " Create set of candidates
  let candidates = [
        \ a:texdata.name,
        \ g:vimtex_latexmk_build_dir . '/' . a:texdata.name,
        \ ]

  " Check for pdf files
  for f in map(candidates,
        \ 'a:texdata.root . ''/'' . v:val . ''.pdf''')
    if filereadable(f)
      return fnamemodify(f, ':p')
    endif
  endfor

  " Check for dvi files
  for f in map(candidates,
        \ 'a:texdata.root . ''/'' . v:val . ''.dvi''')
    if filereadable(f)
      return fnamemodify(f, ':p')
    endif
  endfor

  " Return empty string if no entry is found
  return ''
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

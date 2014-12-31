" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" vim-latex is not initialized until latex#init() has been run once
let s:initialized = 0

function! latex#init() " {{{1
  call s:init_options()
  call s:init_environment()
  call s:init_errorformat()

  call latex#toc#init(s:initialized)
  call latex#fold#init(s:initialized)
  call latex#view#init(s:initialized)
  call latex#motion#init(s:initialized)
  call latex#change#init(s:initialized)
  call latex#latexmk#init(s:initialized)
  call latex#complete#init(s:initialized)

  "
  " This variable is used to allow a distinction between global and buffer
  " initialization
  "
  let s:initialized = 1
endfunction

function! latex#info() " {{{1
  if !s:initialized
    echoerr "Error: vim-latex has not been initialized!"
    return
  endif

  " Print buffer data
  echo printf('%-19s%-s', 'b:latex.id', b:latex.id)
  if has_key(b:latex, 'fold_parts') && !empty(b:latex.fold_parts)
    echo 'b:latex.fold_parts'
    for entry in reverse(copy(b:latex.fold_parts))
      echo printf('  %s  %s', entry[1], entry[0])
    endfor
  endif

  " Print global data
  let n = 0
  for d in g:latex#data
    echo "\n"
    echo "g:latex#data[" . n . "]"
    if has_key(d, 'pid') && d.pid
      echo printf('  %-6s%-s', 'pid', d.pid)
    endif
    echo printf('  %-6s%-s', 'name', s:truncate(d.name))
    echo printf('  %-6s%-s', 'base', s:truncate(d.base))
    echo printf('  %-6s%-s', 'root', s:truncate(d.root))
    echo printf('  %-6s%-s', 'tex',  s:truncate(d.tex))

    for f in ['aux', 'out', 'log']
      silent execute 'let l:tmp = d.' . f . '()'
      if l:tmp != ''
        echo printf('  %-6s%-s', f, s:truncate(l:tmp))
      endif
    endfor

    let cmds = items(d.cmds)
    if len(cmds) > 0
      for [key, val] in cmds
        echo printf('  command: %-9s', key)
        echo printf('    %-s', val)
      endfor
    endif
    let n += 1
  endfor
endfunction

function! latex#help() " {{{1
  if g:latex_mappings_enabled
    nmap <buffer>
    xmap <buffer>
    omap <buffer>
  else
    echo "Mappings not enabled"
  endif
endfunction

function! latex#reinit() " {{{1
  "
  " Stop latexmk processes (if running)
  "
  call latex#latexmk#stop_all()

  "
  " Reset global variables
  "
  let s:initialized = 0
  unlet g:latex#data

  "
  " Reset and reinitialize buffers
  "
  let n = bufnr('%')
  bufdo   if getbufvar('%', '&filetype') == 'tex' |
        \   unlet b:latex                         |
        \   call latex#init()                     |
        \ endif
  silent execute 'buffer ' . n
endfunction
" }}}1

function! s:init_environment() " {{{1
  "
  " Initialize global and local data blobs
  "
  call latex#util#set_default('g:latex#data', [])
  call latex#util#set_default('b:latex', {})
  call latex#util#set_vim_executable()

  "
  " Set some file type specific vim options
  setlocal suffixesadd+=.tex
  setlocal commentstring=\%\ %s

  "
  " Create new or link to existing blob
  "
  let main = s:get_main()
  let id   = s:get_id(main)
  if id >= 0
    let b:latex.id = id
  else
    let data = {}
    let data.cmds = {}
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
      return s:get_main_ext(self, g:latex_latexmk_output)
    endfunction

    call add(g:latex#data, data)
    let b:latex.id = len(g:latex#data) - 1
  endif

  command! -buffer VimLatexInfo         call latex#info()
  command! -buffer VimLatexHelp         call latex#help()
  command! -buffer VimLatexReinitialize call latex#reinit()

  if g:latex_mappings_enabled
    nnoremap <silent><buffer> <localleader>li :call latex#info()<cr>
    nnoremap <silent><buffer> <localleader>lh :call latex#help()<cr>
    nnoremap <silent><buffer> <localleader>lR :call latex#reinit()<cr>
  endif
endfunction

function! s:init_errorformat() " {{{1
  "
  " Note: The error formats assume we're using the -file-line-error with
  "       [pdf]latex. For more info, see |errorformat-LaTeX|.
  "

  " Push file to file stack
  setlocal efm=%-P**%f
  setlocal efm+=%-P**\"%f\"

  " Match errors
  setlocal efm+=%E!\ LaTeX\ %trror:\ %m
  setlocal efm+=%E%f:%l:\ %m
  setlocal efm+=%E!\ %m

  " More info for undefined control sequences
  setlocal efm+=%Z<argument>\ %m

  " More info for some errors
  setlocal efm+=%Cl.%l\ %m

  " Show warnings
  if ! g:latex_quickfix_ignore_all_warnings
    " Ignore some warnings
    for w in g:latex_quickfix_ignored_warnings
      let warning = escape(substitute(w, '[\,]', '%\\\\&', 'g'), ' ')
      exe 'setlocal efm+=%-G%.%#'. warning .'%.%#'
    endfor
    setlocal efm+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
    setlocal efm+=%+W%.%#\ at\ lines\ %l--%*\\d
    setlocal efm+=%+WLaTeX\ %.%#Warning:\ %m
    setlocal efm+=%+W%.%#%.%#Warning:\ %m

    " Parse biblatex warnings
    setlocal efm+=%-C(biblatex)%.%#in\ t%.%#
    setlocal efm+=%-C(biblatex)%.%#Please\ v%.%#
    setlocal efm+=%-C(biblatex)%.%#LaTeX\ a%.%#
    setlocal efm+=%-Z(biblatex)%m

    " Parse hyperref warnings
    setlocal efm+=%-C(hyperref)%.%#on\ input\ line\ %l.
  endif

  " Ignore unmatched lines
  setlocal efm+=%-G%.%#
endfunction
" }}}1
function! s:init_options() " {{{1
  call latex#util#error_deprecated('g:latex_errorformat_ignore_warnings')
  call latex#util#error_deprecated('g:latex_errorformat_show_warnings')
  call latex#util#error_deprecated('g:latex_latexmk_autojump')
  call latex#util#error_deprecated('g:latex_latexmk_quickfix')
  call latex#util#error_deprecated('g:latex_latexmk_options')

  call latex#util#set_default('g:latex_build_dir', '.')
  call latex#util#set_default('g:latex_complete_enabled', 1)
  call latex#util#set_default('g:latex_complete_close_braces', 0)
  call latex#util#set_default('g:latex_complete_recursive_bib', 0)
  call latex#util#set_default('g:latex_complete_patterns',
        \ {
        \ 'ref' : '\C\\v\?\(eq\|page\|[cC]\|labelc\)\?ref\*\?\_\s*{[^{}]*',
        \ 'bib' : '\C\\\a*cite\a*\*\?\(\[[^\]]*\]\)*\_\s*{[^{}]*',
        \ })
  call latex#util#set_default('g:latex_fold_enabled', 1)
  call latex#util#set_default('g:latex_fold_automatic', 1)
  call latex#util#set_default('g:latex_fold_preamble', 1)
  call latex#util#set_default('g:latex_fold_envs', 1)
  call latex#util#set_default('g:latex_fold_parts',
        \ [
        \   "part",
        \   "appendix",
        \   "frontmatter",
        \   "mainmatter",
        \   "backmatter",
        \ ])
  call latex#util#set_default('g:latex_fold_sections',
        \ [
        \   "chapter",
        \   "section",
        \   "subsection",
        \   "subsubsection",
        \ ])
  call latex#util#set_default('g:latex_indent_enabled', 1)
  call latex#util#set_default('g:latex_latexmk_enabled', 1)
  call latex#util#set_default('g:latex_latexmk_callback', 1)
  call latex#util#set_default('g:latex_latexmk_continuous', 1)
  call latex#util#set_default('g:latex_latexmk_background', 0)
  call latex#util#set_default('g:latex_latexmk_output', 'pdf')
  call latex#util#set_default('g:latex_mappings_enabled', 1)
  call latex#util#set_default('g:latex_motion_enabled', 1)
  call latex#util#set_default('g:latex_motion_matchparen', 1)
  call latex#util#set_default('g:latex_quickfix_autojump', '0')
  call latex#util#set_default('g:latex_quickfix_ignore_all_warnings', 0)
  call latex#util#set_default('g:latex_quickfix_ignored_warnings', [])
  call latex#util#set_default('g:latex_quickfix_mode', '2')
  call latex#util#set_default('g:latex_quickfix_open_on_warning', '1')
  call latex#util#set_default('g:latex_toc_enabled', 1)
  call latex#util#set_default('g:latex_toc_fold', 0)
  call latex#util#set_default('g:latex_toc_fold_levels', 10)
  call latex#util#set_default('g:latex_toc_hide_help', 0)
  call latex#util#set_default('g:latex_toc_hide_preamble', 0)
  call latex#util#set_default('g:latex_toc_hide_line_numbers', 1)
  call latex#util#set_default('g:latex_toc_numbers', 1)
  call latex#util#set_default('g:latex_toc_numbers_width', 0)
  call latex#util#set_default('g:latex_toc_resize', 1)
  call latex#util#set_default('g:latex_toc_secnumdepth', 3)
  call latex#util#set_default('g:latex_toc_split_side', 'leftabove')
  call latex#util#set_default('g:latex_toc_split_vertically', 1)
  call latex#util#set_default('g:latex_toc_width', 30)
  call latex#util#set_default('g:latex_view_enabled', 1)
endfunction
" }}}1

function! s:get_id(main) " {{{1
  if exists('g:latex#data') && !empty(g:latex#data)
    let id = 0
    while id < len(g:latex#data)
      if g:latex#data[id].tex == a:main
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
      let main = fnamemodify(candidate, ':p')
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
        \ 'v:val =~ ''\C\\begin\_\s*{document}''')) > 0
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
        \ g:latex_build_dir . '/' . a:texdata.name,
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

function! s:truncate(string) " {{{1
  if len(a:string) >= winwidth('.') - 9
    return a:string[0:10] . "..." . a:string[-winwidth('.')+23:]
  else
    return a:string
  endif
endfunction
" }}}1

" vim: fdm=marker sw=2

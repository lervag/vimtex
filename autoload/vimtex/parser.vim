" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#tex(file, ...) abort " {{{1
  return vimtex#parser#tex#parse(a:file, a:0 > 0 ? a:1 : {})
endfunction

" }}}1
function! vimtex#parser#preamble(file, ...) abort " {{{1
  " This will return the list of lines of the current project from the
  " beginning of the preamble until and including the `\begin{document}`
  return vimtex#parser#tex#parse_preamble(a:file, a:0 > 0 ? a:1 : {})
endfunction

" }}}1
function! vimtex#parser#auxiliary(file) abort " {{{1
  return vimtex#parser#auxiliary#parse(a:file)
endfunction

" }}}1
function! vimtex#parser#fls(file) abort " {{{1
  return vimtex#parser#fls#parse(a:file)
endfunction

" }}}1
function! vimtex#parser#toc(...) abort " {{{1
  let l:vimtex = a:0 > 0 ? a:1 : b:vimtex

  let l:cache = vimtex#cache#open('parser_toc', {
        \ 'persistent': v:false,
        \ 'default': {'entries': [], 'ftime': -1},
        \})
  let l:current = l:cache.get(l:vimtex.tex)

  " Update cache if relevant
  let l:ftime = l:vimtex.getftime()
  if l:ftime > l:current.ftime
    let l:current.ftime = l:ftime
    let l:current.entries = vimtex#parser#toc#parse(l:vimtex.tex)
  endif

  return deepcopy(l:current.entries)
endfunction

" }}}1
function! vimtex#parser#bib(file, ...) abort " {{{1
  return vimtex#parser#bib#parse(a:file, a:0 > 0 ? a:1 : {})
endfunction

" }}}1

function! vimtex#parser#get_externalfiles() abort " {{{1
  let l:preamble = vimtex#parser#preamble(b:vimtex.tex)

  let l:result = []
  for l:line in filter(l:preamble, 'v:val =~# ''\\externaldocument''')
    let l:name = matchstr(l:line, '{\zs[^}]*\ze}')
    call add(l:result, {
          \ 'tex' : l:name . '.tex',
          \ 'aux' : l:name . '.aux',
          \ 'opt' : matchstr(l:line, '\[\zs[^]]*\ze\]'),
          \ })
  endfor

  return l:result
endfunction

" }}}1
function! vimtex#parser#selection_to_texfile(opts) range abort " {{{1
  let l:opts = extend({
        \ 'type': 'range',
        \ 'range': [0, 0],
        \ 'name': b:vimtex.name . '_vimtex_selected',
        \ 'template_name': 'vimtex-template.tex',
        \}, a:opts)

  " Set range from selection type
  if l:opts.type ==# 'command'
    let l:opts.range = [a:firstline, a:lastline]
  elseif l:opts.type ==# 'visual'
    let l:opts.range = [line("'<"), line("'>")]
  elseif l:opts.type ==# 'operator'
    let l:opts.range = [line("'["), line("']")]
  endif

  let l:lines = getline(l:opts.range[0], l:opts.range[1])

  " Restrict the selection to whatever is within the \begin{document} ...
  " \end{document} environment
  let l:start = 0
  let l:end = len(l:lines)
  for l:n in range(len(l:lines))
    if l:lines[l:n] =~# '\\begin\s*{document}'
      let l:start = l:n + 1
    elseif l:lines[l:n] =~# '\\end\s*{document}'
      let l:end = l:n - 1
      break
    endif
  endfor

  " Check if the selection has any real content
  if l:start >= len(l:lines)
        \ || l:end < 0
        \ || empty(substitute(join(l:lines[l:start : l:end], ''), '\s*', '', ''))
    return {}
  endif
  let l:lines = l:lines[l:start : l:end]

  " Load template (if available)
  let l:template = []
  for l:template_file in [
        \ expand('%:r') . '-' . l:opts.template_name,
        \ l:opts.template_name,
        \]
    if filereadable(l:template_file)
      let l:template = readfile(l:template_file)
      break
    endif
  endfor

  " Define the set of lines to compile
  if !empty(l:template)
    let l:i = index(l:template, '%%% VIMTEX PLACEHOLDER')
    let l:lines = l:template[:l:i-1] + l:lines + l:template[l:i+1:]
  else
    let l:lines = vimtex#parser#preamble(b:vimtex.tex)
          \ + l:lines
          \ + ['\end{document}']
  endif

  " Respect the compiler out_dir option
  if empty(b:vimtex.compiler.out_dir)
    let l:out_dir = b:vimtex.root
  else
    let l:out_dir = vimtex#paths#is_abs(b:vimtex.compiler.out_dir)
          \ ? b:vimtex.compiler.out_dir
          \ : b:vimtex.root . '/' . b:vimtex.compiler.out_dir
  endif

  " Write content to temporary file
  let l:file = {}
  let l:file.root = l:out_dir
  let l:file.name = l:opts.name
  let l:file.base = l:file.name . '.tex'
  let l:file.tex = l:file.root . '/' . l:file.name . '.tex'
  call writefile(l:lines, l:file.tex)

  return l:file
endfunction

" }}}1

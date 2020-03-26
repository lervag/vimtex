" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#tex(file, ...) abort " {{{1
  return vimtex#parser#tex#parse(a:file, a:0 > 0 ? a:1 : {})
endfunction

" }}}1
function! vimtex#parser#preamble(file, ...) abort " {{{1
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

  let l:cache = vimtex#cache#open('parsertoc', {
        \ 'persistent': 0,
        \ 'default': {'entries': [], 'ftime': -1},
        \})
  let l:current = l:cache.get(l:vimtex.tex)

  " Update cache if relevant
  let l:ftime = l:vimtex.getftime()
  if l:ftime > l:current.ftime
    let l:cache.modified = 1
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
function! vimtex#parser#selection_to_texfile(type, ...) range abort " {{{1
  "
  " Get selected lines. Method depends on type of selection, which may be
  " either of
  "
  " 1. range from argument
  " 2. Command range
  " 3. Visual mapping
  " 4. Operator mapping
  "
  if a:type ==# 'arg'
    let l:lines = getline(a:1[0], a:1[1])
  elseif a:type ==# 'cmd'
    let l:lines = getline(a:firstline, a:lastline)
  elseif a:type ==# 'visual'
    let l:lines = getline(line("'<"), line("'>"))
  else
    let l:lines = getline(line("'["), line("']"))
  endif

  "
  " Use only the part of the selection that is within the
  "
  "   \begin{document} ... \end{document}
  "
  " environment.
  "
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

  "
  " Check if the selection has any real content
  "
  if l:start >= len(l:lines)
        \ || l:end < 0
        \ || empty(substitute(join(l:lines[l:start : l:end], ''), '\s*', '', ''))
    return {}
  endif

  "
  " Define the set of lines to compile
  "
  let l:lines = vimtex#parser#preamble(b:vimtex.tex)
        \ + ['\begin{document}']
        \ + l:lines[l:start : l:end]
        \ + ['\end{document}']

  "
  " Write content to temporary file
  "
  let l:file = {}
  let l:file.root = b:vimtex.root
  let l:file.base = b:vimtex.name . '_vimtex_selected.tex'
  let l:file.tex  = l:file.root . '/' . l:file.base
  let l:file.pdf = fnamemodify(l:file.tex, ':r') . '.pdf'
  let l:file.log = fnamemodify(l:file.tex, ':r') . '.log'
  call writefile(l:lines, l:file.tex)

  return l:file
endfunction

" }}}1

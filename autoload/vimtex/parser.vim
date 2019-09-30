" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#tex(file, ...) abort " {{{1
  return vimtex#parser#general#parse(a:file, a:0 > 0 ? a:1 : {})
endfunction

" }}}1
function! vimtex#parser#aux(file, ...) abort " {{{1
  let l:options = extend(a:0 > 0 ? a:1 : {}, {
        \ 'detailed' : 0,
        \ 'type' : 'aux',
        \}, 'keep')
  return vimtex#parser#general#parse(a:file, l:options)
endfunction

" }}}1
function! vimtex#parser#fls(file, ...) abort " {{{1
  let l:options = extend(a:0 > 0 ? a:1 : {}, {
        \ 'detailed' : 0,
        \ 'type' : 'fls',
        \ 'input_re_fls' : 'nomatch^',
        \}, 'keep')
  return vimtex#parser#general#parse(a:file, l:options)
endfunction

" }}}1

function! vimtex#parser#toc(file) abort " {{{1
  return vimtex#parser#toc#parse(a:file)
endfunction

" }}}1

function! vimtex#parser#bib(file, ...) abort " {{{1
  return vimtex#parser#bib#parse(a:file, a:0 > 0 ? a:1 : {})
endfunction

" }}}1

function! vimtex#parser#get_externalfiles() abort " {{{1
  let l:preamble = vimtex#parser#tex(b:vimtex.tex, {
        \ 're_stop' : '\\begin{document}',
        \ 'detailed' : 0,
        \})

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
  let l:lines = vimtex#parser#tex(b:vimtex.tex, {
        \ 'detailed' : 0,
        \ 're_stop' : '\\begin\s*{document}',
        \})
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

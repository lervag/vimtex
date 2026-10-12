" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#preview#init_buffer() abort " {{{1
  if !g:vimtex_preview_enabled | return | endif

  command! -buffer VimtexPreviewToggle call vimtex#preview#toggle()
  command! -buffer VimtexPreviewClearCache call vimtex#preview#clear_cache()

  nnoremap <silent><buffer> <plug>(vimtex-preview-toggle)
        \ :call vimtex#preview#toggle()<cr>
endfunction

" }}}1

function! vimtex#preview#toggle() abort " {{{1
  if s:is_active()
    call luaeval('require("vimtex.preview").disable()')
  else
    call vimtex#preview#enable()
  endif
endfunction

" }}}1
function! vimtex#preview#enable() abort " {{{1
  if !g:vimtex_preview_enabled || &filetype !=# 'tex' || s:is_active()
    return
  endif

  let l:engine = vimtex#preview#get_engine()
  for l:exe in [l:engine, 'pdftocairo']
    if !executable(l:exe)
      call vimtex#log#error(
            \ 'Preview requires ' . l:exe . ', which is not executable!')
      return
    endif
  endfor

  call luaeval('require("vimtex.preview").enable(_A)', l:engine)
endfunction

" }}}1
function! vimtex#preview#clear_cache() abort " {{{1
  call luaeval('require("vimtex.preview").clear_cache()')
endfunction

" }}}1

function! vimtex#preview#get_fragment() abort " {{{1
  " Get the fragment under the cursor, i.e. math or a tikz-cd diagram. Returns
  " an empty dict if there is no (nonempty) fragment, else a dict with the
  " keys:
  "
  "   lnum_start  First line of the fragment (including delimiters)
  "   lnum_end    Last line of the fragment (including delimiters)
  "   code        The LaTeX code as a string that can be typeset directly in
  "               a box (see s:normalize())
  "   box         The type of box to typeset the code in: 'hbox' for code
  "               with a natural width, 'vbox' for a paragraph of normal width
  let [l:open, l:close] = s:get_surrounding()
  if empty(l:open) | return {} | endif

  let l:lines = getline(l:open.lnum, l:close.lnum)
  let l:lines[-1] = strpart(l:lines[-1], 0, l:close.cnum - 1)
  let l:lines[0] = strpart(l:lines[0], l:open.cnum - 1 + len(l:open.match))
  call filter(l:lines, { _, x -> x =~# '\S' })
  let l:body = s:trim(join(l:lines, "\n"))

  let l:fragment = s:normalize(l:body, l:open, l:close)
  if empty(l:fragment) | return {} | endif

  return extend({
        \ 'lnum_start': l:open.lnum,
        \ 'lnum_end': l:close.lnum,
        \}, l:fragment)
endfunction

" }}}1
function! vimtex#preview#get_document(fragment, color) abort " {{{1
  " Create a document that typesets the fragment (see
  " vimtex#preview#get_fragment()) with the preamble of the current project.

  let l:preamble = vimtex#parser#preamble(b:vimtex.tex)
  if empty(l:preamble)
    let l:preamble = [
          \ '\documentclass{article}',
          \ '\usepackage{amsmath}',
          \ '\begin{document}',
          \]
  endif

  " The preview package crops each preview environment to a separate page.
  " \vimtexpreviewceil{dim}{step} rounds dim up to a multiple of step.
  let l:lines = l:preamble[:-2] + [
        \ '\usepackage[active,tightpage]{preview}',
        \ '\usepackage{xcolor}',
        \ '\setlength\PreviewBorder{0pt}',
        \ '\newsavebox\vimtexpreviewbox',
        \ '\newcommand\vimtexpreviewceil[2]{\dimexpr#2*\numexpr'
        \ . '(#1+\dimexpr#2/2\relax-1)/\dimexpr#2\relax\relax\relax}',
        \ l:preamble[-1],
        \]

  " The preview is compiled without shell escape, so TikZ externalization
  " would fail
  let l:lines += ['\csname tikzexternaldisable\endcsname']

  " Typeset the code in a box. Note that the code must not be read as a macro
  " argument, since that breaks e.g. the & in tikz-cd diagrams.
  let l:box = a:fragment.box ==# 'hbox'
        \ ? '\setbox\vimtexpreviewbox\hbox{'
        \ : '\setbox\vimtexpreviewbox\vbox{\noindent'
  let l:lines += [
        \ '\begin{preview}',
        \ l:box . '\color[HTML]{' . a:color . '}%',
        \]
        \ + split(a:fragment.code, "\n")
        \ + ['}%']

  " Pad the box to a whole number of terminal cells, i.e. multiples of
  " 6 bp x 12 bp (see show() in lua/vimtex/preview.lua). This way the terminal
  " does not need to scale the image.
  let l:lines += [
        \ '\vbox to \vimtexpreviewceil{\dimexpr\ht\vimtexpreviewbox'
        \ . '+\dp\vimtexpreviewbox\relax}{12bp}{\vss',
        \ '  \hbox to \vimtexpreviewceil{\wd\vimtexpreviewbox}{6bp}{%',
        \ '    \box\vimtexpreviewbox\hss}\vss}%',
        \ '\end{preview}',
        \ '\end{document}',
        \]

  return l:lines
endfunction

" }}}1
function! vimtex#preview#get_engine() abort " {{{1
  " Use the same engine as the compiler of the current project, if the
  " compiler specifies one. Else use the TeX program directive.
  let l:compiler = get(b:vimtex, 'compiler', {})
  let l:engine = has_key(l:compiler, 'get_engine')
        \ ? l:compiler.get_engine()
        \ : b:vimtex.get_tex_program()

  return l:engine =~# 'lua' ? 'lualatex'
        \ : l:engine =~# 'xe\%(la\)\?tex' ? 'xelatex'
        \ : 'pdflatex'
endfunction

" }}}1

function! s:normalize(body, open, close) abort " {{{1
  " Returns a dict with the 'code' and 'box' keys of a fragment (see
  " vimtex#preview#get_fragment()), or an empty dict if there is nothing to
  " typeset.
  if a:body !~# '\S' | return {} | endif

  " Inline math is typeset as is. The \strut ensures that a single line of
  " math has the height of a line of text, see the size computation in
  " lua/vimtex/preview.lua.
  if a:open.match ==# '$' || a:open.match ==# '\('
    return {'code': '$\strut ' . a:body . '$', 'box': 'hbox'}
  endif

  " Labels and tags are not allowed (or not wanted) in inline math
  let l:body = substitute(a:body,
        \ '\v\s*\\%(label|tag\*?)\s*\{[^}]*\}|\s*\\%(nonumber|notag)>',
        \ '', 'g')
  let l:body = s:trim(l:body)

  let l:name = get(a:open, 'name', '')
  if empty(l:name) || index(['equation', 'displaymath', 'math'], l:name) >= 0
    " Display delimiters such as \[ ... \] and $$ ... $$
  elseif index(['align', 'flalign'], l:name) >= 0
    let l:body = '\begin{aligned}' . l:body . '\end{aligned}'
  elseif l:name =~# '^x\{0,2}alignat$'
    let l:body = '\begin{alignedat}' . l:body . '\end{alignedat}'
  elseif index(['gather', 'multline'], l:name) >= 0
    let l:body = '\begin{gathered}' . l:body . '\end{gathered}'
  elseif l:name ==# 'eqnarray'
    let l:body = '\begin{array}{rcl}' . l:body . '\end{array}'
  elseif l:name ==# 'tikzcd'
    let l:body = a:open.match . l:body . a:close.match
  else
    " Unknown environments are typeset as they are, with full line width
    return {'code': a:open.match . a:body . a:close.match, 'box': 'vbox'}
  endif

  return {'code': '$\displaystyle\strut ' . l:body . '$', 'box': 'hbox'}
endfunction

" }}}1
function! s:get_surrounding() abort " {{{1
  " Get the surrounding math, or else a surrounding tikz-cd diagram
  if !g:vimtex_syntax_enabled || vimtex#syntax#in('texMathZone')
    let [l:open, l:close] = vimtex#env#get_surrounding('math')
    if !empty(l:open) | return [l:open, l:close] | endif
  endif

  return vimtex#delim#get_surrounding('env_tex', #{ whitelist: ['tikzcd'] })
endfunction

" }}}1
function! s:is_active() abort " {{{1
  return luaeval('require("vimtex.preview").is_active()')
endfunction

" }}}1
function! s:trim(str) abort " {{{1
  return substitute(a:str, '^\_s*\|\_s*$', '', 'g')
endfunction

" }}}1

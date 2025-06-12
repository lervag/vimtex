" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#state#class#new(opts) abort " {{{1
  let l:opts = extend({
        \ 'main': '',
        \ 'main_parser': '',
        \ 'preserve_root': v:false,
        \ 'unsupported_modules': [],
        \}, a:opts)

  let l:new = deepcopy(s:vimtex)

  let l:new.root = resolve(fnamemodify(l:opts.main, ':h'))
  let l:new.base = fnamemodify(l:opts.main, ':t')
  let l:new.name = fnamemodify(l:opts.main, ':t:r')
  let l:new.main_parser = l:opts.main_parser

  if l:opts.preserve_root && exists('b:vimtex')
    let l:new.root = b:vimtex.root
    let l:new.base = vimtex#paths#relative(l:opts.main, l:new.root)
  endif

  let l:ext = fnamemodify(l:opts.main, ':e')
  let l:new.tex = l:ext =~? '\v^%(%(la)?tex|dtx|tikz|ins)$'
        \ ? l:new.root . '/' . l:new.base
        \ : ''

  " Get preamble for some state parsing
  let l:preamble = !empty(l:new.tex)
        \ ? vimtex#parser#preamble(l:new.tex, {'root' : l:new.root})
        \ : []

  " Create single-line preamble-string without comments
  let l:preamble_joined = join(
        \ map(copy(l:preamble), {_, x -> substitute(x, '\\\@<!%.*', '', '')}),
        \ '')

  let [l:new.documentclass, l:new.documentclass_options] =
        \ s:parse_documentclass(l:preamble_joined)
  let l:new.packages = s:parse_packages(l:preamble_joined)
  let l:new.graphicspath = s:parse_graphicspath(l:preamble_joined, l:new.root)
  let l:new.glossaries = s:parse_glossaries(
        \ l:preamble,
        \ l:new.root,
        \ l:new.packages
        \)

  " Initialize state in submodules
  for l:mod in filter(
        \ ['compiler', 'view', 'qf', 'toc', 'fold', 'context'],
        \ 'index(l:opts.unsupported_modules, v:val) < 0')
    call vimtex#{l:mod}#init_state(l:new)
  endfor

  " Update package list from fls file (if available)
  call l:new.update_packages()

  return l:new
endfunction

" }}}1


let s:vimtex = {}

function! s:vimtex.__pprint() abort dict " {{{1
  let l:items = [
        \ ['name', self.name],
        \ ['base', self.base],
        \ ['root', self.root],
        \ ['tex', self.tex],
        \ ['main parser', self.main_parser],
        \]

  if exists('self.documentclass')
    call add(l:items, ['document class', self.documentclass])
  endif

  if exists('self.documentclass_options')
    let l:string = join(map(sort(keys(self.documentclass_options)),
          \ {_, key -> key .. "=" .. (
          \   self.documentclass_options[key] == v:true ? 'true'
          \   : self.documentclass_options[key] == v:false ? 'false'
          \   : self.documentclass_options[key]
          \ )}
          \))
    call add(l:items, ['document class options', l:string])
  endif

  if !empty(self.packages)
    call add(l:items, ['packages', join(sort(keys(self.packages)))])
  endif

  let l:sources = self.get_sources()
  if len(l:sources) >= 2
    call add(l:items, ['source files', l:sources])
  endif

  call add(l:items, ['compiler', get(self, 'compiler', {})])
  call add(l:items, ['viewer', get(self, 'viewer', {})])

  if exists('self.qf.name')
    call add(l:items, ['qf method', self.qf.name])
  endif

  return [['VimTeX project', l:items]]
endfunction

" }}}1

function! s:vimtex.cleanup() abort dict " {{{1
  if exists('self.compiler.is_running')
        \ && self.compiler.is_running()
    call self.compiler.kill()
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
  silent! cclose
endfunction

" }}}1
function! s:vimtex.getftime() abort dict " {{{1
  return max(map(self.get_sources(), 'getftime(self.root . ''/'' . v:val)'))
endfunction

" }}}1
function! s:vimtex.update_packages() abort dict " {{{1
  if !has_key(self, 'compiler') | return | endif

  " Try to parse .fls file if present, as it is usually more complete. That is,
  " it contains a generated list of all the packages that are used.
  for l:line in vimtex#parser#fls(self.compiler.get_file('fls'))
    let l:package = matchstr(l:line, '^INPUT \zs.\+\ze\.sty$')
    let l:package = fnamemodify(l:package, ':t')
    if !empty(l:package)
      let self.packages[l:package] = {}
    endif
  endfor
endfunction

" }}}1
function! s:vimtex.get_tex_program() abort dict " {{{1
  let l:lines = vimtex#parser#preamble(self.tex, {'root' : self.root})[:20]
  call map(l:lines, { _, x ->
        \ matchstr(x, '\v^\c\s*\%\s*!?\s*tex\s+%(ts-)?program\s*\=\s*\zs.*$')
        \})
  call filter(l:lines, { _, x -> !empty(x) })
  let l:tex_program = get(l:lines, -1, '_')
  return tolower(trim(l:tex_program))
endfunction

" }}}1
function! s:vimtex.is_compileable() abort dict " {{{1
  if self.main_parser ==# 'fallback current file'
    " This conditional branch essentially means VimTeX gave up on finding the
    " current project's main file. This _sometimes_ indicates a file that is
    " not compileable. We therefore do a weak check of whether the file is
    " compileable by looking for the classic preamble header and
    " \begin{document} + \end{document}.

    let l:lines = getline(1, '$')
    let l:index = match(l:lines, '^\s*\\documentclass\_\s*[\[{]')
    if l:index < 0 | return v:false | endif

    let l:index = match(l:lines, '^\s*\\begin\s*{document}', l:index+1)
    if l:index < 0 | return v:false | endif

    let l:index = match(l:lines, '^\s*\\end\s*{document}', l:index+1)
    return l:index >= 0
  endif

  return v:true
endfunction

" }}}1

function! s:vimtex.get_sources(...) abort dict " {{{1
  let l:opts = extend(
        \ #{
        \   refresh: v:false
        \ },
        \ a:0 > 0 ? a:1 : {}
        \)

  if !has_key(self, '__sources') || l:opts.refresh
    let self.__sources = s:gather_sources(self.tex, self.root)
  endif

  return copy(self.__sources)
endfunction

" }}}1


function! s:parse_documentclass(preamble_joined) abort " {{{1
  let l:documentclass = matchstr(
        \ a:preamble_joined,
        \ '\\documentclass[^{]*{\zs[^}]\+\ze}')

  let l:option_string = matchstr(
        \ a:preamble_joined,
        \ '\\documentclass[^\[]*\[\zs[^\]]\+\ze\]')
  let l:options = s:parse_optionlist(l:option_string)

  return [l:documentclass, l:options]
endfunction

" }}}1
function! s:parse_packages(preamble_joined) abort " {{{1
  " Regex pattern:
  " - Match contains package name(s)
  " - First submatch contains package options
  let l:pat = g:vimtex#re#not_comment .. g:vimtex#re#not_bslash
      \ .. '\v\\%(usep|RequireP)ackage\s*%(\[([^[\]]*)\])?\s*\{\s*\zs%([^{}]+\S)\ze\s*\}'

  let l:packages = {}
  for l:match in matchstrlist([a:preamble_joined], pat, #{submatches: v:true})
    let l:new_packages = map(split(l:match.text, ','), {_, x -> trim(x)})
    let l:options = s:parse_optionlist(l:match.submatches[0])
    for l:pkg in l:new_packages
      let l:packages[l:pkg] = l:options
    endfor
  endfor

  return l:packages
endfunction

" }}}1
function! s:parse_graphicspath(preamble_joined, root) abort " {{{1
  " Extract the graphicspath command from this string
  let l:graphicspath = matchstr(a:preamble_joined,
          \ g:vimtex#re#not_bslash
          \ . '\\graphicspath\s*\{\s*\{\s*\zs.{-}\ze\s*\}\s*\}'
          \)

  " Add all parsed graphicspaths
  let l:paths = []
  for l:path in split(l:graphicspath, '\s*}\s*{\s*')
    let l:path = substitute(l:path, '\/\s*$', '', '')
    call add(l:paths, vimtex#paths#is_abs(l:path)
          \ ? l:path
          \ : simplify(a:root . '/' . l:path))
  endfor

  return l:paths
endfunction

" }}}1
function! s:parse_glossaries(preamble, root, packages) abort " {{{1
  if !has_key(a:packages, 'glossaries-extra') | return [] | endif

  " Detect glossary.bib from lines like this:
  "  \GlsXtrLoadResources[src={glossary}]
  "  \GlsXtrLoadResources[src=glossary.bib]
  "  \GlsXtrLoadResources[src={glossary.bib}, selection={all}]
  "  \GlsXtrLoadResources[selection={all},src={glossary.bib}]
  "  \GlsXtrLoadResources[
  "    src={glossary.bib},
  "    selection={all},
  "  ]

  let l:start_search = v:false
  let l:glossaries = []
  for l:line in a:preamble
    if l:line =~# '^\s*\\GlsXtrLoadResources\s*\['
      let l:start_search = v:true
      let l:line = matchstr(l:line, '^\s*\\GlsXtrLoadResources\s*\[\zs.*')
    endif
    if !l:start_search | continue | endif

    let l:matches = split(l:line, '[=,]')
    if empty(l:matches) | continue | endif

    while !empty(l:matches)
      let l:key = trim(remove(l:matches, 0))
      if l:key ==# 'src'
        let l:value = trim(remove(l:matches, 0))
        let l:value = substitute(l:value, '^{', '', '')
        let l:value = substitute(l:value, '[]}]\s*', '', 'g')
        if !vimtex#paths#is_abs(l:value)
          let l:value = vimtex#paths#join(a:root, l:value)
        endif
        if !filereadable(l:value)
          let l:value .= '.bib'
        endif
        call add(l:glossaries, l:value)
        break
      endif
    endwhile
  endfor

  return l:glossaries
endfunction

" }}}1
function! s:gather_sources(texfile, root) abort " {{{1
  let l:sources = vimtex#parser#tex#parse_files(
        \ a:texfile, {'root' : a:root})

  return map(l:sources, 'vimtex#paths#relative(v:val, a:root)')
endfunction

" }}}1

function! s:parse_optionlist(string) abort " {{{1
  let l:options = {}
  for l:element in map(split(a:string, ',', v:true), {_, x -> trim(x)})
    if l:element == ''
      " Empty option
      continue
    elseif l:element =~# '='
      " Key-value option
      let [l:key, l:value] = map(split(l:element, '='), {_, x -> trim(x)})

      if l:value ==? 'true'
        let l:options[l:key] = v:true
      elseif l:value ==? 'false'
        let l:options[l:key] = v:false
      else
        let l:options[l:key] = l:value
      endif
    else
      " Key-only option
      let l:options[l:element] = v:true
    endif
  endfor

  return l:options
endfunction

" }}}1

" vim: fdm=marker

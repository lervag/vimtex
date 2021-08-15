" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#envs#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config).init()
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'environments',
      \ 're' : {
      \   'start' : g:vimtex#re#not_comment . '\\begin\s*\{.{-}\}',
      \   'end' : g:vimtex#re#not_comment . '\\end\s*\{.{-}\}',
      \   'name' : g:vimtex#re#not_comment . '\\%(begin|end)\s*\{\zs.{-}\ze\}'
      \ },
      \ 'whitelist' : [],
      \ 'blacklist' : [],
      \}
function! s:folder.init() abort dict " {{{1
  " Define the validator as simple as possible
  if empty(self.whitelist) && empty(self.blacklist)
    function! self.validate(env) abort dict
      return 1
    endfunction
  elseif empty(self.whitelist)
    function! self.validate(env) abort dict
      return index(self.blacklist, a:env) < 0
    endfunction
  elseif empty(self.blacklist)
    function! self.validate(env) abort dict
      return index(self.whitelist, a:env) >= 0
    endfunction
  else
    function! self.validate(env) abort dict
      return index(self.whitelist, a:env) >= 0 && index(self.blacklist, a:env) < 0
    endfunction
  endif

  return self
endfunction

" }}}1
function! s:folder.level(line, lnum) abort dict " {{{1
  let l:env = matchstr(a:line, self.re.name)

  if !empty(l:env) && self.validate(l:env)
    if a:line =~# self.re.start
      if a:line !~# '\\end'
        return 'a1'
      endif
    elseif a:line =~# self.re.end
      if a:line !~# '\\begin'
        return 's1'
      endif
    endif
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  let env = matchstr(a:line, self.re.name)
  if !self.validate(env) | return | endif

  " Set caption/label based on type of environment
  if env ==# 'frame'
    let option = ''
    let label = ''
    let caption = self.parse_caption_frame(a:line)
  elseif env ==# 'table' || env ==# 'figure'
    let option = ''
    let label = self.parse_label()
    let caption = self.parse_caption(a:line)
  else
    let option = matchstr(a:line, '\[.*\]')
    let label = self.parse_label()
    let caption = self.parse_caption(a:line)
  endif

  let width = winwidth(0)
        \ - (&number ? &numberwidth : 0)
        \ - str2nr(matchstr(&foldcolumn, '\d\+$'))

  " Always make room for the label
  let width_rhs = 0
  if !empty(label)
    let label = '(' . label . ')'
    let width_rhs += len(label)
  endif

  " Use the remaining width for the left-hand side content
  let width_lhs = width - width_rhs - 2

  " Add the possibly indented \begin{...} part
  let width_ind = len(matchstr(a:line, '^\s*'))
  if len(env) > width_lhs - width_ind - 8
    let env = strpart(env, 0, width_lhs - width_ind - 8)
  endif
  let title = repeat(' ', width_ind) . '\begin{' . env . '}'

  " Add option group text
  if !empty(option)
    let width_available = width_lhs - len(title)
    if width_available >= 3
      let title .= (len(option) > width_available - strchars(caption)
            \ ? '[…]'
            \ : option)
    endif
  endif

  " Add caption text
  if !empty(caption)
    let title = printf('%-*S ', 18, title)
    let width_title = strchars(title)
    let width_available = width_lhs - width_title

    if width_available >= 5
      if strchars(caption) > width_available
        let caption = strpart(caption, 0, width_available - 1) . '…'
      endif
      let title .= caption
    endif
  endif

  " Finalle combine the left-hand side and right-hand side and remove trailing
  " spaces
  let title = printf('%-*S %*S', width_lhs, title, width_rhs, label)

  return substitute(title, '\s\+$', '', '')
endfunction

" }}}1
function! s:folder.parse_label() abort dict " {{{1
  let depth = -1
  let i = v:foldstart

  while i <= v:foldend
    let line = getline(i)

    let depth += vimtex#util#count(line, '\\begin{\w\+}')
    let depth -= vimtex#util#count(line, '\\end{\w\+}')

    if depth == 0 && line =~# '^\s*\\label'
      return matchstr(line, '^\s*\\label\%(\[.*\]\)\?{\zs.*\ze}')
    end

    let i += 1
  endwhile

  return ''
endfunction

" }}}1
function! s:folder.parse_caption(line) abort dict " {{{1
  let depth = -1
  let i = v:foldstart

  while i <= v:foldend
    let line = getline(i)

    let depth += vimtex#util#count(line, '\\begin{\w\+}')
    let depth -= vimtex#util#count(line, '\\end{\w\+}')

    if depth == 0 && line =~# '^\s*\\caption'
      return matchstr(line,
            \ '^\s*\\caption\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end

    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" }}}1
function! s:folder.parse_caption_frame(line) abort dict " {{{1
  " Test simple variants first
  let caption1 = matchstr(a:line,'\\begin\*\?{.*}\%(\[[^]]*\]\)\?{\zs.\+\ze}')
  let caption2 = matchstr(a:line,'\\begin\*\?{.*}\%(\[[^]]*\]\)\?{\zs.\+')
  if !empty(caption1)
    return caption1
  elseif !empty(caption2)
    return caption2
  endif

  " Search for \frametitle command
  let i = v:foldstart
  while i <= v:foldend
    if getline(i) =~# '^\s*\\frametitle'
      let frametitle = matchstr(getline(i),
            \ '^\s*\\frametitle\%(\[.*\]\)\?{\zs.\{-1,}\ze\%(}\s*\)\?$')
      if i+1 <= v:foldend && getline(i+1) =~# '^\s*\\framesubtitle'
        let framesubtitle = matchstr(getline(i+1),
              \ '^\s*\\framesubtitle\%(\[.*\]\)\?{\zs.\{-1,}\ze\%(}\s*\)\?$')
        return printf('%S: %S', frametitle, framesubtitle)
      end
      return frametitle
    end
    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\%(\[.*\]\)\?\s*%\s*\zs.*')
endfunction

" }}}1

" vimtex - LaTeX plugin for Vim
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
    let label = ''
    let caption = self.parse_caption_frame(a:line)
  elseif env ==# 'table'
    let label = self.parse_label()
    let caption = self.parse_caption_table(a:line)
  else
    let label = self.parse_label()
    let caption = self.parse_caption(a:line)
  endif

  let width_ind = len(matchstr(a:line, '^\s*'))
  let width = winwidth(0) - (&number ? &numberwidth : 0) - 4 - width_ind

  let width_env = 19
  let width_lab = len(label) + 2 > width - width_env
        \ ? width - width_env
        \ : len(label) + 2
  let width_cap = width - width_env - width_lab

  if !empty(label)
    let label = printf('(%.*S)', width_lab, label)
  endif

  if !empty(caption)
    if strchars(caption) > width_cap
      let caption = strpart(caption, 0, width_cap - 4) . '...'
    endif
  else
    let width_env += width_cap
    let width_cap = 0
  endif

  if strlen(env) > width_env - 8
    let env = strpart(env, 0, width_env - 11) . '...'
  endif
  let env = '\begin{' . env . '}'

  let title = printf('%*S%-*S %-*S  %*S',
        \ width_ind, '',
        \ width_env, env,
        \ width_cap, caption,
        \ width_lab, label)

  return substitute(title, '\s\+$', '', '')
endfunction

" }}}1
function! s:folder.parse_label() abort dict " {{{1
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~# '^\s*\\label'
      return matchstr(getline(i), '^\s*\\label\%(\[.*\]\)\?{\zs.*\ze}')
    end
    let i -= 1
  endwhile
  return ''
endfunction

" }}}1
function! s:folder.parse_caption(line) abort dict " {{{1
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~# '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i -= 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" }}}1
function! s:folder.parse_caption_table(line) abort dict " {{{1
  let i = v:foldstart
  while i <= v:foldend
    if getline(i) =~# '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\s*\(\[.*\]\)\?\s*{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" }}}1
function! s:folder.parse_caption_frame(line) abort dict " {{{1
  " Test simple variants first
  let caption1 = matchstr(a:line,'\\begin\*\?{.*}\(\[[^]]*\]\)\?{\zs.\+\ze}')
  let caption2 = matchstr(a:line,'\\begin\*\?{.*}\(\[[^]]*\]\)\?{\zs.\+')
  if !empty(caption1)
    return caption1
  elseif !empty(caption2)
    return caption2
  endif

  " Search for \frametitle command
  let i = v:foldstart
  while i <= v:foldend
    if getline(i) =~# '^\s*\\frametitle'
      return matchstr(getline(i),
            \ '^\s*\\frametitle\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" }}}1

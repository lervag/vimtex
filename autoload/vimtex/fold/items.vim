" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#items#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config).init()
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'items',
      \ 're' : {},
      \ 'state' : [],
      \}
function! s:folder.init() dict abort " {{{1
  let l:envs = '\{%(' . join(g:vimtex_indent_lists, '|') . ')\*?}'

  let self.re.env_start = '\v^\s*\\begin' . l:envs
  let self.re.env_end = '\v^\s*\\end' . l:envs

  let self.re.fold_re = '^\s*\\item>'
  let self.re.fold_re_next = '^\s*\\%(item>|end' . l:envs . ')'

  let self.re.start = '\v' . self.re.fold_re
  let self.re.end = '\v' . self.re.fold_re_next

  return self
endfunction

" }}}1
function! s:folder.level(line, lnum) dict abort " {{{1
  let l:env_val = has_key(b:vimtex.fold_types_dict, 'envs')
        \ ? b:vimtex.fold_types_dict['envs'].level(a:line, a:lnum)
        \ : 0

  let l:next = getline(a:lnum + 1)

  if a:line =~# self.re.env_start
    call add(self.state, {'folded': v:false})
  elseif a:line =~# self.re.env_end
    call remove(self.state, -1)
    if get(self.state, -1, {'folded': v:false}).folded
          \ && l:next =~# self.re.end
      return 's2'
    endif
  elseif a:line =~# self.re.start
    if l:next !~# self.re.end
      let self.state[-1].folded = v:true
      return l:env_val is# 'a1' ? 'a2' : 'a1'
    endif
  elseif self.state[-1].folded && l:next =~# self.re.end
    let self.state[-1].folded = v:false
    return l:env_val is# 's1' ? 's2' : 's1'
  endif
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  return a:line
endfunction

" }}}1

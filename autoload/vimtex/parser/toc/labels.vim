" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#labels#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'label_dict' : {},
      \ 'prefilter_cmds' : ['label'],
      \ 'priority' : 1,
      \ 're' : g:vimtex#re#not_comment . '\\label\{\zs.{-}\ze\}',
      \}
function! s:matcher.init() abort dict " {{{1
  let l:labels = vimtex#parser#auxiliary#labels()

  let self.label_dict = {}
  for l:x in l:labels
    let self.label_dict[l:x.word] = ' (' . l:x.menu . ')'
  endfor

  let l:wininfo = getwininfo(win_getid())[0]
  let l:width = l:wininfo.width - l:wininfo.textoff - 2
  if stridx(g:vimtex_toc_config.split_pos, 'vert') >= 0
    let l:width = g:vimtex_toc_config.split_width
  endif
  let l:width -= 10
  let l:w1 = l:width/2
  let l:w2 = l:width - l:w1
  let self.format = '%-' . l:w1 . 's%' . l:w2 . 's'
endfunction

" }}}1
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:key = matchstr(a:context.line, self.re)
  let l:label = get(self.label_dict, l:key, '')

  return {
        \ 'title'  : printf(self.format, l:key, l:label),
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'label',
        \ }
endfunction
" }}}1

" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#bib#init() abort " {{{1
  let b:vimtex_fold_bib_maxwidth = s:get_max_key_width()
  augroup vimtex_buffers
    autocmd BufWrite <buffer>
          \ let b:vimtex_fold_bib_maxwidth = s:get_max_key_width()
  augroup END
  setlocal foldmethod=expr
  setlocal foldexpr=vimtex#fold#bib#level(v:lnum)
  setlocal foldtext=vimtex#fold#bib#text()
endfunction

" }}}1

function! vimtex#fold#bib#level(lnum) abort " {{{1
  " Handle blank lines
  if getline(a:lnum) =~ '\v^\s*$'
    if a:lnum == 1
      return 0
    else
      let l:prev_foldlevel = vimtex#fold#bib#level(a:lnum - 1)
      if l:prev_foldlevel == '0'
        return 0
      elseif l:prev_foldlevel == '>1'
        let l:prev_line = getline(a:lnum - 1)
        if s:count(l:prev_line, '{') == s:count(l:prev_line, '}')
          return 0
        else
          return '='
        endif
      else
        return '='
      endif
    endif
  endif

  " Search for the beginning of the entry
  let l:firstline = a:lnum
  while l:firstline >= 1
    if getline(l:firstline) =~ '\v^\s*\@'
      break
    endif
    let l:firstline -= 1
  endwhile

  if l:firstline == a:lnum
    return '>1'
  elseif l:firstline == 0   " beginning of entry wasn't found
    return 0
  endif

  " Check if braces are closed by the current line
  let l:text = join(map(range(l:firstline, a:lnum), 'getline(v:val)'))
  if s:count(l:text, '{') == s:count(l:text, '}')
    return '<1'
  else
    return '1'
  endif

  return 0
endfunction

" }}}1

function! vimtex#fold#bib#text() abort " {{{1
  let l:bib_entries = vimtex#parser#bib#parse_cheap(v:foldstart, v:foldend, {})
  if len(l:bib_entries) != 1
    return foldtext()
  else
    let l:entry = l:bib_entries[0]

    if !empty(l:entry.type) && !empty(l:entry.key)
      let l:foldtext = '@' . l:entry.type . '{' . l:entry.key . '}'
      let l:width = strdisplaywidth(l:foldtext)
      if l:width > b:vimtex_fold_bib_maxwidth
        let l:foldtext = printf('%.' . b:vimtex_fold_bib_maxwidth . 'S', l:foldtext)
        let l:width = strdisplaywidth(l:foldtext)
      endif
      let l:desired_width = b:vimtex_fold_bib_maxwidth + 2
      let l:foldtext .= repeat(' ', l:desired_width - l:width)

      if has_key(l:entry, 'description') && !empty(l:entry.description)
        let l:foldtext .= l:entry.description
      endif
      return l:foldtext
    else
      return foldtext()
    endif
  endif
endfunction

" }}}1

function! s:get_max_key_width() " {{{1
  if g:vimtex_fold_bib_max_key_width > 0
    return g:vimtex_fold_bib_max_key_width
  endif

  let l:entries = vimtex#parser#bib#parse_cheap(1, line('$'),
        \ {'get_description': v:false})
  if empty(l:entries)
    return 32
  endif
  " Extra 3 is for the @ symbol plus curly braces.
  call map(l:entries, {_, e -> 3
        \ + strdisplaywidth(get(e, 'type', ''))
        \ + strdisplaywidth(get(e, 'key', ''))})
  return max(l:entries)
endfunction

" }}}1

function! s:count(container, item) abort " {{{1
  " Necessary because in old Vim versions, count() does not work for strings
  try
    let l:count = count(a:container, a:item)
  catch /E712/
    let l:count = count(split(a:container, '\zs'), a:item)
  endtry

  return l:count
endfunction

" }}}1

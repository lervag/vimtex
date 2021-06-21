" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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

function! vimtex#fold#bib#get_max_key_width() " {{{1
  if g:vimtex_fold_bib_max_key_width > 0
    return g:vimtex_fold_bib_max_key_width
  endif

  let l:entries = vimtex#parser#bib#parse_cheap(1, line('$'),
        \ {'get_description': v:false})
  " Extra 3 is for the @ symbol plus curly braces.
  call map(l:entries, {_, e -> 3
        \ + strdisplaywidth(e.type)
        \ + strdisplaywidth(e.key)})
  return max(l:entries)
endfunction

" }}}1

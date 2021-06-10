" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#bib#text() abort " {{{1
  " Note that the actual folding is handled using foldmethod=syntax; this
  " merely generates the fold text.
  let l:entry_type = ''   " e.g. article, book, thesis, ...
  let l:key = ''          " the cite key
  let l:description = ''  " title of the work, or entryset for sets

  " Search the first line of the fold for the entry type and the key.
  let l:entry_type_key_match = matchlist(getline(v:foldstart),
        \ '\v\@(\S+)\s*\{\s*%((\S+)\s*,)?')
  if !empty(l:entry_type_key_match)
    let l:entry_type = l:entry_type_key_match[1]
    let l:key = l:entry_type_key_match[2]
    " If the key wasn't found, then check the second line of the fold to see
    " if it's there.
    if empty(l:key)
      let l:nextline_match = matchlist(getline(v:foldstart + 1),
            \ '\v^\s*(\S+)\s*,')
      if !empty(l:nextline_match)
        let l:key = l:nextline_match[1]
      endif
    endif
  endif

  " Search inside the fold for the title of the work (or the entryset, if it's
  " a set)
  let l:description_pattern = l:entry_type == 'set' ? 
        \ '\v^\s*entryset\s*\=\s*(\{.+\}|\".+\")\s*,?' :
        \ '\v^\s*title\s*\=\s*(\{.+\}|\".+\")\s*,?'
  let l:lnum = v:foldstart
  while l:lnum <= v:foldend
    let l:description_match = matchlist(getline(l:lnum), l:description_pattern)
    if l:description_match != []
      " Remove surrounding braces or quotes
      let l:description = l:description_match[1][1:-2]
      break
    else
      let l:lnum += 1
    endif
  endwhile

  " Construct the fold text
  if !empty(l:entry_type) && !empty(l:key)
    let l:foldtext = '@' . l:entry_type . '{' . l:key . '}'
    " Pad until the next 'tab' of 4 spaces, before adding in the title. 32
    " just seems like a sensible lower bound to accommodate cite keys of
    " typical lengths.
    let l:width = strdisplaywidth(l:foldtext)
    let l:desired_width = max([b:vimtex_fold_bib_maxwidth, l:width]) + 2
    let l:foldtext .= repeat(' ', l:desired_width - l:width)
    if !empty(l:description)
      let l:foldtext .= l:description
    endif
    return l:foldtext
  else
    " The entry type or key wasn't found; return the default fold text.
    return foldtext()
  endif
endfunction

" }}}1

function! vimtex#fold#bib#get_max_key_width() " {{{1
  let start_time = reltime()
  let l:lnum = 1
  let l:max_width = 0
  while l:lnum <= line('$')
    if trim(getline(l:lnum))[0] == '@'
      let l:entry_type = ''
      let l:key = ''
      let l:entry_type_key_match = matchlist(getline(l:lnum),
            \ '\v\@(\S+)\s*\{\s*%((\S+)\s*,)?')
      if !empty(l:entry_type_key_match)
        let l:entry_type = l:entry_type_key_match[1]
        let l:key = l:entry_type_key_match[2]
        " If the key wasn't found, then check the second line of the fold to see
        " if it's there.
        if !empty(l:entry_type) && empty(l:key)
          let l:nextline_match = matchlist(getline(l:lnum + 1),
                \ '\v^\s*(\S+)\s*,')
          if !empty(l:nextline_match)
            let l:key = l:nextline_match[1]
          endif
        endif
      endif
      if !empty(l:entry_type) && !empty(l:key)
        " the 3 extra characters includes the @ and the { }.
        let l:width = 3 + strdisplaywidth(l:entry_type) + strdisplaywidth(l:key)
        let l:max_width = max([l:max_width, l:width])
      endif
    endif
    let l:lnum += 1
  endwhile
  echo "elapsed time:" reltimestr(reltime(start_time))
  return l:max_width
endfunction

" }}}1

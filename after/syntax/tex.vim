" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !exists('b:current_syntax') || b:current_syntax !=# 'tex'
  echoerr 'vimtex syntax error: please report issue!'
  finish
endif

" Better support for cite commands
" \cite, \citep, \citet, \citeauthor, ...
syntax match texRefZone
      \ "\\\%(auto\|text\)\?cite\%([tp]\*\?\|author\)\?"
      \ nextgroup=texRefOption,texCite

" Add support for cleveref package
" \Cref, \cref, \cpageref, \labelcref, \labelcpageref
syntax region texRefZone matchgroup=texStatement
      \ start="\\\(\(label\)\?c\(page\)\?\|C\|auto\)ref{"
      \ end="}\|%stopzone\>"
      \ contains=@texRefGroup

" \crefrange, \cpagerefrange (these commands expect two arguments)
syntax match texStatement
      \ '\\c\(page\)\?refrange\>'
      \ nextgroup=texRefRangeStart skipwhite skipnl
syntax region texRefRangeStart
      \ start="{"rs=s+1  end="}"
      \ matchgroup=Delimiter
      \ contained contains=texRefZone
      \ nextgroup=texRefRangeEnd skipwhite skipnl
syntax region texRefRangeEnd
      \ start="{"rs=s+1 end="}"
      \ matchgroup=Delimiter
      \ contained contains=texRefZone
highlight link texRefRangeStart texRefZone
highlight link texRefRangeEnd   texRefZone

" {{{1 Support for listings package
syntax region texZone
      \ start="\\begin{lstlisting}"rs=s
      \ end="\\end{lstlisting}\|%stopzone\>"re=e
      \ keepend
      \ contains=texBeginEnd
syntax match texInputFile
      \ "\\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
      \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

" }}}1
" {{{1 Nested syntax highlighting for dot
unlet b:current_syntax
syntax include @DOT syntax/dot.vim
syntax region texZone
      \ start="\\begin{dot2tex}"rs=s
      \ end="\\end{dot2tex}"re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,@DOT
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for minted
let s:minted = get(g:, 'vimtex_syntax_minted', [
      \ {
      \   'lang' : 'c',
      \ },
      \ {
      \   'lang' : 'csharp',
      \   'syntax' : 'cs'
      \ },
      \ {
      \   'lang' : 'python',
      \   'ignore' : [
      \     'pythonEscape',
      \     'pythonBEscape',
      \     ],
      \ }
      \])

for entry in s:minted
  let lang = entry.lang
  let syntax = get(entry, 'syntax', lang)

  unlet b:current_syntax
  execute 'syntax include @' . toupper(lang) 'syntax/' . syntax . '.vim'

  if has_key(entry, 'ignore')
    execute 'syntax cluster' toupper(lang)
          \ 'remove=' . join(entry.ignore, ',')
  endif

  execute 'syntax region texZone'
        \ 'start="\\begin{minted}\_[^}]\{-}{' . lang . '}"rs=s'
        \ 'end="\\end{minted}"re=e'
        \ 'keepend'
        \ 'transparent'
        \ 'contains=texMinted,@' . toupper(lang)

  execute 'syntax region texZone'
        \ 'start="\\begin{' . lang . 'code\*\?}\(\s*\[.\{-}\]\)\?"rs=s'
        \ 'end="\\end{' . lang . 'code\*\?}"re=e'
        \ 'keepend'
        \ 'transparent'
        \ 'contains=texMinted,@' . toupper(lang)
endfor
let b:current_syntax = 'tex'

syntax match texMinted "\\begin{minted}\_[^}]\{-}{\w\+}"
      \ contains=texBeginEnd,texMintedName
syntax match texMinted "\\end{minted}"
      \ contains=texBeginEnd
syntax match texMinted "\\begin{\w*code\*\?}\(\s*\[.\{-}\]\)\?"
      \ contains=texBeginEnd,texMintedName
syntax match texMinted "\\end{\w*code\*\?}"
      \ contains=texBeginEnd
syntax match texMintedName "{\w\+}"

highlight link texMintedName texBeginEndName

" }}}1

" vim: fdm=marker sw=2

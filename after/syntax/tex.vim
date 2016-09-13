" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !exists('b:current_syntax')
  let b:current_syntax = 'tex'
elseif b:current_syntax !=# 'tex'
  echoerr 'vimtex syntax error: please report issue!'
  finish
endif

" Perform spell checking when there is no syntax
" - This will enable spell checking e.g. in toplevel of included files
syntax spell toplevel

" {{{1 General match improvements

syntax match texInputFile /\\includepdf\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt

" {{{1 Italic font, bold font and conceals

if get(g:, 'tex_fast', 'b') =~# 'b'
  let conceal = (has('conceal') && get(g:, 'tex_conceal', 'b') =~# 'b')
        \ ? 'concealends' : ''

  for [style, group, commands] in [
        \ ['texItalStyle', 'texItalGroup', ['emph', 'textit']],
        \ ['texBoldStyle', 'texBoldGroup', ['textbf']],
        \]
    for cmd in commands
      execute 'syntax region' style 'matchgroup=texTypeStyle'
            \ 'start="\\' . cmd . '\s*{" end="}"'
            \ 'contains=@Spell,@' . group
            \ conceal
    endfor
    execute 'syntax cluster texMatchGroup add=' . style
  endfor
endif

" }}}1
" {{{1 Add syntax highlighting for \url, \href, \hyperref

syntax match texStatement '\\url\ze[^\ta-zA-Z]' nextgroup=texUrlVerb
syntax region texUrlVerb matchgroup=Delimiter
      \ start='\z([^\ta-zA-Z]\)' end='\z1' contained

syntax match texStatement '\\url\ze\s*{' nextgroup=texUrl
syntax region texUrl     matchgroup=Delimiter start='{' end='}' contained

syntax match texStatement '\\href' nextgroup=texHref
syntax region texHref matchgroup=Delimiter start='{' end='}' contained
      \ nextgroup=texMatcher

syntax match texStatement '\\hyperref' nextgroup=texHyperref
syntax region texHyperref matchgroup=Delimiter start='\[' end='\]' contained

highlight link texUrl          Function
highlight link texUrlVerb      texUrl
highlight link texHref         texUrl
highlight link texHyperref     texRefZone

" }}}1
" {{{1 Improve support for cite commands
if get(g:, 'tex_fast', 'r') =~# 'r'
  "
  " natbib
  "
  syntax match texStatement '\\cite\%([tp]\*\?\)\?'
        \ nextgroup=texRefOption,texCite

  "
  " biblatex
  "
  execute 'syntax match texStatement /\v\\%(' . join([
        \   '[Cc]iteauthor\*?',
        \   '[Cc]ite%(title|year|date)?\*?',
        \   'citeurl',
        \   '[Pp]arencite\*?',
        \   'foot%(full)?cite%(text)?',
        \   'fullcite',
        \   '[Tt]extcite',
        \   '[Ss]martcite',
        \   'supercite',
        \   '[Aa]utocite\*?',
        \   '[Ppf]?[Nn]otecite'], '|') . ')/'
        \ 'nextgroup=texRefOption,texCite'

  execute 'syntax match texStatement /\v\\%(' . join([
        \   '[Cc]ites',
        \   '[Pp]arencites',
        \   'footcite%(s|texts)',
        \   '[Tt]extcites',
        \   '[Ss]martcites',
        \   'supercites',
        \   '[Aa]utocites'], '|') . ')/'
        \ 'nextgroup=texRefOptions,texCites'

  execute 'syntax match texStatement /\\[pPfFsStTaA]\?[Vv]olcites\?/'
        \ 'nextgroup=texRefOptions,texCites'

  execute 'syntax match texStatement /\\cite\%(field\|list\|name\)/'
        \ 'nextgroup=texRefOptions,texCites'

  syntax region texRefOptions contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texRefGroup,texRefZone
        \ nextgroup=texRefOptions,texCites

  syntax region texCites contained matchgroup=Delimiter
        \ start='{' end='}'
        \ contains=@texRefGroup,texRefZone,texCites
        \ nextgroup=texRefOptions,texCites

  highlight def link texRefOptions texRefOption
  highlight def link texCites texCite
endif

" }}}1
" {{{1 Add support for cleveref package
if get(g:, 'tex_fast', 'r') =~# 'r'
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
endif

" }}}1
" {{{1 Add support for listings package
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
" {{{1 Nested syntax highlighting for lualatex
unlet b:current_syntax
syntax include @LUA syntax/lua.vim
syntax region texZone
      \ start='\\begin{luacode\*\?}'rs=s
      \ end='\\end{luacode\*\?}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,@LUA
syntax region texZone
      \ start='\\\(directlua\|luadirect\){'rs=s
      \ end='}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,@LUA
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for gnuplottex
unlet b:current_syntax
syntax include @GNUPLOT syntax/gnuplot.vim
syntax region texZone
      \ start='\\begin{gnuplot}\(\_s*\[\_[\]]\{-}\]\)\?'rs=s
      \ end='\\end{gnuplot}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,texBeginEndModifier,@GNUPLOT
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for minted

" First set all minted environments to listings
syntax region texZone
      \ start="\\begin{minted}\_[^}]\{-}{\w\+}"rs=s
      \ end="\\end{minted}"re=e
      \ keepend
      \ contains=texMinted

" Next add nested syntax support for desired languages
for entry in get(g:, 'vimtex_syntax_minted', [])
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

  "
  " Support for custom environment names
  "
  for env in get(entry, 'environments', [])
    execute 'syntax region texZone'
          \ 'start="\\begin{' . env . '}"rs=s'
          \ 'end="\\end{' . env . '}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texBeginEnd,@' . toupper(lang)

    " Match starred environments with options
    execute 'syntax region texZone'
          \ 'start="\\begin{' . env . '\*}\s*{\_.\{-}}"rs=s'
          \ 'end="\\end{' . env . '\*}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMintedStarred,texBeginEnd,@' . toupper(lang)
    execute 'syntax match texMintedStarred'
          \ '"\\begin{' . env . '\*}\s*{\_.\{-}}"'
          \ 'contains=texBeginEnd,texDelimiter'
  endfor
endfor
let b:current_syntax = 'tex'

syntax match texMinted '\\begin{minted}\_[^}]\{-}{\w\+}'
      \ contains=texBeginEnd,texMintedName
syntax match texMinted '\\end{minted}'
      \ contains=texBeginEnd
syntax match texMintedName '{\w\+}' contained

highlight link texMintedName texBeginEndName

" }}}1

" vim: fdm=marker sw=2

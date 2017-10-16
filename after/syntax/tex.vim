" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !exists('b:current_syntax')
  let b:current_syntax = 'tex'
elseif b:current_syntax !=# 'tex'
  finish
endif

" Perform spell checking when there is no syntax
" - This will enable spell checking e.g. in toplevel of included files
syntax spell toplevel

" {{{1 Improve handling of newcommand and newenvironment commands

" Allow arguments in newenvironments
syntax region texEnvName contained matchgroup=Delimiter
      \ start="{"rs=s+1  end="}"
      \ nextgroup=texEnvBgn,texEnvArgs contained skipwhite skipnl
syntax region texEnvArgs contained matchgroup=Delimiter
      \ start="\["rs=s+1 end="]"
      \ nextgroup=texEnvBgn,texEnvArgs
      \ skipwhite skipnl
syntax cluster texEnvGroup add=texDefParm,texNewEnv,texComment

" Add support for \renewcommand and \renewenvironment
syntax match texNewCmd "\\renewcommand\>"
      \ nextgroup=texCmdName skipwhite skipnl
syntax match texNewEnv "\\renewenvironment\>"
      \ nextgroup=texEnvName skipwhite skipnl

" Match nested DefParms
syntax match texDefParmNested contained "##\+\d\+"
highlight def link texDefParmNested Identifier
syntax cluster texEnvGroup add=texDefParmNested
syntax cluster texCmdGroup add=texDefParmNested

" }}}1
" {{{1 General match improvements

syntax match texInputFile /\\includepdf\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt

" {{{1 Italic font, bold font and conceals

if get(g:, 'tex_fast', 'b') =~# 'b'
  let s:conceal = (has('conceal') && get(g:, 'tex_conceal', 'b') =~# 'b')
        \ ? 'concealends' : ''

  for [s:style, s:group, s:commands] in [
        \ ['texItalStyle', 'texItalGroup', ['emph', 'textit']],
        \ ['texBoldStyle', 'texBoldGroup', ['textbf']],
        \]
    for s:cmd in s:commands
      execute 'syntax region' s:style 'matchgroup=texTypeStyle'
            \ 'start="\\' . s:cmd . '\s*{" end="}"'
            \ 'contains=@Spell,@' . s:group
            \ s:conceal
    endfor
    execute 'syntax cluster texMatchGroup add=' . s:style
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
" {{{1 Add support for biblatex and csquotes packages (cite commands)

if get(g:, 'tex_fast', 'r') =~# 'r'

  for s:pattern in [
        \ 'bibentry',
        \ 'cite[pt]?\*?',
        \ 'citeal[tp]\*?',
        \ 'cite(num|text|url)',
        \ '[Cc]ite%(title|author|year(par)?|date)\*?',
        \ '[Pp]arencite\*?',
        \ 'foot%(full)?cite%(text)?',
        \ 'fullcite',
        \ '[Tt]extcite',
        \ '[Ss]martcite',
        \ 'supercite',
        \ '[Aa]utocite\*?',
        \ '[Ppf]?[Nn]otecite',
        \ '%(text|block)cquote\*?',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texRefOption,texCite'
  endfor

  for s:pattern in [
        \ '[Cc]ites',
        \ '[Pp]arencites',
        \ 'footcite%(s|texts)',
        \ '[Tt]extcites',
        \ '[Ss]martcites',
        \ 'supercites',
        \ '[Aa]utocites',
        \ '[pPfFsStTaA]?[Vv]olcites?',
        \ 'cite%(field|list|name)',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texRefOptions,texCites'
  endfor

  for s:pattern in [
        \ '%(foreign|hyphen)textcquote\*?',
        \ '%(foreign|hyphen)blockcquote',
        \ 'hybridblockcquote',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texQuoteLang'
  endfor

  syntax region texRefOptions contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texRefGroup,texRefZone
        \ nextgroup=texRefOptions,texCites

  syntax region texCites contained matchgroup=Delimiter
        \ start='{' end='}'
        \ contains=@texRefGroup,texRefZone,texCites
        \ nextgroup=texRefOptions,texCites

  syntax region texQuoteLang contained matchgroup=Delimiter
        \ start='{' end='}'
        \ transparent
        \ contains=@texMatchGroup
        \ nextgroup=texRefOption,texCite

  highlight def link texRefOptions texRefOption
  highlight def link texCites texCite
endif

" }}}1
" {{{1 Add support for array package

"
" The following code changes inline math so as to support the column
" specifiers [0], e.g.
"
"   \begin{tabular}{*{3}{>{$}c<{$}}}
"
" [0]: https://en.wikibooks.org/wiki/LaTeX/Tables#Column_specification_using_.3E.7B.5Ccmd.7D_and_.3C.7B.5Ccmd.7D
"

if exists('b:vimtex.packages.array') && get(g:, 'tex_fast', 'M') =~# 'M'
  syntax clear texMathZoneX
  if has('conceal') && &enc ==# 'utf-8' && get(g:, 'tex_conceal', 'd') =~# 'd'
    syntax region texMathZoneX matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$" end="%stopzone\>" concealends contains=@texMathZoneGroup
  else
    syntax region texMathZoneX matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$" end="%stopzone\>" contains=@texMathZoneGroup
  endif
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

  " \label[xxx]{asd}
  syntax match texStatement '\\label\[.\{-}\]'
        \ nextgroup=texLabelRef skipwhite skipnl
        \ contains=texLabelOpts
  syntax region texLabelOpts contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texRefGroup,texRefZone
  syntax region texLabelRef contained matchgroup=Delimiter
        \ start='{' end='}'
        \ contains=@texRefGroup,texRefZone

  highlight link texRefRangeStart texRefZone
  highlight link texRefRangeEnd   texRefZone
  highlight link texLabelRef      texRefZone
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
" {{{1 Add support for beamer package
syntax match texBeamerDelimiter '<\|>' contained
syntax match texBeamerOpt '<[^>]*>' contained contains=texBeamerDelimiter

syntax match texStatementBeamer '\\only\(<[^>]*>\)\?' contains=texBeamerOpt
syntax match texStatementBeamer '\\item<[^>]*>' contains=texBeamerOpt

syntax match texInputFile
      \ '\\includegraphics<[^>]*>\(\[.\{-}\]\)\=\s*{.\{-}}'
      \ contains=texStatement,texBeamerOpt,texInputCurlies,texInputFileOpt

syntax cluster texDocGroup add=texStatementBeamer

highlight link texStatementBeamer texStatement
highlight link texBeamerOpt Identifier
highlight link texBeamerDelimiter Delimiter

" }}}1
" {{{1 Nested syntax highlighting for dot
unlet b:current_syntax
syntax include @DOT syntax/dot.vim
syntax cluster texDocGroup add=texZoneDot
syntax region texZoneDot
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
syntax cluster texDocGroup add=texZoneLua
syntax region texZoneLua
      \ start='\\begin{luacode\*\?}'rs=s
      \ end='\\end{luacode\*\?}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,@LUA
syntax match texStatement '\\\(directlua\|luadirect\)' nextgroup=texZoneLuaArg
syntax region texZoneLuaArg matchgroup=Delimiter
      \ start='{'
      \ end='}'
      \ contained
      \ contains=@LUA
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for gnuplottex
unlet b:current_syntax
syntax include @GNUPLOT syntax/gnuplot.vim
syntax cluster texDocGroup add=texZoneGnuplot
syntax region texZoneGnuplot
      \ start='\\begin{gnuplot}\(\_s*\[\_[\]]\{-}\]\)\?'rs=s
      \ end='\\end{gnuplot}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,texBeginEndModifier,@GNUPLOT
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for asymptote
unlet b:current_syntax
try
  syntax include @ASYMPTOTE syntax/asy.vim
  syntax cluster texDocGroup add=texZoneAsymptote
  syntax region texZoneAsymptote
        \ start='\\begin{asy}'rs=s
        \ end='\\end{asy}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@ASYMPTOTE
  syntax region texZoneAsymptote
        \ start='\\begin{asydef}'rs=s
        \ end='\\end{asydef}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@ASYMPTOTE
catch /^Vim.*E484/
endtry
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for minted

" First set all minted environments to listings
syntax cluster texFoldGroup add=texZoneMinted
syntax region texZoneMinted
      \ start="\\begin{minted}\_[^}]\{-}{\w\+}"rs=s
      \ end="\\end{minted}"re=e
      \ keepend
      \ contains=texMinted

" Next add nested syntax support for desired languages
for s:entry in get(g:, 'vimtex_syntax_minted', [])
  let s:lang = s:entry.lang
  let s:syntax = get(s:entry, 'syntax', s:lang)

  let s:group_name = 'texZoneMinted' . toupper(s:lang[0]) . s:lang[1:]
  execute 'syntax cluster texFoldGroup add=' . s:group_name

  unlet b:current_syntax
  execute 'syntax include @' . toupper(s:lang) 'syntax/' . s:syntax . '.vim'

  if has_key(s:entry, 'ignore')
    execute 'syntax cluster' toupper(s:lang)
          \ 'remove=' . join(s:entry.ignore, ',')
  endif

  execute 'syntax region' s:group_name
        \ 'start="\\begin{minted}\_[^}]\{-}{' . s:lang . '}"rs=s'
        \ 'end="\\end{minted}"re=e'
        \ 'keepend'
        \ 'transparent'
        \ 'contains=texMinted,@' . toupper(s:lang)

  "
  " Support for custom environment names
  "
  for s:env in get(s:entry, 'environments', [])
    execute 'syntax region' s:group_name
          \ 'start="\\begin{' . s:env . '}"rs=s'
          \ 'end="\\end{' . s:env . '}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texBeginEnd,@' . toupper(s:lang)

    " Match starred environments with options
    execute 'syntax region' s:group_name
          \ 'start="\\begin{' . s:env . '\*}\s*{\_.\{-}}"rs=s'
          \ 'end="\\end{' . s:env . '\*}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMintedStarred,texBeginEnd,@' . toupper(s:lang)
    execute 'syntax match texMintedStarred'
          \ '"\\begin{' . s:env . '\*}\s*{\_.\{-}}"'
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

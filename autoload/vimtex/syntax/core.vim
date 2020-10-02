" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#core#init() abort " {{{1
  " Syntax may be loaded without the main vimtex functionality, thus we need to
  " ensure that the options are loaded!
  call vimtex#options#init()

  syntax spell toplevel

  syntax sync maxlines=500
  syntax sync minlines=50

  let l:cfg = deepcopy(g:vimtex_syntax_config)
  let l:cfg.ext = expand('%:e')
  let l:cfg.is_style_document =
        \ index(['sty', 'cls', 'clo', 'dtx', 'ltx'], l:cfg.ext) >= 0

  call s:init_clusters()

  " {{{2 Primitives

  " Delimiters
  syntax region texMatcher     matchgroup=Delimiter start="{"  skip="\%(\\\\\)*\\}" end="}" transparent contains=@texMatchGroup,texError
  syntax region texMatcher     matchgroup=Delimiter start="\["                      end="]" transparent contains=@texMatchGroup,texError,@NoSpell
  syntax region texMathMatcher matchgroup=Delimiter start="{"  skip="\%(\\\\\)*\\}" end="}" contained   contains=@texMathMatchGroup
  syntax region texParen                            start="("                       end=")" transparent contains=@texMatchGroup,@Spell

  syntax match texDelimiter "&"

  " TeX String Delimiters
  syntax match texString "\(``\|''\|,,\)"

  " Flag mismatching ending delimiters } and ]
  syntax match texError "[}\]]"
  syntax match texErrorMath "}" contained

  " Tex commands
  syntax match texStatement "\\\a\+"
  syntax match texErrorStatement "\\\a*@\a*"

  " Accents and ligatures
  syntax match texAccent "\\[bcdvuH]$"
  syntax match texAccent "\\[bcdvuH]\ze\A"
  syntax match texAccent /\\[=^.\~"`']/
  syntax match texAccent /\\['=t'.c^ud"vb~Hr]{\a}/
  syntax match texLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)$"
  syntax match texLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze\A"
  syntax match texLigature '--'
  syntax match texLigature '---'

  if l:cfg.is_style_document
    syntax match texStatement "\\[a-zA-Z@]\+"
    syntax match texAccent "\\[bcdvuH]\ze[^a-zA-Z@]"
    syntax match texLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze[^a-zA-Z@]"
  endif

  " Environments
  syntax match  texBeginEnd "\v\\%(begin|end)>" nextgroup=texBeginEndName
  syntax region texBeginEndName     matchgroup=Delimiter start="{"  end="}" contained contains=texComment nextgroup=texBeginEndModifier
  syntax region texBeginEndModifier matchgroup=Delimiter start="\[" end="]" contained contains=texComment,@texMathZones,@NoSpell

  " Some common, specific LaTeX commands
  " TODO: This should be updated!
  syntax match texDocType "\v\\%(documentclass|documentstyle|usepackage)>" nextgroup=texBeginEndName,texDocTypeArgs
  syntax region texDocTypeArgs matchgroup=Delimiter start="\[" end="]" contained nextgroup=texBeginEndName contains=texComment,@NoSpell

  " Other
  syntax match texOption "\v%(^|[^\\]\zs)#\d+"

  " TeX input
  syntax match texInput         "\\input\s\+[a-zA-Z/.0-9_^]\+"hs=s+7                  contains=texStatement
  syntax match texInputFile     "\v\\include%(graphics|list)?%(\[.{-}\])?\s*\{.{-}\}" contains=texStatement,texInputCurlies,texInputFileOpt
  syntax match texInputFile     "\v\\%(epsfig|input|usepackage)\s*%(\[.*\])?\{.{-}\}" contains=texStatement,texInputCurlies,texInputFileOpt
  syntax match texInputCurlies  "[{}]"                                                contained
  syntax region texInputFileOpt matchgroup=Delimiter start="\[" end="\]"              contains=texComment contained

  " Spacecodes (TeX'isms)
  " * \mathcode`\^^@ = "2201
  " * \delcode`\( = "028300
  " * \sfcode`\) = 0
  " * \uccode`X = `X
  " * \lccode`x = `x
  syntax match texSpaceCode     "\v\\%(math|cat|del|lc|sf|uc)code`"me=e-1 nextgroup=texSpaceCodeChar
  syntax match texSpaceCodeChar "\v`\\?.%(\^.)?\?%(\d|\"\x{1,6}|`.)" contained

  " Comments
  if l:cfg.ext ==# 'dtx'
    " Documented TeX Format: Only leading "^^A" and "%"
    syntax match texComment "\^\^A.*$" contains=@texCommentGroup
    syntax match texComment "^%\+"     contains=@texCommentGroup
  else
    syntax match texComment "%.*$" contains=@texCommentGroup
  endif

  " Todo and similar within comments
  syntax case ignore
  syntax keyword texTodo contained combak fixme todo xxx
  syntax case match

  " TeX Lengths
  syntax match texLength "\<\d\+\([.,]\d\+\)\?\s*\(true\)\?\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

  " }}}2
  " {{{2 Type Styles

  " LaTeX 2.09:
  syntax match texTypeStyle "\\rm\>"
  syntax match texTypeStyle "\\em\>"
  syntax match texTypeStyle "\\bf\>"
  syntax match texTypeStyle "\\it\>"
  syntax match texTypeStyle "\\sl\>"
  syntax match texTypeStyle "\\sf\>"
  syntax match texTypeStyle "\\sc\>"
  syntax match texTypeStyle "\\tt\>"

  " LaTeX2E
  syntax match texTypeStyle "\\textbf\>"
  syntax match texTypeStyle "\\textit\>"
  syntax match texTypeStyle "\\emph\>"
  syntax match texTypeStyle "\\textmd\>"
  syntax match texTypeStyle "\\textrm\>"

  syntax match texTypeStyle "\\mathbb\>"
  syntax match texTypeStyle "\\mathbf\>"
  syntax match texTypeStyle "\\mathcal\>"
  syntax match texTypeStyle "\\mathfrak\>"
  syntax match texTypeStyle "\\mathit\>"
  syntax match texTypeStyle "\\mathnormal\>"
  syntax match texTypeStyle "\\mathrm\>"
  syntax match texTypeStyle "\\mathsf\>"
  syntax match texTypeStyle "\\mathtt\>"

  syntax match texTypeStyle "\\rmfamily\>"
  syntax match texTypeStyle "\\sffamily\>"
  syntax match texTypeStyle "\\ttfamily\>"

  syntax match texTypeStyle "\\itshape\>"
  syntax match texTypeStyle "\\scshape\>"
  syntax match texTypeStyle "\\slshape\>"
  syntax match texTypeStyle "\\upshape\>"

  syntax match texTypeStyle "\\bfseries\>"
  syntax match texTypeStyle "\\mdseries\>"

  " }}}2
  " {{{2 Type sizes

  syntax match texTypeSize "\\tiny\>"
  syntax match texTypeSize "\\scriptsize\>"
  syntax match texTypeSize "\\footnotesize\>"
  syntax match texTypeSize "\\small\>"
  syntax match texTypeSize "\\normalsize\>"
  syntax match texTypeSize "\\large\>"
  syntax match texTypeSize "\\Large\>"
  syntax match texTypeSize "\\LARGE\>"
  syntax match texTypeSize "\\huge\>"
  syntax match texTypeSize "\\Huge\>"

  " }}}2

  " {{{2 Zones! I think this should be removed!

  syntax region texDocZone matchgroup=texSection start='\\begin\s*{\s*document\s*}' end='\\end\s*{\s*document\s*}' contains=@texZoneGroup,@texDocGroup,@Spell
  syntax region texPartZone matchgroup=texSection start='\\part\>' end='\ze\s*\\\%(part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texPartGroup,@Spell
  syntax region texChapterZone matchgroup=texSection start='\\chapter\>' end='\ze\s*\\\%(chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texChapterGroup,@Spell
  syntax region texSectionZone matchgroup=texSection start='\\section\>' end='\ze\s*\\\%(section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSectionGroup,@Spell
  syntax region texSubSectionZone matchgroup=texSection start='\\subsection\>' end='\ze\s*\\\%(\%(sub\)\?section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSubSectionGroup,@Spell
  syntax region texSubSubSectionZone matchgroup=texSection start='\\subsubsection\>' end='\ze\s*\\\%(\%(sub\)\{,2}section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSubSubSectionGroup,@Spell
  syntax region texParaZone matchgroup=texSection start='\\paragraph\>' end='\ze\s*\\\%(paragraph\>\|\%(sub\)*section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texParaGroup,@Spell
  syntax region texSubParaZone matchgroup=texSection start='\\subparagraph\>' end='\ze\s*\\\%(\%(sub\)\?paragraph\>\|\%(sub\)*section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@Spell
  syntax region texTitle matchgroup=texSection start='\\\%(author\|title\)\>\s*{' end='}' contains=@texZoneGroup,@Spell
  syntax region texAbstract matchgroup=texSection start='\\begin\s*{\s*abstract\s*}' end='\\end\s*{\s*abstract\s*}' contains=@texZoneGroup,@Spell

  " }}}2

  " {{{2 Math stuff

  " Bad/Mismatched math
  syntax match texBadMath "\\end\s*{\s*\(array\|[bBpvV]matrix\|split\|smallmatrix\)\s*}"
  syntax match texBadMath "\\[\])]"

  " Operators and similar
  syntax match texMathOper "[_^=]" contained

  " Text Inside Math Zones
  syntax region texMathText matchgroup=texStatement start="\\\(\(inter\)\?text\|mbox\)\s*{" end="}" contains=@texZoneGroup,@Spell

  " Math environments
  call vimtex#syntax#core#new_math_zone('A', 'displaymath', 1)
  call vimtex#syntax#core#new_math_zone('B', 'eqnarray', 1)
  call vimtex#syntax#core#new_math_zone('C', 'equation', 1)
  call vimtex#syntax#core#new_math_zone('D', 'math', 1)

  " Inline Math Zones
  syntax region texMathZoneZ matchgroup=texStatement start="\\ensuremath\s*{" matchgroup=texStatement end="}" contains=@texMathZoneGroup
  if l:cfg.conceal =~# 'd' && &encoding ==# 'utf-8'
    syntax region texMathZoneV matchgroup=Delimiter start="\\("                      matchgroup=Delimiter end="\\)"  concealends contains=@texMathZoneGroup keepend
    syntax region texMathZoneW matchgroup=Delimiter start="\\\["                     matchgroup=Delimiter end="\\]"  concealends contains=@texMathZoneGroup keepend
    syntax region texMathZoneX matchgroup=Delimiter start="\$" skip="\\\\\|\\\$"     matchgroup=Delimiter end="\$"   concealends contains=@texMathZoneGroup
    syntax region texMathZoneY matchgroup=Delimiter start="\$\$"                     matchgroup=Delimiter end="\$\$" concealends contains=@texMathZoneGroup keepend
  else
    syntax region texMathZoneV matchgroup=Delimiter start="\\("                      matchgroup=Delimiter end="\\)"  contains=@texMathZoneGroup keepend
    syntax region texMathZoneW matchgroup=Delimiter start="\\\["                     matchgroup=Delimiter end="\\]"  contains=@texMathZoneGroup keepend
    syntax region texMathZoneX matchgroup=Delimiter start="\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$"   contains=@texMathZoneGroup
    syntax region texMathZoneY matchgroup=Delimiter start="\$\$"                     matchgroup=Delimiter end="\$\$" contains=@texMathZoneGroup keepend
  endif

  " Math delimiters: \left... and \right...
  syntax match texMathDelimBad contained "\S"
  if l:cfg.conceal !~# 'm' || &encoding !=# 'utf-8'
    syntax match   texMathDelim      "\\\(left\|right\)\>"   contained skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad
    syntax match   texMathDelim      "\\[bB]igg\?[lr]\?\>"   contained skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad
    syntax match   texMathDelimSet2  "\\"                    contained           nextgroup=texMathDelimKey,texMathDelimBad
    syntax match   texMathDelimSet1  "[<>()[\]|/.]\|\\[{}|]" contained
    syntax keyword texMathDelimKey contained backslash lceil      lVert  rgroup     uparrow
    syntax keyword texMathDelimKey contained downarrow lfloor     rangle rmoustache Uparrow
    syntax keyword texMathDelimKey contained Downarrow lgroup     rbrace rvert      updownarrow
    syntax keyword texMathDelimKey contained langle    lmoustache rceil  rVert      Updownarrow
    syntax keyword texMathDelimKey contained lbrace    lvert      rfloor
  else
    syntax match texMathDelim "\\left\["        contained
    syntax match texMathDelim "\\left\\{"       contained skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad contains=texMathSymbol cchar={
    syntax match texMathDelim "\\right\\}"      contained skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad contains=texMathSymbol cchar=}
    syntax match texMathDelim '\\[bB]igg\?[lr]' contained           nextgroup=texMathDelimBad
    call s:match_conceal_math_delims()
  endif
  syntax match texMathDelim contained "\\\(left\|right\)arrow\>\|\<\([aA]rrow\|brace\)\?vert\>"
  syntax match texMathDelim contained "\\lefteqn\>"

  " {{{2 Special TeX characters

  " E.g.:  \$ \& \% \# \{ \} \_ \S \P

  syntax match texSpecialChar "\\[$&%#{}_]"
  if l:cfg.is_style_document
    syntax match texSpecialChar "\\[SP@]\ze[^a-zA-Z@]"
  else
    syntax match texSpecialChar "\\[SP@]\ze\A"
  endif
  syntax match texSpecialChar "\\\\"
  syntax match texOnlyMath "[_^]"
  syntax match texSpecialChar "\^\^[0-9a-f]\{2}\|\^\^\S"

  " {{{2 Specific commands/environments

  " Verbatim
  syntax region texZone start="\\begin{[vV]erbatim}" end="\\end{[vV]erbatim}"
  syntax region texZone start="\\verb\*\?\z([^\ta-zA-Z]\)"  end="\z1"
  if l:cfg.is_style_document
    syntax region texZone start="\\verb\*\?\z([^\ta-zA-Z@]\)" end="\z1"
  endif

  " Tex Reference Zones
  syntax region texZone      matchgroup=texStatement start="@samp{"             end="}"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\nocite{"          end="}"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\bibliography{"    end="}"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\label{"           end="}"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\\(page\|eq\)ref{" end="}"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\v\?ref{"          end="}"  contains=@texRefGroup
  syntax region texRefOption contained matchgroup=Delimiter start='\[' end=']' contains=@texRefGroup,texRefZone        nextgroup=texRefOption,texCite
  syntax region texCite      contained matchgroup=Delimiter start='{' end='}'  contains=@texRefGroup,texRefZone,texCite
  syntax match  texRefZone '\\cite\%([tp]\*\?\)\?\>' nextgroup=texRefOption,texCite

  " \makeatletter ... \makeatother sections
  syntax region texStyle matchgroup=texStatement start='\\makeatletter' end='\\makeatother' contains=@texStyleGroup
  syntax match texStyleStatement "\\[a-zA-Z@]\+" contained
  syntax region texStyleMatcher matchgroup=Delimiter start="{" skip="\\\\\|\\[{}]" end="}" contains=@texStyleGroup,texError contained
  syntax region texStyleMatcher matchgroup=Delimiter start="\[" end="]" contains=@texStyleGroup,texError contained

  " }}}2

  " {{{2 Handle new(command|environment)

  syntax match  texNewCmd "\\newcommand\>" nextgroup=texCmdName skipwhite skipnl
  syntax region texCmdName contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texCmdArgs,texCmdBody skipwhite skipnl
  syntax region texCmdArgs contained matchgroup=Delimiter start="\["rs=s+1 end="]" nextgroup=texCmdBody skipwhite skipnl
  syntax region texCmdBody contained matchgroup=Delimiter start="{"rs=s+1 skip="\\\\\|\\[{}]" matchgroup=Delimiter end="}" contains=@texCmdGroup
  syntax match texNewEnv "\\newenvironment\>" nextgroup=texEnvName skipwhite skipnl
  syntax region texEnvName contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texEnvBgn skipwhite skipnl
  syntax region texEnvBgn contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texEnvEnd skipwhite skipnl contains=@texEnvGroup
  syntax region texEnvEnd contained matchgroup=Delimiter start="{"rs=s+1 end="}" skipwhite skipnl contains=@texEnvGroup

  " {{{2 Definitions/Commands

  syntax match texDefCmd              "\\def\>"       nextgroup=texDefName skipwhite skipnl
  if l:cfg.is_style_document
    syntax match texDefName contained "\\[a-zA-Z@]\+" nextgroup=texDefParms,texCmdBody skipwhite skipnl
    syntax match texDefName contained "\\[^a-zA-Z@]"  nextgroup=texDefParms,texCmdBody skipwhite skipnl
  else
    syntax match texDefName contained "\\\a\+"        nextgroup=texDefParms,texCmdBody skipwhite skipnl
    syntax match texDefName contained "\\\A"          nextgroup=texDefParms,texCmdBody skipwhite skipnl
  endif
  syntax match texDefParms  contained "#[^{]*"        contains=texDefParm nextgroup=texCmdBody skipwhite skipnl
  syntax match  texDefParm  contained "#\d\+"

  " {{{2 Conceal mode support

  " Add support for conceal with custom replacement (conceallevel = 2)

  if &encoding ==# 'utf-8'
    if l:cfg.conceal =~# 'b'
      syntax region texBoldStyle     matchgroup=texTypeStyle start="\\textbf\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
      syntax region texBoldItalStyle matchgroup=texTypeStyle start="\\textit\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
      syntax region texItalStyle     matchgroup=texTypeStyle start="\\textit\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
      syntax region texItalBoldStyle matchgroup=texTypeStyle start="\\textbf\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
      syntax region texEmphStyle     matchgroup=texTypeStyle start="\\emph\s*{"   matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
      syntax region texEmphStyle     matchgroup=texTypeStyle start="\\texts[cfl]\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
      syntax region texEmphStyle     matchgroup=texTypeStyle start="\\textup\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
      syntax region texEmphStyle     matchgroup=texTypeStyle start="\\texttt\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
    endif

    if l:cfg.conceal =~# 'S'
      syntax match texSpecialChar '\\glq\>'  contained conceal cchar=‚
      syntax match texSpecialChar '\\grq\>'  contained conceal cchar=‘
      syntax match texSpecialChar '\\glqq\>' contained conceal cchar=„
      syntax match texSpecialChar '\\grqq\>' contained conceal cchar=“
      syntax match texSpecialChar '\\hyp\>'  contained conceal cchar=-
    endif

    " Many of these symbols were contributed by Björn Winckler
    if l:cfg.conceal =~# 'm'
      call s:match_conceal_math_symbols()
    endif

    " Conceal replace greek letters
    if l:cfg.conceal =~# 'g'
      call s:match_conceal_greek()
    endif

    " Conceal replace superscripts and subscripts
    if l:cfg.conceal =~# 's'
      call s:match_conceal_super_sub(l:cfg)
    endif

    " Conceal replace accented characters and ligatures
    if l:cfg.conceal =~# 'a' && !l:cfg.is_style_document
      call s:match_conceal_accents()
    endif
  endif

  " }}}2

  " The $..$ and $$..$$ make for impossible sync patterns (one can't tell if
  " a "$$" starts or stops a math zone by itself) The following grouptheres
  " coupled with minlines above help improve the odds of good syncing.
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{abstract}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{center}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{description}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{enumerate}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{itemize}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{table}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{tabular}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\\(sub\)*section\>"

  call s:init_highlights(l:cfg)

  let b:current_syntax = 'tex'

  " Load some general syntax improvements
  call vimtex#syntax#load#general()

  if exists('b:vimtex')
    call vimtex#syntax#core#load()
  else
    augroup vimtex_syntax
      autocmd!
      autocmd User VimtexEventInitPost call vimtex#syntax#core#load()
    augroup END
  endif
endfunction

" }}}1
function! vimtex#syntax#core#load() abort " {{{1
  " Initialize b:vimtex_syntax
  let b:vimtex_syntax = {}

  " Initialize project cache (used e.g. for the minted package)
  if !has_key(b:vimtex, 'syntax')
    let b:vimtex.syntax = {}
  endif

  " Reset included syntaxes (necessary e.g. when doing :e)
  call vimtex#syntax#misc#include_reset()

  " Load syntax for documentclass and packages
  call vimtex#syntax#load#packages()
endfunction

" }}}1

function! vimtex#syntax#core#new_math_zone(sfx, mathzone, starred) abort " {{{1
  " This function is based on Charles E. Campbell's syntax script (version 119,
  " dated 2020-06-29)

  execute 'syntax match texBadMath /\\end\s*{\s*' . a:mathzone . '\*\?\s*}/'

  let grp = 'texMathZone' . a:sfx
  execute 'syntax cluster texMathZones add=' . grp
  execute 'syntax region ' . grp
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\s*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\s*}'''
        \ . ' keepend contains=@texMathZoneGroup'
  execute 'highlight def link '.grp.' texMath'

  if !a:starred | return | endif

  let grp .= 'S'
  execute 'syntax cluster texMathZones add=' . grp
  execute 'syntax region ' . grp
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\*\s*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\*\s*}'''
        \ . ' keepend contains=@texMathZoneGroup'
  execute 'highlight def link '.grp.' texMath'
endfunction

" }}}1

function! s:init_clusters() abort " {{{1
  syntax cluster texCmdGroup contains=texCmdBody,texComment,texDefParm,texDelimiter,texDocType,texInput,texLength,texLigature,texMathDelim,texMathOper,texNewCmd,texNewEnv,texRefZone,texSection,texBeginEnd,texBeginEndName,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,@texMathZones,texErrorMath

  syntax cluster texEnvGroup contains=texMatcher,texMathDelim,texSpecialChar,texStatement
  syntax cluster texZoneGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMatcher,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texBoldStyle,texItalStyle,texEmphStyle
  syntax cluster texBoldGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texBoldStyle,texBoldItalStyle,texMatcher
  syntax cluster texItalGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texItalStyle,texEmphStyle,texItalBoldStyle,texMatcher

  syntax cluster texStyleGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,texStyleStatement,texStyleMatcher,@Spell

  syntax cluster texRefGroup contains=texMatcher,texComment,texDelimiter

  syntax cluster texMathZones contains=texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ
  syntax cluster texMatchGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMatcher,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,@Spell,@texMathZones
  syntax cluster texMathDelimGroup contains=texMathDelimBad,texMathDelimKey,texMathDelimSet1,texMathDelimSet2
  syntax cluster texMathMatchGroup contains=@texMathZones,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMathDelim,texMathMatcher,texMathOper,texNewCmd,texNewEnv,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,texErrorMath
  syntax cluster texMathZoneGroup contains=texComment,texDelimiter,texLength,texMathDelim,texMathMatcher,texMathOper,texMathSymbol,texMathText,texRefZone,texSpecialChar,texStatement,texTypeSize,texTypeStyle,texErrorMath,@NoSpell

  syntax cluster texDocGroup contains=texPartZone,@texPartGroup
  syntax cluster texPartGroup contains=texChapterZone,texSectionZone,texParaZone
  syntax cluster texChapterGroup contains=texSectionZone,texParaZone
  syntax cluster texSectionGroup contains=texSubSectionZone,texParaZone
  syntax cluster texSubSectionGroup contains=texSubSubSectionZone,texParaZone
  syntax cluster texSubSubSectionGroup contains=texParaZone
  syntax cluster texParaGroup contains=texSubParaZone

  syntax cluster texMathZoneGroup add=texGreek,texSuperscript,texSubscript,texMathSymbol
  syntax cluster texMathMatchGroup add=texGreek,texSuperscript,texSubscript,texMathSymbol

  syntax cluster texCommentGroup contains=texTodo,@Spell
endfunction

" }}}1
function! s:init_highlights(cfg) abort " {{{1
  " TeX highlighting groups which should share similar highlighting
  highlight def link texBadMath              texError
  highlight def link texMathDelimBad         texError
  highlight def link texErrorMath            texError
  highlight def link texErrorStatement       texError
  highlight def link texError                 Error
  if a:cfg.is_style_document
    highlight def link texOnlyMath           texError
  endif

  highlight texBoldStyle               gui=bold        cterm=bold
  highlight texItalStyle               gui=italic      cterm=italic
  highlight texBoldItalStyle           gui=bold,italic cterm=bold,italic
  highlight texItalBoldStyle           gui=bold,italic cterm=bold,italic
  highlight def link texEmphStyle      texItalStyle
  highlight def link texCite           texRefZone
  highlight def link texDefCmd         texDef
  highlight def link texDefName        texDef
  highlight def link texDocType        texCmdName
  highlight def link texDocTypeArgs    texCmdArgs
  highlight def link texInputFileOpt   texCmdArgs
  highlight def link texInputCurlies   texDelimiter
  highlight def link texLigature       texSpecialChar
  highlight def link texMathDelimSet1 texMathDelim
  highlight def link texMathDelimSet2 texMathDelim
  highlight def link texMathDelimKey  texMathDelim
  highlight def link texMathMatcher   texMath
  highlight def link texAccent        texStatement
  highlight def link texGreek         texStatement
  highlight def link texSuperscript   texStatement
  highlight def link texSubscript     texStatement
  highlight def link texSuperscripts  texSuperscript
  highlight def link texSubscripts    texSubscript
  highlight def link texMathSymbol    texStatement
  highlight def link texMathZoneV     texMath
  highlight def link texMathZoneW     texMath
  highlight def link texMathZoneX     texMath
  highlight def link texMathZoneY     texMath
  highlight def link texMathZoneV     texMath
  highlight def link texMathZoneZ     texMath
  highlight def link texBeginEnd       texCmdName
  highlight def link texBeginEndName   texSection
  highlight def link texSpaceCode      texStatement
  highlight def link texStyleStatement texStatement
  highlight def link texTypeSize       texType
  highlight def link texTypeStyle      texType

  " Basic TeX highlighting groups
  highlight def link texCmdArgs        Number
  highlight def link texCmdName        Statement
  highlight def link texComment        Comment
  highlight def link texDef            Statement
  highlight def link texDefParm        Special
  highlight def link texDelimiter      Delimiter
  highlight def link texInput          Special
  highlight def link texInputFile      Special
  highlight def link texLength         Number
  highlight def link texMath           Special
  highlight def link texMathDelim      Statement
  highlight def link texMathOper       Operator
  highlight def link texNewCmd         Statement
  highlight def link texNewEnv         Statement
  highlight def link texOption         Number
  highlight def link texRefZone        Special
  highlight def link texSection        PreCondit
  highlight def link texSpaceCodeChar  Special
  highlight def link texSpecialChar    SpecialChar
  highlight def link texStatement      Statement
  highlight def link texString         String
  highlight def link texTodo           Todo
  highlight def link texType           Type
  highlight def link texZone           PreCondit
endfunction

" }}}1

function! s:match_conceal_math_delims() abort " {{{1
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?<"             contained conceal cchar=<
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?>"             contained conceal cchar=>
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?("             contained conceal cchar=(
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?)"             contained conceal cchar=)
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\["            contained conceal cchar=[
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?]"             contained conceal cchar=]
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\{"           contained conceal cchar={
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\}"           contained conceal cchar=}
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?|"             contained conceal cchar=|
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\|"           contained conceal cchar=‖
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\downarrow"   contained conceal cchar=↓
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\Downarrow"   contained conceal cchar=⇓
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\lbrace"      contained conceal cchar=[
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\lceil"       contained conceal cchar=⌈
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\lfloor"      contained conceal cchar=⌊
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\lgroup"      contained conceal cchar=⌊
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\lmoustache"  contained conceal cchar=⎛
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rbrace"      contained conceal cchar=]
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rceil"       contained conceal cchar=⌉
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rfloor"      contained conceal cchar=⌋
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rgroup"      contained conceal cchar=⌋
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rmoustache"  contained conceal cchar=⎞
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\uparrow"     contained conceal cchar=↑
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\Uparrow"     contained conceal cchar=↑
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\updownarrow" contained conceal cchar=↕
  syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\Updownarrow" contained conceal cchar=⇕

  if &ambiwidth ==# 'double'
    syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\langle" contained conceal cchar=〈
    syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rangle" contained conceal cchar=〉
  else
    syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\langle" contained conceal cchar=<
    syntax match texMathSymbol "\\[bB]igg\?[lr]\?\\rangle" contained conceal cchar=>
  endif
endfunction

" }}}1
function! s:match_conceal_math_symbols() abort " {{{1
  syntax match texMathSymbol "\\|"                   contained conceal cchar=‖
  syntax match texMathSymbol "\\aleph\>"             contained conceal cchar=ℵ
  syntax match texMathSymbol "\\amalg\>"             contained conceal cchar=∐
  syntax match texMathSymbol "\\angle\>"             contained conceal cchar=∠
  syntax match texMathSymbol "\\approx\>"            contained conceal cchar=≈
  syntax match texMathSymbol "\\ast\>"               contained conceal cchar=∗
  syntax match texMathSymbol "\\asymp\>"             contained conceal cchar=≍
  syntax match texMathSymbol "\\backslash\>"         contained conceal cchar=∖
  syntax match texMathSymbol "\\bigcap\>"            contained conceal cchar=∩
  syntax match texMathSymbol "\\bigcirc\>"           contained conceal cchar=○
  syntax match texMathSymbol "\\bigcup\>"            contained conceal cchar=∪
  syntax match texMathSymbol "\\bigodot\>"           contained conceal cchar=⊙
  syntax match texMathSymbol "\\bigoplus\>"          contained conceal cchar=⊕
  syntax match texMathSymbol "\\bigotimes\>"         contained conceal cchar=⊗
  syntax match texMathSymbol "\\bigsqcup\>"          contained conceal cchar=⊔
  syntax match texMathSymbol "\\bigtriangledown\>"   contained conceal cchar=∇
  syntax match texMathSymbol "\\bigtriangleup\>"     contained conceal cchar=∆
  syntax match texMathSymbol "\\bigvee\>"            contained conceal cchar=⋁
  syntax match texMathSymbol "\\bigwedge\>"          contained conceal cchar=⋀
  syntax match texMathSymbol "\\bot\>"               contained conceal cchar=⊥
  syntax match texMathSymbol "\\bowtie\>"            contained conceal cchar=⋈
  syntax match texMathSymbol "\\bullet\>"            contained conceal cchar=•
  syntax match texMathSymbol "\\cap\>"               contained conceal cchar=∩
  syntax match texMathSymbol "\\cdot\>"              contained conceal cchar=·
  syntax match texMathSymbol "\\cdots\>"             contained conceal cchar=⋯
  syntax match texMathSymbol "\\circ\>"              contained conceal cchar=∘
  syntax match texMathSymbol "\\clubsuit\>"          contained conceal cchar=♣
  syntax match texMathSymbol "\\cong\>"              contained conceal cchar=≅
  syntax match texMathSymbol "\\coprod\>"            contained conceal cchar=∐
  syntax match texMathSymbol "\\copyright\>"         contained conceal cchar=©
  syntax match texMathSymbol "\\cup\>"               contained conceal cchar=∪
  syntax match texMathSymbol "\\dagger\>"            contained conceal cchar=†
  syntax match texMathSymbol "\\dashv\>"             contained conceal cchar=⊣
  syntax match texMathSymbol "\\ddagger\>"           contained conceal cchar=‡
  syntax match texMathSymbol "\\ddots\>"             contained conceal cchar=⋱
  syntax match texMathSymbol "\\diamond\>"           contained conceal cchar=⋄
  syntax match texMathSymbol "\\diamondsuit\>"       contained conceal cchar=♢
  syntax match texMathSymbol "\\div\>"               contained conceal cchar=÷
  syntax match texMathSymbol "\\doteq\>"             contained conceal cchar=≐
  syntax match texMathSymbol "\\dots\>"              contained conceal cchar=…
  syntax match texMathSymbol "\\downarrow\>"         contained conceal cchar=↓
  syntax match texMathSymbol "\\Downarrow\>"         contained conceal cchar=⇓
  syntax match texMathSymbol "\\ell\>"               contained conceal cchar=ℓ
  syntax match texMathSymbol "\\emptyset\>"          contained conceal cchar=∅
  syntax match texMathSymbol "\\equiv\>"             contained conceal cchar=≡
  syntax match texMathSymbol "\\exists\>"            contained conceal cchar=∃
  syntax match texMathSymbol "\\flat\>"              contained conceal cchar=♭
  syntax match texMathSymbol "\\forall\>"            contained conceal cchar=∀
  syntax match texMathSymbol "\\frown\>"             contained conceal cchar=⁔
  syntax match texMathSymbol "\\ge\>"                contained conceal cchar=≥
  syntax match texMathSymbol "\\geq\>"               contained conceal cchar=≥
  syntax match texMathSymbol "\\gets\>"              contained conceal cchar=←
  syntax match texMathSymbol "\\gg\>"                contained conceal cchar=⟫
  syntax match texMathSymbol "\\hbar\>"              contained conceal cchar=ℏ
  syntax match texMathSymbol "\\heartsuit\>"         contained conceal cchar=♡
  syntax match texMathSymbol "\\hookleftarrow\>"     contained conceal cchar=↩
  syntax match texMathSymbol "\\hookrightarrow\>"    contained conceal cchar=↪
  syntax match texMathSymbol "\\iff\>"               contained conceal cchar=⇔
  syntax match texMathSymbol "\\Im\>"                contained conceal cchar=ℑ
  syntax match texMathSymbol "\\imath\>"             contained conceal cchar=ɩ
  syntax match texMathSymbol "\\in\>"                contained conceal cchar=∈
  syntax match texMathSymbol "\\infty\>"             contained conceal cchar=∞
  syntax match texMathSymbol "\\int\>"               contained conceal cchar=∫
  syntax match texMathSymbol "\\jmath\>"             contained conceal cchar=𝚥
  syntax match texMathSymbol "\\land\>"              contained conceal cchar=∧
  syntax match texMathSymbol "\\lceil\>"             contained conceal cchar=⌈
  syntax match texMathSymbol "\\ldots\>"             contained conceal cchar=…
  syntax match texMathSymbol "\\le\>"                contained conceal cchar=≤
  syntax match texMathSymbol "\\left|"               contained conceal cchar=|
  syntax match texMathSymbol "\\left\\|"             contained conceal cchar=‖
  syntax match texMathSymbol "\\left("               contained conceal cchar=(
  syntax match texMathSymbol "\\left\["              contained conceal cchar=[
  syntax match texMathSymbol "\\left\\{"             contained conceal cchar={
  syntax match texMathSymbol "\\leftarrow\>"         contained conceal cchar=←
  syntax match texMathSymbol "\\Leftarrow\>"         contained conceal cchar=⇐
  syntax match texMathSymbol "\\leftharpoondown\>"   contained conceal cchar=↽
  syntax match texMathSymbol "\\leftharpoonup\>"     contained conceal cchar=↼
  syntax match texMathSymbol "\\leftrightarrow\>"    contained conceal cchar=↔
  syntax match texMathSymbol "\\Leftrightarrow\>"    contained conceal cchar=⇔
  syntax match texMathSymbol "\\leq\>"               contained conceal cchar=≤
  syntax match texMathSymbol "\\leq\>"               contained conceal cchar=≤
  syntax match texMathSymbol "\\lfloor\>"            contained conceal cchar=⌊
  syntax match texMathSymbol "\\ll\>"                contained conceal cchar=≪
  syntax match texMathSymbol "\\lmoustache\>"        contained conceal cchar=╭
  syntax match texMathSymbol "\\lor\>"               contained conceal cchar=∨
  syntax match texMathSymbol "\\mapsto\>"            contained conceal cchar=↦
  syntax match texMathSymbol "\\mid\>"               contained conceal cchar=∣
  syntax match texMathSymbol "\\models\>"            contained conceal cchar=╞
  syntax match texMathSymbol "\\mp\>"                contained conceal cchar=∓
  syntax match texMathSymbol "\\nabla\>"             contained conceal cchar=∇
  syntax match texMathSymbol "\\natural\>"           contained conceal cchar=♮
  syntax match texMathSymbol "\\ne\>"                contained conceal cchar=≠
  syntax match texMathSymbol "\\nearrow\>"           contained conceal cchar=↗
  syntax match texMathSymbol "\\neg\>"               contained conceal cchar=¬
  syntax match texMathSymbol "\\neq\>"               contained conceal cchar=≠
  syntax match texMathSymbol "\\ni\>"                contained conceal cchar=∋
  syntax match texMathSymbol "\\notin\>"             contained conceal cchar=∉
  syntax match texMathSymbol "\\nwarrow\>"           contained conceal cchar=↖
  syntax match texMathSymbol "\\odot\>"              contained conceal cchar=⊙
  syntax match texMathSymbol "\\oint\>"              contained conceal cchar=∮
  syntax match texMathSymbol "\\ominus\>"            contained conceal cchar=⊖
  syntax match texMathSymbol "\\oplus\>"             contained conceal cchar=⊕
  syntax match texMathSymbol "\\oslash\>"            contained conceal cchar=⊘
  syntax match texMathSymbol "\\otimes\>"            contained conceal cchar=⊗
  syntax match texMathSymbol "\\owns\>"              contained conceal cchar=∋
  syntax match texMathSymbol "\\P\>"                 contained conceal cchar=¶
  syntax match texMathSymbol "\\parallel\>"          contained conceal cchar=║
  syntax match texMathSymbol "\\partial\>"           contained conceal cchar=∂
  syntax match texMathSymbol "\\perp\>"              contained conceal cchar=⊥
  syntax match texMathSymbol "\\pm\>"                contained conceal cchar=±
  syntax match texMathSymbol "\\prec\>"              contained conceal cchar=≺
  syntax match texMathSymbol "\\preceq\>"            contained conceal cchar=⪯
  syntax match texMathSymbol "\\prime\>"             contained conceal cchar=′
  syntax match texMathSymbol "\\prod\>"              contained conceal cchar=∏
  syntax match texMathSymbol "\\propto\>"            contained conceal cchar=∝
  syntax match texMathSymbol "\\rceil\>"             contained conceal cchar=⌉
  syntax match texMathSymbol "\\Re\>"                contained conceal cchar=ℜ
  syntax match texMathSymbol "\\quad\>"              contained conceal cchar= 
  syntax match texMathSymbol "\\qquad\>"             contained conceal cchar= 
  syntax match texMathSymbol "\\rfloor\>"            contained conceal cchar=⌋
  syntax match texMathSymbol "\\right|"              contained conceal cchar=|
  syntax match texMathSymbol "\\right\\|"            contained conceal cchar=‖
  syntax match texMathSymbol "\\right)"              contained conceal cchar=)
  syntax match texMathSymbol "\\right]"              contained conceal cchar=]
  syntax match texMathSymbol "\\right\\}"            contained conceal cchar=}
  syntax match texMathSymbol "\\rightarrow\>"        contained conceal cchar=→
  syntax match texMathSymbol "\\Rightarrow\>"        contained conceal cchar=⇒
  syntax match texMathSymbol "\\rightleftharpoons\>" contained conceal cchar=⇌
  syntax match texMathSymbol "\\rmoustache\>"        contained conceal cchar=╮
  syntax match texMathSymbol "\\S\>"                 contained conceal cchar=§
  syntax match texMathSymbol "\\searrow\>"           contained conceal cchar=↘
  syntax match texMathSymbol "\\setminus\>"          contained conceal cchar=∖
  syntax match texMathSymbol "\\sharp\>"             contained conceal cchar=♯
  syntax match texMathSymbol "\\sim\>"               contained conceal cchar=∼
  syntax match texMathSymbol "\\simeq\>"             contained conceal cchar=⋍
  syntax match texMathSymbol "\\smile\>"             contained conceal cchar=‿
  syntax match texMathSymbol "\\spadesuit\>"         contained conceal cchar=♠
  syntax match texMathSymbol "\\sqcap\>"             contained conceal cchar=⊓
  syntax match texMathSymbol "\\sqcup\>"             contained conceal cchar=⊔
  syntax match texMathSymbol "\\sqsubset\>"          contained conceal cchar=⊏
  syntax match texMathSymbol "\\sqsubseteq\>"        contained conceal cchar=⊑
  syntax match texMathSymbol "\\sqsupset\>"          contained conceal cchar=⊐
  syntax match texMathSymbol "\\sqsupseteq\>"        contained conceal cchar=⊒
  syntax match texMathSymbol "\\star\>"              contained conceal cchar=✫
  syntax match texMathSymbol "\\subset\>"            contained conceal cchar=⊂
  syntax match texMathSymbol "\\subseteq\>"          contained conceal cchar=⊆
  syntax match texMathSymbol "\\succ\>"              contained conceal cchar=≻
  syntax match texMathSymbol "\\succeq\>"            contained conceal cchar=⪰
  syntax match texMathSymbol "\\sum\>"               contained conceal cchar=∑
  syntax match texMathSymbol "\\supset\>"            contained conceal cchar=⊃
  syntax match texMathSymbol "\\supseteq\>"          contained conceal cchar=⊇
  syntax match texMathSymbol "\\surd\>"              contained conceal cchar=√
  syntax match texMathSymbol "\\swarrow\>"           contained conceal cchar=↙
  syntax match texMathSymbol "\\times\>"             contained conceal cchar=×
  syntax match texMathSymbol "\\to\>"                contained conceal cchar=→
  syntax match texMathSymbol "\\top\>"               contained conceal cchar=⊤
  syntax match texMathSymbol "\\triangle\>"          contained conceal cchar=∆
  syntax match texMathSymbol "\\triangleleft\>"      contained conceal cchar=⊲
  syntax match texMathSymbol "\\triangleright\>"     contained conceal cchar=⊳
  syntax match texMathSymbol "\\uparrow\>"           contained conceal cchar=↑
  syntax match texMathSymbol "\\Uparrow\>"           contained conceal cchar=⇑
  syntax match texMathSymbol "\\updownarrow\>"       contained conceal cchar=↕
  syntax match texMathSymbol "\\Updownarrow\>"       contained conceal cchar=⇕
  syntax match texMathSymbol "\\vdash\>"             contained conceal cchar=⊢
  syntax match texMathSymbol "\\vdots\>"             contained conceal cchar=⋮
  syntax match texMathSymbol "\\vee\>"               contained conceal cchar=∨
  syntax match texMathSymbol "\\wedge\>"             contained conceal cchar=∧
  syntax match texMathSymbol "\\wp\>"                contained conceal cchar=℘
  syntax match texMathSymbol "\\wr\>"                contained conceal cchar=≀

  if &ambiwidth ==# 'double'
    syntax match texMathSymbol "right\\rangle\>" contained conceal cchar=〉
    syntax match texMathSymbol "left\\langle\>"  contained conceal cchar=〈
    syntax match texMathSymbol '\\gg\>'          contained conceal cchar=≫
    syntax match texMathSymbol '\\ll\>'          contained conceal cchar=≪
  else
    syntax match texMathSymbol "right\\rangle\>" contained conceal cchar=>
    syntax match texMathSymbol "left\\langle\>"  contained conceal cchar=<
    syntax match texMathSymbol '\\gg\>'          contained conceal cchar=⟫
    syntax match texMathSymbol '\\ll\>'          contained conceal cchar=⟪
  endif

  syntax match texMathSymbol '\\bar{a}' contained conceal cchar=a̅

  syntax match texMathSymbol '\\dot{A}' contained conceal cchar=Ȧ
  syntax match texMathSymbol '\\dot{a}' contained conceal cchar=ȧ
  syntax match texMathSymbol '\\dot{B}' contained conceal cchar=Ḃ
  syntax match texMathSymbol '\\dot{b}' contained conceal cchar=ḃ
  syntax match texMathSymbol '\\dot{C}' contained conceal cchar=Ċ
  syntax match texMathSymbol '\\dot{c}' contained conceal cchar=ċ
  syntax match texMathSymbol '\\dot{D}' contained conceal cchar=Ḋ
  syntax match texMathSymbol '\\dot{d}' contained conceal cchar=ḋ
  syntax match texMathSymbol '\\dot{E}' contained conceal cchar=Ė
  syntax match texMathSymbol '\\dot{e}' contained conceal cchar=ė
  syntax match texMathSymbol '\\dot{F}' contained conceal cchar=Ḟ
  syntax match texMathSymbol '\\dot{f}' contained conceal cchar=ḟ
  syntax match texMathSymbol '\\dot{G}' contained conceal cchar=Ġ
  syntax match texMathSymbol '\\dot{g}' contained conceal cchar=ġ
  syntax match texMathSymbol '\\dot{H}' contained conceal cchar=Ḣ
  syntax match texMathSymbol '\\dot{h}' contained conceal cchar=ḣ
  syntax match texMathSymbol '\\dot{I}' contained conceal cchar=İ
  syntax match texMathSymbol '\\dot{M}' contained conceal cchar=Ṁ
  syntax match texMathSymbol '\\dot{m}' contained conceal cchar=ṁ
  syntax match texMathSymbol '\\dot{N}' contained conceal cchar=Ṅ
  syntax match texMathSymbol '\\dot{n}' contained conceal cchar=ṅ
  syntax match texMathSymbol '\\dot{O}' contained conceal cchar=Ȯ
  syntax match texMathSymbol '\\dot{o}' contained conceal cchar=ȯ
  syntax match texMathSymbol '\\dot{P}' contained conceal cchar=Ṗ
  syntax match texMathSymbol '\\dot{p}' contained conceal cchar=ṗ
  syntax match texMathSymbol '\\dot{R}' contained conceal cchar=Ṙ
  syntax match texMathSymbol '\\dot{r}' contained conceal cchar=ṙ
  syntax match texMathSymbol '\\dot{S}' contained conceal cchar=Ṡ
  syntax match texMathSymbol '\\dot{s}' contained conceal cchar=ṡ
  syntax match texMathSymbol '\\dot{T}' contained conceal cchar=Ṫ
  syntax match texMathSymbol '\\dot{t}' contained conceal cchar=ṫ
  syntax match texMathSymbol '\\dot{W}' contained conceal cchar=Ẇ
  syntax match texMathSymbol '\\dot{w}' contained conceal cchar=ẇ
  syntax match texMathSymbol '\\dot{X}' contained conceal cchar=Ẋ
  syntax match texMathSymbol '\\dot{x}' contained conceal cchar=ẋ
  syntax match texMathSymbol '\\dot{Y}' contained conceal cchar=Ẏ
  syntax match texMathSymbol '\\dot{y}' contained conceal cchar=ẏ
  syntax match texMathSymbol '\\dot{Z}' contained conceal cchar=Ż
  syntax match texMathSymbol '\\dot{z}' contained conceal cchar=ż

  syntax match texMathSymbol '\\hat{a}' contained conceal cchar=â
  syntax match texMathSymbol '\\hat{A}' contained conceal cchar=Â
  syntax match texMathSymbol '\\hat{c}' contained conceal cchar=ĉ
  syntax match texMathSymbol '\\hat{C}' contained conceal cchar=Ĉ
  syntax match texMathSymbol '\\hat{e}' contained conceal cchar=ê
  syntax match texMathSymbol '\\hat{E}' contained conceal cchar=Ê
  syntax match texMathSymbol '\\hat{g}' contained conceal cchar=ĝ
  syntax match texMathSymbol '\\hat{G}' contained conceal cchar=Ĝ
  syntax match texMathSymbol '\\hat{i}' contained conceal cchar=î
  syntax match texMathSymbol '\\hat{I}' contained conceal cchar=Î
  syntax match texMathSymbol '\\hat{o}' contained conceal cchar=ô
  syntax match texMathSymbol '\\hat{O}' contained conceal cchar=Ô
  syntax match texMathSymbol '\\hat{s}' contained conceal cchar=ŝ
  syntax match texMathSymbol '\\hat{S}' contained conceal cchar=Ŝ
  syntax match texMathSymbol '\\hat{u}' contained conceal cchar=û
  syntax match texMathSymbol '\\hat{U}' contained conceal cchar=Û
  syntax match texMathSymbol '\\hat{w}' contained conceal cchar=ŵ
  syntax match texMathSymbol '\\hat{W}' contained conceal cchar=Ŵ
  syntax match texMathSymbol '\\hat{y}' contained conceal cchar=ŷ
  syntax match texMathSymbol '\\hat{Y}' contained conceal cchar=Ŷ
endfunction

" }}}1
function! s:match_conceal_accents() " {{{1
  for [l:chr; l:targets] in s:map_accents
    for i in range(13)
      if empty(l:targets[i]) | continue | endif
        let l:accent = s:key_accents[i]
        let l:target = l:targets[i]
        if l:accent =~# '\a'
          execute 'syntax match texAccent /' . l:accent . '\%(\s*{' . l:chr . '}\|\s\+' . l:chr . '\)' . '/ conceal cchar=' . l:target
        else
          execute 'syntax match texAccent /' . l:accent . '\s*\%({' . l:chr . '}\|' . l:chr . '\)' . '/ conceal cchar=' . l:target
        endif
    endfor
  endfor

  syntax match texAccent   '\\aa\>' conceal cchar=å
  syntax match texAccent   '\\AA\>' conceal cchar=Å
  syntax match texAccent   '\\o\>'  conceal cchar=ø
  syntax match texAccent   '\\O\>'  conceal cchar=Ø
  syntax match texLigature '\\AE\>' conceal cchar=Æ
  syntax match texLigature '\\ae\>' conceal cchar=æ
  syntax match texLigature '\\oe\>' conceal cchar=œ
  syntax match texLigature '\\OE\>' conceal cchar=Œ
  syntax match texLigature '\\ss\>' conceal cchar=ß
  syntax match texLigature '--'     conceal cchar=–
  syntax match texLigature '---'    conceal cchar=—
endfunction

let s:key_accents = [
      \ '\\`',
      \ '\\''',
      \ '\\^',
      \ '\\"',
      \ '\\\~',
      \ '\\\.',
      \ '\\=',
      \ '\\c',
      \ '\\H',
      \ '\\k',
      \ '\\r',
      \ '\\u',
      \ '\\v'
      \]

let s:map_accents = [
      \ ['a',  'à','á','â','ä','ã','ȧ','ā','' ,'' ,'ą','å','ă','ǎ'],
      \ ['A',  'À','Á','Â','Ä','Ã','Ȧ','Ā','' ,'' ,'Ą','Å','Ă','Ǎ'],
      \ ['c',  '' ,'ć','ĉ','' ,'' ,'ċ','' ,'ç','' ,'' ,'' ,'' ,'č'],
      \ ['C',  '' ,'Ć','Ĉ','' ,'' ,'Ċ','' ,'Ç','' ,'' ,'' ,'' ,'Č'],
      \ ['d',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ď'],
      \ ['D',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ď'],
      \ ['e',  'è','é','ê','ë','ẽ','ė','ē','ȩ','' ,'ę','' ,'ĕ','ě'],
      \ ['E',  'È','É','Ê','Ë','Ẽ','Ė','Ē','Ȩ','' ,'Ę','' ,'Ĕ','Ě'],
      \ ['g',  '' ,'ǵ','ĝ','' ,'' ,'ġ','' ,'ģ','' ,'' ,'' ,'ğ','ǧ'],
      \ ['G',  '' ,'Ǵ','Ĝ','' ,'' ,'Ġ','' ,'Ģ','' ,'' ,'' ,'Ğ','Ǧ'],
      \ ['h',  '' ,'' ,'ĥ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ȟ'],
      \ ['H',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ȟ'],
      \ ['i',  'ì','í','î','ï','ĩ','į','ī','' ,'' ,'į','' ,'ĭ','ǐ'],
      \ ['I',  'Ì','Í','Î','Ï','Ĩ','İ','Ī','' ,'' ,'Į','' ,'Ĭ','Ǐ'],
      \ ['J',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ǰ'],
      \ ['k',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ķ','' ,'' ,'' ,'' ,'ǩ'],
      \ ['K',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ķ','' ,'' ,'' ,'' ,'Ǩ'],
      \ ['l',  '' ,'ĺ','ľ','' ,'' ,'' ,'' ,'ļ','' ,'' ,'' ,'' ,'ľ'],
      \ ['L',  '' ,'Ĺ','Ľ','' ,'' ,'' ,'' ,'Ļ','' ,'' ,'' ,'' ,'Ľ'],
      \ ['n',  '' ,'ń','' ,'' ,'ñ','' ,'' ,'ņ','' ,'' ,'' ,'' ,'ň'],
      \ ['N',  '' ,'Ń','' ,'' ,'Ñ','' ,'' ,'Ņ','' ,'' ,'' ,'' ,'Ň'],
      \ ['o',  'ò','ó','ô','ö','õ','ȯ','ō','' ,'ő','ǫ','' ,'ŏ','ǒ'],
      \ ['O',  'Ò','Ó','Ô','Ö','Õ','Ȯ','Ō','' ,'Ő','Ǫ','' ,'Ŏ','Ǒ'],
      \ ['r',  '' ,'ŕ','' ,'' ,'' ,'' ,'' ,'ŗ','' ,'' ,'' ,'' ,'ř'],
      \ ['R',  '' ,'Ŕ','' ,'' ,'' ,'' ,'' ,'Ŗ','' ,'' ,'' ,'' ,'Ř'],
      \ ['s',  '' ,'ś','ŝ','' ,'' ,'' ,'' ,'ş','' ,'ȿ','' ,'' ,'š'],
      \ ['S',  '' ,'Ś','Ŝ','' ,'' ,'' ,'' ,'Ş','' ,'' ,'' ,'' ,'Š'],
      \ ['t',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ţ','' ,'' ,'' ,'' ,'ť'],
      \ ['T',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ţ','' ,'' ,'' ,'' ,'Ť'],
      \ ['u',  'ù','ú','û','ü','ũ','' ,'ū','' ,'ű','ų','ů','ŭ','ǔ'],
      \ ['U',  'Ù','Ú','Û','Ü','Ũ','' ,'Ū','' ,'Ű','Ų','Ů','Ŭ','Ǔ'],
      \ ['w',  '' ,'' ,'ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['W',  '' ,'' ,'Ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['y',  'ỳ','ý','ŷ','ÿ','ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['Y',  'Ỳ','Ý','Ŷ','Ÿ','Ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['z',  '' ,'ź','' ,'' ,'' ,'ż','' ,'' ,'' ,'' ,'' ,'' ,'ž'],
      \ ['Z',  '' ,'Ź','' ,'' ,'' ,'Ż','' ,'' ,'' ,'' ,'' ,'' ,'Ž'],
      \ ['\\i','ì','í','î','ï','ĩ','į','' ,'' ,'' ,'' ,'' ,'ĭ',''],
      \]

" }}}1
function! s:match_conceal_greek() " {{{1
  syntax match texGreek "\\alpha\>"      contained conceal cchar=α
  syntax match texGreek "\\beta\>"       contained conceal cchar=β
  syntax match texGreek "\\gamma\>"      contained conceal cchar=γ
  syntax match texGreek "\\delta\>"      contained conceal cchar=δ
  syntax match texGreek "\\epsilon\>"    contained conceal cchar=ϵ
  syntax match texGreek "\\varepsilon\>" contained conceal cchar=ε
  syntax match texGreek "\\zeta\>"       contained conceal cchar=ζ
  syntax match texGreek "\\eta\>"        contained conceal cchar=η
  syntax match texGreek "\\theta\>"      contained conceal cchar=θ
  syntax match texGreek "\\vartheta\>"   contained conceal cchar=ϑ
  syntax match texGreek "\\iota\>"       contained conceal cchar=ι
  syntax match texGreek "\\kappa\>"      contained conceal cchar=κ
  syntax match texGreek "\\lambda\>"     contained conceal cchar=λ
  syntax match texGreek "\\mu\>"         contained conceal cchar=μ
  syntax match texGreek "\\nu\>"         contained conceal cchar=ν
  syntax match texGreek "\\xi\>"         contained conceal cchar=ξ
  syntax match texGreek "\\pi\>"         contained conceal cchar=π
  syntax match texGreek "\\varpi\>"      contained conceal cchar=ϖ
  syntax match texGreek "\\rho\>"        contained conceal cchar=ρ
  syntax match texGreek "\\varrho\>"     contained conceal cchar=ϱ
  syntax match texGreek "\\sigma\>"      contained conceal cchar=σ
  syntax match texGreek "\\varsigma\>"   contained conceal cchar=ς
  syntax match texGreek "\\tau\>"        contained conceal cchar=τ
  syntax match texGreek "\\upsilon\>"    contained conceal cchar=υ
  syntax match texGreek "\\phi\>"        contained conceal cchar=ϕ
  syntax match texGreek "\\varphi\>"     contained conceal cchar=φ
  syntax match texGreek "\\chi\>"        contained conceal cchar=χ
  syntax match texGreek "\\psi\>"        contained conceal cchar=ψ
  syntax match texGreek "\\omega\>"      contained conceal cchar=ω
  syntax match texGreek "\\Gamma\>"      contained conceal cchar=Γ
  syntax match texGreek "\\Delta\>"      contained conceal cchar=Δ
  syntax match texGreek "\\Theta\>"      contained conceal cchar=Θ
  syntax match texGreek "\\Lambda\>"     contained conceal cchar=Λ
  syntax match texGreek "\\Xi\>"         contained conceal cchar=Ξ
  syntax match texGreek "\\Pi\>"         contained conceal cchar=Π
  syntax match texGreek "\\Sigma\>"      contained conceal cchar=Σ
  syntax match texGreek "\\Upsilon\>"    contained conceal cchar=Υ
  syntax match texGreek "\\Phi\>"        contained conceal cchar=Φ
  syntax match texGreek "\\Chi\>"        contained conceal cchar=Χ
  syntax match texGreek "\\Psi\>"        contained conceal cchar=Ψ
  syntax match texGreek "\\Omega\>"      contained conceal cchar=Ω
endfunction

" }}}1
function! s:match_conceal_super_sub(cfg) " {{{1
  syntax region texSuperscript matchgroup=Delimiter start='\^{' skip="\\\\\|\\[{}]" end='}' contained concealends contains=texSpecialChar,texSuperscripts,texStatement,texSubscript,texSuperscript,texMathMatcher
  syntax region texSubscript   matchgroup=Delimiter start='_{'  skip="\\\\\|\\[{}]" end='}' contained concealends contains=texSpecialChar,texSubscripts,texStatement,texSubscript,texSuperscript,texMathMatcher

  for [l:from, l:to] in filter(copy(s:map_super),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# a:cfg.conceal_set_super})
    execute 'syntax match texSuperscript /\^' . l:from . '/ contained conceal cchar=' . l:to
    execute 'syntax match texSuperscripts /'  . l:from . '/ contained conceal cchar=' . l:to 'nextgroup=texSuperscripts'
  endfor

  for [l:from, l:to] in filter(copy(s:map_sub),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# a:cfg.conceal_set_sub})
    execute 'syntax match texSubscript /_' . l:from . '/ contained conceal cchar=' . l:to
    execute 'syntax match texSubscripts /' . l:from . '/ contained conceal cchar=' . l:to . ' nextgroup=texSubscripts'
  endfor
endfunction

let s:map_sub = [
      \ ['0',         '₀'],
      \ ['1',         '₁'],
      \ ['2',         '₂'],
      \ ['3',         '₃'],
      \ ['4',         '₄'],
      \ ['5',         '₅'],
      \ ['6',         '₆'],
      \ ['7',         '₇'],
      \ ['8',         '₈'],
      \ ['9',         '₉'],
      \ ['a',         'ₐ'],
      \ ['e',         'ₑ'],
      \ ['h',         'ₕ'],
      \ ['i',         'ᵢ'],
      \ ['j',         'ⱼ'],
      \ ['k',         'ₖ'],
      \ ['l',         'ₗ'],
      \ ['m',         'ₘ'],
      \ ['n',         'ₙ'],
      \ ['o',         'ₒ'],
      \ ['p',         'ₚ'],
      \ ['r',         'ᵣ'],
      \ ['s',         'ₛ'],
      \ ['t',         'ₜ'],
      \ ['u',         'ᵤ'],
      \ ['v',         'ᵥ'],
      \ ['x',         'ₓ'],
      \ [',',         '︐'],
      \ ['+',         '₊'],
      \ ['-',         '₋'],
      \ ['\/',         'ˏ'],
      \ ['(',         '₍'],
      \ [')',         '₎'],
      \ ['\.',        '‸'],
      \ ['r',         'ᵣ'],
      \ ['v',         'ᵥ'],
      \ ['x',         'ₓ'],
      \ ['\\beta\>',  'ᵦ'],
      \ ['\\delta\>', 'ᵨ'],
      \ ['\\phi\>',   'ᵩ'],
      \ ['\\gamma\>', 'ᵧ'],
      \ ['\\chi\>',   'ᵪ'],
      \]

let s:map_super = [
      \ ['0',  '⁰'],
      \ ['1',  '¹'],
      \ ['2',  '²'],
      \ ['3',  '³'],
      \ ['4',  '⁴'],
      \ ['5',  '⁵'],
      \ ['6',  '⁶'],
      \ ['7',  '⁷'],
      \ ['8',  '⁸'],
      \ ['9',  '⁹'],
      \ ['a',  'ᵃ'],
      \ ['b',  'ᵇ'],
      \ ['c',  'ᶜ'],
      \ ['d',  'ᵈ'],
      \ ['e',  'ᵉ'],
      \ ['f',  'ᶠ'],
      \ ['g',  'ᵍ'],
      \ ['h',  'ʰ'],
      \ ['i',  'ⁱ'],
      \ ['j',  'ʲ'],
      \ ['k',  'ᵏ'],
      \ ['l',  'ˡ'],
      \ ['m',  'ᵐ'],
      \ ['n',  'ⁿ'],
      \ ['o',  'ᵒ'],
      \ ['p',  'ᵖ'],
      \ ['r',  'ʳ'],
      \ ['s',  'ˢ'],
      \ ['t',  'ᵗ'],
      \ ['u',  'ᵘ'],
      \ ['v',  'ᵛ'],
      \ ['w',  'ʷ'],
      \ ['x',  'ˣ'],
      \ ['y',  'ʸ'],
      \ ['z',  'ᶻ'],
      \ ['A',  'ᴬ'],
      \ ['B',  'ᴮ'],
      \ ['D',  'ᴰ'],
      \ ['E',  'ᴱ'],
      \ ['G',  'ᴳ'],
      \ ['H',  'ᴴ'],
      \ ['I',  'ᴵ'],
      \ ['J',  'ᴶ'],
      \ ['K',  'ᴷ'],
      \ ['L',  'ᴸ'],
      \ ['M',  'ᴹ'],
      \ ['N',  'ᴺ'],
      \ ['O',  'ᴼ'],
      \ ['P',  'ᴾ'],
      \ ['R',  'ᴿ'],
      \ ['T',  'ᵀ'],
      \ ['U',  'ᵁ'],
      \ ['V',  'ⱽ'],
      \ ['W',  'ᵂ'],
      \ [',',  '︐'],
      \ [':',  '︓'],
      \ [';',  '︔'],
      \ ['+',  '⁺'],
      \ ['-',  '⁻'],
      \ ['<',  '˂'],
      \ ['>',  '˃'],
      \ ['\/',  'ˊ'],
      \ ['(',  '⁽'],
      \ [')',  '⁾'],
      \ ['\.', '˙'],
      \ ['=',  '˭'],
      \]

" }}}1

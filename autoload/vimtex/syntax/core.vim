" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#core#init() abort " {{{1
  let l:cfg = deepcopy(g:vimtex_syntax_config)
  let l:cfg.ext = expand('%:e')
  let l:cfg.is_style_document =
        \ index(['sty', 'cls', 'clo', 'dtx', 'ltx'], l:cfg.ext) >= 0

  syntax spell toplevel

  syntax sync maxlines=500
  syntax sync minlines=50

  " {{{2 Primitives

  " Match TeX braces in general
  " TODO: Do we really need this??
  syntax region texMatcher matchgroup=texDelim
        \ start="{" skip="\\\\\|\\}" end="}" contains=TOP

  " Flag mismatching ending brace delimiter
  syntax match texError "}"

  " Comments
  " * In documented TeX Format, actual comments are defined by leading "^^A".
  "   Almost all other lines start with one or more "%", which may be matched
  "   as comment characters. The remaining part of the line can be interpreted
  "   as TeX syntax.
  " * For more info on dtx files, see e.g.
  "   https://ctan.uib.no/info/dtxtut/dtxtut.pdf
  if l:cfg.ext ==# 'dtx'
    syntax match texComment "\^\^A.*$"
    syntax match texComment "^%\+"
  else
    syntax match texComment "%.*$" contains=@Spell
  endif

  " Do not check URLs and acronyms in comments
  " Source: https://github.com/lervag/vimtex/issues/562
  syntax match texCommentURL "\w\+:\/\/[^[:space:]]\+"
        \ containedin=texComment contained contains=@NoSpell
  syntax match texCommentAcronym '\v<(\u|\d){3,}s?>'
        \ containedin=texComment contained contains=@NoSpell

  " Todo and similar within comments
  syntax case ignore
  syntax keyword texCommentTodo combak fixme todo xxx
        \ containedin=texComment contained
  syntax case match

  " TeX Lengths
  syntax match texLength "\<\d\+\([.,]\d\+\)\?\s*\(true\)\?\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

  " }}}2
  " {{{2 Commands

  " Most general version first
  syntax match texCmd "\\\a\+"
  syntax match texCmdError "\\\a*@\a*"

  " Add some standard contained stuff
  syntax match texOptEqual contained "="
  syntax match texOptSep contained ",\s*"

  " Accents and ligatures
  syntax match texCmdAccent "\\[bcdvuH]$"
  syntax match texCmdAccent "\\[bcdvuH]\ze\A"
  syntax match texCmdAccent /\\[=^.\~"`']/
  syntax match texCmdAccent /\\['=t'.c^ud"vb~Hr]{\a}/
  syntax match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)$"
  syntax match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze\A"

  if l:cfg.is_style_document
    syntax match texCmd "\\[a-zA-Z@]\+"
    syntax match texCmdAccent "\\[bcdvuH]\ze[^a-zA-Z@]"
    syntax match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze[^a-zA-Z@]"
  endif

  " Spacecodes (TeX'isms)
  " * See e.g. https://en.wikibooks.org/wiki/TeX/catcode
  " * \mathcode`\^^@ = "2201
  " * \delcode`\( = "028300
  " * \sfcode`\) = 0
  " * \uccode`X = `X
  " * \lccode`x = `x
  syntax match texCmdSpaceCode "\v\\%(math|cat|del|lc|sf|uc)code`"me=e-1
        \ nextgroup=texCmdSpaceCodeChar
  syntax match texCmdSpaceCodeChar "\v`\\?.%(\^.)?\?%(\d|\"\x{1,6}|`.)" contained

  " Todo commands
  syntax match texCmdTodo '\\todo\w*'

  " Author and title commands
  " TODO: Option groups here
  syntax match texCmd nextgroup=texArgAuthor skipwhite skipnl "\\author\>"
  syntax match texCmd nextgroup=texArgTitle skipwhite skipnl "\\title\>"
  call vimtex#syntax#core#new_cmd_arg('texArgAuthor', '', 'texCmd,texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texArgTitle', '', 'texCmd,texComment')

  " Various commands that take a file argument (or similar)
  syntax match texCmd nextgroup=texArgFile              skipwhite skipnl "\\input\>"
  syntax match texCmd nextgroup=texArgFile              skipwhite skipnl "\\include\>"
  syntax match texCmd nextgroup=texArgFiles             skipwhite skipnl "\\includeonly\>"
  syntax match texCmd nextgroup=texOptFile,texArgFile   skipwhite skipnl "\\includegraphics\>"
  syntax match texCmd nextgroup=texArgFiles             skipwhite skipnl "\\bibliography\>"
  syntax match texCmd nextgroup=texArgFile              skipwhite skipnl "\\bibliographystyle\>"
  syntax match texCmd nextgroup=texOptFile,texArgFile   skipwhite skipnl "\\document\%(class\|style\)\>"
  syntax match texCmd nextgroup=texOptFiles,texArgFiles skipwhite skipnl "\\usepackage\>"
  syntax match texCmd nextgroup=texOptFiles,texArgFiles skipwhite skipnl "\\RequirePackage\>"
  call vimtex#syntax#core#new_cmd_opt('texOptFile', 'texArgFile')
  call vimtex#syntax#core#new_cmd_opt('texOptFiles', 'texArgFiles')
  call vimtex#syntax#core#new_cmd_arg('texArgFile', '', 'texCmd,texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texArgFiles', '', 'texOptSep,texCmd,texComment,@NoSpell')

  " LaTeX 2.09 type styles
  syntax match texCmdStyle "\\rm\>"
  syntax match texCmdStyle "\\em\>"
  syntax match texCmdStyle "\\bf\>"
  syntax match texCmdStyle "\\it\>"
  syntax match texCmdStyle "\\sl\>"
  syntax match texCmdStyle "\\sf\>"
  syntax match texCmdStyle "\\sc\>"
  syntax match texCmdStyle "\\tt\>"

  " LaTeX2E type styles
  syntax match texCmdStyle "\\textbf\>"
  syntax match texCmdStyle "\\textit\>"
  syntax match texCmdStyle "\\textmd\>"
  syntax match texCmdStyle "\\textrm\>"
  syntax match texCmdStyle "\\texts[cfl]\>"
  syntax match texCmdStyle "\\texttt\>"
  syntax match texCmdStyle "\\textup\>"
  syntax match texCmdStyle "\\emph\>"

  syntax match texCmdStyle "\\mathbb\>"
  syntax match texCmdStyle "\\mathbf\>"
  syntax match texCmdStyle "\\mathcal\>"
  syntax match texCmdStyle "\\mathfrak\>"
  syntax match texCmdStyle "\\mathit\>"
  syntax match texCmdStyle "\\mathnormal\>"
  syntax match texCmdStyle "\\mathrm\>"
  syntax match texCmdStyle "\\mathsf\>"
  syntax match texCmdStyle "\\mathtt\>"

  syntax match texCmdStyle "\\rmfamily\>"
  syntax match texCmdStyle "\\sffamily\>"
  syntax match texCmdStyle "\\ttfamily\>"

  syntax match texCmdStyle "\\itshape\>"
  syntax match texCmdStyle "\\scshape\>"
  syntax match texCmdStyle "\\slshape\>"
  syntax match texCmdStyle "\\upshape\>"

  syntax match texCmdStyle "\\bfseries\>"
  syntax match texCmdStyle "\\mdseries\>"

  " Bold and italic commands
  call s:match_bold_italic(l:cfg)

  " Type sizes
  syntax match texCmdSize "\\tiny\>"
  syntax match texCmdSize "\\scriptsize\>"
  syntax match texCmdSize "\\footnotesize\>"
  syntax match texCmdSize "\\small\>"
  syntax match texCmdSize "\\normalsize\>"
  syntax match texCmdSize "\\large\>"
  syntax match texCmdSize "\\Large\>"
  syntax match texCmdSize "\\LARGE\>"
  syntax match texCmdSize "\\huge\>"
  syntax match texCmdSize "\\Huge\>"

  " \newcommand
  syntax match texCmd nextgroup=texArgNewcmdName skipwhite skipnl "\\\%(re\)\?newcommand\>"
  call vimtex#syntax#core#new_cmd_arg('texArgNewcmdName', 'texOptNewcmd,texArgNewcmdBody')
  call vimtex#syntax#core#new_cmd_opt('texOptNewcmd', 'texOptNewcmd,texArgNewcmdBody', '', 'oneline')
  call vimtex#syntax#core#new_cmd_arg('texArgNewcmdBody', '', 'TOP')
  syntax match texParmNewcmd contained "#\d\+" containedin=texArgNewcmdBody

  " \newenvironment
  syntax match texCmd nextgroup=texArgNewenvName skipwhite skipnl "\\\%(re\)\?newenvironment\>"
  call vimtex#syntax#core#new_cmd_arg('texArgNewenvName', 'texArgNewenvBegin,texOptNewenv')
  call vimtex#syntax#core#new_cmd_opt('texOptNewenv', 'texArgNewenvBegin,texOptNewenv', '', 'oneline')
  call vimtex#syntax#core#new_cmd_arg('texArgNewenvBegin', 'texArgNewenvEnd', 'TOP')
  call vimtex#syntax#core#new_cmd_arg('texArgNewenvEnd', '', 'TOP')
  syntax match texParmNewenv contained "#\d\+" containedin=texArgNewenvBegin,texArgNewenvEnd

  " Definitions/Commands
  " E.g. \def \foo #1#2 {foo #1 bar #2 baz}
  syntax match texCmd "\\def\>" nextgroup=texArgDefName skipwhite skipnl
  if l:cfg.is_style_document
    syntax match texArgDefName contained nextgroup=texParmDefPre,texArgDefBody skipwhite skipnl "\\[a-zA-Z@]\+"
    syntax match texArgDefName contained nextgroup=texParmDefPre,texArgDefBody skipwhite skipnl "\\[^a-zA-Z@]"
  else
    syntax match texArgDefName contained nextgroup=texParmDefPre,texArgDefBody skipwhite skipnl "\\\a\+"
    syntax match texArgDefName contained nextgroup=texParmDefPre,texArgDefBody skipwhite skipnl "\\\A"
  endif
  syntax match texParmDefPre contained nextgroup=texArgDefBody skipwhite skipnl "#[^{]*"
  syntax match texParmDef contained "#\d\+" containedin=texParmDefPre,texArgDefBody
  call vimtex#syntax#core#new_cmd_arg('texArgDefBody', '', 'TOP')

  " Reference and cite commands
  syntax match texCmd nextgroup=texArgRef           skipwhite skipnl "\\nocite\>"
  syntax match texCmd nextgroup=texArgRef           skipwhite skipnl "\\label\>"
  syntax match texCmd nextgroup=texArgRef           skipwhite skipnl "\\\(page\|eq\)ref\>"
  syntax match texCmd nextgroup=texArgRef           skipwhite skipnl "\\v\?ref\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\cite\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\cite[tp]\>\*\?"
  call vimtex#syntax#core#new_cmd_arg('texArgRef', '', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_opt('texOptRef', 'texOptRef,texArgRef')

  " \makeatletter ... \makeatother sections
  " https://tex.stackexchange.com/questions/8351/what-do-makeatletter-and-makeatother-do
  " In short: allow @ in multicharacter macro name
  syntax region texRegionSty matchgroup=texCmd start='\\makeatletter' end='\\makeatother' contains=TOP
  syntax match texCmdSty "\\[a-zA-Z@]\+" contained containedin=texRegionSty

  " Add @NoSpell for commands per configuration
  for l:macro in g:vimtex_syntax_nospell_commands
    execute 'syntax match texCmd skipwhite skipnl "\\' . l:macro . '"'
          \ 'nextgroup=texArgNoSpell'
  endfor
  call vimtex#syntax#core#new_cmd_arg('texArgNoSpell', '', '@NoSpell')

  " Sections and parts
  syntax match texCmdParts "\\\(front\|main\|back\)matter\>"
  syntax match texCmdParts nextgroup=texArgPartTitle "\\part\>"
  syntax match texCmdParts nextgroup=texArgPartTitle "\\chapter\>"
  syntax match texCmdParts nextgroup=texArgPartTitle "\\\(sub\)*section\>"
  syntax match texCmdParts nextgroup=texArgPartTitle "\\\(sub\)\?paragraph\>"
  call vimtex#syntax#core#new_cmd_arg('texArgPartTitle', '', 'TOP')

  " }}}2
  " {{{2 Environments

  syntax match texCmdEnv "\v\\%(begin|end)>" nextgroup=texArgEnvName
  call vimtex#syntax#core#new_cmd_arg('texArgEnvName', 'texOptEnvModifier')
  call vimtex#syntax#core#new_cmd_opt('texOptEnvModifier', '', 'texComment,@NoSpell')

  syntax match texCmdEnvMath "\v\\%(begin|end)>" contained nextgroup=texArgEnvMathName
  call vimtex#syntax#core#new_cmd_arg('texArgEnvMathName', '')

  " }}}2
  " {{{2 Verbatim

  " Verbatim environment
  syntax region texRegionVerb
        \ start="\\begin{[vV]erbatim}" end="\\end{[vV]erbatim}"
        \ keepend contains=texCmdEnv,texArgEnvName

  " Verbatim inline
  syntax match texCmd "\\verb\>\*\?" nextgroup=texRegionVerbInline
  if l:cfg.is_style_document
    syntax region texRegionVerbInline matchgroup=texDelim
          \ start="\z([^\ta-zA-Z@]\)" end="\z1" contained
  else
    syntax region texRegionVerbInline matchgroup=texDelim
          \ start="\z([^\ta-zA-Z]\)" end="\z1" contained
  endif

  " }}}2
  " {{{2 Various TeX symbols

  syntax match texSymbolString "\v%(``|''|,,)"
  syntax match texSymbolDash "--"
  syntax match texSymbolDash "---"
  syntax match texSymbolAmp "&"

  " E.g.:  \$ \& \% \# \{ \} \_ \S \P
  syntax match texSpecialChar "\\[$&%#{}_]"
  if l:cfg.is_style_document
    syntax match texSpecialChar "\\[SP@]\ze[^a-zA-Z@]"
  else
    syntax match texSpecialChar "\\[SP@]\ze\A"
  endif
  syntax match texSpecialChar "\\\\"
  syntax match texSpecialChar "\^\^\%(\S\|[0-9a-f]\{2}\)"

  " }}}2
  " {{{2 Math

  " Math clusters for use in math regions
  syntax cluster texClusterMath contains=texCmd,texCmdGreek,texCmdSize,texCmdStyle,texComment,texDelimMath,texDelimMathMod,texLength,texMatcherMath,texMathOper,texSymbolMath,texSpecialChar,texSubscript,texSuperscript,texSymbolAmp,texSymbolDash,@NoSpell
  syntax region texMatcherMath matchgroup=texDelim start="{" skip="\\\\\|\\}" end="}" contained contains=@texClusterMath

  " Math regions: environments
  call vimtex#syntax#core#new_math_region('displaymath', 1)
  call vimtex#syntax#core#new_math_region('eqnarray', 1)
  call vimtex#syntax#core#new_math_region('equation', 1)
  call vimtex#syntax#core#new_math_region('math', 1)

  " Math regions: Inline Math Zones
  if l:cfg.conceal.math_bounds
    syntax region texRegionMath   matchgroup=texDelimMathmode concealends contains=@texClusterMath keepend start="\\("  end="\\)"
    syntax region texRegionMath   matchgroup=texDelimMathmode concealends contains=@texClusterMath keepend start="\\\[" end="\\]"
    syntax region texRegionMathX  matchgroup=texDelimMathmode concealends contains=@texClusterMath         start="\$"   skip="\\\\\|\\\$"  end="\$"
    syntax region texRegionMathXX matchgroup=texDelimMathmode concealends contains=@texClusterMath keepend start="\$\$" end="\$\$"
  else
    syntax region texRegionMath   matchgroup=texDelimMathmode contains=@texClusterMath keepend start="\\("  end="\\)"
    syntax region texRegionMath   matchgroup=texDelimMathmode contains=@texClusterMath keepend start="\\\[" end="\\]"
    syntax region texRegionMathX  matchgroup=texDelimMathmode contains=@texClusterMath         start="\$"   skip="\\\\\|\\\$"  end="\$"
    syntax region texRegionMathXX matchgroup=texDelimMathmode contains=@texClusterMath keepend start="\$\$" end="\$\$"
  endif

  " Math regions: \ensuremath{...}
  syntax match texCmd "\\ensuremath\>" nextgroup=texRegionMathEnsured
  call vimtex#syntax#core#new_cmd_arg('texRegionMathEnsured', '', '@texClusterMath')

  " Bad/Mismatched math
  syntax match texErrorOnlyMath "[_^]"
  syntax match texErrorMath "\\[\])]"
  syntax match texErrorMath "\\end\s*{\s*\(array\|[bBpvV]matrix\|split\|smallmatrix\)\s*}"

  " Operators and similar
  syntax match texMathOper "[_^=]" contained

  " Text Inside Math regions
  syntax match texCmd "\\\(\(inter\)\?text\|mbox\)\>" nextgroup=texArgMathText
  call vimtex#syntax#core#new_cmd_arg('texArgMathText', '', 'TOP,@Spell')

  " Math delimiters: \left... and \right...
  call s:match_math_delims(l:cfg)

  " }}}2
  " {{{2 Conceal mode support

  " Add support for conceal with custom replacement (conceallevel = 2)

  if &encoding ==# 'utf-8'
    if l:cfg.conceal.special_chars
      syntax match texSpecialChar '\\glq\>'  contained conceal cchar=‚
      syntax match texSpecialChar '\\grq\>'  contained conceal cchar=‘
      syntax match texSpecialChar '\\glqq\>' contained conceal cchar=„
      syntax match texSpecialChar '\\grqq\>' contained conceal cchar=“
      syntax match texSpecialChar '\\hyp\>'  contained conceal cchar=-
    endif

    " Many of these symbols were contributed by Björn Winckler
    if l:cfg.conceal.math_delimiters
      call s:match_conceal_math_symbols()
    endif

    " Conceal replace greek letters
    if l:cfg.conceal.greek
      call s:match_conceal_greek()
    endif

    " Conceal replace superscripts and subscripts
    if l:cfg.conceal.super_sub
      call s:match_conceal_super_sub(l:cfg)
    endif

    " Conceal replace accented characters and ligatures
    if l:cfg.conceal.accents && !l:cfg.is_style_document
      call s:match_conceal_accents()
    endif
  endif

  " }}}2

  call s:init_highlights(l:cfg)

  let b:current_syntax = 'tex'
endfunction

" }}}1

function! vimtex#syntax#core#new_cmd_arg(grp, next, ...) abort " {{{1
  let l:contains = a:0 >= 1 ? a:1 : 'texComment'
  let l:options = a:0 >= 2 ? a:2 : ''

  execute 'syntax region' a:grp
        \ 'contained matchgroup=texDelim start="{" skip="\\\\\|\\}" end="}"'
        \ (empty(l:contains) ? '' : 'contains=' . l:contains)
        \ (empty(a:next) ? '' : 'nextgroup=' . a:next . ' skipwhite skipnl')
        \ l:options
endfunction

" }}}1
function! vimtex#syntax#core#new_cmd_opt(grp, next, ...) abort " {{{1
  let l:contains = a:0 > 0 ? a:1 : 'texComment,texCmd,texLength,texOptSep,texOptEqual'
  let l:options = a:0 >= 2 ? a:2 : ''

  execute 'syntax region' a:grp
        \ 'contained matchgroup=texDelim start="\[" skip="\\\\\|\\\]" end="\]"'
        \ (empty(l:contains) ? '' : 'contains=' . l:contains)
        \ (empty(a:next) ? '' : 'nextgroup=' . a:next . ' skipwhite skipnl')
        \ l:options
endfunction

" }}}1
function! vimtex#syntax#core#new_math_region(mathzone, starred) abort " {{{1
  execute 'syntax match texErrorMath /\\end\s*{\s*' . a:mathzone . '\*\?\s*}/'

  execute 'syntax region texRegionMathEnv'
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\s*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\s*}'''
        \ . ' keepend contains=texCmdEnvMath,texArgEnvMathName,@texClusterMath'

  if !a:starred | return | endif

  execute 'syntax region texRegionMathEnvStarred'
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\*\s*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\*\s*}'''
        \ . ' keepend contains=texCmdEnvMath,texArgEnvMathName,@texClusterMath'
endfunction

" }}}1


function! s:init_highlights(cfg) abort " {{{1
  " See :help group-name for list of conventional group names

  " Basic TeX highlighting groups
  highlight def link texArg              Include
  highlight def link texArgAuthor        Identifier
  highlight def link texArgEnvMathName   Delimiter
  highlight def link texArgEnvName       PreCondit
  highlight def link texArgRef           Special
  highlight def link texArgTitle         Underlined
  highlight def link texCmd              Statement
  highlight def link texCmdSpaceCodeChar Special
  highlight def link texCmdTodo          Todo
  highlight def link texComment          Comment
  highlight def link texCommentTodo      Todo
  highlight def link texDelim            Delimiter
  highlight def link texDelimMath        Type
  highlight def link texDelimMathMod     Statement
  highlight def link texError            Error
  highlight def link texLength           Number
  highlight def link texMath             Special
  highlight def link texMathOper         Operator
  highlight def link texOpt              Identifier
  highlight def link texOptSep           NormalNC
  highlight def link texParm             Special
  highlight def link texRegion           PreCondit
  highlight def link texSpecialChar      SpecialChar
  highlight def link texSymbol           SpecialChar
  highlight def link texSymbolString     String
  highlight def link texTitle            String
  highlight def link texType             Type

  highlight def texStyleBold gui=bold        cterm=bold
  highlight def texStyleItal gui=italic      cterm=italic
  highlight def texStyleBoth gui=bold,italic cterm=bold,italic

  " Inherited groups
  highlight def link texArgDefName           texCmd
  highlight def link texArgFile              texArg
  highlight def link texArgFiles             texArg
  highlight def link texArgNewcmdName        texCmd
  highlight def link texArgNewenvName        texArgEnvName
  highlight def link texArgPartTitle         texTitle
  highlight def link texCmd                  texCmd
  highlight def link texCmdAccent            texCmd
  highlight def link texCmdEnv               texCmd
  highlight def link texCmdEnvMath           texCmdEnv
  highlight def link texCmdError             texError
  highlight def link texCmdGreek             texCmd
  highlight def link texCmdLigature          texSpecialChar
  highlight def link texCmdParts             texCmd
  highlight def link texCmdSize              texType
  highlight def link texCmdSpaceCode         texCmd
  highlight def link texCmdSty               texCmd
  highlight def link texCmdStyle             texCmd
  highlight def link texCmdStyle             texType
  highlight def link texCmdStyleBold         texCmd
  highlight def link texCmdStyleBoldItal     texCmd
  highlight def link texCmdStyleItal         texCmd
  highlight def link texCmdStyleItalBold     texCmd
  highlight def link texCommentAcronym       texComment
  highlight def link texCommentURL           texComment
  highlight def link texDelimMathKey         texDelimMath
  highlight def link texDelimMathSet1        texDelimMath
  highlight def link texDelimMathSet2        texDelimMath
  highlight def link texDelimMathmode        texDelim
  highlight def link texErrorMath            texError
  highlight def link texErrorMathDelim       texError
  highlight def link texErrorOnlyMath        texError
  highlight def link texMatcherMath          texMath
  highlight def link texSymbolMath           texCmd
  highlight def link texOptEqual             texSymbol
  highlight def link texOptFile              texOpt
  highlight def link texOptFiles             texOpt
  highlight def link texOptNewcmd            texOpt
  highlight def link texOptNewenv            texOpt
  highlight def link texOptRef               texOpt
  highlight def link texParmDef              texParm
  highlight def link texParmNewcmd           texParm
  highlight def link texParmNewenv           texParm
  highlight def link texRefCite              texRegionRef
  highlight def link texRegionMath           texMath
  highlight def link texRegionMathEnsured    texMath
  highlight def link texRegionMathEnv        texMath
  highlight def link texRegionMathEnvStarred texMath
  highlight def link texRegionMathX          texMath
  highlight def link texRegionMathXX         texMath
  highlight def link texRegionVerb           texRegion
  highlight def link texRegionVerbInline     texRegionVerb
  highlight def link texSubscript            texCmd
  highlight def link texSubscripts           texSubscript
  highlight def link texSuperscript          texCmd
  highlight def link texSuperscripts         texSuperscript
  highlight def link texSymbolAmp            texSymbol
  highlight def link texSymbolDash           texSymbol
endfunction

" }}}1

function! s:match_bold_italic(cfg) abort " {{{1
  let [l:conceal, l:concealends] =
        \ (a:cfg.conceal.styles ? ['conceal', 'concealends'] : ['', ''])

  syntax cluster texClusterBold contains=TOP,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold
  syntax cluster texClusterItal contains=TOP,texCmdStyleItal,texCmdStyleBold,texCmdStyleBoldItal
  syntax cluster texClusterItalBold contains=TOP,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold,texCmdStyleBoldItal

  let l:map = {
        \ 'texCmdStyleBold': 'texStyleBold',
        \ 'texCmdStyleBoldItal': 'texStyleBoth',
        \ 'texCmdStyleItal': 'texStyleItal',
        \ 'texCmdStyleItalBold': 'texStyleBoth',
        \}

  for [l:group, l:pattern] in [
        \ ['texCmdStyleBoldItal', 'emph'],
        \ ['texCmdStyleBoldItal', 'textit'],
        \ ['texCmdStyleBoldItal', 'texts[cfl]'],
        \ ['texCmdStyleBoldItal', 'texttt'],
        \ ['texCmdStyleBoldItal', 'textup'],
        \ ['texCmdStyleItalBold', 'textbf'],
        \ ['texCmdStyleBold', 'textbf'],
        \ ['texCmdStyleItal', 'emph'],
        \ ['texCmdStyleItal', 'textit'],
        \ ['texCmdStyleItal', 'texts[cfl]'],
        \ ['texCmdStyleItal', 'texttt'],
        \ ['texCmdStyleItal', 'textup'],
        \]
    execute 'syntax match' l:group '"\\' . l:pattern . '\>\s*"'
          \ 'skipwhite skipnl nextgroup=' . l:map[l:group] l:conceal
  endfor

  execute 'syntax region texStyleBold matchgroup=texDelim start=/{/ end=/}/'
        \ 'contained contains=@texClusterBold' l:concealends
  execute 'syntax region texStyleItal matchgroup=texDelim start=/{/ end=/}/'
        \ 'contained contains=@texClusterItal' l:concealends
  execute 'syntax region texStyleBoth matchgroup=texDelim start=/{/ end=/}/'
        \ 'contained contains=@texClusterItalBold' l:concealends
endfunction

" }}}1
function! s:match_math_delims(cfg) abort " {{{1
  syntax match texDelimMathMod contained skipwhite nextgroup=texDelimMath "\\\(left\|right\)\>"
  syntax match texDelimMathMod contained skipwhite nextgroup=texDelimMath "\\[bB]igg\?[lr]\?\>"
  syntax match texDelimMath contained "[<>()[\]|/.]\|\\[{}|]"
  syntax match texDelimMath contained "\\backslash"
  syntax match texDelimMath contained "\\downarrow"
  syntax match texDelimMath contained "\\Downarrow"
  syntax match texDelimMath contained "\\lVert"
  syntax match texDelimMath contained "\\langle"
  syntax match texDelimMath contained "\\lbrace"
  syntax match texDelimMath contained "\\lceil"
  syntax match texDelimMath contained "\\lfloor"
  syntax match texDelimMath contained "\\lgroup"
  syntax match texDelimMath contained "\\lmoustache"
  syntax match texDelimMath contained "\\lvert"
  syntax match texDelimMath contained "\\rVert"
  syntax match texDelimMath contained "\\rangle"
  syntax match texDelimMath contained "\\rbrace"
  syntax match texDelimMath contained "\\rceil"
  syntax match texDelimMath contained "\\rfloor"
  syntax match texDelimMath contained "\\rgroup"
  syntax match texDelimMath contained "\\rmoustache"
  syntax match texDelimMath contained "\\rvert"
  syntax match texDelimMath contained "\\uparrow"
  syntax match texDelimMath contained "\\Uparrow"
  syntax match texDelimMath contained "\\updownarrow"
  syntax match texDelimMath contained "\\Updownarrow"

  if !a:cfg.conceal.math_delimiters || &encoding !=# 'utf-8'
    return
  endif

  syntax match texDelimMath contained conceal cchar=< "\\\%([bB]igg\?l\|left\)<"
  syntax match texDelimMath contained conceal cchar=> "\\\%([bB]igg\?r\|right\)>"
  syntax match texDelimMath contained conceal cchar=( "\\\%([bB]igg\?l\|left\)("
  syntax match texDelimMath contained conceal cchar=) "\\\%([bB]igg\?r\|right\))"
  syntax match texDelimMath contained conceal cchar=[ "\\\%([bB]igg\?l\|left\)\["
  syntax match texDelimMath contained conceal cchar=] "\\\%([bB]igg\?r\|right\)]"
  syntax match texDelimMath contained conceal cchar={ "\\\%([bB]igg\?l\|left\)\\{"
  syntax match texDelimMath contained conceal cchar=} "\\\%([bB]igg\?r\|right\)\\}"
  syntax match texDelimMath contained conceal cchar=[ "\\\%([bB]igg\?l\|left\)\\lbrace"
  syntax match texDelimMath contained conceal cchar=⌈ "\\\%([bB]igg\?l\|left\)\\lceil"
  syntax match texDelimMath contained conceal cchar=⌊ "\\\%([bB]igg\?l\|left\)\\lfloor"
  syntax match texDelimMath contained conceal cchar=⌊ "\\\%([bB]igg\?l\|left\)\\lgroup"
  syntax match texDelimMath contained conceal cchar=⎛ "\\\%([bB]igg\?l\|left\)\\lmoustache"
  syntax match texDelimMath contained conceal cchar=] "\\\%([bB]igg\?r\|right\)\\rbrace"
  syntax match texDelimMath contained conceal cchar=⌉ "\\\%([bB]igg\?r\|right\)\\rceil"
  syntax match texDelimMath contained conceal cchar=⌋ "\\\%([bB]igg\?r\|right\)\\rfloor"
  syntax match texDelimMath contained conceal cchar=⌋ "\\\%([bB]igg\?r\|right\)\\rgroup"
  syntax match texDelimMath contained conceal cchar=⎞ "\\\%([bB]igg\?r\|right\)\\rmoustache"
  syntax match texDelimMath contained conceal cchar=| "\\\%([bB]igg\?[lr]\?\|left\|right\)|"
  syntax match texDelimMath contained conceal cchar=‖ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\|"
  syntax match texDelimMath contained conceal cchar=↓ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\downarrow"
  syntax match texDelimMath contained conceal cchar=⇓ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Downarrow"
  syntax match texDelimMath contained conceal cchar=↑ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\uparrow"
  syntax match texDelimMath contained conceal cchar=↑ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Uparrow"
  syntax match texDelimMath contained conceal cchar=↕ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\updownarrow"
  syntax match texDelimMath contained conceal cchar=⇕ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Updownarrow"

  if &ambiwidth ==# 'double'
    syntax match texDelimMath contained conceal cchar=〈 "\\\%([bB]igg\?l\|left\)\\langle"
    syntax match texDelimMath contained conceal cchar=〉 "\\\%([bB]igg\?r\|right\)\\rangle"
  else
    syntax match texDelimMath contained conceal cchar=< "\\\%([bB]igg\?l\|left\)\\langle"
    syntax match texDelimMath contained conceal cchar=> "\\\%([bB]igg\?r\|right\)\\rangle"
  endif
endfunction

" }}}1

function! s:match_conceal_math_symbols() abort " {{{1
  syntax match texSymbolMath "\\|"                   contained conceal cchar=‖
  syntax match texSymbolMath "\\aleph\>"             contained conceal cchar=ℵ
  syntax match texSymbolMath "\\amalg\>"             contained conceal cchar=∐
  syntax match texSymbolMath "\\angle\>"             contained conceal cchar=∠
  syntax match texSymbolMath "\\approx\>"            contained conceal cchar=≈
  syntax match texSymbolMath "\\ast\>"               contained conceal cchar=∗
  syntax match texSymbolMath "\\asymp\>"             contained conceal cchar=≍
  syntax match texSymbolMath "\\backslash\>"         contained conceal cchar=∖
  syntax match texSymbolMath "\\bigcap\>"            contained conceal cchar=∩
  syntax match texSymbolMath "\\bigcirc\>"           contained conceal cchar=○
  syntax match texSymbolMath "\\bigcup\>"            contained conceal cchar=∪
  syntax match texSymbolMath "\\bigodot\>"           contained conceal cchar=⊙
  syntax match texSymbolMath "\\bigoplus\>"          contained conceal cchar=⊕
  syntax match texSymbolMath "\\bigotimes\>"         contained conceal cchar=⊗
  syntax match texSymbolMath "\\bigsqcup\>"          contained conceal cchar=⊔
  syntax match texSymbolMath "\\bigtriangledown\>"   contained conceal cchar=∇
  syntax match texSymbolMath "\\bigtriangleup\>"     contained conceal cchar=∆
  syntax match texSymbolMath "\\bigvee\>"            contained conceal cchar=⋁
  syntax match texSymbolMath "\\bigwedge\>"          contained conceal cchar=⋀
  syntax match texSymbolMath "\\bot\>"               contained conceal cchar=⊥
  syntax match texSymbolMath "\\bowtie\>"            contained conceal cchar=⋈
  syntax match texSymbolMath "\\bullet\>"            contained conceal cchar=•
  syntax match texSymbolMath "\\cap\>"               contained conceal cchar=∩
  syntax match texSymbolMath "\\cdot\>"              contained conceal cchar=·
  syntax match texSymbolMath "\\cdots\>"             contained conceal cchar=⋯
  syntax match texSymbolMath "\\circ\>"              contained conceal cchar=∘
  syntax match texSymbolMath "\\clubsuit\>"          contained conceal cchar=♣
  syntax match texSymbolMath "\\cong\>"              contained conceal cchar=≅
  syntax match texSymbolMath "\\coprod\>"            contained conceal cchar=∐
  syntax match texSymbolMath "\\copyright\>"         contained conceal cchar=©
  syntax match texSymbolMath "\\cup\>"               contained conceal cchar=∪
  syntax match texSymbolMath "\\dagger\>"            contained conceal cchar=†
  syntax match texSymbolMath "\\dashv\>"             contained conceal cchar=⊣
  syntax match texSymbolMath "\\ddagger\>"           contained conceal cchar=‡
  syntax match texSymbolMath "\\ddots\>"             contained conceal cchar=⋱
  syntax match texSymbolMath "\\diamond\>"           contained conceal cchar=⋄
  syntax match texSymbolMath "\\diamondsuit\>"       contained conceal cchar=♢
  syntax match texSymbolMath "\\div\>"               contained conceal cchar=÷
  syntax match texSymbolMath "\\doteq\>"             contained conceal cchar=≐
  syntax match texSymbolMath "\\dots\>"              contained conceal cchar=…
  syntax match texSymbolMath "\\downarrow\>"         contained conceal cchar=↓
  syntax match texSymbolMath "\\Downarrow\>"         contained conceal cchar=⇓
  syntax match texSymbolMath "\\ell\>"               contained conceal cchar=ℓ
  syntax match texSymbolMath "\\emptyset\>"          contained conceal cchar=∅
  syntax match texSymbolMath "\\equiv\>"             contained conceal cchar=≡
  syntax match texSymbolMath "\\exists\>"            contained conceal cchar=∃
  syntax match texSymbolMath "\\flat\>"              contained conceal cchar=♭
  syntax match texSymbolMath "\\forall\>"            contained conceal cchar=∀
  syntax match texSymbolMath "\\frown\>"             contained conceal cchar=⁔
  syntax match texSymbolMath "\\ge\>"                contained conceal cchar=≥
  syntax match texSymbolMath "\\geq\>"               contained conceal cchar=≥
  syntax match texSymbolMath "\\gets\>"              contained conceal cchar=←
  syntax match texSymbolMath "\\gg\>"                contained conceal cchar=⟫
  syntax match texSymbolMath "\\hbar\>"              contained conceal cchar=ℏ
  syntax match texSymbolMath "\\heartsuit\>"         contained conceal cchar=♡
  syntax match texSymbolMath "\\hookleftarrow\>"     contained conceal cchar=↩
  syntax match texSymbolMath "\\hookrightarrow\>"    contained conceal cchar=↪
  syntax match texSymbolMath "\\iff\>"               contained conceal cchar=⇔
  syntax match texSymbolMath "\\Im\>"                contained conceal cchar=ℑ
  syntax match texSymbolMath "\\imath\>"             contained conceal cchar=ɩ
  syntax match texSymbolMath "\\in\>"                contained conceal cchar=∈
  syntax match texSymbolMath "\\infty\>"             contained conceal cchar=∞
  syntax match texSymbolMath "\\int\>"               contained conceal cchar=∫
  syntax match texSymbolMath "\\jmath\>"             contained conceal cchar=𝚥
  syntax match texSymbolMath "\\land\>"              contained conceal cchar=∧
  syntax match texSymbolMath "\\lceil\>"             contained conceal cchar=⌈
  syntax match texSymbolMath "\\ldots\>"             contained conceal cchar=…
  syntax match texSymbolMath "\\le\>"                contained conceal cchar=≤
  syntax match texSymbolMath "\\left|"               contained conceal cchar=|
  syntax match texSymbolMath "\\left\\|"             contained conceal cchar=‖
  syntax match texSymbolMath "\\left("               contained conceal cchar=(
  syntax match texSymbolMath "\\left\["              contained conceal cchar=[
  syntax match texSymbolMath "\\left\\{"             contained conceal cchar={
  syntax match texSymbolMath "\\leftarrow\>"         contained conceal cchar=←
  syntax match texSymbolMath "\\Leftarrow\>"         contained conceal cchar=⇐
  syntax match texSymbolMath "\\leftharpoondown\>"   contained conceal cchar=↽
  syntax match texSymbolMath "\\leftharpoonup\>"     contained conceal cchar=↼
  syntax match texSymbolMath "\\leftrightarrow\>"    contained conceal cchar=↔
  syntax match texSymbolMath "\\Leftrightarrow\>"    contained conceal cchar=⇔
  syntax match texSymbolMath "\\leq\>"               contained conceal cchar=≤
  syntax match texSymbolMath "\\leq\>"               contained conceal cchar=≤
  syntax match texSymbolMath "\\lfloor\>"            contained conceal cchar=⌊
  syntax match texSymbolMath "\\ll\>"                contained conceal cchar=≪
  syntax match texSymbolMath "\\lmoustache\>"        contained conceal cchar=╭
  syntax match texSymbolMath "\\lor\>"               contained conceal cchar=∨
  syntax match texSymbolMath "\\mapsto\>"            contained conceal cchar=↦
  syntax match texSymbolMath "\\mid\>"               contained conceal cchar=∣
  syntax match texSymbolMath "\\models\>"            contained conceal cchar=╞
  syntax match texSymbolMath "\\mp\>"                contained conceal cchar=∓
  syntax match texSymbolMath "\\nabla\>"             contained conceal cchar=∇
  syntax match texSymbolMath "\\natural\>"           contained conceal cchar=♮
  syntax match texSymbolMath "\\ne\>"                contained conceal cchar=≠
  syntax match texSymbolMath "\\nearrow\>"           contained conceal cchar=↗
  syntax match texSymbolMath "\\neg\>"               contained conceal cchar=¬
  syntax match texSymbolMath "\\neq\>"               contained conceal cchar=≠
  syntax match texSymbolMath "\\ni\>"                contained conceal cchar=∋
  syntax match texSymbolMath "\\notin\>"             contained conceal cchar=∉
  syntax match texSymbolMath "\\nwarrow\>"           contained conceal cchar=↖
  syntax match texSymbolMath "\\odot\>"              contained conceal cchar=⊙
  syntax match texSymbolMath "\\oint\>"              contained conceal cchar=∮
  syntax match texSymbolMath "\\ominus\>"            contained conceal cchar=⊖
  syntax match texSymbolMath "\\oplus\>"             contained conceal cchar=⊕
  syntax match texSymbolMath "\\oslash\>"            contained conceal cchar=⊘
  syntax match texSymbolMath "\\otimes\>"            contained conceal cchar=⊗
  syntax match texSymbolMath "\\owns\>"              contained conceal cchar=∋
  syntax match texSymbolMath "\\P\>"                 contained conceal cchar=¶
  syntax match texSymbolMath "\\parallel\>"          contained conceal cchar=║
  syntax match texSymbolMath "\\partial\>"           contained conceal cchar=∂
  syntax match texSymbolMath "\\perp\>"              contained conceal cchar=⊥
  syntax match texSymbolMath "\\pm\>"                contained conceal cchar=±
  syntax match texSymbolMath "\\prec\>"              contained conceal cchar=≺
  syntax match texSymbolMath "\\preceq\>"            contained conceal cchar=⪯
  syntax match texSymbolMath "\\prime\>"             contained conceal cchar=′
  syntax match texSymbolMath "\\prod\>"              contained conceal cchar=∏
  syntax match texSymbolMath "\\propto\>"            contained conceal cchar=∝
  syntax match texSymbolMath "\\rceil\>"             contained conceal cchar=⌉
  syntax match texSymbolMath "\\Re\>"                contained conceal cchar=ℜ
  syntax match texSymbolMath "\\quad\>"              contained conceal cchar= 
  syntax match texSymbolMath "\\qquad\>"             contained conceal cchar= 
  syntax match texSymbolMath "\\rfloor\>"            contained conceal cchar=⌋
  syntax match texSymbolMath "\\right|"              contained conceal cchar=|
  syntax match texSymbolMath "\\right\\|"            contained conceal cchar=‖
  syntax match texSymbolMath "\\right)"              contained conceal cchar=)
  syntax match texSymbolMath "\\right]"              contained conceal cchar=]
  syntax match texSymbolMath "\\right\\}"            contained conceal cchar=}
  syntax match texSymbolMath "\\rightarrow\>"        contained conceal cchar=→
  syntax match texSymbolMath "\\Rightarrow\>"        contained conceal cchar=⇒
  syntax match texSymbolMath "\\rightleftharpoons\>" contained conceal cchar=⇌
  syntax match texSymbolMath "\\rmoustache\>"        contained conceal cchar=╮
  syntax match texSymbolMath "\\S\>"                 contained conceal cchar=§
  syntax match texSymbolMath "\\searrow\>"           contained conceal cchar=↘
  syntax match texSymbolMath "\\setminus\>"          contained conceal cchar=∖
  syntax match texSymbolMath "\\sharp\>"             contained conceal cchar=♯
  syntax match texSymbolMath "\\sim\>"               contained conceal cchar=∼
  syntax match texSymbolMath "\\simeq\>"             contained conceal cchar=⋍
  syntax match texSymbolMath "\\smile\>"             contained conceal cchar=‿
  syntax match texSymbolMath "\\spadesuit\>"         contained conceal cchar=♠
  syntax match texSymbolMath "\\sqcap\>"             contained conceal cchar=⊓
  syntax match texSymbolMath "\\sqcup\>"             contained conceal cchar=⊔
  syntax match texSymbolMath "\\sqsubset\>"          contained conceal cchar=⊏
  syntax match texSymbolMath "\\sqsubseteq\>"        contained conceal cchar=⊑
  syntax match texSymbolMath "\\sqsupset\>"          contained conceal cchar=⊐
  syntax match texSymbolMath "\\sqsupseteq\>"        contained conceal cchar=⊒
  syntax match texSymbolMath "\\star\>"              contained conceal cchar=✫
  syntax match texSymbolMath "\\subset\>"            contained conceal cchar=⊂
  syntax match texSymbolMath "\\subseteq\>"          contained conceal cchar=⊆
  syntax match texSymbolMath "\\succ\>"              contained conceal cchar=≻
  syntax match texSymbolMath "\\succeq\>"            contained conceal cchar=⪰
  syntax match texSymbolMath "\\sum\>"               contained conceal cchar=∑
  syntax match texSymbolMath "\\supset\>"            contained conceal cchar=⊃
  syntax match texSymbolMath "\\supseteq\>"          contained conceal cchar=⊇
  syntax match texSymbolMath "\\surd\>"              contained conceal cchar=√
  syntax match texSymbolMath "\\swarrow\>"           contained conceal cchar=↙
  syntax match texSymbolMath "\\times\>"             contained conceal cchar=×
  syntax match texSymbolMath "\\to\>"                contained conceal cchar=→
  syntax match texSymbolMath "\\top\>"               contained conceal cchar=⊤
  syntax match texSymbolMath "\\triangle\>"          contained conceal cchar=∆
  syntax match texSymbolMath "\\triangleleft\>"      contained conceal cchar=⊲
  syntax match texSymbolMath "\\triangleright\>"     contained conceal cchar=⊳
  syntax match texSymbolMath "\\uparrow\>"           contained conceal cchar=↑
  syntax match texSymbolMath "\\Uparrow\>"           contained conceal cchar=⇑
  syntax match texSymbolMath "\\updownarrow\>"       contained conceal cchar=↕
  syntax match texSymbolMath "\\Updownarrow\>"       contained conceal cchar=⇕
  syntax match texSymbolMath "\\vdash\>"             contained conceal cchar=⊢
  syntax match texSymbolMath "\\vdots\>"             contained conceal cchar=⋮
  syntax match texSymbolMath "\\vee\>"               contained conceal cchar=∨
  syntax match texSymbolMath "\\wedge\>"             contained conceal cchar=∧
  syntax match texSymbolMath "\\wp\>"                contained conceal cchar=℘
  syntax match texSymbolMath "\\wr\>"                contained conceal cchar=≀

  if &ambiwidth ==# 'double'
    syntax match texSymbolMath "right\\rangle\>" contained conceal cchar=〉
    syntax match texSymbolMath "left\\langle\>"  contained conceal cchar=〈
    syntax match texSymbolMath '\\gg\>'          contained conceal cchar=≫
    syntax match texSymbolMath '\\ll\>'          contained conceal cchar=≪
  else
    syntax match texSymbolMath "right\\rangle\>" contained conceal cchar=>
    syntax match texSymbolMath "left\\langle\>"  contained conceal cchar=<
    syntax match texSymbolMath '\\gg\>'          contained conceal cchar=⟫
    syntax match texSymbolMath '\\ll\>'          contained conceal cchar=⟪
  endif

  syntax match texSymbolMath '\\bar{a}' contained conceal cchar=a̅

  syntax match texSymbolMath '\\dot{A}' contained conceal cchar=Ȧ
  syntax match texSymbolMath '\\dot{a}' contained conceal cchar=ȧ
  syntax match texSymbolMath '\\dot{B}' contained conceal cchar=Ḃ
  syntax match texSymbolMath '\\dot{b}' contained conceal cchar=ḃ
  syntax match texSymbolMath '\\dot{C}' contained conceal cchar=Ċ
  syntax match texSymbolMath '\\dot{c}' contained conceal cchar=ċ
  syntax match texSymbolMath '\\dot{D}' contained conceal cchar=Ḋ
  syntax match texSymbolMath '\\dot{d}' contained conceal cchar=ḋ
  syntax match texSymbolMath '\\dot{E}' contained conceal cchar=Ė
  syntax match texSymbolMath '\\dot{e}' contained conceal cchar=ė
  syntax match texSymbolMath '\\dot{F}' contained conceal cchar=Ḟ
  syntax match texSymbolMath '\\dot{f}' contained conceal cchar=ḟ
  syntax match texSymbolMath '\\dot{G}' contained conceal cchar=Ġ
  syntax match texSymbolMath '\\dot{g}' contained conceal cchar=ġ
  syntax match texSymbolMath '\\dot{H}' contained conceal cchar=Ḣ
  syntax match texSymbolMath '\\dot{h}' contained conceal cchar=ḣ
  syntax match texSymbolMath '\\dot{I}' contained conceal cchar=İ
  syntax match texSymbolMath '\\dot{M}' contained conceal cchar=Ṁ
  syntax match texSymbolMath '\\dot{m}' contained conceal cchar=ṁ
  syntax match texSymbolMath '\\dot{N}' contained conceal cchar=Ṅ
  syntax match texSymbolMath '\\dot{n}' contained conceal cchar=ṅ
  syntax match texSymbolMath '\\dot{O}' contained conceal cchar=Ȯ
  syntax match texSymbolMath '\\dot{o}' contained conceal cchar=ȯ
  syntax match texSymbolMath '\\dot{P}' contained conceal cchar=Ṗ
  syntax match texSymbolMath '\\dot{p}' contained conceal cchar=ṗ
  syntax match texSymbolMath '\\dot{R}' contained conceal cchar=Ṙ
  syntax match texSymbolMath '\\dot{r}' contained conceal cchar=ṙ
  syntax match texSymbolMath '\\dot{S}' contained conceal cchar=Ṡ
  syntax match texSymbolMath '\\dot{s}' contained conceal cchar=ṡ
  syntax match texSymbolMath '\\dot{T}' contained conceal cchar=Ṫ
  syntax match texSymbolMath '\\dot{t}' contained conceal cchar=ṫ
  syntax match texSymbolMath '\\dot{W}' contained conceal cchar=Ẇ
  syntax match texSymbolMath '\\dot{w}' contained conceal cchar=ẇ
  syntax match texSymbolMath '\\dot{X}' contained conceal cchar=Ẋ
  syntax match texSymbolMath '\\dot{x}' contained conceal cchar=ẋ
  syntax match texSymbolMath '\\dot{Y}' contained conceal cchar=Ẏ
  syntax match texSymbolMath '\\dot{y}' contained conceal cchar=ẏ
  syntax match texSymbolMath '\\dot{Z}' contained conceal cchar=Ż
  syntax match texSymbolMath '\\dot{z}' contained conceal cchar=ż

  syntax match texSymbolMath '\\hat{a}' contained conceal cchar=â
  syntax match texSymbolMath '\\hat{A}' contained conceal cchar=Â
  syntax match texSymbolMath '\\hat{c}' contained conceal cchar=ĉ
  syntax match texSymbolMath '\\hat{C}' contained conceal cchar=Ĉ
  syntax match texSymbolMath '\\hat{e}' contained conceal cchar=ê
  syntax match texSymbolMath '\\hat{E}' contained conceal cchar=Ê
  syntax match texSymbolMath '\\hat{g}' contained conceal cchar=ĝ
  syntax match texSymbolMath '\\hat{G}' contained conceal cchar=Ĝ
  syntax match texSymbolMath '\\hat{i}' contained conceal cchar=î
  syntax match texSymbolMath '\\hat{I}' contained conceal cchar=Î
  syntax match texSymbolMath '\\hat{o}' contained conceal cchar=ô
  syntax match texSymbolMath '\\hat{O}' contained conceal cchar=Ô
  syntax match texSymbolMath '\\hat{s}' contained conceal cchar=ŝ
  syntax match texSymbolMath '\\hat{S}' contained conceal cchar=Ŝ
  syntax match texSymbolMath '\\hat{u}' contained conceal cchar=û
  syntax match texSymbolMath '\\hat{U}' contained conceal cchar=Û
  syntax match texSymbolMath '\\hat{w}' contained conceal cchar=ŵ
  syntax match texSymbolMath '\\hat{W}' contained conceal cchar=Ŵ
  syntax match texSymbolMath '\\hat{y}' contained conceal cchar=ŷ
  syntax match texSymbolMath '\\hat{Y}' contained conceal cchar=Ŷ
endfunction

" }}}1
function! s:match_conceal_accents() " {{{1
  for [l:chr; l:targets] in s:map_accents
    for i in range(13)
      if empty(l:targets[i]) | continue | endif
        let l:accent = s:key_accents[i]
        let l:target = l:targets[i]
        if l:accent =~# '\a'
          execute 'syntax match texCmdAccent /' . l:accent . '\%(\s*{' . l:chr . '}\|\s\+' . l:chr . '\)' . '/ conceal cchar=' . l:target
        else
          execute 'syntax match texCmdAccent /' . l:accent . '\s*\%({' . l:chr . '}\|' . l:chr . '\)' . '/ conceal cchar=' . l:target
        endif
    endfor
  endfor

  syntax match texCmdAccent   '\\aa\>' conceal cchar=å
  syntax match texCmdAccent   '\\AA\>' conceal cchar=Å
  syntax match texCmdAccent   '\\o\>'  conceal cchar=ø
  syntax match texCmdAccent   '\\O\>'  conceal cchar=Ø
  syntax match texCmdLigature '\\AE\>' conceal cchar=Æ
  syntax match texCmdLigature '\\ae\>' conceal cchar=æ
  syntax match texCmdLigature '\\oe\>' conceal cchar=œ
  syntax match texCmdLigature '\\OE\>' conceal cchar=Œ
  syntax match texCmdLigature '\\ss\>' conceal cchar=ß
  syntax match texSymbolDash  '--'     conceal cchar=–
  syntax match texSymbolDash  '---'    conceal cchar=—
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
  syntax match texCmdGreek "\\alpha\>"      contained conceal cchar=α
  syntax match texCmdGreek "\\beta\>"       contained conceal cchar=β
  syntax match texCmdGreek "\\gamma\>"      contained conceal cchar=γ
  syntax match texCmdGreek "\\delta\>"      contained conceal cchar=δ
  syntax match texCmdGreek "\\epsilon\>"    contained conceal cchar=ϵ
  syntax match texCmdGreek "\\varepsilon\>" contained conceal cchar=ε
  syntax match texCmdGreek "\\zeta\>"       contained conceal cchar=ζ
  syntax match texCmdGreek "\\eta\>"        contained conceal cchar=η
  syntax match texCmdGreek "\\theta\>"      contained conceal cchar=θ
  syntax match texCmdGreek "\\vartheta\>"   contained conceal cchar=ϑ
  syntax match texCmdGreek "\\iota\>"       contained conceal cchar=ι
  syntax match texCmdGreek "\\kappa\>"      contained conceal cchar=κ
  syntax match texCmdGreek "\\lambda\>"     contained conceal cchar=λ
  syntax match texCmdGreek "\\mu\>"         contained conceal cchar=μ
  syntax match texCmdGreek "\\nu\>"         contained conceal cchar=ν
  syntax match texCmdGreek "\\xi\>"         contained conceal cchar=ξ
  syntax match texCmdGreek "\\pi\>"         contained conceal cchar=π
  syntax match texCmdGreek "\\varpi\>"      contained conceal cchar=ϖ
  syntax match texCmdGreek "\\rho\>"        contained conceal cchar=ρ
  syntax match texCmdGreek "\\varrho\>"     contained conceal cchar=ϱ
  syntax match texCmdGreek "\\sigma\>"      contained conceal cchar=σ
  syntax match texCmdGreek "\\varsigma\>"   contained conceal cchar=ς
  syntax match texCmdGreek "\\tau\>"        contained conceal cchar=τ
  syntax match texCmdGreek "\\upsilon\>"    contained conceal cchar=υ
  syntax match texCmdGreek "\\phi\>"        contained conceal cchar=ϕ
  syntax match texCmdGreek "\\varphi\>"     contained conceal cchar=φ
  syntax match texCmdGreek "\\chi\>"        contained conceal cchar=χ
  syntax match texCmdGreek "\\psi\>"        contained conceal cchar=ψ
  syntax match texCmdGreek "\\omega\>"      contained conceal cchar=ω
  syntax match texCmdGreek "\\Gamma\>"      contained conceal cchar=Γ
  syntax match texCmdGreek "\\Delta\>"      contained conceal cchar=Δ
  syntax match texCmdGreek "\\Theta\>"      contained conceal cchar=Θ
  syntax match texCmdGreek "\\Lambda\>"     contained conceal cchar=Λ
  syntax match texCmdGreek "\\Xi\>"         contained conceal cchar=Ξ
  syntax match texCmdGreek "\\Pi\>"         contained conceal cchar=Π
  syntax match texCmdGreek "\\Sigma\>"      contained conceal cchar=Σ
  syntax match texCmdGreek "\\Upsilon\>"    contained conceal cchar=Υ
  syntax match texCmdGreek "\\Phi\>"        contained conceal cchar=Φ
  syntax match texCmdGreek "\\Chi\>"        contained conceal cchar=Χ
  syntax match texCmdGreek "\\Psi\>"        contained conceal cchar=Ψ
  syntax match texCmdGreek "\\Omega\>"      contained conceal cchar=Ω
endfunction

" }}}1
function! s:match_conceal_super_sub(cfg) " {{{1
  syntax region texSuperscript matchgroup=texDelim start='\^{' skip="\\\\\|\\}" end='}' contained concealends contains=texSpecialChar,texSuperscripts,texCmd,texSubscript,texSuperscript,texMatcherMath
  syntax region texSubscript   matchgroup=texDelim start='_{'  skip="\\\\\|\\}" end='}' contained concealends contains=texSpecialChar,texSubscripts,texCmd,texSubscript,texSuperscript,texMatcherMath

  for [l:from, l:to] in filter(copy(s:map_super),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# '[0-9a-zA-W.,:;+-<>/()=]'})
    execute 'syntax match texSuperscript /\^' . l:from . '/ contained conceal cchar=' . l:to
    execute 'syntax match texSuperscripts /'  . l:from . '/ contained conceal cchar=' . l:to 'nextgroup=texSuperscripts'
  endfor

  for [l:from, l:to] in filter(copy(s:map_sub),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# '[0-9aehijklmnoprstuvx,+-/().]'})
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

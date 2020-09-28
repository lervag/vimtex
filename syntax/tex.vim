" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" This script is a fork of version 119 (dated 2020-06-29) of the syntax script
" "tex.vim" created and maintained by Charles E. Campbell [0].
"
" [0]: http://www.drchip.org/astronaut/vim/index.html#SYNTAX_TEX

" Note:
"   removed  support for
"      "g:tex_no_math"
"      "g:tex_no_error"
"      "g:tex_nospell"
"      "g:tex_fast"
"      syntax folding

" TODO: Migrate options
"   6. Please see  :help latex-syntax  for information on options.

if exists('b:current_syntax') || !get(g:, 'vimtex_syntax_alpha')
  finish
endif
let s:keepcpo= &cpo
set cpo&vim
scriptencoding utf-8

" Let user determine which classes of concealment will be supported
"   a=accents/ligatures
"   d=delimiters
"   m=math symbols
"   g=Greek
"   s=superscripts/subscripts
let s:tex_conceal = get(g:, 'tex_conceal', 'abdmgsS')

let s:tex_superscripts = get(g:, 'tex_superscripts', '[0-9a-zA-W.,:;+-<>/()=]')
let s:tex_subscripts = get(g:, 'tex_subscripts', '[0-9aehijklmnoprstuvx,+-/().]')

" Determine whether or not to use "*.sty" mode
" The user may override the normal determination by setting
"   g:tex_stylish to 1      (for    "*.sty" mode)
"    or to           0 else (normal "*.tex" mode)
" or on a buffer-by-buffer basis with b:tex_stylish
let s:extfname = expand(':e')
let b:tex_stylish = exists('g:tex_stylish')
      \ ? g:tex_stylish
      \ : get(b:, 'tex_stylish',
      \   index(['sty', 'cls', 'clo', 'dtx', 'ltx'], s:extfname) >= 0)

let s:tex_comment_nospell = get(g:, 'tex_comment_nospell')
let s:tex_matchcheck = get(g:, 'tex_matchcheck', '[({[]')
let s:tex_excludematcher = get(g:, 'tex_excludematcher')

" {{{1 (La)TeX keywords

" Sses the characters 0-9,a-z,A-Z,192-255 only...
" But: _ is the only one that causes problems. One may override this iskeyword
" setting by providing g:tex_isk
let b:tex_isk = get(g:, 'tex_isk', '48-57,a-z,A-Z,192-255')
if b:tex_stylish && b:tex_isk !~# '@'
  let b:tex_isk = '@,' . b:tex_isk
endif
execute 'syntax iskeyword' . b:tex_isk

" {{{1 Clusters

syntax cluster texCmdGroup contains=texCmdBody,texComment,texDefParm,texDelimiter,texDocType,texInput,texLength,texLigature,texMathDelim,texMathOper,texNewCmd,texNewEnv,texRefZone,texSection,texBeginEnd,texBeginEndName,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,@texMathZones,texMathError

syntax cluster texEnvGroup contains=texMatcher,texMathDelim,texSpecialChar,texStatement
syntax cluster texZoneGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMatcher,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texBoldStyle,texItalStyle,texEmphStyle,texNoSpell
syntax cluster texBoldGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texBoldStyle,texBoldItalStyle,texNoSpell
syntax cluster texItalGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texItalStyle,texEmphStyle,texItalBoldStyle,texNoSpell
if !s:tex_excludematcher
  syntax cluster texBoldGroup add=texMatcher
  syntax cluster texItalGroup add=texMatcher
endif

syntax cluster texMatchGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMatcher,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,@Spell
syntax cluster texMatchNMGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMatcherNM,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,@Spell
syntax cluster texStyleGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,texStyleStatement,texStyleMatcher,@Spell

syntax cluster texPreambleMatchGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMatcherNM,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTitle,texTypeSize,texTypeStyle,texZone,texInputFile,texOption,texMathZoneZ
syntax cluster texRefGroup contains=texMatcher,texComment,texDelimiter

syntax cluster texPreambleMatchGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMatcherNM,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTitle,texTypeSize,texTypeStyle,texZone,texInputFile,texOption,texMathZoneZ
syntax cluster texMathZones contains=texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ
syntax cluster texMatchGroup add=@texMathZones
syntax cluster texMathDelimGroup contains=texMathDelimBad,texMathDelimKey,texMathDelimSet1,texMathDelimSet2
syntax cluster texMathMatchGroup contains=@texMathZones,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMathDelim,texMathMatcher,texMathOper,texNewCmd,texNewEnv,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,texMathError
syntax cluster texMathZoneGroup contains=texComment,texDelimiter,texLength,texMathDelim,texMathMatcher,texMathOper,texMathSymbol,texMathText,texRefZone,texSpecialChar,texStatement,texTypeSize,texTypeStyle,texMathError
syntax cluster texMathZoneGroup add=@NoSpell

" Following used in the \part \chapter \section \subsection \subsubsection
" \paragraph \subparagraph \author \title highlighting
syntax cluster texDocGroup contains=texPartZone,@texPartGroup
syntax cluster texPartGroup contains=texChapterZone,texSectionZone,texParaZone
syntax cluster texChapterGroup contains=texSectionZone,texParaZone
syntax cluster texSectionGroup contains=texSubSectionZone,texParaZone
syntax cluster texSubSectionGroup contains=texSubSubSectionZone,texParaZone
syntax cluster texSubSubSectionGroup contains=texParaZone
syntax cluster texParaGroup contains=texSubParaZone
if has('conceal') && &enc ==# 'utf-8'
  syntax cluster texMathZoneGroup add=texGreek,texSuperscript,texSubscript,texMathSymbol
  syntax cluster texMathMatchGroup add=texGreek,texSuperscript,texSubscript,texMathSymbol
endif

" {{{1 Try to flag {}, [], and () mismatches

if s:tex_matchcheck =~# '{'
  syntax region texMatcher   matchgroup=Delimiter start="{" skip="\\\\\|\\[{}]" end="}" transparent contains=@texMatchGroup,texError
  syntax region texMatcherNM matchgroup=Delimiter start="{" skip="\\\\\|\\[{}]" end="}" transparent contains=@texMatchNMGroup,texError
endif

if s:tex_matchcheck =~# '\['
  syntax region texMatcher   matchgroup=Delimiter start="\["                    end="]" transparent contains=@texMatchGroup,texError,@NoSpell
  syntax region texMatcherNM matchgroup=Delimiter start="\["                    end="]" transparent contains=@texMatchNMGroup,texError,@NoSpell
endif

if s:tex_matchcheck =~# '('
  syntax region texParen start="(" end=")" transparent contains=@texMatchGroup,@Spell
endif

if s:tex_matchcheck =~# '('
  syntax match texError "[}\]]"
else
  syntax match texError "[}\])]"
endif

syntax match texMathError "}" contained
syntax region texMathMatcher matchgroup=Delimiter start="{" skip="\(\\\\\)*\\}" end="}" end="%stopzone\>" contained contains=@texMathMatchGroup

" {{{1 TeX/LaTeX keywords and delimiters

" Instead of trying to be All Knowing, I just match \..alphameric..
" Note that *.tex files may not have "@" in their \commands

if exists('g:tex_tex') || b:tex_stylish
  syntax match texStatement "\\[a-zA-Z@]\+"
else
  syntax match texStatement "\\\a\+"
  syntax match texError "\\\a*@[a-zA-Z@]*"
endif

syntax match texDelimiter "&"
syntax match texDelimiter "\\\\"

syntax match texOption "[^\\]\zs#\d\+\|^#\d\+"

if b:tex_stylish
  syntax match texAccent "\\[bcdvuH][^a-zA-Z@]"me=e-1
  syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)[^a-zA-Z@]"me=e-1
else
  syntax match texAccent "\\[bcdvuH]\A"me=e-1
  syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)\A"me=e-1
endif
syntax match texAccent "\\[bcdvuH]$"
syntax match texAccent +\\[=^.\~"`']+
syntax match texAccent +\\['=t'.c^ud"vb~Hr]{\a}+
syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)$"

" {{{1 \begin{}/\end{} section markers

syntax match  texBeginEnd "\\begin\>\|\\end\>" nextgroup=texBeginEndName
syntax region texBeginEndName     matchgroup=Delimiter start="{"  end="}" contained nextgroup=texBeginEndModifier   contains=texComment
syntax region texBeginEndModifier matchgroup=Delimiter start="\[" end="]" contained contains=texComment,@texMathZones,@NoSpell

" {{{1 \documentclass, \documentstyle, \usepackage

syntax match texDocType "\\documentclass\>\|\\documentstyle\>\|\\usepackage\>" nextgroup=texBeginEndName,texDocTypeArgs
syntax region texDocTypeArgs matchgroup=Delimiter start="\[" end="]" contained nextgroup=texBeginEndName contains=texComment,@NoSpell

" {{{1 TeX input

syntax match texInput           "\\input\s\+[a-zA-Z/.0-9_^]\+"hs=s+7                      contains=texStatement
syntax match texInputFile       "\\include\(graphics\|list\)\=\(\[.\{-}\]\)\=\s*{.\{-}}"  contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texInputFile       "\\\(epsfig\|input\|usepackage\)\s*\(\[.*\]\)\={.\{-}}"   contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texInputCurlies    "[{}]"                                                    contained
syntax region texInputFileOpt  matchgroup=Delimiter start="\[" end="\]"                   contained       contains=texComment

" {{{1 Type Styles

" LaTeX 2.09:
syntax match texTypeStyle "\\rm\>"
syntax match texTypeStyle "\\em\>"
syntax match texTypeStyle "\\bf\>"
syntax match texTypeStyle "\\it\>"
syntax match texTypeStyle "\\sl\>"
syntax match texTypeStyle "\\sf\>"
syntax match texTypeStyle "\\sc\>"
syntax match texTypeStyle "\\tt\>"

" Attributes, commands, families, etc (LaTeX2E):
if s:tex_conceal !~# 'b'
 syntax match texTypeStyle "\\textbf\>"
 syntax match texTypeStyle "\\textit\>"
 syntax match texTypeStyle "\\emph\>"
endif
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

" {{{1 Type sizes

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

" {{{1 Spacecodes (TeX'isms):

" \mathcode`\^^@ = "2201
" \delcode`\( = "028300
" \sfcode`\) = 0
" \uccode`X = `X
" \lccode`x = `x

syntax match texSpaceCode /\\\(math\|cat\|del\|lc\|sf\|uc\)code`/me=e-1 nextgroup=texSpaceCodeChar
syntax match texSpaceCodeChar "`\\\=.\(\^.\)\==\(\d\|\"\x\{1,6}\|`.\)"  contained

" {{{1 Sections, subsections, etc

syntax region texDocZone matchgroup=texSection start='\\begin\s*{\s*document\s*}' end='\\end\s*{\s*document\s*}' contains=@texZoneGroup,@texDocGroup,@Spell
syntax region texPartZone matchgroup=texSection start='\\part\>' end='\ze\s*\\\%(part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texPartGroup,@Spell
syntax region texChapterZone matchgroup=texSection start='\\chapter\>' end='\ze\s*\\\%(chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texChapterGroup,@Spell
syntax region texSectionZone matchgroup=texSection start='\\section\>' end='\ze\s*\\\%(section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSectionGroup,@Spell
syntax region texSubSectionZone matchgroup=texSection start='\\subsection\>' end='\ze\s*\\\%(\%(sub\)\=section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSubSectionGroup,@Spell
syntax region texSubSubSectionZone matchgroup=texSection start='\\subsubsection\>' end='\ze\s*\\\%(\%(sub\)\{,2}section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSubSubSectionGroup,@Spell
syntax region texParaZone matchgroup=texSection start='\\paragraph\>' end='\ze\s*\\\%(paragraph\>\|\%(sub\)*section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texParaGroup,@Spell
syntax region texSubParaZone matchgroup=texSection start='\\subparagraph\>' end='\ze\s*\\\%(\%(sub\)\=paragraph\>\|\%(sub\)*section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@Spell
syntax region texTitle matchgroup=texSection start='\\\%(author\|title\)\>\s*{' end='}' contains=@texZoneGroup,@Spell
syntax region texAbstract matchgroup=texSection start='\\begin\s*{\s*abstract\s*}' end='\\end\s*{\s*abstract\s*}' contains=@texZoneGroup,@Spell

" {{{1 Bold and italic

if s:tex_conceal =~# 'b'
  syntax region texBoldStyle     matchgroup=texTypeStyle start="\\textbf\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
  syntax region texBoldItalStyle matchgroup=texTypeStyle start="\\textit\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
  syntax region texItalStyle     matchgroup=texTypeStyle start="\\textit\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
  syntax region texItalBoldStyle matchgroup=texTypeStyle start="\\textbf\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
  syntax region texEmphStyle     matchgroup=texTypeStyle start="\\emph\s*{"   matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
  syntax region texEmphStyle     matchgroup=texTypeStyle start="\\texts[cfl]\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
  syntax region texEmphStyle     matchgroup=texTypeStyle start="\\textup\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
  syntax region texEmphStyle     matchgroup=texTypeStyle start="\\texttt\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
endif

" {{{1 Bad/Mismatched math

syntax match texBadMath "\\end\s*{\s*\(array\|[bBpvV]matrix\|split\|smallmatrix\)\s*}"
syntax match texBadMath "\\end\s*{\s*\(displaymath\|equation\|eqnarray\|math\)\*\=\s*}"
syntax match texBadMath "\\[\])]"

" {{{1 Math Zones

function! TexNewMathZone(sfx,mathzone,starform) abort " {{{2
  " Creates a mathzone with the given suffix and mathzone name. Starred forms
  " are created if starform is true.  Starred forms have syntax group and
  " synchronization groups with a "S" appended.  Handles: cluster, syntax,
  " sync, and highlighting.
  let grpname = 'texMathZone' . a:sfx
  let syncname = 'texSyncMathZone' . a:sfx
  execute 'syntax cluster texMathZones add=' . grpname
  execute 'syntax region ' . grpname . " start='" . '\\begin\s*{\s*' . a:mathzone . '\s*}''' . " end='" . '\\end\s*{\s*' . a:mathzone . '\s*}''' . ' keepend contains=@texMathZoneGroup'
  execute 'syntax sync match ' . syncname . ' grouphere ' . grpname . ' "\\begin\s*{\s*' . a:mathzone . '\*\s*}"'
  execute 'syntax sync match ' . syncname . ' grouphere ' . grpname . ' "\\begin\s*{\s*' . a:mathzone . '\*\s*}"'
  execute 'highlight def link ' . grpname . ' texMath'

  if !a:starform | return | endif

  let grpname  = 'texMathZone' . a:sfx . 'S'
  let syncname = 'texSyncMathZone' . a:sfx . 'S'
  execute 'syntax cluster texMathZones add=' . grpname
  execute 'syntax region ' . grpname . " start='" . '\\begin\s*{\s*' . a:mathzone . '\*\s*}''' . " end='" . '\\end\s*{\s*' . a:mathzone . '\*\s*}''' . ' keepend contains=@texMathZoneGroup'
  execute 'syntax sync match ' . syncname . ' grouphere ' . grpname . ' "\\begin\s*{\s*' . a:mathzone . '\*\s*}"'
  execute 'syntax sync match ' . syncname . ' grouphere ' . grpname . ' "\\begin\s*{\s*' . a:mathzone . '\*\s*}"'
  execute 'highlight def link ' . grpname . ' texMath'
endfunction

" }}}2

call TexNewMathZone('A', 'displaymath', 1)
call TexNewMathZone('B', 'eqnarray', 1)
call TexNewMathZone('C', 'equation', 1)
call TexNewMathZone('D', 'math', 1)

" {{{2 Inline Math Zones

if has('conceal') && &enc ==# 'utf-8' && s:tex_conceal =~# 'd'
  syntax region texMathZoneV matchgroup=Delimiter start="\\("                      matchgroup=Delimiter end="\\)\|%stopzone\>"             keepend concealends contains=@texMathZoneGroup
  syntax region texMathZoneW matchgroup=Delimiter start="\\\["                     matchgroup=Delimiter end="\\]\|%stopzone\>"             keepend concealends contains=@texMathZoneGroup
  syntax region texMathZoneX matchgroup=Delimiter start="\$" skip="\\\\\|\\\$"     matchgroup=Delimiter end="\$"        end="%stopzone\>"          concealends contains=@texMathZoneGroup
  syntax region texMathZoneY matchgroup=Delimiter start="\$\$"                     matchgroup=Delimiter end="\$\$"      end="%stopzone\>"  keepend concealends contains=@texMathZoneGroup
else
  syntax region texMathZoneV matchgroup=Delimiter start="\\("                      matchgroup=Delimiter end="\\)\|%stopzone\>"             keepend contains=@texMathZoneGroup
  syntax region texMathZoneW matchgroup=Delimiter start="\\\["                     matchgroup=Delimiter end="\\]\|%stopzone\>"             keepend contains=@texMathZoneGroup
  syntax region texMathZoneX matchgroup=Delimiter start="\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$"        end="%stopzone\>"          contains=@texMathZoneGroup
  syntax region texMathZoneY matchgroup=Delimiter start="\$\$"                     matchgroup=Delimiter end="\$\$"      end="%stopzone\>"  keepend contains=@texMathZoneGroup
endif
syntax region texMathZoneZ matchgroup=texStatement start="\\ensuremath\s*{" matchgroup=texStatement end="}" end="%stopzone\>" contains=@texMathZoneGroup

syntax match texMathOper "[_^=]" contained

" {{{2 Text Inside Math Zones

syntax region texMathText matchgroup=texStatement start='\\\(\(inter\)\=text\|mbox\)\s*{' end='}' contains=@texZoneGroup,@Spell

" {{{2 \left..something.. and \right..something.. support

syntax match texMathDelimBad contained "\S"
if !has('conceal') || &enc !=# 'utf-8' || s:tex_conceal !~# 'm'
  syntax match   texMathDelim      contained "\\\(left\|right\)\>"   skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad
  syntax match   texMathDelim      contained "\\[bB]igg\=[lr]\=\>"   skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad
  syntax match   texMathDelimSet2  contained "\\"            nextgroup=texMathDelimKey,texMathDelimBad
  syntax match   texMathDelimSet1  contained "[<>()[\]|/.]\|\\[{}|]"
  syntax keyword texMathDelimKey   contained backslash lceil      lVert    rgroup      uparrow
  syntax keyword texMathDelimKey   contained downarrow lfloor     rangle   rmoustache  Uparrow
  syntax keyword texMathDelimKey   contained Downarrow lgroup     rbrace   rvert       updownarrow
  syntax keyword texMathDelimKey   contained langle    lmoustache rceil    rVert       Updownarrow
  syntax keyword texMathDelimKey   contained lbrace    lvert      rfloor
else
  syntax match texMathDelim contained "\\left\["
  syntax match texMathDelim contained "\\left\\{"  skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad contains=texMathSymbol cchar={
  syntax match texMathDelim contained "\\right\\}" skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad contains=texMathSymbol cchar=}
  let s:texMathDelimList = [
        \ ['<',             '<'],
        \ ['>',             '>'],
        \ ['(',             '('],
        \ [')',             ')'],
        \ ['\[',            '['],
        \ [']',             ']'],
        \ ['\\{',           '{'],
        \ ['\\}',           '}'],
        \ ['|',             '|'],
        \ ['\\|',           '‖'],
        \ ['\\backslash',   '\'],
        \ ['\\downarrow',   '↓'],
        \ ['\\Downarrow',   '⇓'],
        \ ['\\lbrace',      '['],
        \ ['\\lceil',       '⌈'],
        \ ['\\lfloor',      '⌊'],
        \ ['\\lgroup',      '⌊'],
        \ ['\\lmoustache',  '⎛'],
        \ ['\\rbrace',      ']'],
        \ ['\\rceil',       '⌉'],
        \ ['\\rfloor',      '⌋'],
        \ ['\\rgroup',      '⌋'],
        \ ['\\rmoustache',  '⎞'],
        \ ['\\uparrow',     '↑'],
        \ ['\\Uparrow',     '↑'],
        \ ['\\updownarrow', '↕'],
        \ ['\\Updownarrow', '⇕']]
  if &ambw ==# 'double' || exists('g:tex_usedblwidth')
    let s:texMathDelimList += [
          \ ['\\langle', '〈'] ,
          \ ['\\rangle', '〉']]
  else
    let s:texMathDelimList += [
          \ ['\\langle', '<'] ,
          \ ['\\rangle', '>']]
  endif
  syntax match texMathDelim '\\[bB]igg\=[lr]' contained nextgroup=texMathDelimBad
  for texmath in s:texMathDelimList
    execute "syntax match texMathDelim  '\\\\[bB]igg\\=[lr]\\=" . texmath[0] . "'   contained conceal cchar=" . texmath[1]
  endfor
endif
syntax match texMathDelim contained "\\\(left\|right\)arrow\>\|\<\([aA]rrow\|brace\)\=vert\>"
syntax match texMathDelim contained "\\lefteqn\>"

" {{{1 Special TeX characters

" E.g.:  \$ \& \% \# \{ \} \_ \S \P

syntax match texSpecialChar "\\[$&%#{}_]"
if b:tex_stylish
  syntax match texSpecialChar "\\[SP@][^a-zA-Z@]"me=e-1
else
  syntax match texSpecialChar "\\[SP@]\A"me=e-1
endif
syntax match texSpecialChar "\\\\"
syntax match texOnlyMath "[_^]"
syntax match texSpecialChar "\^\^[0-9a-f]\{2}\|\^\^\S"
if s:tex_conceal !~# 'S'
  syntax match texSpecialChar '\\glq\>' contained conceal cchar=‚
  syntax match texSpecialChar '\\grq\>' contained conceal cchar=‘
  syntax match texSpecialChar '\\glqq\>' contained conceal cchar=„
  syntax match texSpecialChar '\\grqq\>' contained conceal cchar=“
  syntax match texSpecialChar '\\hyp\>' contained conceal cchar=-
endif

" {{{1 Comments

" Normal TeX LaTeX: %....
" Documented TeX Format: ^^A... -and- leading %s (only)

if s:tex_comment_nospell
  syntax cluster texCommentGroup contains=texTodo,@NoSpell
else
  syntax cluster texCommentGroup contains=texTodo,@Spell
endif
syntax case ignore
syntax keyword texTodo contained combak fixme todo xxx
syntax case match
if s:extfname ==# 'dtx'
  syntax match texComment "\^\^A.*$" contains=@texCommentGroup
  syntax match texComment "^%\+"     contains=@texCommentGroup
else
  syntax match texComment "%.*$" contains=@texCommentGroup
  syntax region texNoSpell contained matchgroup=texComment start="%\s*nospell\s*{" end="%\s*nospell\s*}" contains=@texZoneGroup,@NoSpell
endif

" %begin-include ... %end-include acts like a texDocZone for \include'd files.  Permits spell checking, for example, in such files.
syntax region texDocZone matchgroup=texSection start='^\s*%begin-include\>' end='^\s*%end-include\>' contains=@texZoneGroup,@texDocGroup,@Spell

" {{{1 Verbatim

" Separate lines used for verb` and verb# so that the end conditions will
" appropriately terminate.

" If g:tex_verbspell exists, then verbatim texZones will permit spellchecking there.

if get(g:, 'tex_verbspell')
  syntax   region texZone start="\\begin{[vV]erbatim}"        end="\\end{[vV]erbatim}\|%stopzone\>" contains=@Spell
  if b:tex_stylish
    syntax region texZone start="\\verb\*\=\z([^\ta-zA-Z@]\)" end="\z1\|%stopzone\>"                contains=@Spell
  else
    syntax region texZone start="\\verb\*\=\z([^\ta-zA-Z]\)"  end="\z1\|%stopzone\>"                contains=@Spell
  endif
else
  syntax   region texZone start="\\begin{[vV]erbatim}"        end="\\end{[vV]erbatim}\|%stopzone\>"
  if b:tex_stylish
    syntax region texZone start="\\verb\*\=\z([^\ta-zA-Z@]\)" end="\z1\|%stopzone\>"
  else
    syntax region texZone start="\\verb\*\=\z([^\ta-zA-Z]\)"  end="\z1\|%stopzone\>"
  endif
endif

" {{{1 Tex Reference Zones

syntax region texZone      matchgroup=texStatement start="@samp{"             end="}\|%stopzone\>"  contains=@texRefGroup
syntax region texRefZone   matchgroup=texStatement start="\\nocite{"          end="}\|%stopzone\>"  contains=@texRefGroup
syntax region texRefZone   matchgroup=texStatement start="\\bibliography{"    end="}\|%stopzone\>"  contains=@texRefGroup
syntax region texRefZone   matchgroup=texStatement start="\\label{"           end="}\|%stopzone\>"  contains=@texRefGroup
syntax region texRefZone   matchgroup=texStatement start="\\\(page\|eq\)ref{" end="}\|%stopzone\>"  contains=@texRefGroup
syntax region texRefZone   matchgroup=texStatement start="\\v\=ref{"          end="}\|%stopzone\>"  contains=@texRefGroup
syntax region texRefOption contained matchgroup=Delimiter start='\[' end=']' contains=@texRefGroup,texRefZone        nextgroup=texRefOption,texCite
syntax region texCite      contained matchgroup=Delimiter start='{' end='}'  contains=@texRefGroup,texRefZone,texCite
syntax match  texRefZone '\\cite\%([tp]\*\=\)\=\>' nextgroup=texRefOption,texCite

" {{{1 Handle new(command|environment)

syntax match  texNewCmd "\\newcommand\>" nextgroup=texCmdName skipwhite skipnl
syntax region texCmdName contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texCmdArgs,texCmdBody skipwhite skipnl
syntax region texCmdArgs contained matchgroup=Delimiter start="\["rs=s+1 end="]" nextgroup=texCmdBody skipwhite skipnl
syntax region texCmdBody contained matchgroup=Delimiter start="{"rs=s+1 skip="\\\\\|\\[{}]" matchgroup=Delimiter end="}" contains=@texCmdGroup
syntax match texNewEnv "\\newenvironment\>" nextgroup=texEnvName skipwhite skipnl
syntax region texEnvName contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texEnvBgn skipwhite skipnl
syntax region texEnvBgn contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texEnvEnd skipwhite skipnl contains=@texEnvGroup
syntax region texEnvEnd contained matchgroup=Delimiter start="{"rs=s+1 end="}" skipwhite skipnl contains=@texEnvGroup

" {{{1 Definitions/Commands

syntax match texDefCmd              "\\def\>"       nextgroup=texDefName skipwhite skipnl
if b:tex_stylish
  syntax match texDefName contained "\\[a-zA-Z@]\+" nextgroup=texDefParms,texCmdBody skipwhite skipnl
  syntax match texDefName contained "\\[^a-zA-Z@]"  nextgroup=texDefParms,texCmdBody skipwhite skipnl
else
  syntax match texDefName contained "\\\a\+"        nextgroup=texDefParms,texCmdBody skipwhite skipnl
  syntax match texDefName contained "\\\A"          nextgroup=texDefParms,texCmdBody skipwhite skipnl
endif
syntax match texDefParms  contained "#[^{]*"        contains=texDefParm nextgroup=texCmdBody skipwhite skipnl
syntax match  texDefParm  contained "#\d\+"

" {{{1 TeX Lengths

syntax match texLength "\<\d\+\([.,]\d\+\)\=\s*\(true\)\=\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

" {{{1 TeX String Delimiters

syntax match texString "\(``\|''\|,,\)"

" makeatletter -- makeatother sections
syntax region texStyle matchgroup=texStatement start='\\makeatletter' end='\\makeatother' contains=@texStyleGroup contained
syntax match texStyleStatement "\\[a-zA-Z@]\+" contained
syntax region texStyleMatcher matchgroup=Delimiter start="{" skip="\\\\\|\\[{}]" end="}" contains=@texStyleGroup,texError contained
syntax region texStyleMatcher matchgroup=Delimiter start="\[" end="]" contains=@texStyleGroup,texError contained

" {{{1 Conceal mode support

" Add support for conceal with custom replacement (conceallevel = 2)

if has('conceal') && &enc ==# 'utf-8'

  " {{{2 Math Symbols
  " (many of these symbols were contributed by Björn Winckler)
  if s:tex_conceal =~# 'm'
    let s:texMathList = [
          \ ['|'              , '‖'],
          \ ['aleph'          , 'ℵ'],
          \ ['amalg'          , '∐'],
          \ ['angle'          , '∠'],
          \ ['approx'         , '≈'],
          \ ['ast'            , '∗'],
          \ ['asymp'          , '≍'],
          \ ['backslash'      , '∖'],
          \ ['bigcap'         , '∩'],
          \ ['bigcirc'        , '○'],
          \ ['bigcup'         , '∪'],
          \ ['bigodot'        , '⊙'],
          \ ['bigoplus'       , '⊕'],
          \ ['bigotimes'      , '⊗'],
          \ ['bigsqcup'       , '⊔'],
          \ ['bigtriangledown', '∇'],
          \ ['bigtriangleup'  , '∆'],
          \ ['bigvee'         , '⋁'],
          \ ['bigwedge'       , '⋀'],
          \ ['bot'            , '⊥'],
          \ ['bowtie'         , '⋈'],
          \ ['bullet'         , '•'],
          \ ['cap'            , '∩'],
          \ ['cdot'           , '·'],
          \ ['cdots'          , '⋯'],
          \ ['circ'           , '∘'],
          \ ['clubsuit'       , '♣'],
          \ ['cong'           , '≅'],
          \ ['coprod'         , '∐'],
          \ ['copyright'      , '©'],
          \ ['cup'            , '∪'],
          \ ['dagger'         , '†'],
          \ ['dashv'          , '⊣'],
          \ ['ddagger'        , '‡'],
          \ ['ddots'          , '⋱'],
          \ ['diamond'        , '⋄'],
          \ ['diamondsuit'    , '♢'],
          \ ['div'            , '÷'],
          \ ['doteq'          , '≐'],
          \ ['dots'           , '…'],
          \ ['downarrow'      , '↓'],
          \ ['Downarrow'      , '⇓'],
          \ ['ell'            , 'ℓ'],
          \ ['emptyset'       , '∅'],
          \ ['equiv'          , '≡'],
          \ ['exists'         , '∃'],
          \ ['flat'           , '♭'],
          \ ['forall'         , '∀'],
          \ ['frown'          , '⁔'],
          \ ['ge'             , '≥'],
          \ ['geq'            , '≥'],
          \ ['gets'           , '←'],
          \ ['gg'             , '⟫'],
          \ ['hbar'           , 'ℏ'],
          \ ['heartsuit'      , '♡'],
          \ ['hookleftarrow'  , '↩'],
          \ ['hookrightarrow' , '↪'],
          \ ['iff'            , '⇔'],
          \ ['Im'             , 'ℑ'],
          \ ['imath'          , 'ɩ'],
          \ ['in'             , '∈'],
          \ ['infty'          , '∞'],
          \ ['int'            , '∫'],
          \ ['jmath'          , '𝚥'],
          \ ['land'           , '∧'],
          \ ['lceil'          , '⌈'],
          \ ['ldots'          , '…'],
          \ ['le'             , '≤'],
          \ ['left|'          , '|'],
          \ ['left\\|'        , '‖'],
          \ ['left('          , '('],
          \ ['left\['         , '['],
          \ ['left\\{'        , '{'],
          \ ['leftarrow'      , '←'],
          \ ['Leftarrow'      , '⇐'],
          \ ['leftharpoondown', '↽'],
          \ ['leftharpoonup'  , '↼'],
          \ ['leftrightarrow' , '↔'],
          \ ['Leftrightarrow' , '⇔'],
          \ ['leq'            , '≤'],
          \ ['leq'            , '≤'],
          \ ['lfloor'         , '⌊'],
          \ ['ll'             , '≪'],
          \ ['lmoustache'     , '╭'],
          \ ['lor'            , '∨'],
          \ ['mapsto'         , '↦'],
          \ ['mid'            , '∣'],
          \ ['models'         , '╞'],
          \ ['mp'             , '∓'],
          \ ['nabla'          , '∇'],
          \ ['natural'        , '♮'],
          \ ['ne'             , '≠'],
          \ ['nearrow'        , '↗'],
          \ ['neg'            , '¬'],
          \ ['neq'            , '≠'],
          \ ['ni'             , '∋'],
          \ ['notin'          , '∉'],
          \ ['nwarrow'        , '↖'],
          \ ['odot'           , '⊙'],
          \ ['oint'           , '∮'],
          \ ['ominus'         , '⊖'],
          \ ['oplus'          , '⊕'],
          \ ['oslash'         , '⊘'],
          \ ['otimes'         , '⊗'],
          \ ['owns'           , '∋'],
          \ ['P'              , '¶'],
          \ ['parallel'       , '║'],
          \ ['partial'        , '∂'],
          \ ['perp'           , '⊥'],
          \ ['pm'             , '±'],
          \ ['prec'           , '≺'],
          \ ['preceq'         , '⪯'],
          \ ['prime'          , '′'],
          \ ['prod'           , '∏'],
          \ ['propto'         , '∝'],
          \ ['rceil'          , '⌉'],
          \ ['Re'             , 'ℜ'],
          \ ['quad'           , ' '],
          \ ['qquad'          , ' '],
          \ ['rfloor'         , '⌋'],
          \ ['right|'         , '|'],
          \ ['right\\|'       , '‖'],
          \ ['right)'         , ')'],
          \ ['right]'         , ']'],
          \ ['right\\}'       , '}'],
          \ ['rightarrow'     , '→'],
          \ ['Rightarrow'     , '⇒'],
          \ ['rightleftharpoons', '⇌'],
          \ ['rmoustache'     , '╮'],
          \ ['S'              , '§'],
          \ ['searrow'        , '↘'],
          \ ['setminus'       , '∖'],
          \ ['sharp'          , '♯'],
          \ ['sim'            , '∼'],
          \ ['simeq'          , '⋍'],
          \ ['smile'          , '‿'],
          \ ['spadesuit'      , '♠'],
          \ ['sqcap'          , '⊓'],
          \ ['sqcup'          , '⊔'],
          \ ['sqsubset'       , '⊏'],
          \ ['sqsubseteq'     , '⊑'],
          \ ['sqsupset'       , '⊐'],
          \ ['sqsupseteq'     , '⊒'],
          \ ['star'           , '✫'],
          \ ['subset'         , '⊂'],
          \ ['subseteq'       , '⊆'],
          \ ['succ'           , '≻'],
          \ ['succeq'         , '⪰'],
          \ ['sum'            , '∑'],
          \ ['supset'         , '⊃'],
          \ ['supseteq'       , '⊇'],
          \ ['surd'           , '√'],
          \ ['swarrow'        , '↙'],
          \ ['times'          , '×'],
          \ ['to'             , '→'],
          \ ['top'            , '⊤'],
          \ ['triangle'       , '∆'],
          \ ['triangleleft'   , '⊲'],
          \ ['triangleright'  , '⊳'],
          \ ['uparrow'        , '↑'],
          \ ['Uparrow'        , '⇑'],
          \ ['updownarrow'    , '↕'],
          \ ['Updownarrow'    , '⇕'],
          \ ['vdash'          , '⊢'],
          \ ['vdots'          , '⋮'],
          \ ['vee'            , '∨'],
          \ ['wedge'          , '∧'],
          \ ['wp'             , '℘'],
          \ ['wr'             , '≀']]
    if &ambw ==# 'double' || exists('g:tex_usedblwidth')
      let s:texMathList += [
            \ ['right\\rangle', '〉'],
            \ ['left\\langle', '〈']]
    else
      let s:texMathList += [
            \ ['right\\rangle', '>'],
            \ ['left\\langle', '<']]
    endif
    for texmath in s:texMathList
      if texmath[0] =~# '\w$'
        exe "syn match texMathSymbol '\\\\".texmath[0]."\\>' contained conceal cchar=".texmath[1]
      else
        exe "syn match texMathSymbol '\\\\".texmath[0]."' contained conceal cchar=".texmath[1]
      endif
    endfor

    if &ambw ==# 'double'
      syntax match texMathSymbol '\\gg\>' contained conceal cchar=≫
      syntax match texMathSymbol '\\ll\>' contained conceal cchar=≪
    else
      syntax match texMathSymbol '\\gg\>' contained conceal cchar=⟫
      syntax match texMathSymbol '\\ll\>' contained conceal cchar=⟪
    endif

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
    "  syn match texMathSymbol '\\bar{a}' contained conceal cchar=a̅

    syntax match texMathSymbol '\\dot{B}' contained conceal cchar=Ḃ
    syntax match texMathSymbol '\\dot{b}' contained conceal cchar=ḃ
    syntax match texMathSymbol '\\dot{D}' contained conceal cchar=Ḋ
    syntax match texMathSymbol '\\dot{d}' contained conceal cchar=ḋ
    syntax match texMathSymbol '\\dot{F}' contained conceal cchar=Ḟ
    syntax match texMathSymbol '\\dot{f}' contained conceal cchar=ḟ
    syntax match texMathSymbol '\\dot{H}' contained conceal cchar=Ḣ
    syntax match texMathSymbol '\\dot{h}' contained conceal cchar=ḣ
    syntax match texMathSymbol '\\dot{M}' contained conceal cchar=Ṁ
    syntax match texMathSymbol '\\dot{m}' contained conceal cchar=ṁ
    syntax match texMathSymbol '\\dot{N}' contained conceal cchar=Ṅ
    syntax match texMathSymbol '\\dot{n}' contained conceal cchar=ṅ
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

    syntax match texMathSymbol '\\dot{C}' contained conceal cchar=Ċ
    syntax match texMathSymbol '\\dot{c}' contained conceal cchar=ċ
    syntax match texMathSymbol '\\dot{E}' contained conceal cchar=Ė
    syntax match texMathSymbol '\\dot{e}' contained conceal cchar=ė
    syntax match texMathSymbol '\\dot{G}' contained conceal cchar=Ġ
    syntax match texMathSymbol '\\dot{g}' contained conceal cchar=ġ
    syntax match texMathSymbol '\\dot{I}' contained conceal cchar=İ

    syntax match texMathSymbol '\\dot{A}' contained conceal cchar=Ȧ
    syntax match texMathSymbol '\\dot{a}' contained conceal cchar=ȧ
    syntax match texMathSymbol '\\dot{O}' contained conceal cchar=Ȯ
    syntax match texMathSymbol '\\dot{o}' contained conceal cchar=ȯ
  endif

  " {{{2 Greek
  if s:tex_conceal =~# 'g'
    function! s:Greek(group, pat, cchar)
      execute 'syntax match ' . a:group . " '" . a:pat . "' contained conceal cchar=" . a:cchar
    endfunction
    call s:Greek('texGreek', '\\alpha\>'           ,'α')
    call s:Greek('texGreek', '\\beta\>'            ,'β')
    call s:Greek('texGreek', '\\gamma\>'           ,'γ')
    call s:Greek('texGreek', '\\delta\>'           ,'δ')
    call s:Greek('texGreek', '\\epsilon\>'         ,'ϵ')
    call s:Greek('texGreek', '\\varepsilon\>'      ,'ε')
    call s:Greek('texGreek', '\\zeta\>'            ,'ζ')
    call s:Greek('texGreek', '\\eta\>'             ,'η')
    call s:Greek('texGreek', '\\theta\>'           ,'θ')
    call s:Greek('texGreek', '\\vartheta\>'        ,'ϑ')
    call s:Greek('texGreek', '\\iota\>'            ,'ι')
    call s:Greek('texGreek', '\\kappa\>'           ,'κ')
    call s:Greek('texGreek', '\\lambda\>'          ,'λ')
    call s:Greek('texGreek', '\\mu\>'              ,'μ')
    call s:Greek('texGreek', '\\nu\>'              ,'ν')
    call s:Greek('texGreek', '\\xi\>'              ,'ξ')
    call s:Greek('texGreek', '\\pi\>'              ,'π')
    call s:Greek('texGreek', '\\varpi\>'           ,'ϖ')
    call s:Greek('texGreek', '\\rho\>'             ,'ρ')
    call s:Greek('texGreek', '\\varrho\>'          ,'ϱ')
    call s:Greek('texGreek', '\\sigma\>'           ,'σ')
    call s:Greek('texGreek', '\\varsigma\>'        ,'ς')
    call s:Greek('texGreek', '\\tau\>'             ,'τ')
    call s:Greek('texGreek', '\\upsilon\>'         ,'υ')
    call s:Greek('texGreek', '\\phi\>'             ,'ϕ')
    call s:Greek('texGreek', '\\varphi\>'          ,'φ')
    call s:Greek('texGreek', '\\chi\>'             ,'χ')
    call s:Greek('texGreek', '\\psi\>'             ,'ψ')
    call s:Greek('texGreek', '\\omega\>'           ,'ω')
    call s:Greek('texGreek', '\\Gamma\>'           ,'Γ')
    call s:Greek('texGreek', '\\Delta\>'           ,'Δ')
    call s:Greek('texGreek', '\\Theta\>'           ,'Θ')
    call s:Greek('texGreek', '\\Lambda\>'          ,'Λ')
    call s:Greek('texGreek', '\\Xi\>'              ,'Ξ')
    call s:Greek('texGreek', '\\Pi\>'              ,'Π')
    call s:Greek('texGreek', '\\Sigma\>'           ,'Σ')
    call s:Greek('texGreek', '\\Upsilon\>'         ,'Υ')
    call s:Greek('texGreek', '\\Phi\>'             ,'Φ')
    call s:Greek('texGreek', '\\Chi\>'             ,'Χ')
    call s:Greek('texGreek', '\\Psi\>'             ,'Ψ')
    call s:Greek('texGreek', '\\Omega\>'           ,'Ω')
    delfunction s:Greek
  endif

  " {{{2 Superscripts/Subscripts
  if s:tex_conceal =~# 's'
    syntax region texSuperscript    matchgroup=Delimiter start='\^{'        skip="\\\\\|\\[{}]" end='}'     contained concealends contains=texSpecialChar,texSuperscripts,texStatement,texSubscript,texSuperscript,texMathMatcher
    syntax region texSubscript      matchgroup=Delimiter start='_{'         skip="\\\\\|\\[{}]" end='}'     contained concealends contains=texSpecialChar,texSubscripts,texStatement,texSubscript,texSuperscript,texMathMatcher

    function! s:SuperSub(group, leader, pat, cchar)
      if a:pat =~# '^\\'
            \ || (a:leader ==# '\^' && a:pat =~# s:tex_superscripts)
            \ || (a:leader ==# '_' && a:pat =~# s:tex_subscripts)
        execute 'syntax match ' . a:group . " '" . a:leader . a:pat . "' contained conceal cchar=" . a:cchar
        execute 'syntax match ' . a:group . "s '" . a:pat         . "' contained conceal cchar=" . a:cchar . ' nextgroup=' . a:group . 's'
      endif
    endfunction
    call s:SuperSub('texSuperscript', '\^', '0', '⁰')
    call s:SuperSub('texSuperscript', '\^', '1', '¹')
    call s:SuperSub('texSuperscript', '\^', '2', '²')
    call s:SuperSub('texSuperscript', '\^', '3', '³')
    call s:SuperSub('texSuperscript', '\^', '4', '⁴')
    call s:SuperSub('texSuperscript', '\^', '5', '⁵')
    call s:SuperSub('texSuperscript', '\^', '6', '⁶')
    call s:SuperSub('texSuperscript', '\^', '7', '⁷')
    call s:SuperSub('texSuperscript', '\^', '8', '⁸')
    call s:SuperSub('texSuperscript', '\^', '9', '⁹')
    call s:SuperSub('texSuperscript', '\^', 'a', 'ᵃ')
    call s:SuperSub('texSuperscript', '\^', 'b', 'ᵇ')
    call s:SuperSub('texSuperscript', '\^', 'c', 'ᶜ')
    call s:SuperSub('texSuperscript', '\^', 'd', 'ᵈ')
    call s:SuperSub('texSuperscript', '\^', 'e', 'ᵉ')
    call s:SuperSub('texSuperscript', '\^', 'f', 'ᶠ')
    call s:SuperSub('texSuperscript', '\^', 'g', 'ᵍ')
    call s:SuperSub('texSuperscript', '\^', 'h', 'ʰ')
    call s:SuperSub('texSuperscript', '\^', 'i', 'ⁱ')
    call s:SuperSub('texSuperscript', '\^', 'j', 'ʲ')
    call s:SuperSub('texSuperscript', '\^', 'k', 'ᵏ')
    call s:SuperSub('texSuperscript', '\^', 'l', 'ˡ')
    call s:SuperSub('texSuperscript', '\^', 'm', 'ᵐ')
    call s:SuperSub('texSuperscript', '\^', 'n', 'ⁿ')
    call s:SuperSub('texSuperscript', '\^', 'o', 'ᵒ')
    call s:SuperSub('texSuperscript', '\^', 'p', 'ᵖ')
    call s:SuperSub('texSuperscript', '\^', 'r', 'ʳ')
    call s:SuperSub('texSuperscript', '\^', 's', 'ˢ')
    call s:SuperSub('texSuperscript', '\^', 't', 'ᵗ')
    call s:SuperSub('texSuperscript', '\^', 'u', 'ᵘ')
    call s:SuperSub('texSuperscript', '\^', 'v', 'ᵛ')
    call s:SuperSub('texSuperscript', '\^', 'w', 'ʷ')
    call s:SuperSub('texSuperscript', '\^', 'x', 'ˣ')
    call s:SuperSub('texSuperscript', '\^', 'y', 'ʸ')
    call s:SuperSub('texSuperscript', '\^', 'z', 'ᶻ')
    call s:SuperSub('texSuperscript', '\^', 'A', 'ᴬ')
    call s:SuperSub('texSuperscript', '\^', 'B', 'ᴮ')
    call s:SuperSub('texSuperscript', '\^', 'D', 'ᴰ')
    call s:SuperSub('texSuperscript', '\^', 'E', 'ᴱ')
    call s:SuperSub('texSuperscript', '\^', 'G', 'ᴳ')
    call s:SuperSub('texSuperscript', '\^', 'H', 'ᴴ')
    call s:SuperSub('texSuperscript', '\^', 'I', 'ᴵ')
    call s:SuperSub('texSuperscript', '\^', 'J', 'ᴶ')
    call s:SuperSub('texSuperscript', '\^', 'K', 'ᴷ')
    call s:SuperSub('texSuperscript', '\^', 'L', 'ᴸ')
    call s:SuperSub('texSuperscript', '\^', 'M', 'ᴹ')
    call s:SuperSub('texSuperscript', '\^', 'N', 'ᴺ')
    call s:SuperSub('texSuperscript', '\^', 'O', 'ᴼ')
    call s:SuperSub('texSuperscript', '\^', 'P', 'ᴾ')
    call s:SuperSub('texSuperscript', '\^', 'R', 'ᴿ')
    call s:SuperSub('texSuperscript', '\^', 'T', 'ᵀ')
    call s:SuperSub('texSuperscript', '\^', 'U', 'ᵁ')
    call s:SuperSub('texSuperscript', '\^', 'V', 'ⱽ')
    call s:SuperSub('texSuperscript', '\^', 'W', 'ᵂ')
    call s:SuperSub('texSuperscript', '\^', ',', '︐')
    call s:SuperSub('texSuperscript', '\^', ':', '︓')
    call s:SuperSub('texSuperscript', '\^', ';', '︔')
    call s:SuperSub('texSuperscript', '\^', '+', '⁺')
    call s:SuperSub('texSuperscript', '\^', '-', '⁻')
    call s:SuperSub('texSuperscript', '\^', '<', '˂')
    call s:SuperSub('texSuperscript', '\^', '>', '˃')
    call s:SuperSub('texSuperscript', '\^', '/', 'ˊ')
    call s:SuperSub('texSuperscript', '\^', '(', '⁽')
    call s:SuperSub('texSuperscript', '\^', ')', '⁾')
    call s:SuperSub('texSuperscript', '\^', '\.', '˙')
    call s:SuperSub('texSuperscript', '\^', '=', '˭')
    call s:SuperSub('texSubscript', '_', '0', '₀')
    call s:SuperSub('texSubscript', '_', '1', '₁')
    call s:SuperSub('texSubscript', '_', '2', '₂')
    call s:SuperSub('texSubscript', '_', '3', '₃')
    call s:SuperSub('texSubscript', '_', '4', '₄')
    call s:SuperSub('texSubscript', '_', '5', '₅')
    call s:SuperSub('texSubscript', '_', '6', '₆')
    call s:SuperSub('texSubscript', '_', '7', '₇')
    call s:SuperSub('texSubscript', '_', '8', '₈')
    call s:SuperSub('texSubscript', '_', '9', '₉')
    call s:SuperSub('texSubscript', '_', 'a', 'ₐ')
    call s:SuperSub('texSubscript', '_', 'e', 'ₑ')
    call s:SuperSub('texSubscript', '_', 'h', 'ₕ')
    call s:SuperSub('texSubscript', '_', 'i', 'ᵢ')
    call s:SuperSub('texSubscript', '_', 'j', 'ⱼ')
    call s:SuperSub('texSubscript', '_', 'k', 'ₖ')
    call s:SuperSub('texSubscript', '_', 'l', 'ₗ')
    call s:SuperSub('texSubscript', '_', 'm', 'ₘ')
    call s:SuperSub('texSubscript', '_', 'n', 'ₙ')
    call s:SuperSub('texSubscript', '_', 'o', 'ₒ')
    call s:SuperSub('texSubscript', '_', 'p', 'ₚ')
    call s:SuperSub('texSubscript', '_', 'r', 'ᵣ')
    call s:SuperSub('texSubscript', '_', 's', 'ₛ')
    call s:SuperSub('texSubscript', '_', 't', 'ₜ')
    call s:SuperSub('texSubscript', '_', 'u', 'ᵤ')
    call s:SuperSub('texSubscript', '_', 'v', 'ᵥ')
    call s:SuperSub('texSubscript', '_', 'x', 'ₓ')
    call s:SuperSub('texSubscript', '_', ',', '︐')
    call s:SuperSub('texSubscript', '_', '+', '₊')
    call s:SuperSub('texSubscript', '_', '-', '₋')
    call s:SuperSub('texSubscript', '_', '/', 'ˏ')
    call s:SuperSub('texSubscript', '_', '(', '₍')
    call s:SuperSub('texSubscript', '_', ')', '₎')
    call s:SuperSub('texSubscript', '_', '\.', '‸')
    call s:SuperSub('texSubscript', '_', 'r', 'ᵣ')
    call s:SuperSub('texSubscript', '_', 'v', 'ᵥ')
    call s:SuperSub('texSubscript', '_', 'x', 'ₓ')
    call s:SuperSub('texSubscript', '_', '\\beta\>' , 'ᵦ')
    call s:SuperSub('texSubscript', '_', '\\delta\>', 'ᵨ')
    call s:SuperSub('texSubscript', '_', '\\phi\>'  , 'ᵩ')
    call s:SuperSub('texSubscript', '_', '\\gamma\>', 'ᵧ')
    call s:SuperSub('texSubscript', '_', '\\chi\>'  , 'ᵪ')
    delfunction s:SuperSub
  endif

  " {{{2 Accented characters and Ligatures:
  if s:tex_conceal =~# 'a'
    if b:tex_stylish
      syntax match texAccent          "\\[bcdvuH][^a-zA-Z@]"me=e-1
      syntax match texLigature        "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)[^a-zA-Z@]"me=e-1
      syntax match texLigature        '--'
      syntax match texLigature        '---'
    else
      function! s:Accents(chr,...)
        let i= 1
        for l:accent in ['`', "\\'", '^', '"', '\~', '\.', '=', 'c', 'H', 'k', 'r', 'u', 'v']
          if i > a:0
            break
          endif
          if strlen(a:{i}) == 0 || a:{i} ==# ' ' || a:{i} ==# '?'
            let i= i + 1
            continue
          endif
          if l:accent =~# '\a'
            execute "syntax match texAccent '" . '\\' . l:accent . '\(\s*{' . a:chr . '}\|\s\+' . a:chr . '\)' . "' conceal cchar=" . a:{i}
          else
            execute "syntax match texAccent '" . '\\' . l:accent . '\s*\({' . a:chr . '}\|' . a:chr . '\)' . "' conceal cchar=" . a:{i}
          endif
          let i= i + 1
        endfor
      endfunction
      "                  \`  \'  \^  \"  \~  \.  \=  \c  \H  \k  \r  \u  \v
      call s:Accents('a','à','á','â','ä','ã','ȧ','ā',' ',' ','ą','å','ă','ǎ')
      call s:Accents('A','À','Á','Â','Ä','Ã','Ȧ','Ā',' ',' ','Ą','Å','Ă','Ǎ')
      call s:Accents('c',' ','ć','ĉ',' ',' ','ċ',' ','ç',' ',' ',' ',' ','č')
      call s:Accents('C',' ','Ć','Ĉ',' ',' ','Ċ',' ','Ç',' ',' ',' ',' ','Č')
      call s:Accents('d',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','ď')
      call s:Accents('D',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','Ď')
      call s:Accents('e','è','é','ê','ë','ẽ','ė','ē','ȩ',' ','ę',' ','ĕ','ě')
      call s:Accents('E','È','É','Ê','Ë','Ẽ','Ė','Ē','Ȩ',' ','Ę',' ','Ĕ','Ě')
      call s:Accents('g',' ','ǵ','ĝ',' ',' ','ġ',' ','ģ',' ',' ',' ','ğ','ǧ')
      call s:Accents('G',' ','Ǵ','Ĝ',' ',' ','Ġ',' ','Ģ',' ',' ',' ','Ğ','Ǧ')
      call s:Accents('h',' ',' ','ĥ',' ',' ',' ',' ',' ',' ',' ',' ',' ','ȟ')
      call s:Accents('H',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','Ȟ')
      call s:Accents('i','ì','í','î','ï','ĩ','į','ī',' ',' ','į',' ','ĭ','ǐ')
      call s:Accents('I','Ì','Í','Î','Ï','Ĩ','İ','Ī',' ',' ','Į',' ','Ĭ','Ǐ')
      call s:Accents('J',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','ǰ')
      call s:Accents('k',' ',' ',' ',' ',' ',' ',' ','ķ',' ',' ',' ',' ','ǩ')
      call s:Accents('K',' ',' ',' ',' ',' ',' ',' ','Ķ',' ',' ',' ',' ','Ǩ')
      call s:Accents('l',' ','ĺ','ľ',' ',' ',' ',' ','ļ',' ',' ',' ',' ','ľ')
      call s:Accents('L',' ','Ĺ','Ľ',' ',' ',' ',' ','Ļ',' ',' ',' ',' ','Ľ')
      call s:Accents('n',' ','ń',' ',' ','ñ',' ',' ','ņ',' ',' ',' ',' ','ň')
      call s:Accents('N',' ','Ń',' ',' ','Ñ',' ',' ','Ņ',' ',' ',' ',' ','Ň')
      call s:Accents('o','ò','ó','ô','ö','õ','ȯ','ō',' ','ő','ǫ',' ','ŏ','ǒ')
      call s:Accents('O','Ò','Ó','Ô','Ö','Õ','Ȯ','Ō',' ','Ő','Ǫ',' ','Ŏ','Ǒ')
      call s:Accents('r',' ','ŕ',' ',' ',' ',' ',' ','ŗ',' ',' ',' ',' ','ř')
      call s:Accents('R',' ','Ŕ',' ',' ',' ',' ',' ','Ŗ',' ',' ',' ',' ','Ř')
      call s:Accents('s',' ','ś','ŝ',' ',' ',' ',' ','ş',' ','ȿ',' ',' ','š')
      call s:Accents('S',' ','Ś','Ŝ',' ',' ',' ',' ','Ş',' ',' ',' ',' ','Š')
      call s:Accents('t',' ',' ',' ',' ',' ',' ',' ','ţ',' ',' ',' ',' ','ť')
      call s:Accents('T',' ',' ',' ',' ',' ',' ',' ','Ţ',' ',' ',' ',' ','Ť')
      call s:Accents('u','ù','ú','û','ü','ũ',' ','ū',' ','ű','ų','ů','ŭ','ǔ')
      call s:Accents('U','Ù','Ú','Û','Ü','Ũ',' ','Ū',' ','Ű','Ų','Ů','Ŭ','Ǔ')
      call s:Accents('w',' ',' ','ŵ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ')
      call s:Accents('W',' ',' ','Ŵ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ')
      call s:Accents('y','ỳ','ý','ŷ','ÿ','ỹ',' ',' ',' ',' ',' ',' ',' ',' ')
      call s:Accents('Y','Ỳ','Ý','Ŷ','Ÿ','Ỹ',' ',' ',' ',' ',' ',' ',' ',' ')
      call s:Accents('z',' ','ź',' ',' ',' ','ż',' ',' ',' ',' ',' ',' ','ž')
      call s:Accents('Z',' ','Ź',' ',' ',' ','Ż',' ',' ',' ',' ',' ',' ','Ž')
      call s:Accents('\\i','ì','í','î','ï','ĩ','į',' ',' ',' ',' ',' ','ĭ',' ')
      "                    \`  \'  \^  \"  \~  \.  \=  \c  \H  \k  \r  \u  \v
      delfunction s:Accents
      syntax match texAccent          '\\aa\>'        conceal cchar=å
      syntax match texAccent          '\\AA\>'        conceal cchar=Å
      syntax match texAccent          '\\o\>'         conceal cchar=ø
      syntax match texAccent          '\\O\>'         conceal cchar=Ø
      syntax match texLigature        '\\AE\>'        conceal cchar=Æ
      syntax match texLigature        '\\ae\>'        conceal cchar=æ
      syntax match texLigature        '\\oe\>'        conceal cchar=œ
      syntax match texLigature        '\\OE\>'        conceal cchar=Œ
      syntax match texLigature        '\\ss\>'        conceal cchar=ß
      syntax match texLigature        '--'            conceal cchar=–
      syntax match texLigature        '---'           conceal cchar=—
    endif
  endif
endif

" {{{1 Synchronization

syntax sync maxlines=200
syntax sync minlines=50
syntax sync match texSyncStop groupthere NONE "%stopzone\>"

" The $..$ and $$..$$ make for impossible sync patterns
" (one can't tell if a "$$" starts or stops a math zone by itself)
" The following grouptheres coupled with minlines above
" help improve the odds of good syncing.
syntax sync match texSyncMathZoneA groupthere NONE "\\end{abstract}"
syntax sync match texSyncMathZoneA groupthere NONE "\\end{center}"
syntax sync match texSyncMathZoneA groupthere NONE "\\end{description}"
syntax sync match texSyncMathZoneA groupthere NONE "\\end{enumerate}"
syntax sync match texSyncMathZoneA groupthere NONE "\\end{itemize}"
syntax sync match texSyncMathZoneA groupthere NONE "\\end{table}"
syntax sync match texSyncMathZoneA groupthere NONE "\\end{tabular}"
syntax sync match texSyncMathZoneA groupthere NONE "\\\(sub\)*section\>"

" {{{1 Highlighting

if !exists('skip_tex_syntax_inits')
  " TeX highlighting groups which should share similar highlighting
  highlight def link texBadMath              texError
  highlight def link texMathDelimBad         texError
  highlight def link texMathError            texError
  highlight def link texError                 Error
  if !b:tex_stylish
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
endif

" {{{1 Cleanup

unlet s:extfname
let b:current_syntax = 'tex'
let &cpo = s:keepcpo
unlet s:keepcpo

call vimtex#syntax#init()

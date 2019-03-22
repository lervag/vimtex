" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:vimtex#re#not_bslash =  '\v%(\\@<!%(\\\\)*)@<='
let g:vimtex#re#not_comment = '\v%(' . g:vimtex#re#not_bslash . '\%.*)@<!'

let g:vimtex#re#tex_input_root =
      \ '\v^\s*\%\s*!?\s*[tT][eE][xX]\s+[rR][oO][oO][tT]\s*\=\s*\zs.*\ze\s*$'
let g:vimtex#re#tex_input_latex = '\v\\%('
      \ . join(get(g:, 'vimtex_include_indicators',
      \            ['input', 'include', 'subfile']),
      \        '|') . ')\s*\{'
let g:vimtex#re#tex_input_import =
      \ '\v\\%(sub)?%(import|%(input|include)from)\*?\{[^\}]*\}\{'
let g:vimtex#re#tex_input_package =
      \ '\v\\%(usepackage|RequirePackage)%(\s*\[[^]]*\])?\s*\{\zs[^}]*\ze\}'

let g:vimtex#re#tex_input = '\v^\s*%(' . join([
      \   g:vimtex#re#tex_input_latex,
      \   g:vimtex#re#tex_input_import,
      \ ], '|') . ')'

let g:vimtex#re#bib_input = '\v\\%(addbibresource|bibliography)>'

let g:vimtex#re#tex_include = g:vimtex#re#tex_input_root
      \ . '|' . g:vimtex#re#tex_input . '\zs[^\}]*\ze\}?'
      \ . '|' . g:vimtex#re#tex_input_package

" {{{1 Completion regexes
let g:vimtex#re#neocomplete =
      \ '\v\\%('
      \ .  '\a*cite\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(text|block)cquote\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(for|hy)\w*cquote\*?\{[^}]*}%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|\a*ref%(\s*\{[^}]*|range\s*\{[^,}]*%(}\{)?)'
      \ . '|hyperref\s*\[[^]]*'
      \ . '|includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(include%(only)?|input|subfile)\s*\{[^}]*'
      \ . '|\a*(gls|Gls|GLS)(pl)?\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|includepdf%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|includestandalone%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|%(usepackage|RequirePackage|PassOptionsToPackage)%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|documentclass%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|begin%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|end%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|\a*'
      \ . ')'

let g:vimtex#re#deoplete = '\\(?:'
      \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|(text|block)cquote\*?(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|(for|hy)\w*cquote\*?{[^}]*}(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|\w*ref(?:\s*\{[^}]*|range\s*\{[^,}]*(?:}{)?)'
      \ . '|hyperref\s*\[[^]]*'
      \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|(?:include(?:only)?|input|subfile)\s*\{[^}]*'
      \ . '|\w*(gls|Gls|GLS)(pl)?\w*(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|includepdf(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|includestandalone(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|(usepackage|RequirePackage|PassOptionsToPackage)(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|documentclass(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|begin(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|end(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|\w*'
      \ .')'

let g:vimtex#re#ncm2#cmds = [
      \ '\\[A-Za-z]+',
      \ '\\(usepackage|RequirePackage|PassOptionsToPackage)(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\documentclass(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\begin(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\end(\s*\[[^]]*\])?\s*\{[^}]*',
      \]
let g:vimtex#re#ncm2#bibtex = [
      \ '\\[A-Za-z]*cite[A-Za-z]*(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(text|block)cquote\*?(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(for|hy)[A-Za-z]*cquote\*?{[^}]*}(\[[^]]*\]){0,2}{[^}]*',
      \]
let g:vimtex#re#ncm2#labels = [
      \ '\\[A-Za-z]*ref({[^}]*|range{([^,{}]*(}{)?))',
      \ '\\hyperref\[[^]]*',
      \ '\\\a*(gls|Gls|GLS)(pl)?\a*(\s*\[[^]]*\]){0,2}\s*\{[^}]*',
      \]
let g:vimtex#re#ncm2#files = [
      \ '\\includegraphics\*?(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(include(only)?|input|subfile){[^}]*',
      \ '\\includepdf(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\includestandalone(\s*\[[^]]*\])?\s*\{[^}]*',
      \]

let g:vimtex#re#ncm2 = g:vimtex#re#ncm2#cmds +
            \ g:vimtex#re#ncm2#bibtex +
            \ g:vimtex#re#ncm2#labels +
            \ g:vimtex#re#ncm2#files

let g:vimtex#re#ncm = copy(g:vimtex#re#ncm2)

let g:vimtex#re#youcompleteme = map(copy(g:vimtex#re#ncm), "'re!' . v:val")

" }}}1

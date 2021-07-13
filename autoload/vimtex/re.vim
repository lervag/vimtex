" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:vimtex#re#not_bslash =  '\v%(\\@<!%(\\\\)*)@<='
let g:vimtex#re#not_comment = '\v%(' . g:vimtex#re#not_bslash . '\%.*)@<!'

let g:vimtex#re#tex_input_root =
      \ '\v^\c\s*\%\s*!?\s*tex\s+root\s*\=\s*\zs.*\ze\s*$'
let g:vimtex#re#tex_input_latex = '\v\\%('
      \ . join(get(g:, 'vimtex_include_indicators', ['input', 'include']), '|')
      \ . ')\s*\{'
let g:vimtex#re#tex_input_import = '\v\\%('
      \ . 'subfile%(include)?'
      \ . '|'
      \ . '%(sub)?%(import|%(input|include)from)\*?\{[^\}]*\}'
      \ . ')\s*\{'
let g:vimtex#re#tex_input_package =
      \ '\v\\%(usepackage|RequirePackage)%(\s*\[[^]]*\])?\s*\{\zs[^}]*\ze\}'

let g:vimtex#re#tex_input = '\v^\s*\zs%(' . join([
      \   g:vimtex#re#tex_input_latex,
      \   g:vimtex#re#tex_input_import,
      \ ], '|') . ')'

let g:vimtex#re#bib_input = '\v^\s*\zs\\%(addbibresource|bibliography)\s*\{'

let g:vimtex#re#tex_include = g:vimtex#re#tex_input_root
      \ . '|' . g:vimtex#re#tex_input . '\zs[^\}]*\ze\}?'
      \ . '|' . g:vimtex#re#tex_input_package

" {{{1 Completion regexes
let g:vimtex#re#neocomplete =
      \ '\v\\%('
      \ .  '%(\a*cite|Cite)\a*\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(\a*cites|Cites)%(\s*\([^)]*\)){0,2}'
      \     . '%(%(\s*\[[^]]*\]){0,2}\s*\{[^}]*\})*'
      \     . '%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|bibentry\s*\{[^}]*'
      \ . '|%(text|block)cquote\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(for|hy)\w*cquote\*?\{[^}]*}%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|defbibentryset\{[^}]*}\{[^}]*'
      \ . '|\a*ref%(\s*\{[^}]*|range\s*\{[^,}]*%(}\{)?)'
      \ . '|hyperref\s*\[[^]]*'
      \ . '|includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(include%(only)?|input|subfile)\s*\{[^}]*'
      \ . '|([cpdr]?(gls|Gls|GLS)|acr|Acr|ACR)\a*\s*\{[^}]*'
      \ . '|(ac|Ac|AC)\s*\{[^}]*'
      \ . '|includepdf%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|includestandalone%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|%(usepackage|RequirePackage|PassOptionsToPackage)%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|documentclass%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|begin%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|end%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|\a*'
      \ . ')'

let g:vimtex#re#deoplete = '\\(?:'
      \ .  '(?:\w*cite|Cite)\w*\*?(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|(?:\w*cites|Cites)(?:\s*\([^)]*\)){0,2}'
      \     . '(?:(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*\})*'
      \     . '(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|bibentry\s*{[^}]*'
      \ . '|(text|block)cquote\*?(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|(for|hy)\w*cquote\*?{[^}]*}(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|defbibentryset{[^}]*}{[^}]*'
      \ . '|\w*ref(?:\s*\{[^}]*|range\s*\{[^,}]*(?:}{)?)'
      \ . '|hyperref\s*\[[^]]*'
      \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|(?:include(?:only)?|input|subfile)\s*\{[^}]*'
      \ . '|([cpdr]?(gls|Gls|GLS)|acr|Acr|ACR)[a-zA-Z]*\s*\{[^}]*'
      \ . '|(ac|Ac|AC)\s*\{[^}]*'
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
      \ '\\([A-Za-z]*cite|Cite)[A-Za-z]*\*?(\[[^]]*\]){0,2}{[^}]*',
      \ '\\([A-Za-z]*cites|Cites)(\s*\([^)]*\)){0,2}'
      \     . '((\s*\[[^]]*\]){0,2}\s*\{[^}]*\})*'
      \     . '(\s*\[[^]]*\]){0,2}\s*\{[^}]*',
      \ '\\bibentry\s*{[^}]*',
      \ '\\(text|block)cquote\*?(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(for|hy)[A-Za-z]*cquote\*?{[^}]*}(\[[^]]*\]){0,2}{[^}]*',
      \ '\\defbibentryset{[^}]*}{[^}]*',
      \]
let g:vimtex#re#ncm2#labels = [
      \ '\\[A-Za-z]*ref({[^}]*|range{([^,{}]*(}{)?))',
      \ '\\hyperref\[[^]]*',
      \ '\\([cpdr]?(gls|Gls|GLS)|acr|Acr|ACR)[a-zA-Z]*\s*\{[^}]*',
      \ '\\(ac|Ac|AC)\s*\{[^}]*',
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

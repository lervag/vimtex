" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexmk#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

function! vimtex#compiler#latexmk#get_rc_opt(root, opt, type, default) abort " {{{1
  "
  " Parse option from .latexmkrc.
  "
  " Arguments:
  "   root         Root of LaTeX project
  "   opt          Name of options
  "   type         0 if string, 1 if integer, 2 if list
  "   default      Value to return if option not found in latexmkrc file
  "
  " Output:
  "   [value, location]
  "
  "   value        Option value (integer or string)
  "   location     An integer that indicates where option was found
  "                 -1: not found (default value returned)
  "                  0: global latexmkrc file
  "                  1: local latexmkrc file
  "

  if a:type == 0
    let l:pattern = '^\s*\$' . a:opt . '\s*=\s*[''"]\(.\+\)[''"]'
  elseif a:type == 1
    let l:pattern = '^\s*\$' . a:opt . '\s*=\s*\(\d\+\)'
  elseif a:type == 2
    let l:pattern = '^\s*@' . a:opt . '\s*=\s*(\(.*\))'
  else
    throw 'VimTeX: Argument error'
  endif

  " Candidate files
  " - each element is a pair [path_to_file, is_local_rc_file].
  let l:files = [
        \ [a:root . '/latexmkrc', 1],
        \ [a:root . '/.latexmkrc', 1],
        \ [fnamemodify('~/.latexmkrc', ':p'), 0],
        \ [fnamemodify(
        \    !empty($XDG_CONFIG_HOME) ? $XDG_CONFIG_HOME : '~/.config', ':p')
        \    . '/latexmk/latexmkrc', 0]
        \]

  let l:result = [a:default, -1]

  for [l:file, l:is_local] in l:files
    if filereadable(l:file)
      let l:match = matchlist(readfile(l:file), l:pattern)
      if len(l:match) > 1
        let l:result = [l:match[1], l:is_local]
        break
      end
    endif
  endfor

  " Parse the list
  if a:type == 2 && l:result[1] > -1
    let l:array = split(l:result[0], ',')
    let l:result[0] = []
    for l:x in l:array
      let l:x = substitute(l:x, "^'", '', '')
      let l:x = substitute(l:x, "'$", '', '')
      let l:result[0] += [l:x]
    endfor
  endif

  return l:result
endfunction

" }}}1
function! vimtex#compiler#latexmk#copy_temp_files() abort " {{{1
  if exists('*b:vimtex.compiler.__copy_temp_files')
    call b:vimtex.compiler.__copy_temp_files()
  endif
endfunction

" }}}1


let s:compiler = vimtex#compiler#_template#new({
      \ 'name' : 'latexmk',
      \ 'aux_dir': '',
      \ 'callback' : 1,
      \ 'continuous': 1,
      \ 'executable' : 'latexmk',
      \ 'options' : [
      \   '-verbose',
      \   '-file-line-error',
      \   '-synctex=1',
      \   '-interaction=nonstopmode',
      \ ],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable(self.executable)
    call vimtex#log#warning(self.executable . ' is not executable')
    let self.enabled = v:false
  endif
endfunction

" }}}1
function! s:compiler.__init() abort dict " {{{1
  call vimtex#util#materialize_property(self, 'aux_dir')

  call s:compare_with_latexmkrc(self, 'out_dir')
  call s:compare_with_latexmkrc(self, 'aux_dir')

  " $VIMTEX_OUTPUT_DIRECTORY overrides configured compiler.aux_dir
  if !empty($VIMTEX_OUTPUT_DIRECTORY)
    if !empty(self.aux_dir)
          \ && (self.aux_dir !=# $VIMTEX_OUTPUT_DIRECTORY)
      call vimtex#log#warning(
            \ 'Setting VIMTEX_OUTPUT_DIRECTORY overrides aux_dir!',
            \ 'Changed aux_dir from: ' . self.aux_dir,
            \ 'Changed aux_dir to: ' . $VIMTEX_OUTPUT_DIRECTORY)
    endif

    let self.aux_dir = $VIMTEX_OUTPUT_DIRECTORY
  endif

  call self.__init_temp_files()
endfunction

" }}}1
function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  let l:cmd = (has('win32')
        \ ? 'set max_print_line=2000 & '
        \ : 'max_print_line=2000 ') . self.executable

  let l:cmd .= ' ' . join(self.options) . a:passed_options
  let l:cmd .= ' ' . self.get_engine()

  if !empty(self.out_dir)
    let l:cmd .= ' -outdir=' . fnameescape(self.out_dir)
  endif

  if !empty(self.aux_dir)
    let l:cmd .= ' -emulate-aux-dir'
    let l:cmd .= ' -auxdir=' . fnameescape(self.aux_dir)
  endif

  if self.continuous
    let l:cmd .= ' -pvc -pvctimeout- -view=none'

    if self.callback
      for [l:opt, l:val] in [
            \ ['compiling_cmd', 'vimtex_compiler_callback_compiling'],
            \ ['success_cmd', 'vimtex_compiler_callback_success'],
            \ ['failure_cmd', 'vimtex_compiler_callback_failure'],
            \]
        let l:cmd .= s:wrap_option_appendcmd(l:opt, 'echo ' . l:val)
      endfor
    endif
  endif

  return l:cmd . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
endfunction

" }}}1
function! s:compiler.__pprint_append() abort dict " {{{1
  let l:list = []

  if !empty(self.aux_dir)
    call add(l:list, ['aux_dir', self.aux_dir])
  endif

  call add(l:list, ['callback', self.callback])
  call add(l:list, ['continuous', self.continuous])
  call add(l:list, ['executable', self.executable])

  return l:list
endfunction

" }}}1

function! s:compiler.get_file(ext) abort dict " {{{1
  if g:vimtex_view_use_temp_files
        \ && index(['pdf', 'synctex.gz'], a:ext) >= 0
    return self.__get_temp_file(a:ext)
  endif

  for l:root in [
        \ $VIMTEX_OUTPUT_DIRECTORY,
        \ self.aux_dir,
        \ self.out_dir,
        \ self.file_info.root
        \]
    if empty(l:root) | continue | endif

    let l:cand = printf('%s/%s.%s', l:root, self.file_info.jobname, a:ext)
    if !vimtex#paths#is_abs(l:root)
      let l:cand = self.file_info.root . '/' . l:cand
    endif

    if filereadable(l:cand)
      return fnamemodify(l:cand, ':p')
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:compiler.create_dirs() abort dict " {{{1
  call self._create_build_dir(self.out_dir)
  call self._create_build_dir(self.aux_dir)
endfunction

" }}}1
function! s:compiler.remove_dirs() abort dict " {{{1
  call self._remove_dir(self.out_dir)
  call self._remove_dir(self.aux_dir)
endfunction

" }}}1

function! s:compiler.clean(full) abort dict " {{{1
  call self.__clean_temp_files(a:full)

  let l:cmd = self.executable
  let l:cmd .= a:full ? ' -C' : ' -c'

  if !empty(self.out_dir)
    let l:cmd .= ' -outdir=' . fnameescape(self.out_dir)
  endif
  if !empty(self.aux_dir)
    let l:cmd .= ' -emulate-aux-dir'
    let l:cmd .= ' -auxdir=' . fnameescape(self.aux_dir)
  endif

  let l:cmd .= ' ' . vimtex#util#shellescape(self.file_info.target_basename)

  call vimtex#jobs#run(l:cmd, {'cwd': self.file_info.root})
endfunction

" }}}1
function! s:compiler.get_engine() abort dict " {{{1
  " Parse tex_program from TeX directive
  let l:tex_program_directive = b:vimtex.get_tex_program()
  let l:tex_program = l:tex_program_directive

  " Parse tex_program from from pdf_mode option in .latexmkrc
  let [l:pdf_mode, l:is_local] = vimtex#compiler#latexmk#get_rc_opt(
        \ self.file_info.root, 'pdf_mode', 1, -1)

  if l:pdf_mode >= 1 && l:pdf_mode <= 5
    let l:tex_program_pdfmode = [
          \ 'pdflatex',
          \ 'pdfps',
          \ 'pdfdvi',
          \ 'lualatex',
          \ 'xelatex',
          \][l:pdf_mode-1]

    " Use pdf_mode if there is no TeX directive
    if l:tex_program_directive ==# '_'
      let l:tex_program = l:tex_program_pdfmode
    elseif l:is_local && l:tex_program_directive !=# l:tex_program_pdfmode
      " Give warning when there may be a confusing conflict
      call vimtex#log#warning(
            \ 'Value of pdf_mode from latexmkrc is inconsistent with ' .
            \ 'TeX program directive!',
            \ 'TeX program: ' . l:tex_program_directive,
            \ 'pdf_mode:    ' . l:tex_program_pdfmode,
            \ 'The value of pdf_mode will be ignored.')
    endif
  endif

  return get(g:vimtex_compiler_latexmk_engines,
        \ l:tex_program,
        \ g:vimtex_compiler_latexmk_engines._)
endfunction

" }}}1

function! s:compiler.__init_temp_files() abort dict " {{{1
  let self.__temp_files = {}
  if !g:vimtex_view_use_temp_files | return | endif

  let l:root = !empty(self.out_dir)
        \ ? self.out_dir
        \ : self.file_info.root
  for l:ext in ['pdf', 'synctex.gz']
    let l:source = printf('%s/%s.%s', l:root, self.file_info.jobname, l:ext)
    let l:target = printf('%s/_%s.%s', l:root, self.file_info.jobname, l:ext)
    let self.__temp_files[l:source] = l:target
  endfor

  augroup vimtex_compiler
    autocmd!
    autocmd User VimtexEventCompileSuccess
          \ call vimtex#compiler#latexmk#copy_temp_files()
  augroup END
endfunction

" }}}1
function! s:compiler.__copy_temp_files() abort dict " {{{1
  for [l:source, l:target] in items(self.__temp_files)
    if getftime(l:source) > getftime(l:target)
      call writefile(readfile(l:source, 'b'), l:target, 'b')
    endif
  endfor
endfunction

" }}}1
function! s:compiler.__get_temp_file(ext) abort dict " {{{1
  for l:file in values(self.__temp_files)
    if filereadable(l:file) && l:file =~# a:ext . '$'
      return l:file
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:compiler.__clean_temp_files(full) abort dict " {{{1
  for l:file in values(self.__temp_files)
    if filereadable(l:file) && (a:full || l:file[-3:] !=# 'pdf')
      call delete(l:file)
    endif
  endfor
endfunction

" }}}1


function! s:compare_with_latexmkrc(dict, option) abort " {{{1
  " Check if option is specified in .latexmkrc.
  " If it is, .latexmkrc should be respected!
  let l:value = vimtex#compiler#latexmk#get_rc_opt(
        \ a:dict.file_info.root, a:option, 0, '')[0]
  if !empty(l:value)
    if !empty(a:dict[a:option]) && (a:dict[a:option] !=# l:value)
      call vimtex#log#warning(
            \ 'Option "' . a:option . '" is overriden by latexmkrc',
            \ 'Changed from: ' . a:dict[a:option],
            \ 'Changed to: ' . l:value)
    endif
    let a:dict[a:option] = l:value
  endif
endfunction

" }}}1
function! s:wrap_option_appendcmd(name, value) abort " {{{1
  " Note: On Linux, we use double quoted perl strings; these interpolate
  "       variables. One should therefore NOT pass values that contain `$`.
  let l:win_cmd_sep = has('nvim') ? '^&' : '&'
  let l:common = printf('$%s = ($%s ? $%s', a:name, a:name, a:name)
  return has('win32')
        \ ? printf(' -e "%s . '' %s '' : '''') . ''%s''"',
        \          l:common, l:win_cmd_sep, a:value)
        \ : printf(' -e ''%s . " ; " : "") . "%s"''',
        \          l:common, a:value)
endfunction

"}}}1

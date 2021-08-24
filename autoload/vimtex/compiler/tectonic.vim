" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#tectonic#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_t#new({
      \ 'name' : 'tectonic',
      \ 'options' : [
      \   '--keep-logs',
      \   '--synctex'
      \ ],
      \})

function! s:compiler.init() abort dict " {{{1
  if !executable('tectonic')
    call vimtex#log#warning('tectonic is not executable!')
    throw 'VimTeX: Requirements not met'
  endif

  call vimtex#compiler#_t#build_dir_materialize(self)
  call vimtex#compiler#_t#build_dir_respect_envvar(self)
endfunction

" }}}1

function! s:compiler.build_cmd() abort dict " {{{1
  let l:cmd = 'tectonic'

  for l:opt in self.options
    if l:opt =~# '^-\%(o\|-outdir\)'
      call vimtex#log#warning("Don't use --outdir or -o in compiler options,"
            \ . ' use build_dir instead, see :help g:vimtex_compiler_tectonic'
            \ . ' for more details')
      continue
    endif

    let l:cmd .= ' ' . l:opt
  endfor

  if empty(self.build_dir)
    let self.build_dir = fnamemodify(self.target_path, ':p:h')
  elseif !isdirectory(self.build_dir)
    call vimtex#log#warning(
          \ "build_dir doesn't exist, it will be created: " . self.build_dir)
    call mkdir(self.build_dir, 'p')
  endif

  return l:cmd
        \ . ' --outdir=' . self.build_dir
        \ . ' ' . vimtex#util#shellescape(self.target)
endfunction

" }}}1
function! s:compiler.pprint_items() abort dict " {{{1
  let l:configuration = []

  call add(l:configuration, ['tectonic options', self.options])

  let l:list = []
  call add(l:list, ['output', self.output])

  if self.target_path !=# b:vimtex.tex
    call add(l:list, ['root', self.root])
    call add(l:list, ['target', self.target_path])
  endif

  call add(l:list, ['configuration', l:configuration])

  if has_key(self, 'process')
    call add(l:list, ['process', self.process])
  endif

  if has_key(self, 'job')
    call add(l:list, ['cmd', self.cmd])
  endif

  return l:list
endfunction

" }}}1

" vim-nuxtex is a LaTeX quickfix and SyncTeX plugin for Vim/Neovim on Linux
" Developper: Kenichi Takizawa
" License: MIT

if exists("current_compiler")
  finish
endif
let current_compiler = 'nuxtex'

let s:keepcpo= &cpo
set cpo&vim

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

" Compilerset makeprg and errorformat
if exists('b:nuxtex_makeprg')
  let &l:makeprg=b:nuxtex_makeprg
elseif exists('g:nuxtex_makeprg')
  let &l:makeprg=g:nuxtex_makeprg
endif
CompilerSet errorformat=%m

augroup nuxtex_make
  au!
  au QuickFixCmdPre make call nuxtex#qfmake#allow()
  au QuickFixCmdPost make call nuxtex#qfmake#qf_init()
  au QuickFixCmdPre cfile call nuxtex#qfmake#allow()
  au QuickFixCmdPost cfile call nuxtex#qfmake#qf_init()
  au QuickFixCmdPre cbuffer call nuxtex#qfmake#allow()
  au QuickFixCmdPost cbuffer call nuxtex#qfmake#qf_init()
  au QuickFixCmdPre cgetfile call nuxtex#qfmake#allow()
  au QuickFixCmdPost cgetfile call nuxtex#qfmake#qf_init()
  au QuickFixCmdPre cgetbuffer call nuxtex#qfmake#allow()
  au QuickFixCmdPost cgetbuffer call nuxtex#qfmake#qf_init()
  au QuickFixCmdPre lmake call nuxtex#qfmake#allow()
  au QuickFixCmdPost lmake call nuxtex#qfmake#loc_init()
  au QuickFixCmdPre lfile call nuxtex#qfmake#allow()
  au QuickFixCmdPost lfile call nuxtex#qfmake#loc_init()
  au QuickFixCmdPre lbuffer call nuxtex#qfmake#allow()
  au QuickFixCmdPost lbuffer call nuxtex#qfmake#loc_init()
  au QuickFixCmdPre lgetfile call nuxtex#qfmake#allow()
  au QuickFixCmdPost lgetfile call nuxtex#qfmake#loc_init()
  au QuickFixCmdPre lgetbuffer call nuxtex#qfmake#allow()
  au QuickFixCmdPost lgetbuffer call nuxtex#qfmake#loc_init()
augroup END

let &cpo = s:keepcpo
unlet s:keepcpo


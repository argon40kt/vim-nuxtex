" vim-nuxtex is a LaTeX quickfix and SyncTeX plugin for Vim/Neovim on Linux
" Developper: Kenichi Takizawa
" License: MIT

"set re=0
let s:save_cpo = &cpo
setlocal cpo&vim

function! nuxtex#qfmake#allow() abort
  " Does not allow error message parser
  " if the compiler plugin is not nuxtex.
  "echo 'b:current_compiler check'
  let s:allow_parse = 0
  if exists('b:current_compiler')
    if b:current_compiler != 'nuxtex'
      return
    endif
  "  echo 'b:current_compiler exists'
  elseif exists('g:current_compiler')
    if g:current_compiler != 'nuxtex'
      return
    endif
  else
  "  echo 'b:current_compiler does not exist'
    return
  endif
  let s:allow_parse = 1
  " Set WindowID for loclist
  let s:qfdict['winid'] = bufwinid(bufnr())
  " Set $LANG parameter to change make message as English
  if !exists('g:nuxtex_sub_make_lang')
    let g:nuxtex_sub_make_lang = v:true
  endif
  let s:old_lang = $LANG
  if g:nuxtex_sub_make_lang
    let $LANG = 'en_US.UTF-8'
  endif
endfunc

function! nuxtex#qfmake#qf_init() abort
  call s:qf_object['init']()
  " Back to $LANG enviroment as user configuration
  if s:allow_parse
    let $LANG = s:old_lang
  endif
endfunc

function! nuxtex#qfmake#loc_init() abort
  call s:loc_object['init']()
  " Back to $LANG enviroment as user configuration
  if s:allow_parse
    let $LANG = s:old_lang
  endif
endfunc

function! s:init() dict
  " Does not execute error message parser
  " if the compiler plugin is not nuxtex.
  if s:allow_parse
  elseif !exists('g:nuxtex_force_quickfix')
    return
  elseif g:nuxtex_force_quickfix
  else
    return
  endif
  let s:qfdict['errlist'] = []
  let s:qfdict['warnlist'] = []
  let s:qfdict['infolist'] = []
  " Lexical analysis
  call self['preprocesser']()
  " AST
  call s:tree_monitor()
  " Update quickfix/loc list
  "let g:qfid = getqflist({'id' : 0}).id
  "call setqflist([], ' ', {'title' : 'nuxtex', 'context' : ''})
  let l:title = self['getmsg']({'title' : 0}).title . '(nuxtex)'
  call self['setmsg']('a', {'title' : l:title})
  call self['setmsg']('r', {'items': []})
  let l:newItems = s:qfdict['errlist'] + s:qfdict['warnlist'] + s:qfdict['infolist']
  "call setqflist([], 'a', {'id': g:qfid, 'items': l:qflist})
  call self['setmsg']('a', {'items': l:newItems})
endfunc

function! s:get_qf(...) dict
  if !a:0
    return getqflist()
  else
    return getqflist(a:1)
  endif
endfunc

function! s:get_loc(...) dict
  if !a:0
    return getloclist(s:qfdict['winid'])
  else
    return getloclist(s:qfdict['winid'], a:1)
  endif
endfunc

function! s:set_qf(mode, struct) dict
  call setqflist([], a:mode, a:struct)
endfunc

function! s:set_loc(mode, struct) dict
  call setloclist(s:qfdict['winid'], [], a:mode, a:struct)
endfunc

function! s:preprocesser() dict
  let l:index = 0
  let l:qflist = self['getmsg']()
  let s:list = []
  "let g:text = ''
  "let l:pattern = '\([()]\@1<=\|\ze[()]\)\|^!\zs\|[0-9]\([0-9]\)\@!\zs\|[^0-9]\([0-9]\)\@=\zs\|\s\S\@=\zs\|\S\s\@=\zs\|\ze\.\|\.\@1<='
  let l:pattern = '\([()]\@1<=\|\ze[()]\)\|^!\zs\|[0-9]\([0-9]\)\@!\zs\|[^0-9]\([0-9]\)\@=\zs\|\s\S\@=\zs\|\S\s\@=\zs\|\ze\.'
  while l:index < len(l:qflist)
    let s:list += split(l:qflist[l:index].text, l:pattern) + ["\n"]
    "let g:text .= l:qflist[l:index].text . "\n"
    let l:index = l:index + 1
  endwhile
  "let g:list = s:list
endfunc

let s:qf_object = {
	\	'init': function("s:init"),
	\	'preprocesser': function("s:preprocesser"),
	\	'getmsg': function("s:get_qf"),
	\	'setmsg': function("s:set_qf")}

let s:loc_object = deepcopy(s:qf_object)
let s:loc_object['getmsg'] = function("s:get_loc")
let s:loc_object['setmsg'] = function("s:set_loc")


function! s:tree_monitor() abort
  "echo $LANG
  let s:status = {'not_start': 0, 'start': 1, 'finish': 2}
  let s:idx = 0
  let s:mode = s:status['not_start']
" Execute tree() analysis while all phrase analysis has not been done.
  while v:true
    call s:tree(v:false, '')
    if s:idx >= len(s:list) - 1
      return
    endif
    let s:idx += 1
  endwhile
endfunc

function! s:tree(file_search, dir) abort
" Define class (Dictionary(function))
  let l:s4x_qf_cat_fin_dict = {'qf_cat_fin_status': function("s:qf_cat_fin_status"),
		\	'cat_fin_con': [],
		\	'cat_fin_con_idx': 0}
  let l:s4x_qf_cat_dict = {'qf_cat_status': function("s:qf_cat_status"),
		\	'cat_status': s:status['not_start'],
		\	'cat_start_con': [],
		\	'cat_start_con_idx': 0,
		\	's4x_cat_fin': deepcopy(l:s4x_qf_cat_fin_dict),
		\	'msg': ''}
  let l:s4x_qf_dict = {'qf_mode': function("s:qf_mode"),
	  \	's4x_qf_cat_msg': deepcopy(l:s4x_qf_cat_dict),
	  \	's4x_qf_cat_line': deepcopy(l:s4x_qf_cat_dict),
	  \	'level': 'W',
	  \	'mode_status': s:status['not_start'],
	  \	'mode_start_con': [],
	  \	'mode_start_con_idx': 0,
	  \	'file': '',
	  \	's4x_mode_fin': deepcopy(l:s4x_qf_cat_fin_dict)}

" Create instances
  let l:s4x_qf_err = deepcopy(l:s4x_qf_dict)
  let l:s4x_qf_overfull = deepcopy(l:s4x_qf_dict)
  let l:s4x_qf_warn = deepcopy(l:s4x_qf_dict)
  let l:s4x_qf_skp1 = deepcopy(l:s4x_qf_dict)


" Set msg and line no select parameter
  let l:s4x_qf_err['s4x_qf_cat_msg']['cat_start_con'] = ['!']
  let l:s4x_qf_err['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:s4x_qf_err['s4x_qf_cat_line']['cat_start_con'] = ["\n", 'l\.', '[0-9]\+']
  let l:s4x_qf_err['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['[0-9]\+']
  let l:s4x_qf_overfull['s4x_qf_cat_msg']['cat_start_con'] = ['\(overfull\)\c']
  let l:s4x_qf_overfull['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:s4x_qf_overfull['s4x_qf_cat_line']['cat_start_con'] = ['lines', '\s\+', '[0-9]\+']
  let l:s4x_qf_overfull['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['[0-9]\+']
  let l:s4x_qf_warn['s4x_qf_cat_msg']['cat_start_con'] = ['.*', '.*']
  "let l:s4x_qf_warn['s4x_qf_cat_msg']['cat_start_con'] = ['\(\(warning\)\c:\|\s\)\@!']
  let l:s4x_qf_warn['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ['\.']
  let l:s4x_qf_warn['s4x_qf_cat_line']['cat_start_con'] = ['line', '\s\+', '[0-9]\+']
  let l:s4x_qf_warn['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['[0-9]\+']
  let l:s4x_qf_skp1['s4x_qf_cat_msg']['cat_start_con'] = ['']
  let l:s4x_qf_skp1['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:s4x_qf_skp1['s4x_qf_cat_line']['cat_start_con'] = ['']
  let l:s4x_qf_skp1['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['[0-9]\+']

" Set each mode global parameter
  let l:s4x_qf_err['level'] = 'E'
  let l:s4x_qf_err['mode_start_con'] = ['!']
  let l:s4x_qf_err['s4x_mode_fin']['cat_fin_con'] = ["\n", '?']
  let l:s4x_qf_overfull['s4x_mode_fin']['cat_fin_con'] = ["\n"]
  let l:s4x_qf_overfull['mode_start_con'] = ['\(overfull\)\c']
  let l:s4x_qf_warn['mode_start_con'] = ['\(latex\)\c', '\s\+', '\(warning\)\c:']
  let l:s4x_qf_warn['s4x_mode_fin']['cat_fin_con'] = ["\n", "\n"]
  let l:s4x_qf_skp1['mode_start_con'] = ['No', '\s\+', 'file', '\s\+']
  let l:s4x_qf_skp1['s4x_mode_fin']['cat_fin_con'] = ["\n"]

" Construct LaTeX Font Warning method from LaTeX Warning Method
  let l:s4x_qf_fwrn = deepcopy(l:s4x_qf_warn)
  let l:s4x_qf_fwrn['mode_start_con'] = ['\(latex\)\c', '\s\+', '\(font\)\c', '\s\+', '\(warning\)\c:']

" Construct skip algrithm from base skip rule
  let l:s4x_qf_skp2 = deepcopy(l:s4x_qf_skp1)
  let l:s4x_qf_skp2['mode_start_con'] = ['\\openout']

" File path getting function definition
  let l:s4x_qf_cat_file = {'file_status': function("s:file_status"),
	\	'mode_status': s:status['start'],
	\	'tmp': 0,
	\	'file': ''}
  let l:s4x_qf_file = deepcopy(l:s4x_qf_cat_file)

" Define directory path getting class
  let l:s4x_qf_cat_fin_dict = {'qf_cat_fin_status': function("s:qf_cat_fin_status"),
		\	'cat_fin_con': [],
		\	'cat_fin_con_idx': 0}
  let l:s4x_qf_cat_dict = {'qf_cat_status': function("s:qf_cat_status"),
		\	'cat_status': s:status['not_start'],
		\	'cat_start_con': [],
		\	'cat_start_con_idx': 0,
		\	's4x_cat_fin': deepcopy(l:s4x_qf_cat_fin_dict),
		\	'msg': ''}
  let l:s4x_qf_sub_make = {'sub_make_status': function("s:sub_make_status"),
	  	\	'sub_make_cat': deepcopy(l:s4x_qf_cat_dict)}

" Directory getting function definition
  let l:sub_make_in = deepcopy(l:s4x_qf_sub_make)
  let l:make_C_in = deepcopy(l:s4x_qf_sub_make)
  let l:sub_make_out = deepcopy(l:s4x_qf_sub_make)
  let l:make_C_out = deepcopy(l:s4x_qf_sub_make)

  let l:sub_make_in['sub_make_cat']['cat_start_con'] = [
	\  'make[', '[0-9]\+', ']:', '\s\+',
	\  'Entering', '\s\+', 'directory', '\s\+']
  let l:make_C_in['sub_make_cat']['cat_start_con'] = [
	\  'make:', '\s\+', 'Entering', '\s\+', 'directory', '\s\+']
  let l:sub_make_out['sub_make_cat']['cat_start_con'] = [
	\  'make[', '[0-9]\+', ']:', '\s\+',
	\  'Leaving', '\s\+', 'directory', '\s\+']
  let l:make_C_out['sub_make_cat']['cat_start_con'] = [
	\  'make:', '\s\+', 'Leaving', '\s\+', 'directory', '\s\+']

  let l:sub_make_in['sub_make_cat']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:make_C_in['sub_make_cat']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:sub_make_out['sub_make_cat']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:make_C_out['sub_make_cat']['s4x_cat_fin']['cat_fin_con'] = ["\n"]

  " For adding directory path prefix
  if a:file_search
    if a:dir == ''
      let l:s4x_qf_file['file'] = ''
    else
      let l:s4x_qf_file['file'] = a:dir . '/'
    endif
  else
    let l:s4x_qf_file['mode_status'] = s:status['not_start']
  endif
  let l:list = ['']
  " Main loop
  while v:true
    if l:s4x_qf_file['file_status']()
    elseif s:mode
      let l:list[0] = s:list[s:idx]
      if l:sub_make_in['sub_make_status'](l:list) || l:make_C_in['sub_make_status'](l:list)
        call s:tree(v:false, l:list[0])
      elseif l:sub_make_out['sub_make_status'](l:list) || l:make_C_out['sub_make_status'](l:list)
        if simplify(l:list[0] . '/') == simplify(a:dir . '/')
	  "echo "exit\n"
          return
	endif
      endif
      call l:s4x_qf_skp1['qf_mode']('')
      call l:s4x_qf_skp2['qf_mode']('')
      call l:s4x_qf_err['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_overfull['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_warn['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_fwrn['qf_mode'](l:s4x_qf_file['file'])
    elseif trim(s:list[s:idx]) == '('
      let s:idx += 1
      call s:tree(v:true, a:dir)
    elseif trim(s:list[s:idx]) == ')'
      return
    else
      let l:list[0] = s:list[s:idx]
      if l:sub_make_in['sub_make_status'](l:list) || l:make_C_in['sub_make_status'](l:list)
        call s:tree(v:false, l:list[0])
      elseif l:sub_make_out['sub_make_status'](l:list) || l:make_C_out['sub_make_status'](l:list)
        if simplify(l:list[0] . '/') == simplify(a:dir . '/')
	  "echo "exit\n"
          return
	endif
      endif
      call l:s4x_qf_skp1['qf_mode']('')
      call l:s4x_qf_skp2['qf_mode']('')
      call l:s4x_qf_err['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_overfull['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_warn['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_fwrn['qf_mode'](l:s4x_qf_file['file'])
    endif
    if s:idx >= len(s:list) - 1
      return
    endif
    let s:idx += 1
  endwhile
endfunc

function! s:file_status() dict
  if self['mode_status'] == s:status['start']
    let s:mode = s:status['start']
    if s:is_str_equal(s:list[s:idx], "\n")
      " Did not found actual file name in the section
      let self['file'] = ''
      if self['tmp'] > 0
        "Goto back point. This case is not err/warn msg block
        let s:idx = self['tmp']
      endif
      " Finish file search mode but file was not found
      let self['mode_status'] = s:status['not_start']
      let s:mode = s:status['not_start']
    else
      let self['file'] .= s:list[s:idx]
      if filereadable(self['file'])
        " Finish file search mode because file has been found
        let self['mode_status'] = s:status['not_start']
        let s:mode = s:status['not_start']
      elseif s:is_str_equal(trim(s:list[s:idx]), '[()]') && self['tmp'] == 0
        " Keep back point for file not found case
        let self['tmp'] = s:idx
      endif
    endif
  endif
  "echo self['file']
  return self['mode_status']
endfunc

function! s:qf_cat_status() dict
  if self['cat_status'] == s:status['start']
    " Collect msg/line no
    let self['msg'] .= s:list[s:idx]
    let self['cat_status'] = self['s4x_cat_fin']['qf_cat_fin_status']()
  elseif self['cat_status'] == s:status['finish']
    " Initializing for next cycle
    let self['cat_start_con_idx'] = 0
    "let self['msg'] = ''
  elseif !s:is_str_equal(s:list[s:idx], self['cat_start_con'][self['cat_start_con_idx']])
    " Initializing for next cycle
    let self['cat_start_con_idx'] = 0
    let self['msg'] = ''
  elseif self['cat_start_con_idx'] < len(self['cat_start_con']) - 1
    " Count up start condition while satisfing the condition
    let self['cat_start_con_idx'] += 1
    let self['msg'] = ''
  else
    " Initialize data
    let self['msg'] = s:list[s:idx]
    let self['s4x_cat_fin']['cat_fin_con_idx'] = 0
    let self['cat_status'] = self['s4x_cat_fin']['qf_cat_fin_status']()
  endif
  return self['cat_status']
endfunc

function! s:qf_cat_fin_status() dict
  let l:cat_fin_con_len = len(self['cat_fin_con'])
  if l:cat_fin_con_len < 1
    let self['cat_fin_con_idx'] = 0
  elseif s:is_str_equal(s:list[s:idx], self['cat_fin_con'][self['cat_fin_con_idx']])
    if self['cat_fin_con_idx'] >= l:cat_fin_con_len - 1
      let self['cat_fin_con_idx'] = 0
      return s:status['finish']
    else
      let self['cat_fin_con_idx'] += 1
    endif
  else
    let self['cat_fin_con_idx'] = 0
  endif
  return s:status['start']
endfunc

function! s:qf_mode(fpath) dict
  if self['mode_status'] == s:status['start']
  elseif s:mode == s:status['start']
    return
  elseif !s:is_str_equal(s:list[s:idx], self['mode_start_con'][self['mode_start_con_idx']])
    let self['mode_start_con_idx'] = 0
    return
  elseif self['mode_start_con_idx'] < len(self['mode_start_con']) - 1
    let self['mode_start_con_idx'] += 1
    return
  else
    let s:mode = s:status['start']
    let self['mode_status'] = s:status['start']
    let self['s4x_qf_cat_msg']['cat_start_con_idx'] = 0
    let self['s4x_qf_cat_msg']['msg'] = ''
    let self['s4x_qf_cat_line']['cat_start_con_idx'] = 0
    let self['s4x_qf_cat_line']['msg'] = ''
    "let self['s4x_qf_cat_msg']['cat_start_con_idx'] = 0
    "let self['s4x_qf_cat_msg']['s4x_cat_fin']['msg'] = ''
    "let self['s4x_qf_cat_line']['cat_start_con_idx'] = 0
    "let self['s4x_qf_cat_line']['s4x_cat_fin']['msg'] = ''
    let self['s4x_mode_fin']['cat_fin_con_idx'] = 0
  endif

  " Get the results of err/warn message and line no
  let l:msg_status = self['s4x_qf_cat_msg']['qf_cat_status']()
  let l:line_status = self['s4x_qf_cat_line']['qf_cat_status']()
  let self['mode_status'] = self['s4x_mode_fin']['qf_cat_fin_status']()
  if l:msg_status == 2 && l:line_status == 2 || self['mode_status'] == 2
    " Initialize s4x_qf_cat_dict class parameter for next cycle.
    let self['s4x_qf_cat_msg']['cat_status'] = s:status['not_start']
    let self['s4x_qf_cat_line']['cat_status'] = s:status['not_start']
    let s:mode = s:status['not_start']
    let self['mode_status'] = s:status['not_start']
    " Rewrite to quickfix list if there are any message.
    if a:fpath != '' || self['s4x_qf_cat_line']['msg'] != '' || self['s4x_qf_cat_msg']['msg'] != ''
      call s:qfdict['categorize_msg']({'type' : self['level'],
	\	'filename' : a:fpath,
	\	'lnum' : self['s4x_qf_cat_line']['msg'],
	\	'text' : trim(self['s4x_qf_cat_msg']['msg'])})
    endif
  endif
endfunc

function! s:categorize_msg(newItem) dict
  if a:newItem['type'] == 'E'
    let self['errlist'] += [a:newItem]
  elseif a:newItem['type'] == 'W'
    let self['warnlist'] += [a:newItem]
  else
    let self['infolist'] += [a:newItem]
  endif
endfunc

let s:qfdict = {'categorize_msg': function("s:categorize_msg"),
	\	'errlist': [],
	\	'warnlist': [],
	\	'infolist': [],
	\	'winid': 0}

function s:ltrim(list) abort
  let l:str = trim(a:list[0])
  let l:after = ''
  let l:len_str = strchars(l:str)
  if strcharpart(l:str,0,1) == "'"
    let l:start = 1
  else
    let l:start = 0
  endif
  if strcharpart(l:str,l:len_str - 1,1) == "'"
    let l:length = l:len_str - l:start - 1
  else
    let l:length = l:len_str - l:start
  endif
  let l:after = strcharpart(l:str,l:start,l:length)

  let l:list = a:list
  let l:list[0] = l:after
  "echo l:after
endfunc

function s:sub_make_status(list) dict
  let l:list = a:list
  if !self['sub_make_cat']['cat_status'] && s:mode
    return 0
  endif
  call self['sub_make_cat']['qf_cat_status']()
  let l:dir_status = self['sub_make_cat']['cat_status']
  if l:dir_status == 2
    let self['sub_make_cat']['cat_status'] = 0
    let self['sub_make_cat']['cat_start_con_idx'] = 0
    let l:dir = self['sub_make_cat']['msg']
    let l:list[0] = l:dir
    call s:ltrim(l:list)
    let s:mode = 0
    return 1
  elseif l:dir_status == 1
    let s:mode = 1
  endif
  return 0
endfunc

function! s:is_str_equal(str, pattern) abort
  let l:list = matchstrpos(a:str, a:pattern)
  return (!l:list[1]) && (l:list[2] == len(a:str)) && (a:pattern != '')
endfunc

let &cpo = s:save_cpo
unlet s:save_cpo


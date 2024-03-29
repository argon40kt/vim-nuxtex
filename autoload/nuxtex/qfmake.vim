
"set re=0

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
endfunc

function! nuxtex#qfmake#qf_init() abort
  call s:qf_object['init']()
endfunc

function! nuxtex#qfmake#loc_init() abort
  call s:loc_object['init']()
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
  let l:pattern = '\([()]\@1<=\|\ze[()]\)\|^! \zs\|[0-9]\([0-9]\)\@!\zs\|^Overfull\zs\|\ze\(line\)\|[^0-9]\([0-9]\)\@=\zs\|\(warning:\)\c\zs\|\ze\.'
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
  let s:status = {'not_start': 0, 'start': 1, 'finish': 2}
  let s:idx = 0
  let s:mode = s:status['not_start']
" Execute tree() analysis while all phrase analysis has not been done.
  while v:true
    call s:tree()
    if s:idx >= len(s:list) - 1
      return
    endif
    let s:idx += 1
  endwhile
endfunc

function! s:tree() abort
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

" Set msg and line no select parameter
  let l:s4x_qf_err['s4x_qf_cat_msg']['cat_start_con'] = ['\s*!\s*']
  let l:s4x_qf_err['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  let l:s4x_qf_err['s4x_qf_cat_line']['cat_start_con'] = ["\n", '\s*l\.\s*', '\s*[0-9]\+\s*']
  let l:s4x_qf_err['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['\s*[0-9]\+\s*']
  let l:s4x_qf_overfull['s4x_qf_cat_msg']['cat_start_con'] = ['\s*\(overfull\)\c\s*']
  let l:s4x_qf_overfull['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ["\n"]
  "let l:s4x_qf_overfull['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = [".*).*"]
  let l:s4x_qf_overfull['s4x_qf_cat_line']['cat_start_con'] = ['\s*lines\s*', '\s*[0-9]\+\s*']
  let l:s4x_qf_overfull['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['\s*[0-9]\+\s*']
  let l:s4x_qf_warn['s4x_qf_cat_msg']['cat_start_con'] = ['\s*\(latex\)\c\s\+\(\(font\)\c\s\+\)\=\(warning\)\c:\s*']
  let l:s4x_qf_warn['s4x_qf_cat_msg']['s4x_cat_fin']['cat_fin_con'] = ['\s*\.\s*']
  let l:s4x_qf_warn['s4x_qf_cat_line']['cat_start_con'] = ['\s*line\s*', '\s*[0-9]\+\s*']
  let l:s4x_qf_warn['s4x_qf_cat_line']['s4x_cat_fin']['cat_fin_con'] = ['\s*[0-9]\+\s*']

" Set each mode global parameter
  let l:s4x_qf_err['level'] = 'E'
  let l:s4x_qf_err['mode_start_con'] = ['\s*!\s*']
  let l:s4x_qf_overfull['s4x_mode_fin']['cat_fin_con'] = ["\n"]
  let l:s4x_qf_overfull['mode_start_con'] = ['\(overfull\)\c']
  let l:s4x_qf_warn['mode_start_con'] = ['\s*\(latex\)\c\s\+\(\(font\)\c\s\+\)\=\(warning\)\c:\s*']
  let l:s4x_qf_warn['s4x_mode_fin']['cat_fin_con'] = ["\n", "\n"]

"File path getting function definition
  let l:s4x_qf_cat_file = {'file_status': function("s:file_status"),
	\	'mode_status': s:status['start'],
	\	'tmp': 0,
	\	'file': ''}
  let l:s4x_qf_file = deepcopy(l:s4x_qf_cat_file)

  while v:true
    if l:s4x_qf_file['file_status']()
    elseif s:mode
      call l:s4x_qf_err['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_overfull['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_warn['qf_mode'](l:s4x_qf_file['file'])
    elseif trim(s:list[s:idx]) == '('
      let s:idx += 1
      call s:tree()
    elseif trim(s:list[s:idx]) == ')'
      return
    else
      call l:s4x_qf_err['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_overfull['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_warn['qf_mode'](l:s4x_qf_file['file'])
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
  elseif s:is_str_equal(s:list[s:idx], self['cat_fin_con'][self['cat_fin_con_idx']])
    if self['cat_fin_con_idx'] >= l:cat_fin_con_len - 1
      let self['cat_fin_con_idx'] = s:status['not_start']
      return s:status['finish']
    else
      let self['cat_fin_con_idx'] += 1
    endif
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
    " Rewrite to quickfix list.
    call s:qfdict['categorize_msg']({'type' : self['level'],
	\	'filename' : a:fpath,
	\	'lnum' : self['s4x_qf_cat_line']['msg'],
	\	'text' : trim(self['s4x_qf_cat_msg']['msg'])})
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

function! s:is_str_equal(str, pattern) abort
  let l:list = matchstrpos(a:str, a:pattern)
  return (!l:list[1]) && (l:list[2] == len(a:str))
endfunc


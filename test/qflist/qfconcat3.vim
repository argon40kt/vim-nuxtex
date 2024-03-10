
let s:script_directory = expand('<sfile>:p:h')
exec 'source ' . s:script_directory . '/qflist/qferr.txt'
"exec 'source ' . s:script_directory . '/qflist/qfwarn1.txt'
"exec 'source ' . s:script_directory . '/qflist/qfwarn2.txt'

set re=0
let s:status = {'not_start': 0, 'start': 1, 'finish': 2}

function! s:qfconcat()
  call setqflist([], ' ', {'title' : 'my test', 'context' : ''})
  let g:qfid = getqflist({'id' : 0}).id
  let s:idx = 0
  let s:mode = s:status['not_start']
  let s:qfdict['errlist'] = []
  let s:qfdict['warnlist'] = []
  call s:preprocesser()
  call s:tree_monitor()
  call s:update_qflist()
endfunc

function! s:update_qflist()
  "for qfdict in s:qfdict['errlist']
  "  call setqflist([], 'a', qfdict)
  "endfor
  "for qfdict in s:qfdict['warnlist']
  "  call setqflist([], 'a', qfdict)
  "endfor
  let l:qflist = s:qfdict['errlist'] + s:qfdict['warnlist']
  call setqflist([], 'a', {'id': g:qfid, 'items': l:qflist})
endfunc

function! s:preprocesser()
  let l:index = 0
  let g:list = []
  let g:text = ''
  let l:pattern = '\([()]\@1<=\|\ze[()]\)\|^! \zs\|[0-9]\([0-9]\)\@!\zs\|^Overfull\zs\|\ze\(line\)\|[^0-9]\([0-9]\)\@=\zs\|\(warning:\)\c\zs\|\ze\.'
  "let l:pattern = '\([()]\@1<=\|\ze[()]\)\|^! \zs\|[0-9]\([0-9]\)\@!\zs\|^Overfull\zs\|\ze\(line\)\|[^0-9]\([0-9]\)\@=\zs'
  "let l:pattern = '^! \zs\|[0-9]\([0-9]\)\@!\zs\|^Overfull\zs\|\ze\(lines\s\+\([0-9]\+\)\)\|[^0-9]\([0-9]\)\@=\zs\|\([()]\@1<=\|\ze[()]\)'
  while l:index < len(g:qflist)
    let g:list += split(g:qflist[l:index].text, l:pattern) + ["\n"]
    let g:text .= g:qflist[l:index].text . "\n"
    let l:index = l:index + 1
  endwhile
  "echo g:text
endfunc

function! s:tree_monitor() abort
" Execute tree() analysis while all phrase analysis has not been done.
  while v:true
    call s:tree()
    if s:idx >= len(g:list) - 1
      "let g:last_phrase = g:list[s:idx - 1]
      return
    endif
    "let g:redo = 1
    "echo g:redo
    let s:idx += 1
  endwhile
endfunc

function! s:tree() abort
" Define class (Dictionary(function))
  let l:s4x_qf_cat_fin_dict = {'qf_cat_fin_status': function("s:qf_cat_fin_status"),
		\	'cat_fin_con': [],
		\	'cat_fin_con_idx': 0}
		"\	'msg': ''}
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
  let l:s4x_qf_file = {'file_status': function("s:file_status"),
	\	'mode_status': s:status['start'],
	\	'tmp': 0,
	\	'file': ''}

  "while s:idx < len(g:list)
  while v:true
    if l:s4x_qf_file['file_status']()
    elseif s:mode
      call l:s4x_qf_err['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_overfull['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_warn['qf_mode'](l:s4x_qf_file['file'])
    elseif trim(g:list[s:idx]) == '('
      let s:idx += 1
      call s:tree()
    elseif trim(g:list[s:idx]) == ')'
      return
    else
      call l:s4x_qf_err['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_overfull['qf_mode'](l:s4x_qf_file['file'])
      call l:s4x_qf_warn['qf_mode'](s4x_qf_file['file'])
    endif
    if s:idx >= len(g:list) - 1
      return
    endif
    let s:idx += 1
  endwhile
endfunc

function! s:file_status() dict
  if self['mode_status'] == s:status['start']
    let s:mode = s:status['start']
    if s:is_str_equal(g:list[s:idx], "\n")
    "if !match(g:list[s:idx], "\n")
      " Did not found actual file name in the section
      let self['file'] = ''
      if self['tmp'] > 0
        "Goto back point. This case is not err/warn msg block
        let s:idx = self['tmp'] - 1
      endif
      " Finish file search mode but file was not found
      let self['mode_status'] = s:status['not_start']
      let s:mode = s:status['not_start']
    else
      let self['file'] .= g:list[s:idx]
      if filereadable(self['file'])
        " Finish file search mode because file has been found
        let self['mode_status'] = s:status['not_start']
        let s:mode = s:status['not_start']
      elseif s:is_str_equal(trim(g:list[s:idx]), '[()]') && self['tmp'] == 0
        " Keep back point for file not found case
        let self['tmp'] = s:idx
      endif
    endif
  endif
  return self['mode_status']
endfunc

"function! s:qf_cat_status() dict
"  if self['cat_status'] == s:status['start']
"  "echo 'pattern 1'
"    " Collect msg/line no
"    let self['msg'] .= g:list[s:idx]
"    let self['cat_status'] = self['s4x_cat_fin']['qf_cat_fin_status']()
"  elseif self['cat_status'] == s:status['finish']
"  "echo 'patttern 2'
"  elseif s:is_str_equal(g:list[s:idx], self['cat_start_con'][self['cat_start_con_idx']])
"  " Match start data collection condition partialy/fully
"    if self['cat_start_con_idx'] >= len(self['cat_start_con']) - 1
"  "echo 'patttern 3'
"      " Initialize data
"      let self['s4x_cat_fin']['cat_fin_con_idx'] = 0
"      let self['msg'] = g:list[s:idx]
"      "let self['s4x_cat_fin']['msg'] = ''
"      " Collect msg/line no
"      let self['cat_status'] = self['s4x_cat_fin']['qf_cat_fin_status']()
"    else
"  "echo 'patttern 4'
"      let self['cat_start_con_idx'] += 1
"    endif
"  else
"    " Initializing for next cycle
"  "echo 'patttern 5'
"    let self['cat_start_con_idx'] = 0
"  endif
"  return self['cat_status']
"endfunc

function! s:qf_cat_status() dict
  if self['cat_status'] == s:status['start']
    " Collect msg/line no
    let self['msg'] .= g:list[s:idx]
    let self['cat_status'] = self['s4x_cat_fin']['qf_cat_fin_status']()
  elseif self['cat_status'] == s:status['finish']
    " Initializing for next cycle
    let self['cat_start_con_idx'] = 0
    "let self['msg'] = ''
  elseif !s:is_str_equal(g:list[s:idx], self['cat_start_con'][self['cat_start_con_idx']])
    " Initializing for next cycle
    let self['cat_start_con_idx'] = 0
    let self['msg'] = ''
  elseif self['cat_start_con_idx'] < len(self['cat_start_con']) - 1
    " Count up start condition while satisfing the condition
    let self['cat_start_con_idx'] += 1
    let self['msg'] = ''
  else
    " Initialize data
    let self['msg'] = g:list[s:idx]
    let self['s4x_cat_fin']['cat_fin_con_idx'] = 0
    let self['cat_status'] = self['s4x_cat_fin']['qf_cat_fin_status']()
  endif
  return self['cat_status']
endfunc

function! s:qf_cat_fin_status() dict
  "let self['msg'] .= g:list[s:idx]
  let l:cat_fin_con_len = len(self['cat_fin_con'])
  "echo self['cat_fin_con']
  if l:cat_fin_con_len < 1
  elseif s:is_str_equal(g:list[s:idx], self['cat_fin_con'][self['cat_fin_con_idx']])
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
  elseif !s:is_str_equal(g:list[s:idx], self['mode_start_con'][self['mode_start_con_idx']])
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
"echo g:list[s:idx]
  endif

  " Get the results of err/warn message and line no
  let l:msg_status = self['s4x_qf_cat_msg']['qf_cat_status']()
  let l:line_status = self['s4x_qf_cat_line']['qf_cat_status']()
  let self['mode_status'] = self['s4x_mode_fin']['qf_cat_fin_status']()
  "echo l:msg_status
  "echo l:line_status
  if l:msg_status == 2 && l:line_status == 2 || self['mode_status'] == 2
    " Initialize s4x_qf_cat_dict class parameter for next cycle.
    let self['s4x_qf_cat_msg']['cat_status'] = s:status['not_start']
    let self['s4x_qf_cat_line']['cat_status'] = s:status['not_start']
    let s:mode = s:status['not_start']
    let self['mode_status'] = s:status['not_start']
    " Rewrite to quickfix list.
    let l:text = self['s4x_qf_cat_msg']['msg']
    let l:lnum = self['s4x_qf_cat_line']['msg']
    "let l:text = self['s4x_qf_cat_msg']['s4x_cat_fin']['msg']
    "let l:lnum = self['s4x_qf_cat_line']['s4x_cat_fin']['msg']
    let l:newItems = [{'type' : self['level'],
	\	'filename' : a:fpath,
	\	'lnum' : l:lnum ,
	\	'text' : trim(l:text)}]
    "call setqflist([], 'a', {'id' : g:qfid, 'items': l:newItems})
    call s:qfdict['categorize_msg'](l:newItems)
  endif
endfunc

function! s:categorize_msg(newItems) dict
  if a:newItems[0]['type'] == 'E'
    "let self['errlist'] += [{'id' : g:qfid, 'items': a:newItems}]
    let self['errlist'] += a:newItems
  else
    "let self['warnlist'] += [{'id' : g:qfid, 'items': a:newItems}]
    let self['warnlist'] += a:newItems
  endif
endfunc

let s:qfdict = {'categorize_msg': function("s:categorize_msg"),
	\	'errlist': [],
	\	'warnlist': []}

function! s:is_str_equal(str, pattern) abort
  return !len(split(a:str, a:pattern))
endfunc

call s:qfconcat()

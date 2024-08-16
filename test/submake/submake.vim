let s:status = {'not_start': 0, 'start': 1, 'finish': 2}
let s:mode = 0
let s:list = ['make:', ' ', 'Entering', ' ', 'directory', ' ',
	\  "'/path/to/source'", "\n", '適当なメッセージ', "\n",
	\  'Trial', ' ', 'comment', "\n",
	\  'make:', ' ', 'Leaving', ' ', 'directory', ' ',
	\  "'/path/to/source'", "\n"]
let s:idx = 0
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

function s:ltrim(list) abort
  let l:str = trim(a:list[0])
  "echo l:str
  "echo strcharpart(l:str,0,1)
  "echo strchars(l:str)
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

  "echo l:after
  "echo strchars(l:after)
  let l:list = a:list
  let l:list[0] = l:after
endfunc
"let s:list = ["''ab'あいうcdeえお"]
"call s:ltrim(s:list)
"echo s:list[0]
"echo strchars(s:list[0])
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

function s:tree() abort
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
  let l:s4x_qf_sub_make = {'sub_make_status': function("s:sub_make_status"),
	  	\	'sub_make_cat': deepcopy(l:s4x_qf_cat_dict)}

" Construnction
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
  let l:list = ['']
  while s:idx < len(s:list)
    let l:list[0] = s:list[s:idx]
    if l:sub_make_in['sub_make_status'](l:list) || l:make_C_in['sub_make_status'](l:list)
      echo "Go to directory: " . l:list[0]
    elseif l:sub_make_out['sub_make_status'](l:list) || l:make_C_out['sub_make_status'](l:list)
      echo "Get out from directory: " . l:list[0]
    endif
    let s:idx += 1
  endwhile
endfunc

call s:tree()

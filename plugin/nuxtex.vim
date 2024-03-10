
if exists("g:did_nuxtex")
	finish
endif
let g:did_nuxtex = 1

let s:save_cpo = &cpo
set cpo&vim
filetype plugin on

"if !hasmapto('<Plug>NuxtexSyncsrcEnd')
"	map <unique><nowait> <leader><leader>ne <Plug>NuxtexSyncsrcEnd
"endif
"noremap <silent><unique><script> <Plug>NuxtexSyncsrcEnd :call nuxtex#backward#end_syncsrc()<CR>
command! NuxtexBackwardEnd call nuxtex#backward#end_syncsrc()
command! NuxtexBackwardStatus call nuxtex#backward#status_syncsrc()

"map <unique> <Leader>sl <C-\><C-n>:call nuxtex#backward#init()<CR>

augroup sync_Window
	autocmd!
	autocmd BufWinEnter * call s:win_log_StartUp()
	autocmd WinEnter * call s:renew_Window()
	autocmd BufHidden * call s:Window_Removed()
augroup END

function s:win_log_StartUp() abort
	let l:cur_winID = win_getid()
	let l:cur_bufNum = winbufnr(l:cur_winID)
	if exists("s:old_window_Buffer")
		let s:last_window_Buffer = copy(s:old_window_Buffer)
		let s:last_window_Buffer[l:cur_bufNum] = l:cur_winID
	else
		let s:last_window_Buffer = {}
		let s:last_window_Buffer[l:cur_bufNum] = l:cur_winID
	endif
	"let g:last_window_Buffer = copy(s:last_window_Buffer)
"	echo s:last_window_Buffer
endfunction

function s:renew_Window() abort
	if exists("s:last_window_Buffer")
		let s:old_window_Buffer = copy(s:last_window_Buffer)
	endif
	let l:cur_winID = win_getid()
	let l:cur_bufNum = winbufnr(l:cur_winID)
	let s:last_window_Buffer[l:cur_bufNum] = l:cur_winID
	"let g:last_window_Buffer = copy(s:last_window_Buffer)
"	echo s:last_window_Buffer
endfunction

function s:Window_Removed() abort
	for l:Key in keys(s:last_window_Buffer)
		if !bufloaded(l:Key)
			call remove(s:last_window_Buffer, l:Key)
		endif
	endfor
	"let g:last_window_Buffer = copy(s:last_window_Buffer)
"	echo s:last_window_Buffer
endfunction

function g:Last_Window_Buffer() abort
  return copy(s:last_window_Buffer)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

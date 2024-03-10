
let s:script_directory = expand('<sfile>:p:h')

function nuxtex#backward#init() abort

	if exists('s:synctex_syncsrc_process')
		return
	endif
	if !has('nvim') && !has('job')
		echoerr "vim-nuxtex requires +job if you set 'let g:nuxtex_viewer_type = 'evince' / 'atril' / 'xreader' / 'zathura'"
		finish
	endif

	call nuxtex#backward#python3cmd()
	let l:SyncSourcePyCmd = g:nuxtex_python_cmd . ' ' . s:script_directory . '/Receiver.py'

	if has('nvim')
		let s:synctex_syncsrc_process = jobstart(l:SyncSourcePyCmd, {'on_stdout' : function('s:SyncSourceStdOutNvim')})
	else
		let s:synctex_syncsrc_process = job_start(l:SyncSourcePyCmd, {'callback' : 'nuxtex#backward#syncsrc_vim'})
	endif

endfunction

function nuxtex#backward#python3cmd()
	if !exists('g:nuxtex_python_cmd')
		let g:nuxtex_python_cmd = 'python3'
	endif
endfunction

function s:SyncSourceStdOutNvim(ch, callback, opt) dict
	" echo a:callback
	call s:SyncSourceStdOut(a:callback[0])
endfunction

function nuxtex#backward#syncsrc_vim(ch, callback) abort
	call s:SyncSourceStdOut(a:callback)
endfunction

function s:SyncSourceStdOut(callback) abort

	let l:callback = split(a:callback, '|')
	try
		let l:viewer = l:callback[3]
		"exec '!echo g:nuxtex_viewer_type = ' . g:nuxtex_viewer_type . ' >> $HOME/synctex.log'
		"exec '!echo l:viewer = ' . l:viewer . ' >> $HOME/synctex.log'
		if l:viewer ==# g:nuxtex_viewer_type
			let l:file = l:callback[0]
			let l:line = str2nr(l:callback[1])
			let l:col = str2nr(l:callback[2])
			call s:cursor_travel(l:file, l:line, l:col)
		endif
	catch
	endtry
endfunction

function nuxtex#backward#status_syncsrc() abort
	if !exists('s:synctex_syncsrc_process')
		echo "Backward search receiver is not running"
		return 0
	endif
	echo s:synctex_syncsrc_process
endfunction

function nuxtex#backward#end_syncsrc() abort
	if !exists('s:synctex_syncsrc_process')
		echo "Backward search receiver is not running"
		return 0
	endif
	if has('nvim')
			call jobstop(s:synctex_syncsrc_process)
	else
			call job_stop(s:synctex_syncsrc_process)
	endif
	echo "Backward search receiver proccess was stopped"
	unlet! s:synctex_syncsrc_process
	return 1
endfunction

function s:cursor_travel(file, line, col) abort

	if has('win32') && !has('nvim')
		"call foreground()
		call remote_foreground(v:servername)
	else
		call foreground()
	endif

	let l:source_buf_nr = bufnr(a:file)
	let l:source_win_id = win_findbuf(l:source_buf_nr)
"	call ch_log(l:source_win_id)

"Check whether window exists
	if !empty(l:source_win_id)

		"Check whether window cursor log exists
		"if has_key(g:last_window_Buffer, l:source_buf_nr)
		if has_key(g:Last_Window_Buffer(), l:source_buf_nr)

			"Check whether window cursor log is true
			"if l:source_buf_nr == winbufnr(g:last_window_Buffer[l:source_buf_nr])
			"	call win_gotoid(g:last_window_Buffer[l:source_buf_nr])
			if l:source_buf_nr == winbufnr(g:Last_Window_Buffer()[l:source_buf_nr])
				call win_gotoid(g:Last_Window_Buffer()[l:source_buf_nr])
			else
				let s:last_window_buffer = {}
				call win_gotoid(l:source_win_id[0])
				echom 'Records of last actived windows of the buffers was reset.' |
			endif
		else
			call win_gotoid(l:source_win_id[0])
		endif

		call cursor(a:line , 1)
		redraw!
		echo a:file . ', ' . a:line . ':' . a:col
	elseif l:source_buf_nr >=0
		if !exists('g:nuxtex_open_method')
			let g:nuxtex_open_method = 't'
		endif
		if g:nuxtex_open_method == 't'
			tabnew
		elseif g:nuxtex_open_method == 'h'
			vs
		elseif g:nuxtex_open_method == 'j'
			split
			wincmd j
		elseif g:nuxtex_open_method == 'k'
			split
		elseif g:nuxtex_open_method == 'l'
			vs
			wincmd l
		elseif g:nuxtex_open_method == 'H'
			vertical topleft split
		elseif g:nuxtex_open_method == 'J'
			botright split
		elseif g:nuxtex_open_method == 'K'
			topleft split
		elseif g:nuxtex_open_method == 'L'
			vertical botright split
		elseif g:nuxtex_open_method == 'c'
		else
			echoerr 'Unknown option g:nuxtex_open_method = ' . g:nuxtex_open_mathod
		endif
"		call ch_log(a:file)
		execute 'buffer!' . l:source_buf_nr

		call cursor(a:line , 1)
		redraw!
		echo a:file . ', ' . a:line . ':' . a:col
	else
		echo a:file . ', ' . a:line . ':' . a:col . ' is not stored in buffer.'
	endif
endfunction


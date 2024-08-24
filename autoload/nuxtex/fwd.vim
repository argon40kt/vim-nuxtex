
function nuxtex#fwd#check_to_pdf() abort
	let l:files = s:get_outputfile()

	if l:files['pdf'] == ''
		return
	endif

	"echo s:modify_pdf_cmd(l:files['src'], l:files['pdf'])
  if !exists('s:bufnr')
    let s:bufnr = bufadd('')
  elseif !bufexists(s:bufnr)
    let s:bufnr = bufadd('')
  endif
  call bufload(s:bufnr)
  call deletebufline(s:bufnr,1,'$')
  call appendbufline(s:bufnr,0,s:modify_pdf_cmd(l:files['src'], l:files['pdf']))
  if bufwinid(s:bufnr) < 0
    5split
    exec 'buf ' . s:bufnr
    set ro
  endif
"echo s:bufnr
endfunction

function nuxtex#fwd#jump_to_pdf() abort
	let l:files = s:get_outputfile()

	if l:files['pdf'] == ''
		return
	endif
	call s:exec_pdf_view(files['src'],files['pdf'])
	call nuxtex#backward#init()
endfunction

function s:get_outputfile() abort
	if !exists('g:nuxtex_viewer_type')
		let g:nuxtex_viewer_type = 'evince'
	"	let g:nuxtex_viewer_type = 'manual'
	endif

	let l:input_src = expand("%:p")
	if has('win32')
		let l:input_src = substitute(l:input_src, '/', '\', 'g')
	endif

	"Using manual setting of pdf.
	if exists('b:nuxtex_output_pdf')
		if filereadable(b:nuxtex_output_pdf)
			let l:output_pdf = fnamemodify(b:nuxtex_output_pdf, ":p")
			return {'src' : l:input_src, 'pdf' : l:output_pdf}
		else
			echoerr "b:nuxtex_output_pdf = '" .  b:nuxtex_output_pdf . "' does not exist." |
			echoerr 'Set true path of pdf file in b:nuxtex_output_pdf or unlet the variable.'
			return {'src' : l:input_src, 'pdf' : ''}
		endif
	endif

	" Extracting '%!TeX root' in source file.
	let l:root_exists = s:tex_root()
	if l:root_exists == ''
		" '%!TeX root' path is incorrect.
		return {'src' : l:input_src, 'pdf' : ''}
	endif

	"Auto output searching depends on "gzip" command.
	if exists('g:nuxtex_gzip_path')
		let l:gzip_cmd = g:nuxtex_gzip_path
		if !executable(l:gzip_cmd)
			echoerr '"gzip" command was not found in g:nuxtex_gzip_path = ' .
			\ "'" . g:nuxtex_gzip_path . "'"
			return {'src' : l:input_src, 'pdf' : ''}
		endif
	else
		let l:gzip_cmd = 'gzip'
	endif

	"If gzip command is not found, output pdf file name is guessed by
	"source file name.
	if !exists('g:nuxtex_gz_parse')
		let g:nuxtex_gz_parse = v:true
	endif
	if g:nuxtex_gz_parse != v:true && g:nuxtex_gz_parse != v:false
		echoerr 'Unknown option of g:nuxtex_gz_parse = "' . g:nuxtex_gz_parse . '"'
		return {'src' : l:input_src, 'pdf' : ''}
	endif
	if !executable(l:gzip_cmd) || g:nuxtex_gz_parse == v:false
		let l:output_pdf = fnamemodify(l:root_exists, ':p:r') . '.pdf'
		if filereadable(l:output_pdf)
			return {'src' : l:input_src, 'pdf' : l:output_pdf}
		else
			echo l:output_pdf . ' was not found.' |
			echo 'I recommend you to set up "gzip" command to enable auto search output pdf' |
			echo 'or you can set b:nuxtex_output_pdf.'
			return {'src' : l:input_src, 'pdf' : ''}
		endif
	else
		let l:gzip_cmd = l:gzip_cmd . ' -cdk '
	endif

	let l:old_dir = getcwd()

	exe 'lcd ' . fnamemodify(l:root_exists, ':p:h')
	" Search synctex.gz file recurcively.
	while strchars(getcwd()) > 3
		let l:synctex_gz = glob(getcwd() . '/*.synctex.gz', '', v:true)
		"echo getcwd() |

		" Search all synctex.gz file on the directory.
		for l:synctex_gz_file in l:synctex_gz
			echo shellescape(l:synctex_gz_file) . "\n"
			if !has('iconv') || !exists('g:nuxtex_sys_enc')
				let l:gzip_stdout = systemlist(l:gzip_cmd . shellescape(l:synctex_gz_file))
			else
				let l:gzip_stdout = split(iconv(system(l:gzip_cmd . '"' . l:synctex_gz_file . '"'), g:nuxtex_sys_enc, &enc), '\n')
			endif

			" Reading synctex.gz file.
			for l:gzip_stdout_line in l:gzip_stdout
				if match(l:gzip_stdout_line, "Input") != 0
					continue
				elseif match(l:gzip_stdout_line, "Output") == 0
					break
				endif

				if has('win32')
					let l:tex_src_drv = split(l:gzip_stdout_line,':')[2]
					let l:tex_src_drive = toupper(l:tex_src_drv)
					let l:tex_src_path = split(l:gzip_stdout_line,':')[3]
					" " Native source path described in synctex.gz.
					" let l:tex_src_native = l:tex_src_drv . ':' . l:tex_src_path
					" let l:tex_src_native = substitute(l:tex_src_native, '/', '\', 'g')

					let l:tex_src_input = l:tex_src_drive . ':' . l:tex_src_path
					let l:tex_src_input = simplify(l:tex_src_input)
					let l:tex_src_input = substitute(l:tex_src_input, '/', '\', 'g')
				else
					" Native source path described in synctex.gz.
					let l:tex_src_list = split(l:gzip_stdout_line,':\zs')
					let l:tex_src_native = ''
					let l:idx = 2
					while l:idx < len(l:tex_src_list)
						let l:tex_src_native .= l:tex_src_list[l:idx]
						let l:idx += 1
					endwhile
					"let l:tex_src_native = split(l:gzip_stdout_line,':')[2]
					echo l:tex_src_native
					let l:tex_src_input = simplify(l:tex_src_native)
				endif

				if simplify(l:input_src) == l:tex_src_input

					let l:synctex_file = fnamemodify(l:synctex_gz_file, ":p:r")
					let l:output_pdf = fnamemodify(l:synctex_file, ":p:r") . '.pdf'
					exe 'lcd ' .  l:old_dir
					return {'src' : l:tex_src_input, 'pdf' : l:output_pdf}
				endif
			endfor
		endfor

		lcd ../
	endwhile

	exe 'lcd ' .  l:old_dir

	echo '.synctex.gz file of ' . l:input_src . ' was not found in source directory and parent directories.' |
	\ echo 'If you use -synctex=1 option in compile, you can set "b:nuxtex_output_pdf".'

	return {'src' : l:input_src, 'pdf' : ''}
endfunction

function s:tex_root() abort
	let l:detect_src_list = [['%', '!', 'TeX', ' ', 'root', '='],
				\['%', '!', 'TEX', ' ', 'root', '=']]
	" '%! ... ' will be ignored.
	let l:detect_th_list = [2, 2]

	let l:current_src = expand("%:p")
	let l:line_num = 1
	while l:line_num != line('$') + 1
		let l:detect_th_idx = 0
		for l:detect_src in l:detect_src_list
			let l:detect_th = l:detect_th_list[l:detect_th_idx]
			let l:detect_th_idx += 1

			let l:detect_max = len(l:detect_src)
			let l:detect_idx = 0
			let l:mode = l:detect_src[l:detect_idx]

			let l:Line = trim(getline(l:line_num))
			let l:length = strchars(l:Line)
			let l:src_col = 0
			while l:src_col < l:length
				if l:mode == ''
					let l:modelen = 1
				else
					let l:modelen = strchars(l:mode)
				endif
				let l:char = strcharpart(l:Line, l:src_col, l:modelen)
				" echo l:mode . ') [' . l:char . '] ' . l:detect_idx |
				"Initial of current phrase.
				let l:topchar = strcharpart(l:char, 0, 1)
				let l:white_char = l:topchar != ' ' && l:topchar != '	'
				if l:detect_idx == l:detect_max && l:white_char
					" %!TeX root = exists on the top of source.
					let l:root_path = strcharpart(l:Line, l:src_col)
					return s:modify_src_path(l:root_path, l:current_src, l:Line)
				elseif l:topchar != strcharpart(l:mode, 0, 1) && l:white_char
					if l:detect_idx == l:detect_th
						" There are %! but not %!TeX root =.
						break
					endif
					" There are not %!TeX root = in top of source.
					return l:current_src
				elseif l:char == l:mode
					" Check next phrase.
					let l:detect_idx += 1
					let l:mode = get(l:detect_src, l:detect_idx, '')
					" Skip current phrase.
					let l:src_col += l:modelen - 1
				endif
				let l:src_col += 1
			endwhile
		endfor

		"Exit this function if %!TeX root = is not complete.
		"if l:detect_idx < l:detect_max && l:detect_idx > l:detect_th
		"	return l:current_src
		"endif
		let l:line_num += 1
	endwhile
endfunction

function s:modify_src_path(root_file, current_src, Line) abort
	let l:old_dir = getcwd()
	" Change directory to current source file.
	exe 'lcd ' . fnamemodify(a:current_src, ':p:h')
	" Get full path of root file.
	let l:root_file = fnamemodify(a:root_file, ':p')
	exe 'lcd ' . l:old_dir
	if filereadable(l:root_file)
		return l:root_file
	else
		echohl ErrorMsg
		echo a:Line . ' does not exist.' |
		echo 'Describe true path.'
		echoh None
		return ''
	endif
endfunction

let s:script_directory = expand('<sfile>:p:h')
function s:synctex_cmd_collection() abort
	call nuxtex#backward#python3cmd()

	if g:nuxtex_viewer_type == 'zathura'
		if !exists('g:nuxtex_zathura_cmd')
			let g:nuxtex_zathura_cmd = 'zathura'
		endif
		if !exists('g:nuxtex_zathura_opt')
			let g:nuxtex_zathura_opt = '--synctex-forward "@line:@col:@tex" "@pdf"'
		endif
		let l:viewer_native = g:nuxtex_zathura_cmd
		let l:viewer_opt = g:nuxtex_zathura_opt
	elseif g:nuxtex_viewer_type == 'evince' ||
	\	g:nuxtex_viewer_type == 'atril' ||
	\	g:nuxtex_viewer_type == 'xreader'
		let l:viewer_native = g:nuxtex_python_cmd
		let l:script = s:script_directory . '/fwdpy.py'
		let l:viewer_opt = l:script . ' ' .
			\	g:nuxtex_viewer_type .
			\	' "@line:@col:@tex" "@pdf"'
	else
		echoerr 'Unknown type of viewer g:nuxtex_viewer_type = "' . g:nuxtex_viewer_type . '".'
		return
	endif

	return l:viewer_native . ' ' . l:viewer_opt
endfunction

function s:synctex_extcmd_async(fwd_cmd) abort
	if has('win32')
		let l:start_cmd = 'start cmd /s /c "start "" '
		let l:fwd_cmd = l:start_cmd . a:fwd_cmd . '"'
	else
		let l:fwd_cmd = a:fwd_cmd . ' > /dev/null 2>&1 &'
	endif
	"silent exe '!' . l:fwd_cmd
	call system(l:fwd_cmd)
	redraw!
endfunction

function s:exec_pdf_view(input_src, output_pdf) abort
	let l:fwd_cmd = s:modify_pdf_cmd(a:input_src, a:output_pdf)
	if s:chk_viewer_cmd(l:fwd_cmd) == v:false
		return
	endif

	"let l:fwd_cmd = substitute(l:fwd_cmd, '%', '\\%', 'g')
	"let l:fwd_cmd = substitute(l:fwd_cmd, '#', '\\#', 'g')
	"let l:fwd_cmd = substitute(l:fwd_cmd, '!', '\\!', 'g')
	call s:synctex_extcmd_async(l:fwd_cmd)
	"echo l:fwd_cmd
endfunction

function s:chk_viewer_cmd(fwd_cmd) abort
	let l:cmd_part = trim(a:fwd_cmd)
	if strcharpart(l:cmd_part, 0, 1) == '"'
		let l:exe_path = split(l:cmd_part, '"')[0]
		let l:exe_path_print = '"' . l:exe_path . '"'
	else
		let l:exe_path = split(l:cmd_part)[0]
		let l:exe_path_print = l:exe_path
	endif

	if !executable(l:exe_path)
		echohl ErrorMsg
		echo l:exe_path_print . ' is not executable.' |
		echo 'Try :NuxtexChkFwdCmd to check forward search command.' |
		echo 'And you should change settings of g:nuxtex_viewer_type or g:nuxtex_zathura_cmd.'
		echohl None
		return v:false
	endif
	return v:true
endfunction

function s:modify_pdf_cmd(input_src, output_pdf) abort
"TO DO embed fnameescape().
	let l:viewer_cmd = s:synctex_cmd_collection()
	let l:fwd_cmd = substitute(l:viewer_cmd, '@pdf', '\=a:output_pdf', 'g')
	let l:fwd_cmd = substitute(l:fwd_cmd, '@line', line('.'), 'g')
	let l:fwd_cmd = substitute(l:fwd_cmd, '@col', col('.'), 'g')
	let l:fwd_cmd = substitute(l:fwd_cmd, '@tex', '\=a:input_src', 'g')

	return l:fwd_cmd
endfunction


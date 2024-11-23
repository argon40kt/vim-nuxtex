" vim-nuxtex is a LaTeX quickfix and SyncTeX plugin for Vim/Neovim on Linux
" Developper: Kenichi Takizawa
" License: MIT

let s:save_cpo = &cpo
setlocal cpo&vim

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
	if !executable(l:gzip_cmd) || !g:nuxtex_gz_parse
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
		let l:gzip_cmd = shellescape(l:gzip_cmd) . ' -cdk '
	endif

	let l:old_dir = getcwd()

	call chdir(fnamemodify(l:root_exists, ':p:h'))
	" Search synctex.gz file recurcively.
	while strchars(getcwd()) > 3
		" Search all synctex.gz file in the directory.
		for l:synctex_gz_file in glob(getcwd() . '/*.synctex.gz', '', v:true)
			"echo shellescape(l:synctex_gz_file) . "\n"
			if !has('iconv') || !exists('g:nuxtex_sys_enc')
				let l:gzip_stdout = systemlist(l:gzip_cmd . shellescape(l:synctex_gz_file))
			else
				let l:gzip_stdout = split(iconv(system(l:gzip_cmd . shellescape(l:synctex_gz_file)), g:nuxtex_sys_enc, &enc), '\n')
				"echo &enc . "\n"
			endif
			if s:read_synctex(l:gzip_stdout, l:input_src)
				let l:output_pdf = fnamemodify(l:synctex_gz_file, ":p:r:r") . '.pdf'
				call chdir(l:old_dir)
				return {'src' : l:input_src, 'pdf' : l:output_pdf}
			endif
		endfor
		" Search all synctex file in the directory.
		for l:synctex_file in glob(getcwd() . '/*.synctex', '', v:true)
			let l:synctex_read = readfile(l:synctex_file)
			if has('iconv') && exists('g:nuxtex_sys_enc')
				let l:idx = 0
				while l:idx < len(l:synctex_read)
					let l:synctex_read[l:idx] = iconv(l:synctex_read[l:idx], g:nuxtex_sys_enc, &enc)
					let l:idx += 1
				endwhile
			endif
			if s:read_synctex(l:synctex_read, l:input_src)
				let l:output_pdf = fnamemodify(l:synctex_file, ":p:r") . '.pdf'
				call chdir(l:old_dir)
				return {'src' : l:input_src, 'pdf' : l:output_pdf}
			endif
		endfor

		call chdir('../')
	endwhile

	call chdir(l:old_dir)

	echo '.synctex.gz or uncompresssed .synctex file of ' . l:input_src . ' was not found in source directory and parent directories.' |
	\ echo 'If you use -synctex=1 option in compile, you can set "b:nuxtex_output_pdf".'

	return {'src' : l:input_src, 'pdf' : ''}
endfunction

function s:read_synctex(synctex_line, input_src)
	" Reading synctex.gz file.
	for l:gzip_stdout_line in a:synctex_line
		if match(l:gzip_stdout_line, "Input") != 0
			continue
		endif

		" Native source path described in synctex.gz.
		let l:tex_src_list = split(l:gzip_stdout_line,':\zs')
		let l:tex_src_native = ''
		let l:idx = 2
		while l:idx < len(l:tex_src_list)
			let l:tex_src_part = l:tex_src_list[l:idx]
			if has('win32') && l:idx == 2
				let l:tex_src_part = toupper(l:tex_src_part)
			endif
			let l:tex_src_native .= l:tex_src_part
			let l:idx += 1
		endwhile
		"let l:tex_src_native = split(l:gzip_stdout_line,':')[2]
		"echo l:tex_src_native
		let l:tex_src_input = simplify(l:tex_src_native)
		if has('win32')
			let l:tex_src_input = substitute(l:tex_src_input, '/', '\', 'g')
		endif

		if simplify(a:input_src) == l:tex_src_input
			return v:true
		endif
	endfor
	return v:false
endfunction

function s:tex_root() abort
	let l:current_src = expand("%:p")
	let l:line_num = 1
	while l:line_num < line('$') + 1
		let l:Line = getline(l:line_num)
		let l:is_comment = matchstrpos(l:Line, '\s*\(%.*\)\=')
		if l:is_comment[1] || l:is_comment[2] != strlen(l:Line)
			" This line is not comment out.
			" So, return current source path.
			return l:current_src
		endif
		let l:tex_root = matchstrpos(l:Line, '\s*%\s*!\s*\(tex\)\c\s\+\(root\)\c\s*=')
		if !l:tex_root[1]
		" Found %!TeX root = ...
			let l:root_path = trim(strcharpart(l:Line, strchars(l:tex_root[0])))
			"if !match(l:root_path, "'")
			"	" TO DO: use ltrim() instead of trim()
			"	let l:root_path = trim(l:root_path, "'")
			"elseif !match(l:root_path, '"')
			"	" TO DO: use ltrim() instead of trim()
			"	let l:root_path = trim(l:root_path, '"')
			"endif
			return s:modify_src_path(l:root_path, l:current_src, l:Line)
		endif
		let l:line_num += 1
	endwhile
endfunction

function s:modify_src_path(root_file, current_src, Line) abort
	let l:old_dir = getcwd()
	" Change directory to current source file.
	call chdir(fnamemodify(a:current_src, ':p:h'))
	" Get full path of root file.
	let l:root_file = fnamemodify(a:root_file, ':p')
	call chdir(l:old_dir)
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
			let g:nuxtex_zathura_opt = '--synctex-forward @line:@col:@tex @pdf'
		endif
		let l:viewer_native = g:nuxtex_zathura_cmd
		let l:viewer_opt = g:nuxtex_zathura_opt
	elseif g:nuxtex_viewer_type == 'evince' ||
	\	g:nuxtex_viewer_type == 'atril' ||
	\	g:nuxtex_viewer_type == 'xreader'
		let l:viewer_native = g:nuxtex_python_cmd
		let l:script = shellescape(s:script_directory . '/fwdpy.py')
		let l:viewer_opt = l:script . ' ' .
			\	g:nuxtex_viewer_type .
			\	' @line:@col:@tex @pdf'
	else
		echoerr 'Unknown type of viewer g:nuxtex_viewer_type = "' . g:nuxtex_viewer_type . '".'
		return ''
	endif
	if !executable(l:viewer_native)
		echohl ErrorMsg
		echo l:viewer_native . ' is not executable.' |
		echo 'You should change settings of g:nuxtex_viewer_type or g:nuxtex_zathura_cmd.'
		echohl None
		return ''
	endif
	return shellescape(l:viewer_native) . ' ' . l:viewer_opt
endfunction

function s:exec_pdf_view(input_src, output_pdf) abort
	let l:fwd_cmd = s:modify_pdf_cmd(a:input_src, a:output_pdf)
	if l:fwd_cmd == ''
		return
	endif
	"let l:fwd_cmd = substitute(l:fwd_cmd, '%', '\\%', 'g')
	"let l:fwd_cmd = substitute(l:fwd_cmd, '#', '\\#', 'g')
	"let l:fwd_cmd = substitute(l:fwd_cmd, '!', '\\!', 'g')
	if has('win32')
		let l:start_cmd = 'start cmd /s /c "start "" '
		let l:fwd_cmd = l:start_cmd . l:fwd_cmd . '"'
	else
		let l:fwd_cmd = l:fwd_cmd . ' > /dev/null 2>&1 &'
	endif
	"silent exe '!' . l:fwd_cmd
	call system(l:fwd_cmd)
	redraw!
	"echo l:fwd_cmd
endfunction

function s:modify_pdf_cmd(input_src, output_pdf) abort
"TO DO embed fnameescape().
	if !exists('g:nuxtex_syncsrc_escape')
		let g:nuxtex_syncsrc_escape = v:true
	endif
	if g:nuxtex_syncsrc_escape
		let l:input_src = shellescape(a:input_src)
	else
		let l:input_src = a:input_src
	endif
	if !exists('g:nuxtex_syncpdf_escape')
		let g:nuxtex_syncpdf_escape = v:true
	endif
	if g:nuxtex_syncpdf_escape
		let l:output_pdf = shellescape(a:output_pdf)
	else
		let l:output_pdf = a:output_pdf
	endif
	let l:viewer_cmd = s:synctex_cmd_collection()
	if l:viewer_cmd == ''
		return ''
	endif
	let l:fwd_cmd = substitute(l:viewer_cmd, '@pdf', '\=l:output_pdf', 'g')
	let l:fwd_cmd = substitute(l:fwd_cmd, '@line', line('.'), 'g')
	let l:fwd_cmd = substitute(l:fwd_cmd, '@col', col('.'), 'g')
	let l:fwd_cmd = substitute(l:fwd_cmd, '@tex', '\=l:input_src', 'g')

	return l:fwd_cmd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo


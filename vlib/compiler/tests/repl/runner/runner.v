module runner

import os

struct RunnerOptions {
pub:
	wd string
	vexec string
	files []string
}

pub fn full_path_to_v(dirs_in int) string {
	vname := if os.user_os() == 'windows' { 'v.exe' } else { 'v' }
	mut path := os.executable()
	for i := 0; i < dirs_in; i++ {
		path = os.dir(path)
	}
	vexec := path + os.path_separator + vname
	/*
	args := os.args
	vreal  := os.realpath('v')
	myself := os.realpath( os.executable() )
	wd := os.getwd() + os.path_separator
	println('args are: $args')
	println('vreal   : $vreal')
	println('myself  : $myself')
	println('wd      : $wd')
    */	
	return vexec
}

fn find_working_diff_command() ?string {
	for diffcmd in ['colordiff', 'diff', 'colordiff.exe', 'diff.exe'] {
		p := os.exec('$diffcmd --version') or { continue }
		if p.exit_code == 0 { return diffcmd }
	}
	return error('no working diff command found')
}

fn diff_files( file_result, file_expected string ) string {
	diffcmd := find_working_diff_command() or { return err }
	diff := os.exec('$diffcmd   --minimal  --text   --unified=2  $file_result  $file_expected') or { return 'found diff command "$diffcmd" does not work' }
	return diff.output
}

pub fn run_repl_file(wd string, vexec string, file string) ?string {
	fcontent := os.read_file(file) or {	return error('Could not read file $file') }
	content := fcontent.replace('\r', '')		
	input := content.all_before('===output===\n')
	output := content.all_after('===output===\n')
	
	input_temporary_filename := 'input_temporary_filename.txt'
	os.write_file(input_temporary_filename, input)

	r := os.exec('"$vexec" runrepl < $input_temporary_filename') or {
		os.rm(input_temporary_filename)
		return error('Could not execute "$vexec runrepl < $input_temporary_filename" ')
	}
	os.rm(input_temporary_filename)

	result := r.output.replace('\r','').replace('>>> ', '').replace('>>>', '').replace('... ', '').all_after('Use Ctrl-C or `exit` to exit\n').replace(wd, '' )

	if result != output {
		file_result   := '${file}.result.txt'
		file_expected := '${file}.expected.txt'
		os.write_file( file_result, result )
		os.write_file( file_expected, output )
		diff := diff_files( file_result, file_expected )
		return error('Difference found in REPL file: $file
====> Got      :
|$result|
====> Expected :
|$output|
====> Diff     :
$diff
		')
	} else {
		return 'Repl file $file is OK'
	}
}

pub fn run_prod_file(wd string, vexec string, file string) ?string {
	file_expected := '${file}.expected.txt'
	f_expected_content := os.read_file(file_expected) or { return error('Could not read file $file') }
	expected_content := f_expected_content.replace('\r', '')		

	cmd := '"$vexec" -prod run "$file"'
	r := os.exec(cmd) or {
		return error('Could not execute: $cmd')
	}

	if r.exit_code != 0 {
		return error('$cmd return exit code: $r.exit_code')
	}

	result := r.output.replace('\r','')

	if result != expected_content {
		file_result   := '${file}.result.txt'
		os.write_file( file_result, result )
		diff := diff_files( file_result, file_expected )
		return error('Difference found in test: $file
====> Got      :
|$result|
====> Expected :
|$expected_content|
====> Diff     :
$diff
		')
	} else {
		return 'Prod file $file is OK'
	}
}

pub fn new_options() RunnerOptions {
	wd := os.getwd() + os.path_separator
	vexec := full_path_to_v(5)
	mut files := []string
	if os.args.len > 1 {
		files = os.args[1..]
	} else {
		files = os.walk_ext('.', '.repl')
	}
	return RunnerOptions {
		wd: wd
		vexec: vexec
		files: files
	}
}

pub fn new_prod_options() RunnerOptions {
	wd := os.getwd() + os.path_separator
	vexec := full_path_to_v(4)
	mut files := []string
	if os.args.len > 1 {
		files = os.args[1..]
	} else {
		files = os.walk_ext(wd, '.prod.v')
	}
	return RunnerOptions {
		wd: wd
		vexec: vexec
		files: files
	}
}


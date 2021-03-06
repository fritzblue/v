import os

fn main() {
	println('Updating V...')
	vroot := os.dir(os.args[1])
	os.chdir(vroot)
	s := os.exec('git -C "$vroot" pull --rebase origin master') or { panic(err) }
	println(s.output)
	$if windows {
		v_backup_file := '$vroot/v_old.exe'
		if os.file_exists( v_backup_file ) {
			os.rm( v_backup_file )
		}
		os.mv('$vroot/v.exe', v_backup_file)
		s2 := os.exec('"$vroot/make.bat"') or { panic(err) }
		println(s2.output)
	} $else {
		s2 := os.exec('make -C "$vroot"') or { panic(err) }
		println(s2.output)
	}
}

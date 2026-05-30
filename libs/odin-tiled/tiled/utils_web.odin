// Implementations of `read_entire_file` and `write_entire_file` using the libc
// stuff emscripten exposes. You can read the files that get bundled by
// `--preload-file assets` in `build_web` script.

#+build wasm32, wasm64p32

package tiled


import "base:runtime"
import "core:log"
import "core:c"
import "core:strings"

// These will be linked in by emscripten.
@(default_calling_convention = "c")
foreign {
	fopen  :: proc(filename, mode: cstring) -> ^FILE ---
	fseek  :: proc(stream: ^FILE, offset: c.long, whence: Whence) -> c.int ---
	ftell  :: proc(stream: ^FILE) -> c.long ---
	fclose :: proc(stream: ^FILE) -> c.int ---
	fread  :: proc(ptr: rawptr, size: c.size_t, nmemb: c.size_t, stream: ^FILE) -> c.size_t ---
	fwrite :: proc(ptr: rawptr, size: c.size_t, nmemb: c.size_t, stream: ^FILE) -> c.size_t ---
}

@(private="file")
FILE :: struct {}

Whence :: enum c.int {
	SET,
	CUR,
	END,
}

// Similar to raylib's LoadFileData
_read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	if name == "" {
		log.error("No file name provided")
		return
	}

	file := fopen(strings.clone_to_cstring(name, context.temp_allocator), "rb")

	if file == nil {
		log.errorf("Failed to open file %v", name)
		return
	}

	defer fclose(file)

	fseek(file, 0, .END)
	size := ftell(file)
	fseek(file, 0, .SET)

	if size <= 0 {
		log.errorf("Failed to read file %v", name)
		return
	}

	data_err: runtime.Allocator_Error
	data, data_err = make([]byte, size, allocator, loc)

	if data_err != nil {
		log.errorf("Error allocating memory: %v", data_err)
		return
	}

	read_size := fread(raw_data(data), 1, c.size_t(size), file)

	if read_size != c.size_t(size) {
		log.warnf("File %v partially loaded (%i bytes out of %i)", name, read_size, size)
	}

	log.debugf("Successfully loaded %v", name)
	return data, true
}

// Similar to raylib's SaveFileData.
//
// Note: This can save during the current session, but I don't think you can
// save any data between sessions. So when you close the tab your saved files
// are gone. Perhaps you could communicate back to emscripten and save a cookie.
// Or communicate with a server and tell it to save data.
_write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	if name == "" {
		log.error("No file name provided")
		return
	}

	file := fopen(strings.clone_to_cstring(name, context.temp_allocator), truncate ? "wb" : "ab")
	defer fclose(file)

	if file == nil {
		log.errorf("Failed to open '%v' for writing", name)
		return
	}

	bytes_written := fwrite(raw_data(data), 1, len(data), file)

	if bytes_written == 0 {
		log.errorf("Failed to write file %v", name)
		return
	} else if bytes_written != len(data) {
		log.errorf("File partially written, wrote %v out of %v bytes", bytes_written, len(data))
		return
	}

	log.debugf("File written successfully: %v", name)
	return true
}
Path_Separator        :: _Path_Separator        // OS-Specific
Path_Separator_String :: _Path_Separator_String // OS-Specific
Path_Separator_Chars  :: `/\`
Path_List_Separator   :: _Path_List_Separator   // OS-Specific
_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

//todo this is bad
@(require_results)
_join_path :: proc(elems: []string, allocator: runtime.Allocator) -> (joined: string, err: runtime.Allocator_Error) {
	for e, i in elems {
		if e != "" {
			p,err := strings.join(elems[i:], Path_Separator_String, allocator)
			return p,err
		}
	}
	return "", nil
}


_dir :: proc(path: string) -> string {
	if path == "" {
		return "."
	}

	d, _ := split_path(path)
	return d
}

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

split_path :: proc(path: string) -> (dir, file: string) {
	i := len(path) - 1
	for i >= 0 && !_is_path_separator(path[i]) {
		i -= 1
	}
	if i == 0 {
		return path[:i+1], path[i+1:]
	} else if i > 0 {
		return path[:i], path[i+1:]
	}
	return "", path
}

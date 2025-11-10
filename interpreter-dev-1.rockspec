package = "interpreter"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/lua-interpreter.git"
}
description = {
	summary = "A Drop-In Interpreter for your Scripts.",
	detailed = "A Drop-In Interpreter for your Scripts.",
	homepage = "https://github.com/thenumbernine/lua-interpreter",
	license = "MIT"
}
dependencies = {
	"lua >= 5.3"
}
build = {
	type = "builtin",
	modules = {
		interpreter = "interpreter.lua",
		["interpreter.run"] = "run.lua"
	}
}

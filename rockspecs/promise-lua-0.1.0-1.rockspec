package = "promise-lua"
version = "0.1.0-1"
source = {
    url = "git+https://github.com/pyericz/promise-lua",
}
description = {
    summary = "Promises/A+ implemented in Lua language.",
    detailed = "Promises/A+ implemented in Lua language.",
    homepage = "https://github.com/pyericz/promise-lua",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
build = {
    type = "builtin",
    modules = {
        ["promise"] = "src/promise.lua",
    }
}
dependencies = {
    "lua >= 5.1",
}

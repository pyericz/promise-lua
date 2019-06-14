# promise-lua
[Promises/A+](https://promisesaplus.com/) implemented in Lua language.

## Installation
You can install promise-lua using [LuaRocks](https://luarocks.org/modules/pyericz/promise-lua):
```
$ luarocks install promise-lua
```

## Usage
```lua
Promise(function(resolve, reject)
    setTimeout(function()
        math.randomseed(os.time())
        local num = math.random(10)
        if num % 2 == 0 then
            resolve(num)
        else
            local errMsg = string.format('[ERROR] Expect an even number, but get %d', num)
            reject(errMsg)
        end
    end, 1000)
end
)
:thenCall(function(value)
    print('an even number', value)
end)
:catch(function(err)
    print(err)
end)
:finally(function()
    print('all done')
end)

```

## License
[MIT License](https://github.com/pyericz/promise-lua/blob/master/LICENSE)

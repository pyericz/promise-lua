# promise-lua
[Promises/A+](https://promisesaplus.com/) implemented in Lua language.

## Installation
You can install promise-lua using [LuaRocks](https://luarocks.org/modules/pyericz/promise-lua):
```
$ luarocks install promise-lua
```

## Usage
### Basic usages
```lua
Promise(function(resolve, reject)
    -- do stuff after 1000 milliseconds.
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

### Promise.resolve
```lua
local p = Promise.resolve(3)
:thenCall(function(value)
    print('promise resolve a value: ', value)
    return value
end)

Promise.resolve({
    thenCall = function()
        print('thenable called')
    end
})

Promise.resolve(p)
:thenCall(function(value)
    print('resolve from a promise: ', value)
end)

--[[
Output:
    promise resolve a value: 3
    thenable called
    resolve from a promise: 3
--]]
```

### Promise.reject
```lua
Promise.reject('[ERROR] this is an error msg')
:catch(function(reason)
    print('catch an error: ', reason)
end)

--[[
Output:
    catch an error: [ERROR] this is an error msg
--]]
```

### Promise.race
```lua
local p1 = Promise.resolve(3)

local p2 = Promise(function (resolve, reject)
    setTimeout(resolve, 1000, true)
end)

local p3 = Promise(function (resolve, reject)
    setTimeout(resolve, 2000, 'hello')
end)

Promise.race({p1, p2, p3})
:thenCall(function (value)
    print('winner value:', value)
end)

--[[
Output:
    winner value: 3
--]]
```

### Promise.all
```lua
local p1 = Promise.resolve(3)

local p2 = Promise(function (resolve, reject)
    setTimeout(resolve, 1000, true)
end)

local p3 = Promise(function (resolve, reject)
    setTimeout(resolve, 2000, 'hello')
end)

Promise.all({p1, p2, p3})
:thenCall(function (value)
    print('first one: all done!')
end)
:catch(function (reason)
    print('first one rejected!')
end)

local p4 = Promise.reject('[ERROR]')

Promise.all({p1, p2, p3, p4})
:thenCall(function (value)
    print('second one: all done!')
end)
:catch(function (reason)
    print('second one rejected!')
end)

--[[
Output:
    first one: all done!
    second one rejected!
--]]
```


## License
[MIT License](https://github.com/pyericz/promise-lua/blob/master/LICENSE)

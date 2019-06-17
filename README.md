# promise-lua
promise-lua is an es6 Promise mechanism in Lua, with the exception that `then` function is replaced by `thenCall` since `then` is a keyword of Lua languange.

## Installation
You can install promise-lua using [LuaRocks](https://luarocks.org/modules/pyericz/promise-lua):
```
$ luarocks install promise-lua
```

## Usage
To create `Promise` object, simply use `Promise.new(func)` in which `func` is of following form:
```lua
function (resolve, reject)
    -- Do any async or sync operations.
    -- when success, call `resolve`,
    -- when failed, call `reject`
end
```

`Promise(func)` is a shorthand of `Promise.new(func)`. After create, do `thenCall` to actually resolve or reject.
```lua
local p = ... -- p is a Promise object 
p:thenCall(function (value)
    -- resolved with value
end, function (reason)
    -- rejected with reason
end)
```

Since `thenCall` returns a new Promise object, you can chain multiple `thenCall` as following:
```lua
local p = ... -- p is a Promise object
p:thenCall(function (value)
    -- resolved with value
    return value
end, function (reason)
    -- rejected with reason
end)
:thenCall(function (value)
    -- resolve from last resolve result
end)
```

There are more methods defined in Promise object, like `catch` and `finally`. For more information, please check out this [doc](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise). 

Here is a full basic usage example.
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

## More methods

### Promise.resolve
Returns a new Promise object that is resolved with the given value. For more information, checkout [doc](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve). 
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
Returns a new Promise object that is rejected with the given reason. For more information, checkout [doc](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/reject).
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
Wait until any of the promises is resolved or rejected. For more information, checkout [doc](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race).
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
Wait for all promises to be resolved, or for any to be rejected. For more information, checkout [doc](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all).
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

local p4 = Promise(function (resolve, reject)
    setTimeout(reject, 2000, '[ERROR]')
end)

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

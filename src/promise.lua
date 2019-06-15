local PENDING = 'pending'
local FULFILLED = 'fulfilled'
local REJECTED = 'rejected'

local function noop() end

local function isThenable(x)
    return type(x) == 'table' and x.thenCall ~= nil
end

local promise = {}

local newPromise
local resolve
local promiseOnFulfilled
local promiseOnRejected

local function isPromise(x)
    if type(x) ~= 'table' then return false end
    local mt = getmetatable(x)
    while mt ~= nil do
        if mt == promise then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

local function execFulfilled(thenInfo, value)
    local n = thenInfo
    if type(n.onFulfilled) ~= 'function' then
        promiseOnFulfilled(n.promise, value)
    else
        local success, ret = pcall(n.onFulfilled, value)
        if success then
            resolve(n.promise, ret)
        else
            promiseOnRejected(n.promise, ret)
        end
    end
end

local function execRejected(thenInfo, reason)
    local n = thenInfo
    if type(n.onRejected) ~= 'function' then
        promiseOnRejected(n.promise, reason)
    else
        local success, ret = pcall(n.onRejected, reason)
        if success then
            resolve(n.promise, ret)
        else
            promiseOnRejected(n.promise, ret)
        end
    end
end

promiseOnFulfilled = function (p, value)
    if p.state == PENDING then
        p.value = value
        p.reason = nil
        p.state = FULFILLED
    end
    for _,n in ipairs(p.thenInfoList) do
        execFulfilled(n, value)
    end
end

promiseOnRejected = function (p, reason)
    if p.state == PENDING then
        p.value = nil
        p.reason = reason
        p.state = REJECTED
    end
    for _,n in ipairs(p.thenInfoList) do
        execRejected(n, reason)
    end
end


local function resolveThenable(p, x)
    local thenCall = x.thenCall
    if type(thenCall) == 'function' then
        local isCalled = false
        local function resolvePromise(y)
            if isCalled then return end
            isCalled = true
            resolve(p, y)
        end
        local function rejectPromise(r)
            if isCalled then return end
            isCalled = true
            promiseOnRejected(p, r)
        end
        local success, err = pcall(thenCall, x, resolvePromise, rejectPromise)
        if not success then
            if not isCalled then
                promiseOnRejected(p, err)
            end
        end
    else
        promiseOnFulfilled(p, x)
    end
end

--[[
    define p resolution procedure
--]]
resolve = function (p, x)
    if p == x then
        promiseOnRejected(p, 'TypeError')
        return
    end
    if isPromise(x) then
        if x.state == PENDING then
            p.state = PENDING
        end
        resolveThenable(p, x)
    elseif isThenable(x) then
        resolveThenable(p, x)
    else
        promiseOnFulfilled(p, x)
    end
end


function promise:new()
    local p = {}
    setmetatable(p, self)
    self.__index = self
    p.thenInfoList = {}
    p.state = PENDING
    p.value = nil
    p.reason = nil

    return p
end

function promise:thenCall(onFulfilled, onRejected)
    local p = newPromise(noop)

    local thenInfo = {
        promise = p,
    }

    if type(onFulfilled) == 'function' then
        thenInfo.onFulfilled = onFulfilled
    end
    if type(onRejected) == 'function' then
        thenInfo.onRejected = onRejected
    end


    if self.state == FULFILLED then
        execFulfilled(thenInfo, self.value)
    elseif self.state == REJECTED then
        execRejected(thenInfo, self.reason)
    end

    table.insert(self.thenInfoList, thenInfo)

    return p
end

function promise:catch(onRejected)
    return self:thenCall(nil, onRejected)
end

function promise:finally(func)
    return self:thenCall(
        function ()
            func()
        end,
        function ()
            func()
        end
    )
end

newPromise = function (func)
    local obj = promise:new()
    local isCalled = false
    local function onFulfilled(value)
        if isCalled then return end
        isCalled = true
        promiseOnFulfilled(obj, value)
    end

    local function onRejected(reason)
        if isCalled then return end
        isCalled = true
        promiseOnRejected(obj, reason)
    end

    if type(func) == 'function' then
        func(onFulfilled, onRejected)
    end
    return obj
end

local Promise = {}
setmetatable(Promise, {
    __call = function (_, func)
        return newPromise(func)
    end
})

Promise.new = newPromise

local function newPromiseFromValue(value)
    local p = newPromise(noop)
    p.state = FULFILLED
    p.value = value
    p.reason = nil
    return p
end

function Promise.resolve(value)
    if isPromise(value) then return value end
    if isThenable(value) then
        local thenCall = value.thenCall
        if type(thenCall) == 'function' then
            return newPromise(function(onFulfilled, onRejected)
                value:thenCall(onFulfilled, onRejected)
            end)
        else
            return newPromise(function(_, onRejected)
                onRejected('TypeError')
            end)
        end
    end
    return newPromiseFromValue(value)
end


function Promise.reject(value)
    return newPromise(function(_, onRejected)
        onRejected(value)
    end)
end

function Promise.race(values)
    assert(type(values) == 'table', 'Promise.race needs an table')
    assert(next(values) ~= nil, 'An empty table')
    return newPromise(function(onFulfilled, onRejected)
        for _, value in pairs(values) do
            Promise.resolve(value):thenCall(onFulfilled, onRejected)
        end
    end)
end

function Promise.all(array)
    assert(type(array) == 'table', 'Promise.all needs an array')
    local args = {}
    for i=1, #array do
        args[i] = array[i]
    end

    return newPromise(function (onFulfilled, onRejected)
        if #args == 0 then return onFulfilled({}) end
        local remaining = #args
        local function res(i, val)
            if val then
                if isPromise(val) then
                    if val.state == FULFILLED then
                        return res(i, val.value)
                    end
                    if val.state == REJECTED then
                        onRejected(val.reason)
                    end
                    val:thenCall(function (v)
                        res(i, v)
                    end, onRejected)
                    return
                elseif isThenable(val) then
                    local thenCall = val.thenCall
                    if type(thenCall) == 'function' then
                        local p = newPromise(function(r, rj)
                            val:thenCall(r, rj)
                        end)
                        p:thenCall(function (v)
                            res(i, v)
                        end, onRejected)
                        return
                    end
                end
            end
            args[i] = val
            remaining = remaining - 1
            if remaining == 0 then
                onFulfilled(args)
            end
        end
        for i=1, #args do
            res(i, args[i])
        end
    end)
end

return Promise

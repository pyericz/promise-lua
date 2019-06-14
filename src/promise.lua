local PENDING = 'pending'
local FULFILLED = 'fulfilled'
local REJECTED = 'rejected'

local function isThenable(x)
    return type(x) == 'table' and x.thenCall ~= nil
end

local Promise = {}

local resolve
local promiseOnFulfilled
local promiseOnRejected

local function isPromise(x)
    if type(x) ~= 'table' then return false end
    local mt = getmetatable(x)
    while mt ~= nil do
        if mt == Promise then
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

promiseOnFulfilled = function (promise, value)
    if promise.state == PENDING then
        promise.value = value
        promise.reason = nil
        promise.state = FULFILLED
    end
    for _,n in ipairs(promise.thenInfoList) do
        execFulfilled(n, value)
    end
end

promiseOnRejected = function (promise, reason)
    if promise.state == PENDING then
        promise.value = nil
        promise.reason = reason
        promise.state = REJECTED
    end
    for _,n in ipairs(promise.thenInfoList) do
        execRejected(n, reason)
    end
end


local function handleThenable(promise, x)
    local thenCall = x.thenCall
    if type(thenCall) == 'function' then
        local isCalled = false
        local function resolvePromise(y)
            if isCalled then return end
            isCalled = true
            resolve(promise, y)
        end
        local function rejectPromise(r)
            if isCalled then return end
            isCalled = true
            promiseOnRejected(promise, r)
        end
        local success, err = pcall(thenCall, x, resolvePromise, rejectPromise)
        if not success then
            if not isCalled then
                promiseOnRejected(promise, err)
            end
        end
    else
        promiseOnFulfilled(promise, x)
    end
end

--[[
    define promise resolution procedure
--]]
resolve = function (promise, x)
    if promise == x then
        promiseOnRejected(promise, 'TypeError')
        return
    end
    if isPromise(x) then
        if x.state == PENDING then
            promise.state = PENDING
        end
        handleThenable(promise, x)
    elseif isThenable(x) then
        handleThenable(promise, x)
    else
        promiseOnFulfilled(promise, x)
    end
end


function Promise:new()
    local promise = {}
    setmetatable(promise, self)
    self.__index = self
    promise.thenInfoList = {}
    promise.state = PENDING
    promise.value = nil
    promise.reason = nil

    return promise
end

function Promise:thenCall(onFulfilled, onRejected)
    local promise = Promise:new()

    local thenInfo = {
        promise = promise,
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

    return promise
end

function Promise:catch(onRejected)
    return self:thenCall(nil, onRejected)
end

function Promise:finally(func)
    return self:thenCall(
        function ()
            func()
        end,
        function ()
            func()
        end
    )
end

return function (func)
    local obj = Promise:new()
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

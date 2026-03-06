GameEvent = {}

local _listeners = {}

function GameEvent.add(eventName, func, tag, priority)
	assert(tag, "Tag must not be nil")
	
	if not _listeners[eventName] then
		_listeners[eventName] = {}
	end
	
	local eventListeners = _listeners[eventName]
	local eventListenerSize = #eventListeners
	for i = 1, eventListenerSize do
		if tag == eventListeners[i][2] then
			return
		end
	end

	if priority and eventListenerSize >= priority then
		table.insert(eventListeners, priority, {func, tag})
	else
		table.insert(eventListeners, {func, tag})
	end
end

function GameEvent.remove(func)
	for eventName, eventListeners in pairs(_listeners) do
		for i = 1, #eventListeners do
			if eventListeners[i][1] == func then
				table.remove(eventListeners, i)
				if 0 == #listeners[eventName] then
					listeners[eventName] = nil
				end
				return
			end
		end
	end
end

function GameEvent.removeByNameAndTag(eventName, tag)
	assert(tag, "Tag must not be nil")
	local eventListeners = _listeners[eventName]
	if not eventListeners then return end

	for i = #eventListeners, 1, -1 do
		if eventListeners[i][2] == tag then
			table.remove(eventListeners, i)
			break
		end
	end

	if 0 == #eventListeners then
		listeners[eventName] = nil
	end
end

function GameEvent.removeByTag(tag)
	assert(tag, "Tag must not be nil")
	for eventName, eventListeners in pairs(_listeners) do
		self.removeListenerByNameAndTag(eventName, tag)
	end
end

function GameEvent.removeAll()
	_listeners = {}
end

function GameEvent.push(eventName, ...)
	local eventListeners = _listeners[eventName]
	if not eventListeners then
		return
	end
	for index, listeners in ipairs(eventListeners) do
		local result, stop = pcall(listeners[1], ...)
		if result then
			if stop then break end
		else
			local tag = listeners[2]
            local tarid
            if type(tag) == "string" then
                tarid = tag
            else
                tarid = tag.ID or 0
            end
            local err = "派发事件发生错误：事件名=" .. eventName .. " 模块ID=" .. tarid .. "   "
			LOGPrint(err, stop)

		end
	end
end

return GameEvent
local GameEvent = {}

GameEvent._listeners = {}

-- eventName:string, func:function, tag:anything
function GameEvent:add(eventName, func, tag)
	assert(tag, "添加【"..eventName.."】事件未传递tag")
	local listeners = self._listeners
	if not listeners[eventName] then
		listeners[eventName] = {}
	end
	
	local eventListeners = listeners[eventName]
	for i = 1, #eventListeners do
		if tag == eventListeners[i][2] then
			-- avoid repeate add listener for a tag
			return
		end
	end
	table.insert(eventListeners, {func, tag})
end

function GameEvent:remove(func)
	local listeners = self._listeners
	for eventName, eventListeners in pairs(listeners) do
		for i = 1, #eventListeners do
			if eventListeners[i][1] == func then
				-- remove listener
				table.remove(eventListeners, i)
				-- clear table
				if 0 == #listeners[eventName] then
					listeners[eventName] = nil
				end
				return
			end
		end
	end
end

function GameEvent:removeByNameAndTag(eventName, tag)
	assert(tag, "Tag must not be nil")
	local listeners = self._listeners
	local eventListeners = listeners[eventName]
	if not eventListeners then return end

	for i = #eventListeners, 1, -1 do
		if eventListeners[i][2] == tag then
			-- remove listener
			table.remove(eventListeners, i)
			break
		end
	end
	-- clear table
	if 0 == #eventListeners then
		listeners[eventName] = nil
	end
end

function GameEvent:removeByTag(tag)
	assert(tag, "Tag must not be nil")
	local listeners = self._listeners
	for eventName, eventListeners in pairs(listeners) do
		self:removeByNameAndTag(eventName, tag)
	end
end

function GameEvent:removeAll()
	self._listeners = {}
end

function GameEvent:push(eventName, ...)
	local listeners = self._listeners or {}
	local eventListeners = listeners[eventName]
	if not eventListeners then
		return
	end
	local tmp = {}
	for index, listeners in ipairs(eventListeners) do
		tmp[index] = listeners
	end
	for _, listeners in ipairs(tmp) do
		listeners[1](...)
	end
end

return GameEvent
local SysConstMaster_and_apprenticeant = require("game_config/cfgcsv/Master_and_apprentice")
local MentorApplicationTask = {}
MentorApplicationTask.__index = MentorApplicationTask

local __inst = nil
function MentorApplicationTask.Get()
	if not __inst then
		__inst = setmetatable({}, MentorApplicationTask)
	end
	return __inst
end

--出师条件
function MentorApplicationTask:setOut()
	local list = {}
	for i=1,#SysConstMaster_and_apprenticeant do
		local task = SysConstMaster_and_apprenticeant[i]
		if task.type == 1 then
			table.insert(list,task)
		end
	end
	return list
end
--徒弟任务
function MentorApplicationTask:applictionTask()
	local list = {}
	for i=1,#SysConstMaster_and_apprenticeant do
		local task = SysConstMaster_and_apprenticeant[i]
		if task.type == 2 then
			table.insert(list,task)
		end
	end
	return list
end

--贡献度任务
function MentorApplicationTask:gxdTask()
	local list = {}
	for i=1,#SysConstMaster_and_apprenticeant do
		local task = SysConstMaster_and_apprenticeant[i]
		if task.type == 3 then
			table.insert(list,task)
		end
	end
	return list
end

return MentorApplicationTask
local Config = {}

-- 脚本模板
Config.Template =
[[
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local _T = class("_T", BaseFGUILayout)

--- 界面被创建时调用
function _T:Create()
    self._ui = FGUI:ui_delegate(self.component)
end

--- 界面打开时调用
function _T:Enter(data)
end

--- 界面打开和刷新时调用
function _T:Refresh(data)
end

--- 界面关闭时调用
function _T:Exit()
end

--- 界面销毁时调用
function _T:Destroy()
end

--- 界面每帧执行(通常不启用)
-- function _T:Update(dt)
-- end

return _T
]]


return Config

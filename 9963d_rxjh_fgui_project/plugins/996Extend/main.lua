--FYI: https://github.com/Tencent/xLua/blob/master/Assets/XLua/Doc/XLua_Tutorial_EN.md

_G.PluginPath = PluginPath
-- require(PluginPath .. '/../../../../Tool')
require(PluginPath .. '/Src/Util')
require(PluginPath .. '/Src/TextExtend')

local FilterItemIcon = require(PluginPath ..'/Src/FilterItemIcon')
local Template = require(PluginPath .. '/Src/Template')

-- 开始发布
function onPublishStart(packages)
    FilterItemIcon.onPublishStart(packages)
end

function onDestroy()
    -------do cleanup here-------
    FilterItemIcon.onDestroy()
    Template.onDestroy()
end

Template.Init()




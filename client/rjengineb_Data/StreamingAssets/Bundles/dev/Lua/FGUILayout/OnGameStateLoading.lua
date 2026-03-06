--[[
游戏世界加载完成时调用我，早于GUIInit.lua
]]

function OnGameStateLoading()
    SL:Print("Hello World, This is OnGameStateLoading!")

end
OnGameStateLoading()
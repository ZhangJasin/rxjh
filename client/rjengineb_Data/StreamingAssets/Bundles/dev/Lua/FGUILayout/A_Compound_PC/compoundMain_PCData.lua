local compoundMainData = SL:RequireFile("FGUILayout/A_Compound/compoundMainData")

local compoundMain_PCData = class("compoundMain_PCData", compoundMainData)

-- PC端可以复用移动端的数据层
-- 如果有PC端特殊需求可以在这里扩展

return compoundMain_PCData

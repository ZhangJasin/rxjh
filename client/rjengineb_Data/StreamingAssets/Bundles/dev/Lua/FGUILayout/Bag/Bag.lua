Bag = {}
Bag.willPos = {}

function Bag.main()
    -- 背包满提醒文本
    SL:RegisterLUAEvent(LUA_EVENT_BAG_IS_FULL, "Bag", function()
        SL:AddBubbleTips(global.MMO.BUBBLE_TIPS_BAG_FULL, FGUIDefine.BubbleTipType.Bag, function()
            FGUIFunction:OpenBag()
        end)
        SL:ShowSystemTips(GET_STRING(60003001))
    end)
    -- 背包物品删除
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "Bag", function(item)
        -- 关闭 背包满提醒文本
        SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_BAG_FULL)
    end)
end

-- 设置将要拖拽至背包位置(只在pc下使用)
function Bag.setWillDragToPos(makeIndex,pos)
    if not makeIndex or not pos then
        return
    end

    if type(pos) ~= "number" then
        return
    end
    
    if SL:GetValue("IS_PC_OPER_MODE") then
        Bag.willPos[makeIndex] = pos
    end
end

-- 获取记录的位置
function Bag.getWillDragToPos(makeIndex)
    if SL:GetValue("IS_PC_OPER_MODE") then
        return Bag.willPos[makeIndex]
    end
    return nil
end
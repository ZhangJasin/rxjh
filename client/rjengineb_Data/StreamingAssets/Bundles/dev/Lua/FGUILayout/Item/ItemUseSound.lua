ItemUseSound = {}

-- 物品使用音效
function ItemUseSound.main()
    SL:RegisterLUAEvent(LUA_EVENT_ITEM_USE_SOUND,"ItemUseSound",ItemUseSound.onUsePlay)
end

function ItemUseSound.onUsePlay(itemData)
    if not itemData then
       return
    end

    local itemConfig =  SL:GetValue("ITEM_DATA",itemData.Index)
    if itemConfig and itemConfig.SubType then
        if itemConfig.SubType == 1 then               -- 使用红药音效
            SL:PlaySound(3, nil, nil, -1)
        elseif itemConfig.SubType == 2 then           -- 使用蓝药音效
            SL:PlaySound(4, nil, nil, -1)
        end
    end
end

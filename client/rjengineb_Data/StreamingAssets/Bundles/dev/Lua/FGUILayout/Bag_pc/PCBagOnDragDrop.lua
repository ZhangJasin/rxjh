PCBagOnDragDrop = {}


function PCBagOnDragDrop.main()
end

-- 显示面板
function PCBagOnDragDrop.Show()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Bag_pc", "PCBagOnDragDropPanel", nil,FGUI_LAYER.BG)
    end
end

function PCBagOnDragDrop.Hide()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Close("Bag_pc", "PCBagOnDragDropPanel")
    end
end
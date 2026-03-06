local HudBase = require("FGUILayout/Hud/HudBase")
local HudItem = class("HudItem", HudBase)

function HudItem:ctor(uiHud)
    HudItem.super.ctor(self, uiHud)
end

function HudItem:Init(actorID)
    HudItem.super.Init(self, actorID)

    HUDHelp:SetPosition(self._uiHud, 0, 1, 0)
end

function HudItem:RefreshLabelNameVisible()
    local typeIndex = SL:GetValue("ITEM_INDEX_BY_ACTOR_ID", self._actorID)
    typeIndex = (typeIndex == 0 and 1 or typeIndex)
    local isVisible = SL:GetValue("ITEM_DROP_SHOW", typeIndex)
    self:SetHudNameVisible(isVisible)
end
return HudItem
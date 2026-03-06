local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PickItemEffectUI = class("PickItemEffectUI", BaseFGUILayout)
local Queue = requireUtil( "queue" )
local RefIDList = requireUtil("RefIDList")

local MAX_PICK_FX_COUNT = 15


function PickItemEffectUI:Create(itemPos)
	self._ui = FGUI:ui_delegate(self.component)
    self._refIDList = RefIDList.new()
    self._pickFxPool = Queue.new()

    local x, y = FGUIFunction:GetPickItemFxUIEndPos()
    if x and y then
        self._ePos = {x=x, y=y}
    else
        self._ePos = nil
    end

    self._fxID, self._duration, self._height, self._isUI = SL:GetPickFxData()
    self._duration = SL:GetPickItemFxDuration()

    self._fxObj = {}
    self._pickCount = 0
end

function PickItemEffectUI:Refresh(itemPos)
    if not self._ePos then 
        return 
    end 

    if self._pickCount >= MAX_PICK_FX_COUNT then 
        return 
    end 
    self._pickCount = self._pickCount + 1

    local itemPosX, itemPosY, itemPosZ = FGUI:SceneConvertToWorld(itemPos.x, itemPos.y, itemPos.z)
    local refID = self._refIDList:Get()
    self._fxObj[refID] = {}
    self._fxObj[refID].fxObj = self:CreatePickItemFxUI(refID)
    self._fxObj[refID].lifeTime = 0
    self._fxObj[refID].key = refID

    self._fxObj[refID].sPosX = itemPosX
    self._fxObj[refID].sPosY = itemPosY
    self._fxObj[refID].cPosX = (itemPosX + self._ePos.x) / 2
    self._fxObj[refID].cPosY = (itemPosY + self._ePos.y) / 2
    self._fxObj[refID].ePosX = self._ePos.x
    self._fxObj[refID].ePosY = self._ePos.y

    FGUI:setVisible(self._fxObj[refID].fxObj, false)
    FGUI:setPosition(self._fxObj[refID].fxObj, itemPosX, itemPosY)

    if not self.Timer then 
        self.Timer = SL:Schedule(handler(self, self.PickTick), 0.01)
    end
end

function PickItemEffectUI:Exit()
    self._refIDList:Reset()
    self._pickFxPool:clear()
end

-- 拾取特效 场景 -> UI控件
local sp = {x = 0, y = 0}
local cp = {x = 0, y = 0}
local ep = {x = 0, y = 0}
local bp = {x = 0, y = 0}
function PickItemEffectUI:CalculatePickItemBezierPoint(t, sposx,sposy,cposx,cposy,eposx,eposy)
    local u = 1 - t 
    local tt = t * t 
    local uu = u * u
    local ut2 = u * t * 2
    bp.x = 0
    bp.y = 0

    sp.x = sposx * uu
    sp.y = sposy * uu

    cp.x = cposx * ut2 
    cp.y = cposy * ut2 

    ep.x = eposx * tt 
    ep.y = eposy * tt 

    bp.x = bp.x + sp.x + cp.x + ep.x 
    bp.y = bp.y + sp.y + cp.y + ep.y 
    
    return bp
end 

function PickItemEffectUI:CreatePickItemFxUI()
    local fxObj = nil
    if self._pickFxPool:empty() then 
        fxObj = FGUI:CreateObject(self.component, "PickItem", "PickItemModel")
        local ui_model = FGUI:GetChild(fxObj, "model_item")
        local model = self:UIModel_Bind(ui_model)
        FGUI:UIModel_addFx(model, self._fxID)
        self._pickFxPool:push(fxObj)
    else 
        fxObj = self._pickFxPool:pop()
    end 

    return fxObj
end  

function PickItemEffectUI:RecyclePickItemFxUI(data)
    FGUI:setPosition(data.fxObj, 9999, 9999)
    self._pickFxPool:push(data.fxObj)

    local key = data.key
    self._refIDList:Recycle(key)
    self._fxObj[key] = nil

    self._pickCount = self._pickCount - 1
    if self._pickCount <= 0 then 
        self._pickCount = 0

        if self.Timer then 
            SL:UnSchedule(self.Timer)
            self.Timer = nil
        end 
    end 
end 

local mPos = {x = 0, y = 0}
function PickItemEffectUI:PlayAction(data)
    mPos = self:CalculatePickItemBezierPoint(data.lifeTime/self._duration,data.sPosX,data.sPosY,data.cPosX,data.cPosY,data.ePosX,data.ePosY)
    FGUI:setPosition(data.fxObj, mPos.x, mPos.y)
end 

function PickItemEffectUI:PickTick(dt)
    if next(self._fxObj) then 
        for key, data in pairs(self._fxObj) do
            data.lifeTime = data.lifeTime + 0.01
            if data.lifeTime > self._duration then 
                self:RecyclePickItemFxUI(data) 
            else 
                if not FGUI:getVisible(data.fxObj) then 
                    FGUI:setVisible(data.fxObj, true)
                end 
                self:PlayAction(data)
            end 
        end
    end
end

return PickItemEffectUI
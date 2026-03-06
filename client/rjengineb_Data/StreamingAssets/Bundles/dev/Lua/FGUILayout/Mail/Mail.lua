Mail = {}

function Mail.main()
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_RESPONSE_LIST, "Mail", function(mails, isReadAll)
        if isReadAll then
            SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_MAIL_RECEIVED)
        end
    end)
    
    -- 提取单个邮件
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_UPDATE, "Mail", function(mail, rewardCount)
        if rewardCount == 0 then 
            SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_MAIL_RECEIVED)
        end
    end)
    
    -- 提取所有邮件
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_UPDATE_ALL, "Mail", function(mails, rewardCount)
        if rewardCount == 0 then 
            SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_MAIL_RECEIVED)
        end
    end)
    
    -- 删除单个邮件
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_DELETE, "Mail", function(mailID, mailCount)
        if mailCount <= 0 then 
            SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_MAIL_RECEIVED)
        end 
    end)
    
    -- 删除所有邮件
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_DELETE_ALL_READ, "Mail", function()
        SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_MAIL_RECEIVED)
    end)
    
    -- 读取邮件
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_READ, "Mail", function(mailID, isReadAll)
        if isReadAll then
            SL:DelBubbleTips(global.MMO.BUBBLE_TIPS_MAIL_RECEIVED)
        end
    end)
    
    -- 新邮件提醒
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_NEW_NOTICE, "Mail", function()
        local function callback()
            SL:JumpTo(8)
        end
        local id = 2
        SL:AddBubbleTips(id, FGUIDefine.BubbleTipType.Mail, callback)
    end)
end
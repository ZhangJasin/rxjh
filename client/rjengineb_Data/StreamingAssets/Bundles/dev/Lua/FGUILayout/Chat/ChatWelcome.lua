-- 聊天上线欢迎

ChatWelcome = {}

function ChatWelcome.main()
    local defaultChat = SL:GetValue("GAME_DATA", "DefaultChat")
    if defaultChat and defaultChat ~= "" then
        SL:ShowSystemChat(defaultChat, 255)
    end
end
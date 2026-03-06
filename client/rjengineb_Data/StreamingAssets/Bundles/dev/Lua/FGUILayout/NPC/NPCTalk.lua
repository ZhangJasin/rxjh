-- npc点击

NPCTalk = {}

function NPCTalk.main()
    SL:RegisterLUAEvent(LUA_EVENT_TALK_TO_NPC, "NPCTalk", function(data)
        SL:PlaySound(205)
    end)
end
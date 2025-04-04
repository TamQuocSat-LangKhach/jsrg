local hezhi = fk.CreateSkill {
  name = "hezhi$"
}

Fk:loadTranslationTable{ }

hezhi:addEffect("Compulsory", {
  can_trigger = function(self, event, target, player, data)
    -- 在这里实现can_trigger逻辑
    if some_condition then
      return true
    end
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    -- 在这里实现on_trigger逻辑
    local a = event:getCostData(skill)
    -- 假设这里的逻辑需要读取cost_data并作出某些处理
    if a then
      player:drawCards(2, hezhi.name)
    end
  end,
})

return hezhi

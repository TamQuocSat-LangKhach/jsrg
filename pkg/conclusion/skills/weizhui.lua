local weizhui = fk.CreateSkill {
  name = "weizhui$"
}

Fk:loadTranslationTable{
  ['#weizhui-use'] = '危坠：你可以将一张黑色牌当【过河拆桥】对 %src 使用',
}

weizhui:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(weizhui.name) and player ~= target and target.phase == Player.Finish 
      and not player:isAllNude() and not target:isNude() and target.kingdom == "wei"
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local cardIds = table.filter(target:getCardIds("he"), function (id)
      if Fk:getCardById(id).color ~= Card.Black then return false end
      local c = Fk:cloneCard("dismantlement")
      c.skillName = weizhui.name
      c:addSubcard(id)
      return target:canUseTo(c, player)
    end)
    if #cardIds == 0 then return end
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = weizhui.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cardIds }),
      prompt = "#weizhui-use:"..player.id
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    player.room:useVirtualCard("dismantlement", event:getCostData(self), target, player, weizhui.name, true)
  end,
})

return weizhui

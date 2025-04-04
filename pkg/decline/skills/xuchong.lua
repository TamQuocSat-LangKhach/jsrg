local xuchong = fk.CreateSkill {
  name = "xuchong"
}

Fk:loadTranslationTable{
  ['xuchong'] = '虚宠',
  ['xuchong_draw'] = '摸一张牌',
  ['xuchong_hand'] = '令%dest本回合手牌上限+2',
  ['#xuchong-choose'] = '虚宠：选择项执行完成后你获得一张【影】',
  [':xuchong'] = '当你成为牌的目标后，你可以选择一项：1.摸一张牌；2.令当前回合角色本回合手牌上限+2。选择项执行完成后，你获得一张【影】。',
}

xuchong:addEffect(fk.TargetConfirmed, {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, { choices = { "xuchong_draw", "xuchong_hand::" .. room.current.id }, skill_name = xuchong.name, prompt = "#xuchong-choose"})
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) == "xuchong_draw" then
      player:drawCards(1, xuchong.name)
    else
      room:addPlayerMark(room.current, MarkEnum.AddMaxCardsInTurn, 2)
    end

    local shades = getShade(room, 1)
    room:obtainCard(player, shades, true, fk.ReasonPrey, player.id, xuchong.name)
  end,
})

return xuchong

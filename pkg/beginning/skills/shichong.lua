local shichong = fk.CreateSkill {
  name = "shichong"
}

Fk:loadTranslationTable{
  ['shichong'] = '恃宠',
  ['#shichong-invoke'] = '恃宠：你可以获得 %dest 一张手牌',
  ['#shichong-card'] = '恃宠：你可以交给 %src 一张手牌',
  [':shichong'] = '转换技，当你使用牌指定其他角色为唯一目标后，阳：你可以获得目标角色一张手牌；阴：目标角色可以交给你一张手牌。',
}

shichong:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.tos and #AimGroup:getAllTargets(data.tos) == 1 and
      data.to ~= player.id and not player.room:getPlayerById(data.to):isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(shichong.name, false) == fk.SwitchYang then
      if room:askToSkillInvoke(player, {
        skill_name = shichong.name,
        prompt = "#shichong-invoke::" .. data.to
      }) then
        event:setCostData(skill, {tos = {data.to}})
      end
    else
      local to = room:getPlayerById(data.to)
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = shichong.name,
        cancelable = true,
        prompt = "#shichong-card:" .. player.id
      })
      if #card > 0 then
        event:setCostData(skill, {cards = card})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(shichong.name, true) == fk.SwitchYang then
      local to = room:getPlayerById(data.to)
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = shichong.name
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, shichong.name, nil, false, player.id)
    else
      room:moveCardTo(event:getCostData(skill).cards, Card.PlayerHand, player, fk.ReasonGive, shichong.name, nil, false, data.to)
    end
  end,
})

return shichong

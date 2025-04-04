local shejus = fk.CreateSkill {
  name = "shejus"
}

Fk:loadTranslationTable{
  ['shejus'] = '慑惧',
  [':shejus'] = '锁定技，当你使用【杀】指定唯一目标后或成为【杀】的唯一目标后，你与对方议事：若结果为黑色，双方各减1点体力上限；否则意见为黑色的角色摸两张牌。',
}

shejus:addEffect(fk.TargetSpecified, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1 and
      not player.room:getPlayerById(data.from):isKongcheng() and not player.room:getPlayerById(data.to):isKongcheng() and
      not player.room:getPlayerById(data.from).dead and not player.room:getPlayerById(data.to).dead
  end,
  on_use = function (skill, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    if data.from == player.id then
      to = room:getPlayerById(data.to)
    end
    room:doIndicate(player.id, {to.id})
    local discussion = U.Discussion(player, {player, to}, {
      skill_name = skill.name,
    })
    if discussion.color == "black" then
      if not player.dead then
        room:changeMaxHp(player, -1)
      end
      if not to.dead then
        room:changeMaxHp(to, -1)
      end
    else
      for _, p in ipairs({player, to}) do
        if not p.dead and discussion.results[p.id].opinion == "black" then
          p:drawCards(2, skill.name)
        end
      end
    end
  end,
})

shejus:addEffect(fk.TargetConfirmed, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1 and
      not player.room:getPlayerById(data.from):isKongcheng() and not player.room:getPlayerById(data.to):isKongcheng() and
      not player.room:getPlayerById(data.from).dead and not player.room:getPlayerById(data.to).dead
  end,
  on_use = function (skill, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    if data.from == player.id then
      to = room:getPlayerById(data.to)
    end
    room:doIndicate(player.id, {to.id})
    local discussion = U.Discussion(player, {player, to}, {
      skill_name = skill.name,
    })
    if discussion.color == "black" then
      if not player.dead then
        room:changeMaxHp(player, -1)
      end
      if not to.dead then
        room:changeMaxHp(to, -1)
      end
    else
      for _, p in ipairs({player, to}) do
        if not p.dead and discussion.results[p.id].opinion == "black" then
          p:drawCards(2, skill.name)
        end
      end
    end
  end,
})

return shejus

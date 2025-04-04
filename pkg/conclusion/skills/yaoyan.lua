local yaoyan = fk.CreateSkill {
  name = "yaoyan"
}

Fk:loadTranslationTable{
  ['yaoyan'] = '邀宴',
  ['#yaoyan-ask'] = '邀宴；你是否于本回合结束后参与议事？',
  ['@@yaoyan-turn'] = '邀宴',
  ['#yaoyan_discussion'] = '邀宴',
  ['#yaoyan-prey'] = '邀宴；你可以选择其中至少一名角色，获得他们的各一张手牌',
  ['#yaoyan-damage'] = '邀宴：你可以对其中一名角色造成2点伤害',
  [':yaoyan'] = '准备阶段开始时，你可以令所有角色依次选择是否于本回合结束时参与议事，若此议事结果为：红色，你获得至少一名未参与议事的角色各一张手牌；黑色，你对一名参与议事的角色造成2点伤害。',
}

yaoyan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(yaoyan.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player)
    local room = player.room

    room:setPlayerMark(player, "yaoyan_owner-turn", 1)
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player, false), Util.IdMapper))
    for _, p in ipairs(room:getAlivePlayers()) do
      if room:askToSkillInvoke(p, {
        skill_name = yaoyan.name,
        prompt = "#yaoyan-ask"
      }) then
        room:setPlayerMark(p, "@@yaoyan-turn", 1)
      end
    end
  end,
})

yaoyan:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:getMark("yaoyan_owner-turn") > 0 and
      table.find(player.room.alive_players, function(p) return p:getMark("@@yaoyan-turn") > 0 and not p:isKongcheng() end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room

    local targets = table.filter(room.alive_players, function(p) return p:getMark("@@yaoyan-turn") > 0 and not p:isKongcheng() end)
    local discussion = U.Discussion(player, targets, yaoyan.name)

    if discussion.color == "red" then
      local others = table.filter(room.alive_players, function(p)
        return not table.contains(targets, p) and not p:isKongcheng()
      end)

      if #others > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = others,
          min_num = 1,
          max_num = 999,
          prompt = "#yaoyan-prey",
          skill_name = "yaoyan"
        })
        room:sortPlayersByAction(tos)
        for _, p in ipairs(tos) do
          if not p:isKongcheng() then
            local card = room:askToChooseCard(player, {
              target = p,
              flag = "h",
              skill_name = "yaoyan"
            })
            room:obtainCard(player.id, card, false, fk.ReasonPrey)
          end
        end
      end
    elseif discussion.color == "black" then
      targets = table.filter(targets, function(p) return p:isAlive() end)
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#yaoyan-damage",
        skill_name = "yaoyan"
      })
      if #tos > 0 then
        room:damage{
          from = player,
          to = tos[1],
          damage = 2,
          damageType = fk.NormalDamage,
          skillName = yaoyan.name,
        }
      end
    end
  end,
})

return yaoyan

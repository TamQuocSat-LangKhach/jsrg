local xiangjia = fk.CreateSkill {
  name = "xiangjia"
}

Fk:loadTranslationTable{
  ['xiangjia'] = '相假',
  ['#xiangjia'] = '相假：你可视为使用【借刀杀人】，然后目标角色可视为对你使用【借刀杀人】',
  ['#xiangjia-use'] = '相假：你可视为对 %dest 使用【借刀杀人】（请选择 %dest 【杀】的目标）',
  [':xiangjia'] = '出牌阶段限一次，若你装备区有武器牌，你可以视为使用一张【借刀杀人】，然后目标角色可以视为对你使用一张【借刀杀人】。',
}

xiangjia:addEffect('viewas', {
  anim_type = "control",
  pattern = "collateral",
  prompt = "#xiangjia",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("collateral")
    c.skillName = skill.name
    return c
  end,
  after_use = function(self, player, use)
    local room = player.room
    local targets = TargetGroup:getRealTargets(use.tos)
    local collateral = Fk:cloneCard("collateral")
    for _, pId in ipairs(targets) do
      local p = room:getPlayerById(pId)
      if p:isAlive() and p:canUseTo(collateral, player) then
        local availableTargets = table.map(
          table.filter(room.alive_players, function(to)
            return to ~= player and collateral.skill:targetFilter(to.id, { player.id }, {}, collateral, nil, p)
          end),
          Util.IdMapper
        )

        if #availableTargets > 0 then
          local tos = room:askToChoosePlayers(p, {
            targets = availableTargets,
            min_num = 1,
            max_num = 1,
            prompt = "#xiangjia-use::" .. player.id,
            skill_name = skill.name
          })
          if #tos > 0 then
            room:useCard{
              from = pId,
              tos = {{ player.id }, { tos[1].id }},
              card = collateral,
            }
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0 and player:getEquipment(Card.SubtypeWeapon)
  end,
})

return xiangjia

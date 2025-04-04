local yansha = fk.CreateSkill {
  name = "yansha"
}

Fk:loadTranslationTable{
  ['yansha'] = '宴杀',
  ['#yansha'] = '宴杀：你可视为使用指定任意目标的【五谷丰登】，结算后非目标可将装备当【杀】对目标使用',
  ['yanshaViewas'] = '宴杀',
  ['#yansha-slash'] = '宴杀：你可以将一张装备牌当无距离限制的【杀】对其中一名角色使用',
  [':yansha'] = '出牌阶段限一次，你可以视为使用一张以至少一名角色为目标的【五谷丰登】，然后所有非目标角色依次可以将一张装备牌当做无距离限制的【杀】对其中一名目标角色使用。',
}

yansha:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  prompt = "#yansha",
  can_use = function(self, player)
    return
      player:usedSkillTimes(yansha.name, Player.HistoryPhase) == 0 and
      player:canUse(Fk:cloneCard("amazing_grace"))
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return player:canUseTo(Fk:cloneCard("amazing_grace"), Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local amazingGrace = Fk:cloneCard("amazing_grace")
    amazingGrace.skillName = yansha.name

    local useData = {
      from = effect.from.id,
      tos = table.map(effect.tos, function(to) return { to.id } end),
      card = amazingGrace,
    }
    room:useCard(useData)

    local targets = TargetGroup:getRealTargets(useData.tos)
    if #targets > 0 then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isAlive() and not table.contains(targets, p.id) then
          room:setPlayerMark(p, yansha.name, TargetGroup:getRealTargets(useData.tos))
          local success, dat = room:askToUseActiveSkill(
            p,
            {
              skill_name = "yanshaViewas",
              prompt = "#yansha-slash",
              cancelable = true,
              extra_data = { bypass_times = true, bypass_distances = true }
            }
          )
          room:setPlayerMark(p, yansha.name, 0)

          if success then
            local card = Fk.skills["yanshaViewas"]:viewAs(dat.cards)
            table.removeOne(card.skillNames, "yanshaSlash")
            room:useCard{
              from = p.id,
              tos = table.map(dat.targets, function(toId) return { toId } end),
              card = card,
              extraUse = true,
            }
          end
        end
      end
    end
  end,
})

yansha:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return
      card and
      table.contains(card.skillNames, "yanshaSlash") and
      not table.contains(from:getTableMark(yansha.name), to.id)
  end,
})

return yansha

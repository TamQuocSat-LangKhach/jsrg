local lipan = fk.CreateSkill {
  name = "lipan"
}

Fk:loadTranslationTable{
  ['lipan'] = '离叛',
  ['#lipan-invoke'] = '离叛：你可以改变势力并摸牌，然后执行一个出牌阶段',
  ['#lipan-duel'] = '离叛：你可以将一张牌当【决斗】对 %dest 使用',
  [':lipan'] = '结束阶段结束时，你可以变更势力，然后摸X张牌并执行一个额外的出牌阶段（X为势力与你相同的其他角色数）。此阶段结束时，所有势力与你相同的其他角色可以将一张牌当【决斗】对你使用。',
}

lipan:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(lipan.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local kingdoms = {"Cancel", "wei", "shu", "wu", "qun", "jin"}
    local choices = table.simpleClone(kingdoms)
    table.removeOne(choices, player.kingdom)
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = lipan.name,
      prompt = "#lipan-invoke",
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeKingdom(player, event:getCostData(skill).choice, true)
    local tos = table.filter(room:getOtherPlayers(player, false), function(p) return p.kingdom == player.kingdom end)
    if #tos > 0 then
      player:drawCards(#tos, lipan.name)
    end
    if not player.dead then
      player:gainAnExtraPhase(Player.Play, true)
    end
  end,
})

lipan:addEffect(fk.EventPhaseEnd, {
  name = "#lipan_trigger",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Play and player:usedSkillTimes(lipan.name, Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player, false), function(p) return p.kingdom == player.kingdom and not p:isNude() end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if p.kingdom == player.kingdom and not p:isNude() and not p.dead then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          skill_name = "lipan",
          prompt = "#lipan-duel::"..player.id,
        })
        if #card > 0 then
          room:useVirtualCard("duel", card, p, player, "lipan")
        end
      end
    end
  end,
})

return lipan

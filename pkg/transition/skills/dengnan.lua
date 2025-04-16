local dengnan = fk.CreateSkill {
  name = "dengnan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["dengnan"] = "登难",
  [":dengnan"] = "限定技，出牌阶段，你可以视为使用一张非伤害类普通锦囊牌，此回合结束时，若此牌的目标均于此回合受到过伤害，你重置〖登难〗。",

  ["#dengnan"] = "登难：视为使用一种非伤害普通锦囊牌！若目标本回合均受到伤害则回合结束时重置！",
  ["@@dengnan-turn"] = "登难",
}

local U = require "packages/utility/utility"

dengnan:addEffect("viewas", {
  anim_type = "control",
  prompt = "#dengnan",
  interaction = function(self, player)
    if player:getMark(dengnan.name) == 0 then
      local names = table.filter(Fk:getAllCardNames("t"), function (name)
        return not Fk:cloneCard(name).is_damage_card
      end)
      player:setMark(dengnan.name, names)
    end
    local all_names = player:getMark(dengnan.name)
    local names = player:getViewAsCardNames(dengnan.name, all_names)
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = dengnan.name
    return card
  end,
  before_use = function (self, player, use)
    local mark = player:getTableMark("dengnan-turn")
    table.insertTableIfNeed(mark, table.map(use.tos, Util.IdMapper))
    player.room:setPlayerMark(player, "dengnan-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(dengnan.name, Player.HistoryGame) == 0
  end,
})

dengnan:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark("dengnan-turn") ~= 0 and player:hasSkill(dengnan.name, true) then
      local mark = player:getTableMark("dengnan-turn")
      player.room.logic:getActualDamageEvents(1, function(e)
        table.removeOne(mark, e.data.to.id)
      end, Player.HistoryTurn)
      return #mark == 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory(dengnan.name, 0, Player.HistoryGame)
  end,
})

return dengnan

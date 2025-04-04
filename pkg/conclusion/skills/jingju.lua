local jingju = fk.CreateSkill {
  name = "jingju"
}

Fk:loadTranslationTable{
  ['jingju'] = '惊惧',
  ['#jingju-choose'] = '惊惧：请选择你要移动判定区牌的角色',
  [':jingju'] = '你可以将其他角色判定区里的一张牌移至你的判定区里，视为你使用一张基本牌。',
  ['$jingju1'] = '朕有罪…求大将军饶恕…',
  ['$jingju2'] = '朕本无此心、绝无此心！'
}

jingju:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  interaction = function(skill)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(skill.player, jingju.name, all_names)
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(skill.interaction.data)
    card.skillName = jingju.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.map(table.filter(player.room:getOtherPlayers(player, false), function(p)
      return p:canMoveCardsInBoardTo(player, "j")
    end), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      prompt = "#jingju-choose",
      skill_name = jingju.name
    })
    local to = room:getPlayerById(tos[1])
    if to then
      room:askToMoveCardInBoard(player, {
        target_one = to,
        target_two = player,
        skill_name = jingju.name,
        flag = "j",
        move_from = to
      })
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p) return p:canMoveCardsInBoardTo(player, "j") end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      table.find(Fk:currentRoom().alive_players, function(p) return p:canMoveCardsInBoardTo(player, "j") end)
  end,
})

return jingju

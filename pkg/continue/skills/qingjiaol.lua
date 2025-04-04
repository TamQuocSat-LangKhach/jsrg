local qingjiaol = fk.CreateSkill {
  name = "qingjiaol"
}

Fk:loadTranslationTable{
  ['qingjiaol'] = '轻狡',
  ['#qingjiaol-sincere_treat'] = '轻狡：你可以将一张牌当【推心置腹】对一名手牌数大于你的角色使用',
  ['#qingjiaol-looting'] = '轻狡：你可以将一张牌当【趁火打劫】对一名手牌数小于你的角色使用',
  [':qingjiaol'] = '群势力技，出牌阶段各限一次，你可以将一张牌当【推心置腹】/【趁火打劫】对一名手牌数大于/小于你的角色使用。',
}

qingjiaol:addEffect('viewas', {
  anim_type = "control",
  prompt = function(self, player, selected_cards)
    if skill.interaction.data == "sincere_treat" then
      return "#qingjiaol-sincere_treat"
    elseif skill.interaction.data == "looting" then
      return "#qingjiaol-looting"
    end
  end,
  interaction = function(self, player)
    local names = {}
    for _, name in ipairs({"sincere_treat", "looting"}) do
      if player:getMark("qingjiaol_"..name.."-phase") == 0 then
        table.insert(names, name)
      end
    end
    return U.CardNameBox {choices = names}
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not skill.interaction.data then return end
    local card = Fk:cloneCard(skill.interaction.data)
    card.skillName = qingjiaol.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "qingjiaol_"..use.card.name.."-phase", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("qingjiaol_sincere_treat-phase") == 0 or player:getMark("qingjiaol_looting-phase") == 0
  end,
})

qingjiaol:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    if table.contains(card.skillNames, qingjiaol.name) then
      if card.name == "sincere_treat" then
        return to:getHandcardNum() <= from:getHandcardNum()
      elseif card.name == "looting" then
        return to:getHandcardNum() >= from:getHandcardNum()
      end
    end
  end,
})

return qingjiaol

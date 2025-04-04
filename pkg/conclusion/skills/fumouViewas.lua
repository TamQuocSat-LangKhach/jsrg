local fumou = fk.CreateSkill {
  name = "js__fumou"
}

Fk:loadTranslationTable{
  ['#js__fumou_viewas'] = '复谋',
  ['js__fumou'] = '复谋',
}

fumou:addEffect('viewas', {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).name == "shade"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("unexpectation")
    card:addSubcard(cards[1])
    card.skillName = "js__fumou_tag"
    return card
  end,
  before_use = function(self, player, use)
    table.remove(use.card.skillNames, "js__fumou_tag")
    use.card.skillName = fumou.name
  end,
})

return fumou

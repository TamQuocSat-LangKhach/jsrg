local fumou_viewas = fk.CreateSkill {
  name = "js__fumou_viewas",
}

Fk:loadTranslationTable{
  ["js__fumou_viewas"] = "复谋",
}

fumou_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).name == "shade"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("unexpectation")
    card:addSubcard(cards[1])
    card.skillName = "js__fumou"
    return card
  end,
})

return fumou_viewas

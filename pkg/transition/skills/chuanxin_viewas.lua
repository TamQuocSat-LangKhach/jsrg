local chuanxin_viewas = fk.CreateSkill {
  name = "js__chuanxin_viewas",
}

Fk:loadTranslationTable{
  ["js__chuanxin_viewas"] = "穿心",
}

chuanxin_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcards(cards)
    card.skillName = "js__chuanxin"
    return card
  end,
})

return chuanxin_viewas

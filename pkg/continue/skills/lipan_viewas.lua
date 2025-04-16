local lipan_viewas = fk.CreateSkill{
  name = "lipan_viewas",
}

Fk:loadTranslationTable{
  ["lipan_viewas"] = "离叛",
}

lipan_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = "lipan"
    c:addSubcard(cards[1])
    return c
  end,
})

return lipan_viewas

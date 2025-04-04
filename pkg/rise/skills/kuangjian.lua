local kuangjian = fk.CreateSkill {
  name = "kuangjian"
}

Fk:loadTranslationTable{
  ['kuangjian'] = '匡谏',
  ['#kuangjian'] = '匡谏：将装备牌当任意基本牌使用（目标不能为你且无次数限制），结算后目标角色使用弃牌堆中此装备牌',
  [':kuangjian'] = '你可以将装备牌当任意基本牌使用（目标不能为你且无次数限制），结算后目标角色使用弃牌堆中的此装备牌。',
}

-- ViewAsSkill
kuangjian:addEffect('viewas', {
  anim_type = "special",
  pattern = ".|.|.|.|.|basic",
  prompt = "#kuangjian",
  interaction = function(skill)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(skill.player, kuangjian.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  before_use = function (skill, player, use)
    use.extraUse = true
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(skill.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = kuangjian.name
    return card
  end,
  after_use = function (skill, player, use)
    local room = player.room
    if table.contains(room.discard_pile, use.card.subcards[1]) then
      local card = Fk:getCardById(use.card.subcards[1])
      if card.type ~= Card.TypeEquip then return end
      for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
        local p = room:getPlayerById(id)
        if not p.dead and not p:prohibitUse(card) then
          room:useCard{
            from = p.id,
            tos = {{p.id}},
            card = card,
          }
        end
      end
    end
  end,
  enabled_at_response = function (skill, player, response)
    local banner = Fk:currentRoom():getBanner("kuangjian_dying")
    if banner == player.id then return false end
    return not response
  end,
})

-- ProhibitSkill
kuangjian:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return table.contains(card.skillNames, "kuangjian") and from == to
  end,
})

-- TargetModSkill
kuangjian:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "kuangjian")
  end,
})

-- TriggerSkill
kuangjian:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return data.cardName == "peach" and data.extraData and table.contains(data.extraData.must_targets or {}, player.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not data.afterRequest then
      room:setBanner("kuangjian_dying", player.id)
    else
      room:setBanner("kuangjian_dying", 0)
    end
  end,
})

return kuangjian

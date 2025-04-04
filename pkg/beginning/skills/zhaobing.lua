local zhaobing = fk.CreateSkill {
  name = "zhaobing"
}

Fk:loadTranslationTable{
  ['zhaobing'] = '诏兵',
  ['#zhaobing-invoke'] = '诏兵：你可以弃置全部手牌，令等量其他角色选择交给你一张【杀】或失去1点体力',
  ['#zhaobing-choose'] = '诏兵：选择至多%arg名其他角色，依次选择交给你一张【杀】或失去1点体力',
  ['#zhaobing-card'] = '诏兵：交给 %src 一张【杀】，否则失去1点体力',
  [':zhaobing'] = '结束阶段，你可以弃置全部手牌，然后令至多等量的其他角色各选择一项：1.展示并交给你一张【杀】；2.失去1点体力。',
}

zhaobing:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhaobing.name) and player.phase == Player.Finish and not player:isKongcheng() and
      table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = zhaobing.name, prompt = "#zhaobing-invoke" })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player.dead then return end
    local targets = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = n,
      prompt = "#zhaobing-choose:::"..n,
      skill_name = zhaobing.name,
      cancelable = true
    })
    if #targets == 0 then return end
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if p:isKongcheng() or player.dead then
          room:loseHp(p, 1, zhaobing.name)
        else
          local card = room:askToCards(p, {
            min_num = 1,
            max_num = 1,
            pattern = "slash",
            prompt = "#zhaobing-card:"..player.id,
            skill_name = zhaobing.name,
            cancelable = true
          })
          if #card > 0 then
            p:showCards(card)
            if not player.dead and table.contains(p:getCardIds("h"), card[1]) then
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, zhaobing.name, nil, true, p.id)
            end
          else
            room:loseHp(p, 1, zhaobing.name)
          end
        end
      end
    end
  end,
})

return zhaobing

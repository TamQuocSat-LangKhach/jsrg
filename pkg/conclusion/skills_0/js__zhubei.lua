local js__zhubei = fk.CreateSkill {
  name = "js__zhubei"
}

Fk:loadTranslationTable{
  ['js__zhubei'] = '逐北',
  [':js__zhubei'] = '锁定技，你对本回合受到过伤害/失去过最后手牌的角色造成的伤害+1/使用牌无次数限制。',
}

js__zhubei:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(js__zhubei.name) and
      #player.room.logic:getActualDamageEvents(2, function(e)
        return e.data[1].to == data.to
      end) > 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  can_refresh = function (self, event, target, player, data)
    if player:getMark(js__zhubei.name .. "_lost-turn") == 0 and player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, js__zhubei.name .. "_lost-turn", 1)
  end,
})

local js__zhubei_targetmod = fk.CreateSkill {
  name = "#js__zhubei_targetmod"
}

js__zhubei_targetmod:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and player:hasSkill(js__zhubei.name) and to and to:getMark(js__zhubei.name .. "_lost-turn") > 0
  end,
})

return js__zhubei

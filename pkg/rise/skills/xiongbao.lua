local xiongbao = fk.CreateSkill {
  name = "xiongbao",
}

Fk:loadTranslationTable{
  ["xiongbao"] = "凶暴",
  [":xiongbao"] = "当你参与议事选择议事牌前，你可以改为额外展示一张手牌，若如此做，其他角色改为随机展示一张手牌。",

  ["#xiongbao-invoke"] = "擅政：%dest 发起“%arg”议事，你可以展示两张意见牌（双倍意见！）令其他议事角色改为随机展示一张手牌",
}

local U = require "packages/utility/utility"

xiongbao:addEffect(U.StartDiscussion, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiongbao.name) and
      (player == data.from or table.contains(data.tos, player)) and
      player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      include_equip = false,
      skill_name = xiongbao.name,
      cancelable = true,
      prompt = "#xiongbao-invoke::" .. data.from.id .. ":" .. data.reason,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(data.tos) do
      data.results[p] = data.results[p] or {}
      if p == player then
        data.results[player].toCards = event:getCostData(self).cards
        local card = table.map(event:getCostData(self).cards, function (id)
          return Fk:getCardById(id)
        end)
        if card[1]:getColorString() == card[2]:getColorString() then
          data.results[player].opinion = card[1]:getColorString()
        else
          data.results[player].opinion = "noresult"
        end
      else
        local id = table.random(p:getCardIds("h"))
        data.results[p].toCards = {id}
        data.results[p].opinion = Fk:getCardById(id):getColorString()
      end
    end
  end,
})

return xiongbao

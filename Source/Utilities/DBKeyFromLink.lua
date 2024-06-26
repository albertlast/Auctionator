function Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
  if itemLink ~= nil then
    local _, _, itemString = string.find(itemLink, "^|c%x+|H(.+)|h%[.*%]")
    if itemString == nil and string.find(itemLink, "^item") then
      itemString = itemLink
    end
    if itemString ~= nil then
      local linkType, itemId, _, _, _, _, _, _, _ = strsplit(":", itemString)
      if linkType == "battlepet" then
        return "p:"..itemId;
      elseif linkType == "item" then
        return itemId;
      end
    end
  end
  return nil
end

local function IsGear(itemLink)
  local classType = select(6, C_Item.GetItemInfoInstant(itemLink))
  return classType ~= nil and Auctionator.Utilities.IsEquipment(classType)
end

function Auctionator.Utilities.DBKeyFromLink(itemLink, callback)
  local basicKey = Auctionator.Utilities.BasicDBKeyFromLink(itemLink)

  if basicKey == nil then
    callback({})
    return
  end

  if IsGear(itemLink) then
    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then
      callback({})
      return
    end

    item:ContinueOnItemLoad(function()
      local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) or 0
      local name = item:GetItemName()

      if Auctionator.Constants.IsClassic and itemLevel >= Auctionator.Constants.ITEM_LEVEL_THRESHOLD then
        callback({"gn:" .. basicKey .. ":" .. name .. ":" .. itemLevel, "g:" .. basicKey .. ":" .. itemLevel, basicKey})
      elseif not Auctionator.Constants.IsClassic and itemLevel >= Auctionator.Constants.ITEM_LEVEL_THRESHOLD then
        callback({"g:" .. basicKey .. ":" .. itemLevel, basicKey})
      else
        callback({basicKey})
      end
    end)
  else
    callback({basicKey})
  end
end

function Auctionator.Utilities.DBKeysFromMultipleLinks(itemLinks, callback)
  local result = {}

  for index, link in ipairs(itemLinks) do
    Auctionator.Utilities.DBKeyFromLink(link, function(dbKeys)
      result[index] = dbKeys

      for i = 1, #itemLinks do
        if result[i] == nil then
          return
        end
      end
      callback(result)
    end)
  end
end

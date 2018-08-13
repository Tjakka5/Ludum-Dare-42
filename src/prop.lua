local Lovox  = require("lib.lovox")
local Assets = require("assets/assets").prop

return Lovox.newVoxelBatch(love.graphics.newArrayImage(Assets), Assets.layers, 300, "static")

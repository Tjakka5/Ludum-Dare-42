local Class = require("lib.class")
local Lovox = require("lib.lovox")
local Vec3  = require("lib.vec3")

local Entity = require("src.entity")
local World  = require("src.world")

local Enemy = Class("Enemy", Entity)
Enemy.isEnemy = true
Enemy.image = love.graphics.newArrayImage({
   "assets/skeleton0.png",
   "assets/skeleton1.png",
   "assets/skeleton2.png",
   "assets/skeleton1-stab.png"
})
Enemy.batch = Lovox.newVoxelBatch(Enemy.image, 48, 100, "dynamic")

Enemy.animations = {
   idle    = {1},
   walking = {2, 1, 0, 1},
   stab    = {3},
}
Enemy.animTimer = 0
Enemy.animIndex = 1
Enemy.state     = "walking"

function Enemy:initialize(...)
   Entity.initialize(self, ...)

   self.shape = World:circle(self.position.x, self.position.y, 20)
   self.shape.obj = self

   self.id = self.batch:add(self.position.x, self.position.y, self.position.z, -math.pi/2, 2)
end

function Enemy:idle(dt)
   Enemy.batch:setAnimationFrame(self.id, 1)

   return "idle"
end

function Enemy:walking(dt)
   if self.animIndex > 4 then
      self.animIndex = 1
   end

   self.position = self.position + (Vec3(math.cos(self.rotation), math.sin(self.rotation), 0) * 0.1)

   return "walking"
end

function Enemy:stab(dt)
   if self.animIndex > 2 then
      self.animIndex = 1
      return "stab"
   end

   return "stab"
end


function Enemy:onHit()
   self.isAlive = false

   return true
end

function Enemy:onDeath()
   Entity.onDeath(self)
   self.batch:setTransformation(self.id, 0, 0, 0, 0)
end

function Enemy:update(dt)
   Entity.update(self, dt)

   self.animTimer = self.animTimer + dt
   if self.animTimer >= 0.15 then
      self.animTimer = 0
      self.animIndex = self.animIndex + 1
   end

   self.state = self[self.state](self, dt)
   Enemy.batch:setAnimationFrame(self.id, self.animations[self.state][self.animIndex])

   self.batch:setTransformation(self.id, self.position.x, self.position.y, self.position.z, self.rotation - math.pi/2, 2)
   self.shape:moveTo(self.position.x, self.position.y)
end

function Enemy.render()
   Enemy.batch:draw()
end

return Enemy

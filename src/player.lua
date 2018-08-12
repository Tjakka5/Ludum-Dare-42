local Class = require("lib.class")
local Lovox = require("lib.lovox")
local Vec3  = require("lib.vec3")
local Input = require("lib.input")
local Timer = require("lib.timer")
local Trail = require("lib.trail")

local Entity   = require("src.entity")
local World    = require("src.world")

local Player = Class("Player", Entity)
Player.isPlayer = true
Player.image = love.graphics.newArrayImage({
   "assets/knight.png"
})
Player.batch = Lovox.newVoxelBatch(Player.image, 48, 1, "dynamic")

Player.acceleration = 5000
Player.maxVelocity  = 350
Player.friction     = 15

Player.dashing      = false
Player.dashSpeed    = 4500
Player.curDashSpeed = 0
Player.dashFriction = 10

Player.chain = 0
Player.chainTimer = nil

Player.animations = {
   idle    = {1},
   walking = {1, 1, 1, 1},
   stab    = {1},
}
Player.animTimer = 0
Player.animIndex = 1
Player.state     = "idle"

Player.trails = {}


function Player:initialize(entities, ...)
   Entity.initialize(self, ...)
   self.shape = World:circle(self.position.x, self.position.y, 20)
   self.shape.obj = self

   self.input = Input()
   self.input:registerCallbacks()

   self.controller = self.input:newController({
      moveUp    = {"key:w", "key:up"},
      moveLeft  = {"key:a", "key:left"},
      moveDown  = {"key:s", "key:down"},
      moveRight = {"key:d", "key:right"},
      dash      = {"mouse:1"},
   })
   
   self.batch:add(self.position.x, self.position.y, self.position.z, -math.pi/2, 2)

   self.entities = entities
end


function Player:idle(dt)
   return "idle"
end

function Player:walking(dt)
   if self.animIndex > 4 then
      self.animIndex = 1
   end

   self.position = self.position + (Vec3(math.cos(self.rotation), math.sin(self.rotation), 0) * 0.1)

   return "walking"
end

function Player:stab(dt)
   if self.animIndex > 2 then
      self.animIndex = 1
      return "stab"
   end

   return "stab"
end

function Player:update(dt)
   Entity.update(self, dt)
   
   if not self.dashing then
      -- Input
      local movementVector = Vec3(
         self.controller:get("moveRight") - self.controller:get("moveLeft"), 
         self.controller:get("moveDown")  - self.controller:get("moveUp"),
         0
      )

      self.velocity = self.velocity + movementVector * self.acceleration * dt

      -- Friction and speed clamp
      self.velocity = self.velocity:trim(self.maxVelocity)
      
   end

   local friction = self.dashing and self.dashFriction or self.friction
   self.velocity = self.velocity - (self.velocity * friction * dt)

   if self.velocity:len() < 0.1 then
      self.velocity.x, self.velocity.y, self.velocity.z = 0, 0, 0
   end
   
   -- Move
   self.position = self.position + self.velocity * dt

   -- Collision
   self.shape:moveTo(self.position.x, self.position.y)
   for other, sep_vec in pairs(World:collisions(self.shape)) do
      other = other.obj

      self.position.x = self.position.x + sep_vec.x
      self.position.y = self.position.y + sep_vec.y

      if self.dashing then
         if other.isEnemy then
            if other:onHit() then
               self.chain = self.chain + 1

               if self.timer then
                  Timer.cancel(self.timer)
               end

               self.timer = Timer.after(0.5, function()
                  self.chain = 0
                  self.timer = nil
               end)
            end

            self.dashing = false
         end

         local s = 2 * (self.velocity.x * sep_vec.x + self.velocity.y * sep_vec.y) / (sep_vec.x * sep_vec.x + sep_vec.y * sep_vec.y)
         self.velocity = -Vec3(s * sep_vec.x - self.velocity.x, s * sep_vec.y - self.velocity.y, 0)
      end
   end
   self.shape:moveTo(self.position.x, self.position.y)

   -- Rotation
   self.rotation = math.atan2(love.mouse.getY() - self.position.y, love.mouse.getX() - self.position.x)

   -- Activate dash
   if not self.dashing then
      if self.controller:pressed("dash") then
         self.velocity = Vec3(math.cos(self.rotation), math.sin(self.rotation), 0) * self.dashSpeed
         self.dashing = true

         local trail = Trail:new({
            type = "mesh",
            content = {
               source = love.graphics.newImage("assets/trail.png"),
               width = 48,
               mode = "stretch",
            },
            duration = 0.4,
         })
         trail:setMotion(0, 0)
         trail:setPosition(self.position.x, self.position.y - 32)
   
         table.insert(self.trails, 1, trail)
      end
   end

   -- Dashing
   if self.dashing then
      if self.velocity:len() < 30 then
         self.dashing = false
      end

      self.trails[1]:setMotion(0, 0)
      self.trails[1]:setPosition(self.position.x, self.position.y - 32)
   end

   -- Update data
   self.state = self[self.state](self, dt)
   Player.batch:setAnimationFrame(1, self.animations[self.state][self.animIndex])

   self.batch:setTransformation(1, self.position.x, self.position.y, self.position.z, self.rotation - math.pi/2, 2)
   self.controller:endFrame()
end

function Player.render()
   Player.batch:draw()
end

return Player

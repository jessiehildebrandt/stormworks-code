--------------------------------------------------------------------------------
-- Touchscreen GPS Map Controller
-- Touchscreen UI code

--------------------------------------------------------------------------------
-- Composite inputs

-- Boolean
-- [1-2] - Touch input data

-- Number
-- [1-6] - Touch input data
-- [7] - GPS X output signal
-- [8] - GPS Y output signal
-- [9] - Compass sensor signal

--------------------------------------------------------------------------------
-- Button class

Button = {}
Button.__index = Button

----------------------------------------
-- Button:updatePressedState
-- Updates the "pressed" state of the button

function Button:updatePressedState( isPressed, inputX, inputY )

   -- If the screen isn't being touched then nothing is being pressed
   if not isPressed then
      self.pressed = false
      return
   end

   -- Check if the input coordinates are within the button's bounding box
   if inputX > self.x
      and inputY > self.y
      and inputX < self.x + self.width
      and inputY < self.y + self.height
   then
      self.pressed = true
      self.callbackFunc()
   else
      self.pressed = false
   end

end

----------------------------------------
-- Button:draw
-- Draws the button object to the screen

function Button:draw()
   if self.pressed then

      -- Draw background
      screen.drawRect( self.x, self.y, self.width, self.height )
      screen.drawRectF( self.x, self.y, self.width, self.height )

      -- Draw text
      screen.setColor( 0, 0, 0 )
      screen.drawTextBox( self.x + 1, self.y + 1, self.width, self.height, self.text, 0, 0 )
      screen.setColor( 255, 255, 255 )

   else

      -- Draw background
      screen.drawRect( self.x, self.y, self.width, self.height )

      -- Draw text
      screen.drawTextBox( self.x + 1, self.y + 1, self.width, self.height, self.text, 0, 0 )

   end
end

----------------------------------------
-- Button:new
-- Creates a new button object

function Button:new( x, y, width, height, text, callbackFunc )

   -- Create new object
   local newButton = {}

   -- Set button properties
   newButton.x = x
   newButton.y = y
   newButton.width = width
   newButton.height = height
   newButton.text = text
   newButton.pressed = false
   newButton.callbackFunc = callbackFunc

   -- Set class functions appropriately (No 'setmetatable' in Stormworks yet... :c)
   newButton.updatePressedState = Button.updatePressedState
   newButton.draw = Button.draw

   -- Return new object
   return newButton

end

--------------------------------------------------------------------------------
-- drawShipIndicator
-- Draws an indicator to the screen at the provided coordinates with an angle indicator

function drawShipIndicator( centerX, centerY, angle )

   -- Convert provided angle to radians
   angle = math.rad( angle )

   -- Calculate angle vector for angle indicator
   local c = math.cos( angle )
   local s = math.sin( angle )
   local vecX = ( c * 0 ) - ( s * -2 )
   local vecY = ( s * 0 ) + ( c * -2 )

   -- Calculate angle indicator screen position
   local indicatorX = centerX + vecX
   local indicatorY = centerY + vecY

   -- Draw ship indicator to the provided coordinates
   screen.setColor( 255, 255, 255 )
   screen.drawCircleF( centerX, centerY, 1 )

   -- Draw angle indicator around the ship indicator
   screen.setColor( 255, 0, 0 )
   screen.drawCircleF( indicatorX, indicatorY, 1 )
   screen.setColor( 255, 255, 255 )

end

--------------------------------------------------------------------------------
-- Global data

-- Persistent map state data
mapZoom = 2

-- Persistent GPS data
gpsX = 0
gpsY = 0
gpsAngle = 0

-- UI object
ui = {
   initialized = false,
   pressTriggered = false,
   buttons = {}
}

--------------------------------------------------------------------------------
-- onTick
-- Runs every physics engine tick

function onTick()

   -- Get GPS data from composite input
   gpsX = input.getNumber( 7 )
   gpsY = input.getNumber( 8 )
   gpsAngle = ( ( 1 - input.getNumber( 9 ) ) % 1 ) * 360

   -- Get input values, if any
   local isPressed = input.getBool( 1 )
   local inputX = input.getNumber( 3 )
   local inputY = input.getNumber( 4 )

   -- Update button press states
   for _, button in pairs( ui.buttons ) do
      button:updatePressedState( isPressed, inputX, inputY )
   end

end

--------------------------------------------------------------------------------
-- onDraw
-- Runs every time the screen is redrawn

function onDraw()

   -- Get basic screen properties
   screenWidth = screen.getWidth()
   screenHeight = screen.getHeight()
   centerX = screenWidth / 2
   centerY = screenHeight / 2

   -- Initialize UI objects if necessary
   if not ui.initialized then
      ui.buttons.zoomInButton = Button:new(
         screenWidth - 20, 2, 7, 7, '+',
         function() mapZoom = math.min( math.max( mapZoom - 0.075, 0.5 ), 10 ) end
      )
      ui.buttons.zoomOutButton = Button:new(
         screenWidth - 10, 2, 7, 7, '-',
         function() mapZoom = math.min( math.max( mapZoom + 0.075, 0.5 ), 10 ) end
      )
      ui.initialized = true
   end

   -- Map colors: land
   screen.setMapColorLand( 0, 255, 0 )
   screen.setMapColorGrass( 0, 255, 0 )
   screen.setMapColorSand( 0, 255, 0 )
   screen.setMapColorSnow( 0, 255, 0 )

   -- Map colors: water
   screen.setMapColorShallows( 0, 0, 0 )
   screen.setMapColorOcean( 0, 0, 0 )

   -- Draw map
   screen.drawMap( gpsX, gpsY, mapZoom )

   -- Draw ship indicator
   drawShipIndicator( centerX, centerY, gpsAngle )

   -- Draw buttons
   for _, button in pairs( ui.buttons ) do
      button:draw()
   end

end

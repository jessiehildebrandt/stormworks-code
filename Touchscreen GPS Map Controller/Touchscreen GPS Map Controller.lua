--------------------------------------------------------------------------------
-- Touchscreen GPS Map Controller
-- Touchscreen UI code

--------------------------------------------------------------------------------
-- Composite Inputs

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

function Button:updatePressedState( inputX, inputY )

   -- Check if the input coordinates are within the button's bounding box
   if inputX > self.x
      and inputY > self.y
      and inputX < self.x + self.width
      and inputY < self.y + self.height
   then
      self.pressed = true
   else
      self.pressed = false
   end

end

----------------------------------------
-- Button:draw
-- Draws the button object to the screen

function Button:draw()

   -- Draw button background
   if self.pressed then
      screen.drawRectF( self.x, self.y, self.width, self.height )
   else
      screen.drawRect( self.x, self.y, self.width, self.height )
   end

   -- Draw button text
   screen.drawTextBox( self.x, self.y, self.width, self.height, self.text, 0, 0 )

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

   -- Set class functions appropriately (No 'setmetatable' in Stormworks yet... :c)
   newButton.updatePressedState = Button.updatePressedState
   newButton.draw = Button.draw

   -- Return new object
   return newButton

end

--------------------------------------------------------------------------------
-- drawRotatedTriangle
-- Draws a triangle to the screen at the provided coordinates and angle

function drawRotatedTriangle( centerX, centerY, size, angle )

   -- Calculate pre-rotation coordinates
   local x1 = centerX;
   local y1 = centerY - size / 2
   local x2 = centerX + size / 2
   local y2 = centerY + size / 2
   local x3 = centerX - size / 2
   local y3 = y2

   -- Convert angle to radians
   angle = math.rad( angle )

   -- Calculate rotated coordinates
   local x1r = ( x1 - centerX ) * math.cos( angle ) - ( y1 - centerY ) * math.sin( angle ) + centerX
   local y1r = ( x1 - centerX ) * math.sin( angle ) + ( y1 - centerY ) * math.cos( angle ) + centerY

   local x2r = ( x2 - centerX ) * math.cos( angle ) - ( y2 - centerY ) * math.sin( angle ) + centerX
   local y2r = ( x2 - centerX ) * math.sin( angle ) + ( y2 - centerY ) * math.cos( angle ) + centerY

   local x3r = ( x3 - centerX ) * math.cos( angle ) - ( y3 - centerY ) * math.sin( angle ) + centerX
   local y3r = ( x3 - centerX ) * math.sin( angle ) + ( y3 - centerY ) * math.cos( angle ) + centerY

   -- Draw triangle
   screen.drawTriangle( x1r, y1r, x2r, y2r, x3r, y3r )

end

--------------------------------------------------------------------------------
-- Global data

-- Persistent map state data
mapZoom = 4

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
   gpsAngle = input.getNumber( 9 )

   -- Get input values, if any
   local isPressed = input.getBool( 1 )
   local inputX = input.getNumber( 3 )
   local inputY = input.getNumber( 4 )

   -- Handle presses
   if isPressed then

      -- Update button press states
      for _, button in pairs(ui.buttons) do
         button:updatePressedState( inputX, inputY )
      end

   end

   -- Check button press states and trigger actions
   if ui.initialized then

      -- Trigger zoom in button function on press
      if ui.buttons.zoomInButton.pressed then
         if mapZoom > 0.1 then
            mapZoom = mapZoom - 0.1
         else
            mapZoom = 0.1
         end
      end

      -- Trigger zoom out button function on press
      if ui.buttons.zoomOutButton.pressed then
         if mapZoom < 50 then
            mapZoom = mapZoom + 0.1
         else
            mapZoom = 50
         end
      end

   end

   -- Clear all press states if no pressing is happening
   if not isPressed then
      for _, button in pairs(ui.buttons) do
         button.pressed = false
      end
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

   -- Map colors: land
   screen.setMapColorLand( 0, 255, 0 )
   screen.setMapColorGrass( 0, 255, 0 )
   screen.setMapColorSand( 0, 255, 0 )
   screen.setMapColorSnow( 0, 255, 0 )

   -- Map colors: water
   screen.setMapColorShallows( 0, 0, 255 )
   screen.setMapColorOcean( 0, 0, 0 )

   -- Draw map
   screen.drawMap( gpsX, gpsY, mapZoom )

   -- Draw ship indicator
   drawRotatedTriangle( centerX, centerY, 4, gpsAngle )

   -- Initialize UI objects
   if not ui.initialized then
      ui.buttons.zoomInButton = Button:new( screenWidth - 14, screenHeight - 8, 6, 6, '+')
      ui.buttons.zoomOutButton = Button:new( screenWidth - 8, screenHeight - 8, 6, 6, '-')
      ui.initialized = true
   end

   -- Draw buttons
   if ui.initialized then
      for _, button in pairs(ui.buttons) do
         button:draw()
      end
   end

end

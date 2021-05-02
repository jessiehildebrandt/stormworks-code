--------------------------------------------------------------------------------
-- Touchscreen GPS Map + Radar Controller
-- Touchscreen UI code

--------------------------------------------------------------------------------
-- Composite inputs

-- Boolean
-- [1-2] - Touch input data
-- [3] - Radar target found
-- [4] - Radar power

-- Number
-- [1-6] - Touch input data
-- [7] - GPS X output signal
-- [8] - GPS Y output signal
-- [9] - Compass sensor signal
-- [10] - Radar signal strength
-- [11] - Radar target distance
-- [12] - Radar rotation
-- [13] - Radar range

--------------------------------------------------------------------------------
-- Composite outputs

-- Boolean
-- [5] - Radar beep

--------------------------------------------------------------------------------
-- ui library

ui = {

   ----------------------------------------
   -- UI state

   initialized = false,
   pressTriggered = false,
   buttons = {},

   ----------------------------------------
   -- initialize
   -- Initializes the UI

   initialize = function()

      ui.buttons.zoomInButton = uiButton.create(
         screenWidth - 18, 2, 6, 6, '+',
         function() mapZoom = math.min( math.max( mapZoom - 0.075, 0.5 ), 10 ) end
      )

      ui.buttons.zoomOutButton = uiButton.create(
         screenWidth - 9, 2, 6, 6, '-',
         function() mapZoom = math.min( math.max( mapZoom + 0.075, 0.5 ), 10 ) end
      )

      ui.initialized = true

   end

}

--------------------------------------------------------------------------------
-- uiButton library

uiButton = {

   ----------------------------------------
   -- updatePressedState
   -- Updates the "pressed" state of a button

   updatePressedState = function( button, isPressed, inputX, inputY )

      -- If the screen isn't being touched then nothing is being pressed
      if not isPressed then
         button.pressed = false
         return
      end

      -- Check if the input coordinates are within the button's bounding box
      if inputX > button.x
         and inputY > button.y
         and inputX < button.x + button.width
         and inputY < button.y + button.height
      then
         button.pressed = true
         button.callbackFunc()
      else
         button.pressed = false
      end

   end,

   ----------------------------------------
   -- draw
   -- Draws a button object to the screen

   draw = function( button )

      if button.pressed then

         -- Draw background
         screen.setColor( table.unpack( UI_FG_COLOR ) )
         screen.drawRect( button.x, button.y, button.width, button.height )
         screen.drawRectF( button.x, button.y, button.width, button.height )

         -- Draw text
         screen.setColor( table.unpack( UI_BG_COLOR ) )
         screen.drawTextBox( button.x + 1, button.y + 1, button.width, button.height, button.text, 0, 0 )

      else

         -- Draw border
         screen.setColor( table.unpack( UI_FG_COLOR ) )
         screen.drawRect( button.x, button.y, button.width, button.height )

         -- Draw text
         screen.setColor( table.unpack( UI_FG_COLOR ) )
         screen.drawTextBox( button.x + 1, button.y + 1, button.width, button.height, button.text, 0, 0 )

      end

   end,

   ----------------------------------------
   -- create
   -- Creates a new button object

   create = function( x, y, width, height, text, callbackFunc )

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

      -- Return new object
      return newButton

   end

}

--------------------------------------------------------------------------------
-- drawShipIndicator
-- Draws an indicator to the screen at the provided coordinates with an angle indicator

function drawShipIndicator( centerX, centerY, angle )

   -- Convert provided angle to radians
   angle = math.rad( angle )

   -- Calculate angle vector for angle indicator
   local c = math.cos( angle )
   local s = math.sin( angle )
   local vecX = ( c * 0 ) - ( s * -3 )
   local vecY = ( s * 0 ) + ( c * -3 )

   -- Calculate angle indicator screen position
   local indicatorX = centerX + vecX
   local indicatorY = centerY + vecY

   -- Draw ship indicator to the provided coordinates
   screen.setColor( table.unpack( SHIP_COLOR ) )
   screen.drawRectF( centerX, centerY, 1, 1 )

   -- Draw angle indicator around the ship indicator
   screen.setColor( table.unpack( ANGLE_INDICATOR_COLOR ) )
   screen.drawRectF( indicatorX, indicatorY, 1, 1 )

end

--------------------------------------------------------------------------------
-- drawRadarSweep
-- Draws a visual radar sweep to the screen at the provided coordinates

function drawRadarSweep( centerX, centerY, radius, angle )

   -- Convert provided angle to radians
   angle = math.rad( angle )

   -- Calculate sweep triangle coordinates
   local x2 = centerX + radius * math.cos( angle - math.rad( 90 ) )
   local y2 = centerY + radius * math.sin( angle - math.rad( 90 ) )

   -- Draw sweep line to screen
   screen.setColor( table.unpack( RADAR_COLOR ) )
   screen.drawLine( centerX, centerY, x2, y2 )

end

--------------------------------------------------------------------------------
-- Constants

-- Radar configuration
RADAR_CONTACT_LINGER_FRAMES = 180
RADAR_MIN_CONTACT_DISTANCE = 100

-- UI colors
UI_FG_COLOR = { 200, 200, 200 }
UI_BG_COLOR = { 0, 0, 0 }

-- Map colors
LAND_COLOR = { 0, 0, 0 }
WATER_COLOR = { 0, 0, 100 }

-- Overlay colors
RADAR_COLOR = { 200, 200, 0 }
SHIP_COLOR = { 200, 200, 200 }
ANGLE_INDICATOR_COLOR = { 200, 0, 0 }

--------------------------------------------------------------------------------
-- Global data

-- Persistent map state data
mapZoom = 2

-- Persistent GPS data
gpsX = 0
gpsY = 0
gpsAngle = 0

-- Persistent radar data
radarContacts = {}
radarRotation = 0
radarPower = false
radarRange = 1000

--------------------------------------------------------------------------------
-- onTick
-- Runs every physics engine tick

function onTick()

   -- Get GPS data from composite input
   gpsX = input.getNumber( 7 )
   gpsY = input.getNumber( 8 )
   gpsAngle = ( ( 1 - input.getNumber( 9 ) ) % 1 ) * 360

   -- Get radar data from composite input
   local radarTargetFound = input.getBool( 3 )
   radarPower = input.getBool( 4 )
   local radarSignalStrength = input.getNumber( 10 )
   local radarTargetDistance = input.getNumber( 11 )
   radarRotation =  math.abs( input.getNumber( 12 ) * 360 ) + gpsAngle
   radarRange = input.getNumber( 13 )

   -- Get input values, if any
   local isPressed = input.getBool( 1 )
   local inputX = input.getNumber( 3 )
   local inputY = input.getNumber( 4 )

   -- Update button press states
   for _, button in pairs( ui.buttons ) do
      uiButton.updatePressedState( button, isPressed, inputX, inputY )
   end

   -- If the radar system is off, we can just stop here (and make sure the contact list is empty)
   if not radarPower then
      radarContacts = {}
      return
   end

   -- Add new radar target to contact list, if any
   if radarTargetFound and radarTargetDistance > RADAR_MIN_CONTACT_DISTANCE then

      -- Output a beep signal
      output.setBool( 5, true )

      -- Calculate target position relative to current ship position
      local c = math.cos( math.rad( radarRotation ) )
      local s = math.sin( math.rad( radarRotation ) )
      local targetRelativeX = ( c * 0 ) - ( s * -radarTargetDistance )
      local targetRelativeY = ( s * 0 ) - ( c * -radarTargetDistance )

      -- Add target to list of contacts
      table.insert( radarContacts, {
            aliveFrames = 0,
            mass = radarSignalStrength * radarTargetDistance,
            relativeX = targetRelativeX,
            relativeY = targetRelativeY,
            gpsXOrigin = gpsX,
            gpsYOrigin = gpsY
      } )

   else

      -- Do not output a beep signal
      output.setBool( 5, false )

   end

   -- Update radar contact lifespans
   contactsToRemove = {}
   for index, contact in pairs( radarContacts ) do
      contact.aliveFrames = contact.aliveFrames + 1
      if contact.aliveFrames >= RADAR_CONTACT_LINGER_FRAMES then
         table.insert( contactsToRemove, index )
      end
   end

   -- Remove expired contacts
   for _, contactIndex in pairs( contactsToRemove ) do
      table.remove( radarContacts, contactIndex )
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
      ui.initialize()
   end

   -- Map colors: land
   screen.setMapColorLand( table.unpack( LAND_COLOR ) )
   screen.setMapColorGrass( table.unpack( LAND_COLOR ) )
   screen.setMapColorSand( table.unpack( LAND_COLOR ) )
   screen.setMapColorSnow( table.unpack( LAND_COLOR ) )

   -- Map colors: water
   screen.setMapColorShallows( table.unpack( WATER_COLOR ) )
   screen.setMapColorOcean( table.unpack( WATER_COLOR ) )

   -- Draw map
   screen.drawMap( gpsX, gpsY, mapZoom )

   -- Draw radar overlay (if enabled)
   if radarPower then

      -- Draw radar sweep
      local _, trueRadarRadius = map.mapToScreen(
         0, 0, mapZoom,
         screenWidth, screenHeight,
         0, -radarRange
      )
      trueRadarRadius = trueRadarRadius - centerY
      drawRadarSweep( centerX, centerY, trueRadarRadius, radarRotation )

      -- Draw radar contacts
      for _, contact in pairs( radarContacts ) do
         local contactX, contactY = map.mapToScreen(
            gpsX, gpsY, mapZoom,
            screenWidth, screenHeight,
            contact.gpsXOrigin + contact.relativeX, contact.gpsYOrigin + contact.relativeY
         )
         local contactSize = math.min( math.max( contact.mass / 50000, 1 ), 5 )
         screen.setColor( table.unpack( RADAR_COLOR ) )
         screen.drawCircleF( contactX, contactY, contactSize )
      end

   end

   -- Draw ship indicator
   drawShipIndicator( centerX, centerY, gpsAngle )

   -- Draw buttons
   for _, button in pairs( ui.buttons ) do
      uiButton.draw( button )
   end

end

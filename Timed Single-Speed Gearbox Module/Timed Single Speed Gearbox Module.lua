--------------------------------------------------------------------------------
-- Timed Single Speed Gearbox Module

--------------------------------------------------------------------------------
-- Composite inputs

-- Number
-- [1] - Vessel speed
-- [2] - Shift speed
-- [3] - Minimum seconds between shifts

--------------------------------------------------------------------------------
-- Constants

TICK_RATE = 60

--------------------------------------------------------------------------------
-- Global data

shiftOutput = false
shiftTimerFrames = -1

--------------------------------------------------------------------------------
-- secondsToTicks
-- Converts a value from seconds to in-game physics engine ticks

function secondsToTicks( seconds )
   return seconds * TICK_RATE
end

--------------------------------------------------------------------------------
-- onTick
-- Runs every physics engine tick

function onTick()

   -- Get input data from composite input
   local speed = input.getNumber( 1 )
   local shiftSpeed = input.getNumber( 2 )
   local minFramesBetweenShifts = secondsToTicks( input.getNumber( 3 ) )

   -- Update shift output to composite output
   output.setBool( 1, shiftOutput )

   -- Initialize shift frame timer if necessary
   if shiftTimerFrames == -1 then
      shiftTimerFrames = minFramesBetweenShifts
   end

   -- If it is not time to shift yet, increment timer and return early
   if shiftTimerFrames < minFramesBetweenShifts then
      shiftTimerFrames = shiftTimerFrames + 1
      return
   end

   -- If the conditions are right to change gears, do so and reset the timer
   if speed > shiftSpeed and shiftOutput == false then
      shiftOutput = true
      shiftTimerFrames = 0
   elseif speed < shiftSpeed and shiftOutput == true then
      shiftOutput = false
      shiftTimerFrames = 0
   end

end

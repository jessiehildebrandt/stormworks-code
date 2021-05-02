--------------------------------------------------------------------------------
-- Virtual Lightswitch Module

--------------------------------------------------------------------------------
-- Composite Inputs

-- Boolean
-- [ XX ] - Insert switch input data here

--------------------------------------------------------------------------------
-- calculateSwitchState
-- Calculates the state of the virtual light output given two switch channels

function calculateSwitchState( switchChannels )

   -- Get switch states from the composite input
   switchA = input.getBool(  switchChannels[ 1 ] )
   switchB = input.getBool(  switchChannels[ 2 ] )

   -- Calculate virtual AND gate states
   ANDGateA = switchA and switchB
   ANDGateB = (not switchA) and (not switchB)

   -- Calculate virtual NOR gate state
   NORGate = not (ANDGateA or ANDGateB)

   -- Return output
   return NORGate

end

--------------------------------------------------------------------------------
-- onTick
-- Runs every physics engine tick

function onTick()

   -- Example switch definition (substitute your own)
   exampleSwitches = [ 1, 2 ]

   -- Calculate switch outputs
   output.setBool( exampleSwitches[ 1 ], calculateSwitchState( exampleSwitches ) )

end

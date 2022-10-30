#=
Let's simulate evolution

I want this to be on a hex grid. That means some shenanigans right off the
bat, as a cartesian grid is much easier to simulate

You can view a 2D hex grid as a 3D cubic grid with certain limits imposed.
call the axes of this griq pqr
since p+q+r=0, we discard r
giving two spatial coordinates p, q (as you'd expect).
p corresponds to positive x axis in cartesian coords
q corresponds to "half positive y plus half negative x"

An array of hex cells is inherently rhombic. But it still has the same total
area as a square array, so is stored as one, with indexing offset by the
width of the triangle moved from one side of the square to the other to
create the rhombus (this is simpler than it sounds)
=#

#=
A Creature must:
-Be able to move (based on its Locomotion traits and the local terrain)
-Be able to interact (based on its Reach+Action traits and the surroundings)
-[...]
Creatures have Traits.
A Trait is a function that a Creature uses to determine what it can do
regarding something in its environment
The function can be anything, but generally it will be a
polynomial with coefficients given by the Creature's genes
There doesn't seem to be a need to represent Traits with structs.
Each Trait is simply an array of coefficients
=#
mutable struct Creature

end

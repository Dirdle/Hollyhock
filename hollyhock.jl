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

module Hollyhock


include("hollyhockHexagonalArrays.jl")
using .HexagonArrays

#=
The map is a rectangular grid of hexagonal tiles and the entities currently
occupying each tile. Tiles are 8-bit unsigned integers; entities are simulation
constructs of various kinds (creatures, parts thereof, energy sources, etc)
=#

const terraincolors = []

abstract type Entity end

struct WorldMap
    tiles::HexagonArray{UInt8, 2}
    entities::Array{Entity, 1}
end

function WorldMap(n::Integer)
    #Constructor for an "empty" nxn map
    WorldMap(HexagonArray(zeros(UInt8, n, n), Array{Entity, 1}(undef, 0)))
end

function getterraincolor(m::WorldMap, I::Vararg{Int})
    return terraincolors[m.tiles[I]]
end

#=
A Creature must:
-Be able to move (based on its Locomotion traits and the local terrain)
-Be able to interact (based on its Reach+Action traits and the surroundings)
-[...]
A creature is a collection of Cells and the linking structure of those,
ie a graph where the nodes are Cells.
=#
mutable struct Creature

end




end

#=
Create and display images, animations and plots for hollyhock
=#

module HollyhockView

include("hollyhockHexagonalArrays.jl")
include("hollyhock.jl")

using .HexagonArrays, .Hollyhock
using Gtk, Graphics, Cairo

abstract type Drawable end
abstract type Background <: Drawable end
abstract type MobileEnt <: Drawable end

#Debating whether to have instead a Board struct that stores a canvas, a window
#and a list of all the things that get drawn. 
struct Board
    canvas::GtkCanvas
    window::GtkWindowLeaf
end

function initviewer(name="hollyhock")
    #create a canvas and a window to hold it
    c = @GtkCanvas()
    win = GtkWindow(c, name)

    #... other initialisation tasks
    
    return Board(c, win)
end

function placesprite(a::Any, board::Board, pos::Point)
    #Fallback drawing function for types that don't define a specific draw fn
    #Draws a string representation of the object, at the specified location
    #on the specified canvas
    c = board.canvas(pos[1] <= width(c) && pos[2] <= height(c)) ||
                        @warn "placing sprite outside canvas area"
    s = repr(a)
    ctx = getgc(c)
    #TODO pick a font
    select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL,
                 Cairo.FONT_WEIGHT_NORMAL)
    #TODO make text size fit to canvas
    set_font_size(ctx, 24.0)
    #Centered text is cute, but maybe this should be
    extents = text_extents(ctx, s)
    x = pos[1] - (extents[3]/2 + extents[1])
    y = pos[2] - (extents[4]/2 + extents[2])
    move_to(ctx, x, y)
    show_text(ctx, s)
end




function testview()
    testboard = initviewer("test")
    
    

end


end
ℯ
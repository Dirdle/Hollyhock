#=
Hexagonal arrays used for representing the space of the simulation.
=#

#Ranges used for axes of a hexagonal grid with axial coordinates
#Equivalent to UnitRange for basically all cases
#Functions shamelessly copied from the example ZeroRange in the CustomUnitRanges module
mutable struct AxialRange{T<:Integer} <: AbstractUnitRange{T}
    start::T
    stop::T
    function AxialRange{T}(a, o) where {T}
        if a > o
            error("first index greater than last")
        else
            return new{T}(a, o)
        end
    end
end

function AxialRange(n::Integer)
    return AxialRange{typeof(n)}(1, n)
end

function AxialRange(a::Integer, o::Integer)
    T1 = typeof(a)
    T2 = typeof(o)
    if T1 != T2
        error("start and stop mismatching types")
    else
        return AxialRange{T1}(a, o)
    end
end

Base.length(axr::AxialRange{T}) where {T} = one(T) + axr.stop - axr.start
Base.first(axr::AxialRange) = axr.start
Base.last(axr::AxialRange) = axr.stop

function Base.iterate(axr::AxialRange)
    return length(axr) <= 0 ? nothing : (axr.start, axr.start)
end

function Base.iterate(axr::AxialRange{T}, i) where {T}
    a = convert(T, i + 1)
    return length(axr) + axr.start <= a ? nothing : (a, a)
end

function Base.checkbounds(axr::AxialRange{T}, i::Integer) where {T}
    if !(axr.start <= i <= axr.stop)
        Base.throw_boundserror(axr, i)
    end
end

function Base.checkbounds(axr::AxialRange{T}, s::AbstractUnitRange{S}) where {T, S}
    if !(axr.start <= start(s) & axr.stop >= stop(s))
        Base.throw_boundserror(axr, i)
    end
end

@inline function Base.getindex(axr::AxialRange{T}, i::Integer) where {T}
    @boundscheck checkbounds(axr, i)
    convert(T, i + axr.start - 1)
end

@inline function Base.getindex(axr::AxialRange{T}, s::AbstractUnitRange{S}) where {T,S<:Integer}
    @boundscheck checkbounds(axr, s)
    convert(T, first(s) + axr.start - 1):convert(T, last(s) + axr.start - 1)
end

function Base.show(io::IO, axr::AxialRange)
    print(io, typeof(axr).name.name, "(", axr.start, ":", axr.stop, ")")
end

#N is 1 or 2 - if larger than 2 we're not talking about hexagons any more
mutable struct HexagonArray{T, N} <: AbstractArray{T, N}
    vals::Array{T, N}
    axes::NTuple{N, AxialRange{Int64}}
    size::NTuple{N, Int64}
end

function HexagonArray(square::Array{T, 1}) where T
    #1D constructor (equiv to square array)
    return HexagonArray{T, 1}(square,(AxialRange{Int64}(1, size(square)[1])), size(square))
end

function HexagonArray(square::Array{T, 2}) where T
    #2D constructor
    #note that using the full range of both axes will still attempt to access
    #values that are actually out of range. This must be handled by get/setindex
    #and functions that use HexArr must handle the returned null vals
    s1, s2 = size(square)
    qmin = -1*floor(Int, (s1 - 1)/2)
    qmax = s2 - 1
    qaxis = AxialRange{Int64}(qmin, qmax)
    raxis = AxialRange{Int64}(0, s1 - 1)
    return HexagonArray{T, 2}(square, (raxis, qaxis), (length(raxis), length(qaxis)))
end

Base.axes(H::HexagonArray) = H.axes
Base.size(H::HexagonArray) = H.size
Base.length(H::HexagonArray) = length(H.vals)


#nonstandard checkbounds behaviour:
#If fully out of bounds, throw error
#If in bounds but in the empty regions, return false
#otherwise return true
function Base.checkbounds(H::HexagonArray{T, 1}, I::NTuple{1, S}) where {T, S<:Integer}
    checkbounds(axes(H)[1], I[1])
    return true
end

function Base.checkbounds(H::HexagonArray{T, 2}, I::NTuple{2, S}) where {T, S<:Integer}
    rax, qax = axes(H)
    r, q = I
    checkbounds(rax, r)
    checkbounds(qax, q)
    qmax = length(qax) + first(qax)
    if q < 0
        #check if in null region on left
        return r >= -2 * q
    else
        #check if in null region on right
        return q <= (qmax - floor(Int, r/2) - 1)
    end
end

@inline function Base.getindex(H::HexagonArray, I::Vararg{Int})
    #Note that if @inbounds is used, this will assume the index I is
    #not merely within the array but within the "inner space" where values
    #are defined, rather than the edges where that isn't always the case
    isInFilledRegion = true
    @boundscheck isInFilledRegion = checkbounds(H, I)
    if isInFilledRegion
        r, q = I
        i = r + 1
        j = q + floor(Int, (i-1)/2) + 1
        return getindex(H.vals, i, j)
    else
        return nothing
    end
end

@inline function Base.setindex!(H::HexagonArray, v, I::Vararg{Int})
    #Note that if @inbounds is used, this will assume the index I is
    #not merely within the array but within the "inner space" where values
    #are defined, rather than the edges where that isn't always the case
    isInFilledRegion = true
    @boundscheck isInFilledRegion = checkbounds(H, I)
    if isInFilledRegion
        r, q = I
        i = r + 1
        j = q + floor(Int, (i-1)/2) + 1
        setindex!(H.vals, v, i, j)
        return nothing
    else
        return nothing
    end
end
#

function Base.show(io::IO, ::MIME"text/plain", H::HexagonArray{T, N}, maxelwidth=9) where {T, N}
    if maxelwidth % 2 == 0
        maxelwidth += 1
        #so maxelwidth - 3 is even, so that the offset can be half a column
    end
    print(io, "$(size(H)[2])×$(size(H)[1]) HexagonArray{$(eltype(H))}: \n")
    #Determine how much horizontal space each element will be given
    elwidth = 2
    for i in H
        i == nothing ? l = 1 : l = length(repr(i))
        #Actual max is 3 less (space for '...')
        if l >= maxelwidth - 3
            elwidth = maxelwidth - 3
            break
        elseif l > elwidth
            elwidth = l
        end
    end
    elwidth % 2 == 0 ? nothing : elwidth += 1
    #print the array
    rax, qax = axes(H)
    for r in rax
        #offset every other line by half the column width
        r % 2 == 0 ? print(io, ' '^(1+floor(Int, (elwidth/2)))) : nothing
        for q in qax
            #get the string of the element and pad it to elwidth (both sides)
            H[r, q] == nothing ? e = '•' : e = H[r, q]
            s = lpad(e, ceil(Int, elwidth/2))
            s = rpad(s, elwidth)
            #if needed, also trim the element to fit
            length(e) > elwidth ? s = s[1:(elwidth-3)]*"..." : nothing
            print(io, s, "  ")
        end
        r < last(rax) ? print(io, '\n') : nothing
    end
end

function Base.show(io::IO,  H::HexagonArray)
    print(io, "$(size(H)[2])×$(size(H)[1]) HexagonArray{$(eltype(H))}")
    #Could smarten this up a little
end


#=
Tests
=#

function testHexagonalArrays()
    #Create a hexagonal array
    A = reshape(Vector(1:36), (6,6))
    H = HexagonArray(A)

    @assert H[0,-2] == nothing
    @assert H[1,1] == 8

    H[1,1] = 1207
    @assert H[1,1] == 1207
    try
        print(H[-1, -1])
        print("Failed negative check: accessed $(size(H)[2])×$(size(H)[1]) HexagonArray at [-1,-1]"
    catch BoundsError
        #task failed successfully
    end

end

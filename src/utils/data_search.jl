# https://discourse.julialang.org/t/maintaining-a-fixed-size-top-n-values-list/78868/7
struct BoundedBinaryHeap{T, O <: Base.Ordering} <: DataStructures.AbstractHeap{T}
    ordering::O
    valtree::Vector{T}
    n::Int # maximum length

    function BoundedBinaryHeap{T}(n::Integer, ordering::Base.Ordering) where T
        n ≥ 1 || throw(ArgumentError("max heap size $n must be ≥ 1"))
        new{T, typeof(ordering)}(ordering, sizehint!(Vector{T}(), n), n)
    end

    function BoundedBinaryHeap{T}(n::Integer, ordering::Base.Ordering, xs::AbstractVector) where T
        n ≥ length(xs) || throw(ArgumentError("initial array is larger than max heap size $n"))
        valtree = sizehint!(DataStructures.heapify(xs, ordering), n)
        new{T, typeof(ordering)}(ordering, valtree, n)
    end
end

BoundedBinaryHeap(n::Integer, ordering::Base.Ordering, xs::AbstractVector{T}) where T = BoundedBinaryHeap{T}(n, ordering, xs)

BoundedBinaryHeap{T, O}(n::Integer) where {T, O<:Base.Ordering} = BoundedBinaryHeap{T}(n, O())
BoundedBinaryHeap{T, O}(n::Integer, xs::AbstractVector) where {T, O<:Base.Ordering} = BoundedBinaryHeap{T}(n, O(), xs)

Base.length(h::BoundedBinaryHeap) = length(h.valtree)
Base.isempty(h::BoundedBinaryHeap) = isempty(h.valtree)
@inline Base.first(h::BoundedBinaryHeap) = h.valtree[1]

Base.pop!(h::BoundedBinaryHeap) = DataStructures.heappop!(h.valtree, h.ordering)

function Base.push!(h::BoundedBinaryHeap, v)
    if length(h) < h.n
        DataStructures.heappush!(h.valtree, v, h.ordering)
    elseif Base.Order.lt(h.ordering, @inbounds(h.valtree[1]), v)
        DataStructures.percolate_down!(h.valtree, 1, v, h.ordering)
    end
    return h
end

"""
    data_search_n(collection, x; n = 10, dist = Levenshtein())

Search for `n` closest matches in `collection` for `x`.

Returns a list of (distance, index)
"""
function data_search_n(
    collection, x;
    n = 10,
    dist = Hamming()
)
    indices = eachindex(collection)
    T = Tuple{Float64, eltype(indices)}
    heap = BoundedBinaryHeap{T}(n, Base.Order.Reverse)
    for id in indices
        d = dist(x, collection[id])
        push!(heap, (d, id))
    end
    dists = T[]
    while !isempty(heap)
        push!(dists, pop!(heap))
    end
    @view dists[end:-1:1]
end

data_search(collection, x; kwargs...) = data_search_n(collection, x, n = 1, kwargs...)[1][2]

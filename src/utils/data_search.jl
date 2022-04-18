function find_closest_n(
    dist_func::Function, collection;
    n = 10, ordering = Base.Order.Reverse,
    should_break::Nullable{Function} = nothing
)
    result = dist_func(first(collection))
    T = typeof(result)
    heap = BoundedBinaryHeap{T}(n, ordering)
    push!(heap, result)
    is_first = true
    for x in collection
        if is_first
            is_first = false
            continue
        end
        result = dist_func(x)
        isnothing(result) && continue
        push!(heap, result)
        if !isnothing(should_break) && should_break(result)
            break
        end
    end
    results = T[]
    while !isempty(heap)
        push!(results, pop!(heap))
    end
    @view results[end:-1:1]
end
find_closest(dist_func::Function, collection; kwargs...) =
    find_closest_n(dist_func, collection; n = 1, kwargs...)[1]

"""
    data_search_n(collection, x; n = 10, dist = Levenshtein())

Search for `n` closest matches in `collection` for `x`.

Returns a list of (distance, index)
"""
data_search_n(
    collection, x;
    n = 10,
    dist = StringDistances.Hamming()
) = find_closest_n(eachindex(collection), n = n) do i
    dist(x, collection[i]), i
end

data_search(collection, x; kwargs...) = data_search_n(collection, x; n = 1, kwargs...)[1][2]

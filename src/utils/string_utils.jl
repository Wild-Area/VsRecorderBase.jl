remove_spaces(s::AbstractString) = replace(s, r"\s+" => "")

parse_int(s::AbstractString, default = 0) = let m = match(r"\d+", s)
    isnothing(m) ? default : parse(Int64, m.match)
end

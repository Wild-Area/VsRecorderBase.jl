# Serialize as YAML for custom types with missable fields
# From https://github.com/JuliaData/YAML.jl/blob/master/src/writer.jl
module VsYAML

using ..VsRecorderBase: LITERAL_TYPES

# recursively print a dictionary
_print(io::IO, dict::AbstractDict, level::Int=0, ignore_level::Bool=false) =
    if isempty(dict)
        println(io, "{}")
    else
        for (i, pair) in enumerate(dict)
            _print(io, pair, level, ignore_level ? i == 1 : false) # ignore indentation of first pair
        end
    end

# recursively print an array
_print(io::IO, arr::AbstractVector, level::Int=0, ignore_level::Bool=false) =
    if isempty(arr)
        println(io, "[]")
    else
        for elem in arr
            if elem isa AbstractVector # vectors of vectors must be handled differently
                print(io, _indent("-\n", level))
                _print(io, elem, level + 1)
            else
                print(io, _indent("- ", level))   # print the sequence element identifier '-'
                _print(io, elem, level + 1, true) # print the value directly after
            end
        end
    end

# print a single key-value pair
function _print(io::IO, pair::Pair, level::Int=0, ignore_level::Bool=false)
    key = if pair[1] === nothing
        "null" # this is what the YAML parser interprets as 'nothing'
    else
        string(pair[1]) # any useful case
    end
    print(io, _indent(key * ":", level, ignore_level)) # print the key
    if (pair[2] isa AbstractDict || pair[2] isa AbstractVector) && !isempty(pair[2])
        print(io, "\n") # a line break is needed before a recursive structure
    else
        print(io, " ") # a whitespace character is needed before a single value
    end
    _print(io, pair[2], level + 1) # print the value
end

# _print a single string
_print(io::IO, str::AbstractString, level::Int=0, ignore_level::Bool=false) =
    if occursin('\n', strip(str)) || occursin('"', str)
        if endswith(str, "\n\n")   # multiple trailing newlines: keep
            println(io, "|+")
            str = str[1:end-1]     # otherwise, we have one too many
        elseif endswith(str, "\n") # one trailing newline: clip
            println(io, "|")
        else                       # no trailing newlines: strip
            println(io, "|-")
        end
        indent = repeat("  ", max(level, 1))
        for line in split(str, "\n")
            println(io, indent, line)
        end
    else
        # quote and escape
        println(io, replace(repr(MIME("text/plain"), str), raw"\$" => raw"$"))
    end

# handle NaNs and Infs
_print(io::IO, val::Float64, level::Int=0, ignore_level::Bool=false) =
    if isfinite(val)
        println(io, string(val)) # the usual case
    elseif isnan(val)
        println(io, ".NaN") # this is what the YAML parser interprets as NaN
    elseif val == Inf
        println(io, ".inf")
    elseif val == -Inf
        println(io, "-.inf")
    end

_print(io::IO, val::Nothing, level::Int=0, ignore_level::Bool=false) =
    println(io, "~") # this is what the YAML parser interprets as nothing

# add indentation to a string
_indent(str::AbstractString, level::Int, ignore_level::Bool=false) =
    repeat("  ", ignore_level ? 0 : level) * str

_print(
    io::IO,
    val::LITERAL_TYPES,
    level::Int=0, ignore_level::Bool=false
) = _print(io, string(val), level, ignore_level)

_print(io::IO, val::Tuple, level::Int=0, ignore_level::Bool=false) =
    _print(io, collect(val), level, ignore_level)

function _print(io::IO, val::T, level::Int=0, ignore_level::Bool=false) where T
    dict = Dict{Symbol, Any}()
    for key in fieldnames(T)
        value = getfield(val, key)
        ismissing(value) && continue
        dict[key] = value
    end
    _print(io, dict, level, ignore_level)
end

function yaml(data::Any, prefix::AbstractString="")
    io = IOBuffer()
    print(io, prefix)
    _print(io, data)
    return String(take!(io))
end

end
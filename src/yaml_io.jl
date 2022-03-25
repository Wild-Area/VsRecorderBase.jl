# Serialize & Deserialize YAML for custom types with missable fields
import YAML: _print

_print(
    io::IO,
    val::Union{Integer, AbstractFloat, Bool, Dates.DateTime, Dates.Time, Dates.Date, Symbol},
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
serialize(object::Serializable) = YAML.yaml(object)


deserialize(yaml, T::Type) = YAML.load(yaml)

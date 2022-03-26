_open_video(open_func, file; gray) = VsStream(
    video = if gray
        open_func(file, target_format=VideoIO.AV_PIX_FMT_GRAY8)
    else
        open_func(file)
    end
)

open_video(file; gray = true) = _open_video(VideoIO.openvideo, file; gray = gray)

open_camera(
    device = VideoIO.DEFAULT_CAMERA_DEVICE[];
    gray = true
) = _open_video(VideoIO.opencamera, device; gray = gray)

read_frame(stream::VsStream) = VsFrame(
    image = read(stream.video),
    time = position(stream.video)
)

# Serialize & Deserialize YAML for custom types with missable fields
import YAML: _print

const LITERAL_TYPES = Union{Integer, AbstractFloat, Bool, Dates.DateTime, Dates.Time, Dates.Date, Symbol}
_to_generator(d::AbstractDict) = (Symbol(key) => value for (key, value) in d)

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
serialize(object) = YAML.yaml(object)

_parse(val, ::Type{Any}) = val
_parse(val, ::Type{T}) where T <: LITERAL_TYPES = T(val)
_parse(int::Integer, ::Type{T}) where T <: Enum = T(int)
function _parse(s, ::Type{T}) where T <: Enum
    values = instances(T)
    s = lowercase(string(s))
    values[findfirst(values) do x
        lowercase(string(x)) == s
    end]
end
_parse(arr::AbstractArray, ::Type{<:AbstractArray{T}}) where T = [_parse(x, TE) for x in arr]
_parse(arr::AbstractArray, ::Type{T}) where T <: Tuple = tuple(_parse(x, eltype(TE)) for (x, TE) in zip(arr, T.types))
_parse(dict::AbstractDict, T::Type{<:AbstractDict{TKey, TValue}}) where {TKey, TValue} = T(
    _parse(key, TKey) => _parse(value, TValue)
    for (key, value) in dict
)
function _parse(dict::AbstractDict, T::Type)
    params = Dict{Symbol, Any}()
    for key in fieldnames(T)
        params[key] = dict[string(key)]
    end
    T(; _to_generator(params)...)
end

"""
    deserialize(yaml, T)

Note that `T` must be a type that can be constructed by keywords, e.g., defined by `Base.@kwdef`
"""
function deserialize(yaml, T::Type)
    dict = YAML.load(yaml)
    _parse(dict, T)
end

_to_toml(x::LITERAL_TYPES) = x
_to_toml(x::Enum) = string(x)
_to_toml(dict::AbstractDict) = Dict(
    key => _to_toml(value)
    for (key, value) in dict
)
_to_toml(data) = Dict(
    string(key) => _to_toml(getfield(data, key))
    for key in fieldnames(typeof(data))
)
_to_toml(params::Union{AbstractVsSource, AbstractVsStrategy}) = Dict(
    "type": typeof(source).name.name,
    "params": invoke(_to_toml, Tuple{Any}, params)
)

function save_config(config::VsConfig, filename)
    open(filename, "w") do fo
        TOML.save(_to_toml, fo, config)
    end
end

function _load_T(base_type, data)
    type_name = Symbol(data["type"])
    params = data["params"]
    cmp_type(x) = false
    cmp_type(x::DataType) = x.name.name == type_name
    T = findfirst(_get_type, subtypes(base_type))
    _parse(params, T)
end

function load_config(filename)
    data = open(filename, "r") do fo
        TOML.parse(fo)
    end
    data["strategy"] = _load_T(AbstractVsStrategy, data["strategy"])
    data["source"] = _load_T(AbstractVsSource, data["source"])
    VsConfig(; _to_generator(data)...)
end

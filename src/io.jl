_open_video(open_func, file; gray) = VsStream(
    video = if gray
        open_func(file, target_format=VideoIO.AV_PIX_FMT_GRAY8)
    else
        open_func(file)
    end
)

open_video(file; gray = false) = _open_video(VideoIO.openvideo, file; gray = gray)

open_camera(
    device = VideoIO.DEFAULT_CAMERA_DEVICE[];
    gray = false
) = _open_video(VideoIO.opencamera, device; gray = gray)

read_frame(stream::VsStream) = VsFrame(
    image = read(stream.video),
    time = position(stream.video)
)

function load_image(file; gray = false)
    img = load(file)
    if gray
        img = to_gray_image(img)
    end
    img
end

const LITERAL_TYPES = Union{Integer, AbstractFloat, Bool, Dates.DateTime, Dates.Time, Dates.Date, Symbol}
abstract type SimpleTypeWrapper{T} end
macro type_wrapper(name, T, default=nothing)
    name = esc(name)
    T = esc(T)
    default = esc(default)
    default_constructor = if !isnothing(default)
        :($name() = $name($default))
    end
    quote
        struct $name <: SimpleTypeWrapper{$T}
            value::$T
        end
        $default_constructor
        Base.convert(::Type{$name}, x::$name) = x
        Base.convert(::Type{$name}, x) = $name(convert($T, x))
        Base.convert(::Type{$T}, x::$name) = x.value
        Base.show(io::IO, x::$name) = show(io, x.value)
        @forward $name.value Base.getindex, Base.setindex!
    end
end

_to_generator(d::AbstractDict) = (Symbol(key) => value for (key, value) in d)
function to_snake_case(s::AbstractString)
    s = replace(s, r"([a-z])([A-Z])" => s"\1_\2", '-' => '_')
    lowercase(s)
end

serialize(object) = VsYAML.yaml(object)

_parse(val, ::Type{Any}; kwargs...) = val
_parse(val, T::Type; kwargs...) = convert(T, val)
_parse(val, ::Type{TS}; kwargs...) where {T, TS <: SimpleTypeWrapper{T}} =
    TS(_parse(val, T))
_parse(int::Integer, ::Type{T}; kwargs...) where T <: Enum = T(int)
function _parse(s, ::Type{T}; kwargs...) where T <: Enum
    values = instances(T)
    s = lowercase(string(s))
    values[findfirst(values) do x
        lowercase(string(x)) == s
    end]
end
_parse(arr::AbstractArray, ::Type{<:AbstractArray{T}}; kwargs...) where T = [_parse(x, T) for x in arr]
_parse(arr::AbstractArray, ::Type{T}; kwargs...) where T <: Tuple =
    tuple(_parse(x, eltype(TE)) for (x, TE) in zip(arr, T.types))
_parse(dict::AbstractDict, T::Type{<:AbstractDict{TKey, TValue}}; kwargs...) where {TKey, TValue} = T(
    _parse(key, TKey) => _parse(value, TValue)
    for (key, value) in dict
)
function _parse(dict::AbstractDict, T::Type; other_key = nothing)
    params = Dict{Symbol, Any}()
    if !isnothing(other_key)
        other_key = Symbol(other_key)
        params[other_key] = Dict{Symbol, Any}()
    end
    fnames = fieldnames(T)
    for (key, value) in dict
        skey = to_snake_case(string(key))
        skey = Symbol(skey)
        if skey ∉ fnames
            if !isnothing(other_key)
                params[other_key][skey] = value
            end
            continue
        end
        TF = fieldtype(T, skey)
        params[skey] = _parse(value, TF)
    end
    T(; _to_generator(params)...)
end

"""
    deserialize(yaml, T)

Note that `T` must be a type that can be constructed by keywords, e.g., defined by `Base.@kwdef`
"""
function deserialize(yaml, T::Type; other_key = nothing, kwargs...)
    dict = YAML.load(yaml; kwargs...)
    _parse(dict, T; other_key = other_key)
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

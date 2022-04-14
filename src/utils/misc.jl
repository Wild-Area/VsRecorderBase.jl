const ∞ = 20070128.0

const Missable{T} = Union{Missing, T}
const Nullable{T} = Union{Nothing, T}
_parse(val, ::Type{Nullable{T}}; kwargs...) where T = _parse(val, T; kwargs...)
_parse(val, ::Type{Missable{T}}; kwargs...) where T = _parse(val, T; kwargs...)

"""
A simple singleton struct to represent something existing/true.
"""
struct Yes end
_parse(::Any, ::Type{Yes}; kwargs...) = Yes()
_serialize_convert(::Yes) = true

±(center, half) = center - half : center + half

function _make_nullable(expr, T, default)
    @assert expr.head ≡ :struct
    fields = expr.args[3].args
    for i in 1:length(fields)
        field = fields[i]
        field isa Expr || continue
        if field.head ≡ :(::)
            field.args[2] = :($T{$(field.args[2])})
            fields[i] = :($field = $default)
        elseif field.head ≡ :(=)
            arg1 = field.args[1]
            if arg1 isa Expr && arg1.head ≡ :(::)
                arg1.args[2] = arg1.args[2]
            end
            field.args[2] = field.args[2]
        end
    end
    esc(quote
        Base.@kwdef $expr
    end)
end

"""
    @missable mutable struct SomeStruct
        fields...
    end

Make all fields that do not have a default value missable/optional.
"""
macro missable(expr)
    _make_nullable(expr, Missable, missing)
end

macro nullable(expr)
    _make_nullable(expr, Nullable, nothing)
end

abstract type SimpleTypeWrapper{T} end
macro type_wrapper(name, T, default = :nothing, base_type = :SimpleTypeWrapper)
    struct_name = name
    name = esc(name)
    T = esc(T)
    default_constructor = if default ≢ :nothing
        :($name() = $name($default))
    end
    if base_type ≢ :SimpleTypeWrapper
        base_type = esc(base_type)
    end
    quote
        struct $struct_name <: $base_type{$T}
            value::$T
        end
        $default_constructor
        Base.convert(::Type{$name}, x::$name) = x
        Base.convert(::Type{$name}, x) = $name(convert($T, x))
        Base.convert(::Type{$T}, x::$name) = x.value
        Base.print(io::IO, x::$name) = print(io, x.value)
        Base.show(io::IO, x::$name) = show(io, x.value)
        Base.getindex(x::$name) = x.value
        Base.:(==)(x::$name, y::$name) = x.value == y.value
        Base.:(==)(x::$name, y::$T) = x.value == y
        Base.:(==)(x::$T, y::$name) = x == y.value
        Base.isless(x::$name, y::$name) = isless(x.value, y.value)
        @forward $name.value Base.getindex, Base.setindex!
    end
end
_parse(val, ::Type{TS}; kwargs...) where {T, TS <: SimpleTypeWrapper{T}} =
    TS(_parse(val, T; kwargs...))
_serialize_convert(x::SimpleTypeWrapper) = x.value

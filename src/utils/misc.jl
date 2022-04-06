const ∞ = 20070128.0

const Missable{T} = Union{Missing, T}
const Nullable{T} = Union{Nothing, T}

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
        Base.print(io::IO, x::$name) = print(io, x.value)
        Base.getindex(x::$name) = x.value
        @forward $name.value Base.getindex, Base.setindex!
    end
end

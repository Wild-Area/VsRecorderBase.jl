abstract type AbstractVsStrategy end

"""Abstract type for sources (e.g., a game)."""
abstract type AbstractVsSource end

"""Abstract type for scenes."""
abstract type AbstractVsScene end

"""Abstract type for streams. Should support `eof`, `seek` and `skipframes`."""
abstract type AbstractVsStream end

Base.@kwdef struct VsStream <: AbstractVsStream
    video::VideoIO.VideoReader
end
@forward VsStream.video Base.eof, Base.seek, Base.seekstart, Base.seekend, VideoIO.skipframe, VideoIO.skipframes

"""Frame."""
Base.@kwdef struct VsFrame{T <: AbstractMatrix}
    image::T
    index::Int
end
image(frame::VsFrame) = frame.image
index(frame::VsFrame) = frame.index

Base.@kwdef struct VsContextData
    dict::Dict{Symbol, Any} = Dict()
end
getproperty(data::VsContextData, key::Symbol) = getfield(data, :dict)[key]
setproperty(data::VsContextData, key::Symbol, value) = getfield(data, :dict)[key] = value


Base.@kwdef struct VsConfig{
    TStrategy <: AbstractVsStrategy,
    TSource <: AbstractVsSource,
}
    num_skip_frames::Int = 59
    use_gray_image::Bool = true
    ocr_language::String = "eng"
    gaussian_filter_σ::Float64 = 0.5
    strategy::TStrategy
    source::TSource
end

"""Context."""
Base.@kwdef mutable struct VsContext{
    TStrategy <: AbstractVsStrategy,
    TSource <: AbstractVsSource,
    TStream <: Union{AbstractVsStream, Nothing}
}
    config::VsConfig{TStrategy, TSource}
    stream::TStream
    ocr_instance::TessInst
    current_frame::Union{VsFrame, Nothing} = nothing
    current_scene::Union{AbstractVsScene, Nothing} = nothing
    data::Dict{Symbol, Any} = VsContextData()
end

"""
    vs_setup(source_type; kwargs...)

Create a `VsConfig` with given args.
"""
vs_setup(::Type{T}; kwargs...) where T <: AbstractVsSource =
    error("Not implemented: vs_setup($T)")

"""
    vs_init!(context)

Initialize.
"""
vs_init!(::T) where T <: VsContext =
    error("Not implemented: vs_init!($T)")


"""
    vs_parse_frame!(context, frame)

Parse a frame. Returns a `Union{AbstractVsScene, Nothing}`.
"""
vs_parse_frame!(::T, ::VsFrame) where T <: VsContext =
    error("Not implemented: vs_parse_frame!($T, VsFrame)")

"""
    vs_update!(context, scene)

Store `scene` in `context`.
"""
vs_update!(::T, ::TS) where {T <: VsContext, TS <: AbstractVsScene} =
    error("Not implemented: vs_parse_frame!($T, $TS)")

"""
    vs_result(context)

Fetch the result.
"""
vs_result(::T) where T <: VsContext = error("Not implemented: vs_result($T)")

vs_tryparse_scene(
    ::Type{<:AbstractVsScene},
    ::VsFrame,
    ::VsContext
) = nothing


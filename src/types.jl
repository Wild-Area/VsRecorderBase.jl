abstract type AbstractVsStrategy end

"""Abstract type for sources (e.g., a game)."""
abstract type AbstractVsSource end

"""Abstract type for scenes."""
abstract type AbstractVsScene end

"""Abstract type for streams. Should support the common functions."""
abstract type AbstractVsStream end

Base.@kwdef struct VsStream <: AbstractVsStream
    video::VideoIO.VideoReader
end
@forward VsStream.video Base.close, Base.eof, Base.seek, Base.seekstart, Base.seekend,
    VideoIO.skipframe, VideoIO.skipframes, VideoIO.framerate

"""Frame."""
Base.@kwdef struct VsFrame{T <: AbstractMatrix}
    image::T
    time::Rational{Int64} = 0 // 1
end
image(frame::VsFrame) = frame.image
time(frame::VsFrame) = frame.time
Base.show(io::IO, mime::MIME"image/png", s::VsFrame; kwargs...) = show(io, mime, s.image; kwargs...)

Base.@kwdef struct VsContextData
    dict::Dict{Symbol, Any} = Dict()
end
Base.getproperty(data::VsContextData, key::Symbol) = get(getfield(data, :dict), key, nothing)
Base.setproperty!(data::VsContextData, key::Symbol, value) = getfield(data, :dict)[key] = value


Base.@kwdef struct VsConfig{
    TStrategy <: AbstractVsStrategy,
    TSource <: AbstractVsSource,
}
    # in seconds
    process_interval::Float64 = 1.0
    num_skip_frames::Int = 59
    use_gray_image::Bool = true
    ocr_language::String = "eng"
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
    current_time_skippable::Float64 = 0.0
    data::VsContextData = VsContextData()
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


"""Abstract type for sources (e.g., a game)."""
abstract type AbstractVsSource end

"""Abstract type for scenes."""
abstract type AbstractVsScene end

"""Abstract type for contexts."""
abstract type AbstractVsContext end

Base.@kwdef struct VsStream
    video::VideoIO.VideoReader
end
@forward VsStream.video Base.eof, Base.seek, Base.seekstart, Base.seekend, VideoIO.skipframe, VideoIO.skipframes

Base.@kwdef struct VsFrame{T <: AbstractMatrix}
    image::T
end

"""
    vs_init(config)

Initialize. Returns a context.
"""
vs_init(::VsConfig{T}) where T = error("Unsupported source: $T")

"""
    vs_parse(context, frame, config)

Parse a frame for a source.
"""
vs_parse(::AbstractVsContext, ::VsFrame, ::VsConfig{T}) where T = error("Unsupported source: $T")


"""
    vs_result(context, config)

Fetch the result.
"""
vs_result(::AbstractVsContext, ::VsConfig{T}) where T = error("Unsupported source: $T")

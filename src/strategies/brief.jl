module BriefStrategyModule

export BriefStrategy

using ..VsRecorderBase: AbstractVsStrategy, AbstractVsSource,
    VsContext, VsContextData,
    VsFrame, AbstractVsScene,
    vs_tryparse_scene,
    to_gray_image, _to_generator
    
import ..VsRecorderBase: vs_init!, vs_parse_frame!

"""BRIEF strategy"""
Base.@kwdef struct BriefStrategy <: AbstractVsStrategy
    # (n, threshold)
    fast_corner_params::Tuple{Int, Float64} = (12, 0.4)
    brief_params::Dict{String, Any} = Dict(
        "size" => 256,
        "window" => 10,
        "seed" => 20070128,
        "sampling_type"
    )
    match_threshold::Float64 = 0.1
end

"""
BRIEF feature descriptor of a scene.
"""
struct BriefDescriptor
    descriptors::Vector{BitVector}
    keypoints::Vector{CartesianIndex{2}}
end

feature_images(::T) where T <: AbstractVsSource = error("Unsupported source: $T")

function _create_descriptor(img, n, threshold, brief_params)
    img = to_gray_image(img)
    keypoints = Keypoints(fastcorners(img, n, threshold))
    desc, keypoints = create_descriptor(img, keypoints, brief_params)
    BriefDescriptor(desc, keypoints)
end

function _create_descriptors(ctx::VsContext{BriefStrategy})
    brief_params = ctx.data.brief_params
    n, threshold = ctx.config.strategy.fast_corner_params
    descriptors = OrderedDict{Type, BriefDescriptor}()
    for (scene_type, img) in feature_images(ctx.config.source)
        descriptors[scene_type] = _create_descriptor(img, n, threshold, brief_params)
    end
    descriptors
end

function _get_scene_type(img, data, strategy)
    descriptors = data.scene_descriptors
    brief_params = data.brief_params
    n, threshold = strategy.fast_corner_params
    match_threshold = strategy.match_threshold

    img_desc, img_keypoints = _create_descriptor(img, n, threshold, brief_params)
    closest_scene_type, max_matches = nothing, 0
    for (scene_type, desc) in descriptors
        matches = match_keypoints(
            img_keypoints, desc.keypoints,
            img_desc, desc.descriptors,
            match_threshold
        )
        if length(matches) > max_matches
            closest_scene_type = scene_type
            max_matches = length(matches)
        end
    end
    closest_scene_type
end

function vs_init!(ctx::VsContext{BriefStrategy})
    config = ctx.config
    strategy = config.strategy
    data = ctx.data
    data.brief_params = BRIEF(; _to_generator(strategy.brief_params)...)
    data.scene_descriptors = _create_descriptors(ctx)
    ctx
end

function vs_parse_frame!(ctx::VsContext{BriefStrategy}, frame::VsFrame)
    data = ctx.data
    img = image(frame)
    T = _get_scene_type(img, data, ctx.config.strategy)
    isnothing(T) && return nothing
    tryparse_scene(T, frame, ctx)
end

end

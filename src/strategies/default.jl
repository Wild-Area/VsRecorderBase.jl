module DefaultStrategyModule

export DefaultStrategy

using LinearAlgebra
using Images
using DataStructures: OrderedDict

using ..VsRecorderBase: AbstractVsStrategy, AbstractVsSource,
    VsContext, VsContextData,
    VsFrame, AbstractVsScene,
    vs_tryparse_scene,
    to_gray_image

import ..VsRecorderBase: vs_init!, vs_parse_frame!


"""Default strategy

The features should be almost exactly found in the input image.

A weighted mean squared error is used for the distance between subsections.

D = sum((I1 - I2) .^ 2 .* M) / sum(M)
"""
Base.@kwdef struct DefaultStrategy <: AbstractVsStrategy
    match_threshold::Float64 = 0.05
    width::Int64 = 640
    height::Int64 = 360
end

"""
Simple feature descriptor of a scene.
"""
struct SimpleFeature{T <: Union{Gray{Float32}, RGB{Float32}}}
    image::Matrix{T}
    mask::Matrix{Float32}
    mask_sum::Float32
end

feature_image_and_masks(::T, ::VsContext) where T <: AbstractVsSource = error("Unsupported source: $T")

function _normalize(img, use_gray_image, size)
    if use_gray_image
        img = to_gray_image(img)
    end
    img = imresize(img, size)
    float(img)
end

function _create_descriptors(ctx::VsContext{DefaultStrategy})
    strategy = ctx.config.strategy
    height, width = strategy.height, strategy.width
    use_gray_image = ctx.config.use_gray_image
    ColorType = use_gray_image ? Gray{N0f8} : RGB{N0f8}
    T = SimpleFeature{ColorType}
    descriptors = OrderedDict{Type, T}()
    for (scene_type, img, mask) in feature_image_and_masks(ctx.config.source, ctx)
        img = _normalize(img, use_gray_image, (height, width))
        mask = reinterpret(Float32, float(mask))
        descriptors[scene_type] = T(img, mask, sum(mask))
    end
    descriptors
end

_difference(img1::Matrix{Gray{Float32}}, img2, mask, mask_sum) =
    sum(((img1 .- img2) .^ 2) .* mask) / mask_sum

function _difference(img1::Matrix{RGB{Float32}}, img2, mask, mask_sum)
    s = sum(((img1 .- img2) .^ 2) .* mask) / mask_sum
    norm([red(s), green(s), blue(s)])
end

function _get_scene_type(ctx, img)
    config = ctx.config
    strategy = config.strategy

    descriptors = ctx.data.scene_descriptors
    threshold = strategy.match_threshold
    height, width = strategy.height, strategy.width
    use_gray_image = config.use_gray_image

    img = _normalize(img, use_gray_image, (height, width))
    closest_scene_type, closest_distance = nothing, typemax(Float32)
    for (scene_type, desc) in descriptors
        distance = _difference(img, desc.image, desc.mask, desc.mask_sum)
        distance < threshold && return scene_type
        if distance < closest_distance
            closest_scene_type = scene_type
            closest_distance = distance
        end
    end
    closest_scene_type
end

function vs_init!(ctx::VsContext{DefaultStrategy})
    data = ctx.data
    data.scene_descriptors = _create_descriptors(ctx)
    ctx
end

function vs_parse_frame!(ctx::VsContext{DefaultStrategy}, frame::VsFrame)
    img = image(frame)
    T = _get_scene_type(ctx, img)
    isnothing(T) && return nothing
    vs_tryparse_scene(T, frame, ctx)
end

end

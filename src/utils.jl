to_gray_image(img::AbstractMatrix{<:Gray}) = img
to_gray_image(img::AbstractMatrix) = Gray.(img)

struct BlurredImage{T1 <: AbstractMatrix, T2 <: AbstractMatrix}
    image::T1
    original::T2
end

blur(img::BlurredImage, _) = img
blur(img::AbstractMatrix, σ) = BlurredImage(imfilter(img, KernelFactors.gaussian((σ, σ))), img)
blur(img::AbstractMatrix, ctx::VsContext) = blur(img, ctx.config.gaussian_filter_σ)

function image_distance(
    img1::BlurredImage, img2::BlurredImage,
    ::Union{VsContext, Nothing} = nothing;
    no_blur = false
)
    I1 = no_blur ? img1.original : img1.image
    I2 = no_blur ? img2.original : img2.image
    sum((I1 .- I2) .^ 2)
end

image_distance(
    img1::AbstractMatrix, img2::AbstractMatrix,
    ctx::VsContext;
    no_blur = false
) = image_distance(
    no_blur ? BlurredImage(img1, img1) : blur(img1, ctx),
    no_blur ? BlurredImage(img2, img2) : blur(img2, ctx),
)

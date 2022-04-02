struct Rect
    top::Int
    left::Int
    height::Int
    width::Int
    resolution::Tuple{Int, Int}
end
Rect((top, left), (height, width); resolution = (0, 0)) = Rect(
    top, left, height, width, resolution
)

struct SubImage{T, TSA <: SubArray{T}} <: AbstractMatrix{T}
    image::TSA
    rect::Rect
end
@forward SubImage.image Base.setindex!, Base.getindex, Base.length, Base.size
image(s::SubImage) = s.image
Base.copy(s::SubImage) = copy(s.image)

"""
    subimage(image, (top, left), (height, width); resolution = size(image))
    subimage(image, rect)

Return a sub-image of the image. The rect is in the given `resolution`.
"""
function subimage(img::AbstractMatrix, rect::Rect)
    resolution = rect.resolution
    top, left, height, width = if resolution ≠ (0, 0)
        ih, iw = size(parent(img))
        dh, dw = resolution
        rect.top * ih ÷ dh,
        rect.left * iw ÷ dw,
        rect.height * ih ÷ dh,
        rect.width * iw ÷ dw
    else
        rect.top, rect.left, rect.height, rect.width
    end
    s = @view img[top:top + height - 1, left:left + width - 1]
    SubImage(s, rect)
end

subimage(
    img::AbstractMatrix,
    (top, left),
    (height, width);
    resolution = (0, 0)
) = subimage(
    img,
    Rect((top, left), (height, width), resolution = resolution)
)

subimage(img::SubImage, rect::Rect) = let pr = img.rect
    @assert pr.resolution == rect.resolution
    subimage(
        parent(img.image),
        (pr.top + rect.top - 1, pr.left + rect.left - 1),
        (rect.height, rect.width),
        resolution = rect.resolution
    )
end


Base.getindex(img::AbstractMatrix, rect::Rect) = subimage(img, rect)
Base.getindex(img::SubImage, rect::Rect) = subimage(img, rect)
Base.size(rect::Rect) = (rect.height, rect.width)
topleft(rect::Rect) = (rect.top, rect.left)

is_gray(img::AbstractMatrix{<:Gray}) = true
is_gray(img::AbstractMatrix) = false

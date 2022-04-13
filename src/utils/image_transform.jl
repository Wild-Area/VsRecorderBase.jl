to_gray_image(img::AbstractMatrix{<:Gray}) = img
to_gray_image(img::AbstractMatrix) = Gray.(img)

blur(img::AbstractMatrix, σ = 0.5f0) = imfilter(img, KernelFactors.gaussian((σ, σ)))

color_distance(a::Gray, b::Gray) = Float32(a - b)
color_distance(a::RGB, b::RGB) = norm.(a - b)
color_distance(a::RGB, b::Gray) = color_distance(Gray(a), b)
color_distance(a::Gray, b::RGB) = color_distance(a, Gray(b))

function floodfill!(
    img::AbstractMatrix{T},
    starting_point, color,
    threshold = 0.1
) where T <: Union{Gray{Float32}, RGB{Float32}}
    q = Queue{Tuple{Int, Int}}()
    img = float(img)
    y, x = starting_point
    c = img[y, x]
    enqueue!(q, (y, x))
    h, w = size(img)
    visited = zeros(Bool, (h, w))
    visited[y, x] = true
    @inbounds while length(q) > 0
        y, x = dequeue!(q)
        img[y, x] = color
        for (dy, dx) in (
            (-1, 0), (1, 0), (0, -1), (0, 1)
        )
            uy, ux = y + dy, x + dx
            if 0 < uy && uy ≤ h && 0 < ux && ux ≤ w && !visited[uy, ux]
                if color_distance(c, img[uy, ux]) < threshold
                    enqueue!(q, (uy, ux))
                    visited[uy, ux] = true
                end
            end
        end
    end
    img
end

floodfill(img, starting_point, color, threshold = 0.1) =
    floodfill!(float(copy(img)), starting_point, color, threshold)

function draw_outline!(img::AbstractMatrix, color = 0, width::Int = 1, threshold = 0.05)
    color = RGB(color)
    width < 1 && return img
    h, w = size(img)
    bg_color = img[1, 1]
    if color_distance(color, bg_color) < threshold
        return img
    end
    is_bg_color = map(img) do x
        color_distance(x, bg_color) < threshold
    end
    d = width
    @inbounds for x in 1:w
        for y in 1:h
            !is_bg_color[y, x] && continue
            for dx in -d:d, dy in -d:d
                uy, ux = y + dy, x + dx
                if 0 < uy && uy ≤ h && 0 < ux && ux ≤ w && !is_bg_color[uy, ux]
                    img[y, x] = color
                end
            end
        end
    end
    img
end
draw_outline(img, color=0, width=1) = draw_outline!(copy(img), color, width)

function cycled_translate(img::AbstractMatrix, (dy, dx))
    h, w = size(img)
    dy, dx = dy % h, dx % w
    if dy < 0
        dy += h
    end
    if dx < 0
        dx += w
    end
    img2 = similar(img)
    @inbounds begin
        img2[1:dy, 1:dx] = @view img[h - dy + 1:h, w - dx + 1:w]
        img2[1 + dy:h, 1 + dx:w] = @view img[1:h - dy, 1:w - dx]
        img2[1:dy, 1 + dx:w] = @view img[h - dy + 1:h, 1:w - dx]
        img2[1 + dy:h, 1:dx] = @view img[1:h - dy, w - dx + 1:w]
    end
    img2
end

function blend_color(blend::AbstractMatrix, base::AbstractMatrix)
    base = HSL.(base)
    blend = HSL.(blend)
    new_img = similar(base)
    chs = channelview(new_img)
    ax = axes(base)
    chs[3, ax...] = channelview(base)[3, ax...]
    chs[1:2, ax...] = channelview(blend)[1:2, ax...]
    RGB.(new_img)
end

function bounding_rect(img::AbstractMatrix, background_color)
    h, w = size(img)
    compare = !=(background_color)
    f = (func, xs, init) -> func((x for x in xs if !isnothing(x)), init = init)
    top = f(minimum, (findfirst(compare, view(img, :, x)) for x in 1:w), h)
    bottom = f(maximum, (findlast(compare, view(img, :, x)) for x in 1:w), 0)
    left = f(minimum, (findfirst(compare, view(img, y, :)) for y in 1:h), w)
    right = f(maximum, (findlast(compare, view(img, y, :)) for y in 1:h), 0)
    Rect((top, left), (bottom - top + 1, right - left + 1))
end

shrink(img::AbstractMatrix, background_color = img[1, 1]) = img[bounding_rect(img, background_color)]

function prepare_text_for_ocr(
    img::AbstractMatrix;
    threshold = 0.35f0,
    white_text = true
)
    img = Gray.(img)
    if white_text
        img = complement.(img)
    end
    img[img .> threshold] .= 1
    img
end
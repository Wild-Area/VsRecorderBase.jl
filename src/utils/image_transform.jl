to_gray_image(img::AbstractMatrix{<:Gray}) = img
to_gray_image(img::AbstractMatrix) = Gray.(img)

blur(img::AbstractMatrix, σ = 0.5) = imfilter(img, KernelFactors.gaussian((σ, σ)))
blur(img, σ = 0.5) = blur(image(img), σ)

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

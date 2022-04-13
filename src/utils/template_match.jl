image_distance(img1::AbstractMatrix, img2::AbstractMatrix) = mse(img1, img2)
image_distance(
    img1::AbstractMatrix{<:Gray},
    img2::AbstractMatrix{<:Gray},
    weights::AbstractMatrix,
    weights_sum = sum(weights)
) = sum(((float(img1) .- img2) .^ 2) .* weights) / weights_sum
image_distance(
    img1::AbstractMatrix{<:RGB},
    img2::AbstractMatrix,
    weights::AbstractMatrix,
    weights_sum = sum(weights)
) = sum((norm.(float(img1) .- img2, (2f0,)) .^ 2) .* weights) / weights_sum
image_distance(
    img1::AbstractMatrix{<:Gray},
    img2::AbstractMatrix{<:RGB},
    weights::AbstractMatrix,
    weights_sum = sum(weights)
) = image_distance(img1, Gray.(img2), weights, weights_sum)


function template_match_all(
    template, img;
    indices = axes(img),
    σ = 0.5f0,
    mask = nothing,
    border = Fill(1)
)
    if σ > 0
        template, img = blur(template, σ), blur(img, σ)
    end
    h, w = (size(template) .+ 1) .÷ 2 .* 2 .- 1
    template = @view template[1:h, 1:w]
    f = if isnothing(mask)
        (window) -> image_distance(window, template)
    else
        mask = @view mask[1:h, 1:w]
        (window) -> image_distance(window, template, mask)
    end
    window_size = size(template)
    dists = mapwindow(
        f, img, window_size,
        indices = indices,
        border = border
    )
    perms = sortperm(reshape(dists, :))
    perms, dists
end

"""
    template_match(template, image; indices = axes(image) σ = 0.5f0, mask = nothing, border = Fill(1))

Match `template` in `image`. `indices` are the points of the centers of windows in the image.

If `σ ≤ 0`, no blur is applied.
"""
function template_match(
    template, img;
    indices = axes(img),
    σ = 0.5f0,
    mask = nothing,
    border = Fill(1)
)
    perms, dists = template_match_all(
        template, img;
        indices = indices,
        σ = σ,
        mask = mask,
        border = border
    )
    perms[1], dists[perms[1]]
end


function get_table_size(img, block_size)
    th, tw = size(img)
    bh, bw = block_size
    nrows = th ÷ bh
    ncols = tw ÷ bw
    (nrows, ncols)
end

"""
    table_search(
        template, table;
        block_size = size(template),
        rect = ((1, 1), block_size),
        indices = 1:block_count
    )

Find `template` in `table`. `rect` = (topleft, size) is the region of the block to search.
"""
function table_search(
    template, table;
    block_size = size(template),
    table_size = get_table_size(table, block_size),
    rect = Rect((1, 1), block_size),
    indices = nothing,
    mask = nothing
)
    if isnothing(indices)
        indices = 1:(table_size[1] * table_size[2])
    end

    rect_size = size(rect)
    if size(template) != rect_size
        template = imresize(template, rect_size)
    end

    _, closest_i = find_closest(indices) do i
        block_img = block(table, i, table_size, block_size)
        subsection = subimage(block_img, rect)
        dist = if isnothing(mask)
            image_distance(subsection, template)
        else
            block_mask = block(mask, i, table_size, block_size)
            submask = subimage(block_mask, rect)
            image_distance(subsection, template, submask)
        end
        dist, i
    end
    closest_i
end

struct SpriteSheet{T <: Union{Gray{Float32}, RGB{Float32}}, TM <: Union{Matrix{Float32}, Nothing}}
    image::Matrix{T}
    mask::TM
    block_size::Tuple{Int, Int}
    # (nrows, ncols)
    table_size::Tuple{Int, Int}
    data::OrderedDict{Int, String}
    filename::String
end

function SpriteSheet(filename; gray = false)
    filename, ext = splitext(filename)
    if lowercase(ext) ∉ ("", ".png")
        throw("Should be a png file: $filename")
    end
    img = load_image("$filename.png", gray = gray)
    mask = try
        reinterpret(Float32, float(load_image("$filename.mask.png", gray = true))) |> copy
    catch
        nothing
    end
    raw_data, block_size, indices = open("$filename.yaml") do fi
        data = YAML.load(fi)
        data["data"], data["block-size"], get(data, "indices", nothing)
    end
    block_size = (block_size[1], block_size[2])
    table_size = get_table_size(img, block_size)
    data = OrderedDict{Int, String}()
    if isnothing(indices)
        indices = 1:length(raw_data)
    end
    @assert length(indices) ≡ length(raw_data)
    for (i, s) in zip(indices, raw_data)
        data[i] = string(s)
    end
    SpriteSheet(float(img), mask, block_size, table_size, data, filename)
end

@forward SpriteSheet.data Base.length, Base.getindex
image(s::SpriteSheet) = s.image
Base.show(io::IO, mime::MIME"image/png", s::SpriteSheet; kwargs...) = show(io, mime, s.image; kwargs...)

block(img::AbstractMatrix, i, table_size, block_size) = let (_, ncols) = table_size, (bh, bw) = block_size
    subimage(
        img,
        (
            (i - 1) ÷ ncols * bh + 1,
            ((i - 1) % ncols) * bw + 1
        ),
        (bh, bw)
    )
end
block(s::SpriteSheet, i) = block(s.image, i, s.table_size, s.block_size)


function table_search(
    template, sheet::SpriteSheet;
    rect = Rect((1, 1), sheet.block_size),
    indices = keys(sheet.data)
)
    i = table_search(
        template, sheet.image,
        block_size = sheet.block_size,
        table_size = sheet.table_size,
        rect = rect,
        indices = indices,
        mask = sheet.mask
    )
    sheet[i]
end

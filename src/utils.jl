const ∞ = 20070128.0

to_gray_image(img::AbstractMatrix{<:Gray}) = img
to_gray_image(img::AbstractMatrix) = Gray.(img)

image_rect(img::AbstractMatrix, (top, left), (height, width)) =
    @view img[top:top + height - 1, left:left + width - 1]

blur(img::AbstractMatrix, σ) = imfilter(img, KernelFactors.gaussian((σ, σ)))

image_distance(img1::AbstractMatrix, img2::AbstractMatrix) = mse(img1, img2)

function tempalte_match_all(template, img, indices; σ = 0.5)
    if σ > 0
        template, img = blur(template, σ), blur(img, σ)
    end
    f = (window) -> image_distance(window, template)
    window_size = size(template)
    dists = mapwindow(f, img, window_size, indices=indices, border=Fill(1))
    sortperm(dists), dists
end

"""
    tempalte_match(template, image, indices; σ = 0.5)

Match `template` in `image`. `indices` are the points of the centers of windows in the image.

If `σ ≤ 0`, no blur is applied.
"""
function tempalte_match(
    template, img, indices = axes(img);
    σ = 0.5
)
    perms, dists = tempalte_match_all(template, img, indices; σ = σ)
    perms[1], dists[1]
end

"""
    table_search(
        template, table;
        block_size = size(template),
        rect = ((1, 1), block_size),
        σ = 0.5,
        range = 1:block_count
    )

Find `template` in `table`. `rect` = (topleft, size) is the region of the block to search.

If `σ ≤ 0`, no blur is applied.
"""
function table_search(
    template, table;
    block_size = size(template),
    rect = ((1, 1), block_size),
    σ = 0.5,
    range = nothing
)
    th, tw = size(table)
    bh, bw = block_size
    (oy, ox), (rh, rw) = rect
    ncols = tw ÷ bw
    nrows = th ÷ bh
    if isnothing(range)
        range = 1:ncols * nrows
    end

    if size(template) != (rh, rw)
        template = imresize(template, (rh, rw))
    end

    if σ > 0
        template, table = blur(template, σ), blur(table, σ)
    end
    
    closest_dist, closest_i = ∞, 0
    for i in range
        col = (i - 1) % ncols + 1
        row = (i - 1) ÷ ncols + 1
        x_start = (col - 1) * bw + ox
        y_start = (row - 1) * bh + oy
        subsection = @view table[
            y_start:y_start + rh - 1,
            x_start:x_start + rw - 1
        ]
        dist = image_distance(template, subsection)
        if dist < closest_dist
            closest_dist = dist
            closest_i = i
        end
    end
    closest_i
end


const Missable{T} = Union{Missing, T}
const Nullable{T} = Union{Nothing, T}

function _make_nullable(expr, T, default)
    @assert expr.head ≡ :struct
    fields = expr.args[3].args
    for i in 1:length(fields)
        field = fields[i]
        field isa Expr || continue
        if field.head ≡ :(::)
            field.args[2] = :($T{$(field.args[2])})
            fields[i] = :($field = $default)
        elseif field.head ≡ :(=)
            arg1 = field.args[1]
            if arg1 isa Expr && arg1.head ≡ :(::)
                arg1.args[2] = arg1.args[2]
            end
            field.args[2] = field.args[2]
        end
    end
    esc(quote
        Base.@kwdef $expr
    end)
end

"""
    @missable mutable struct SomeStruct
        fields...
    end

Make all fields that do not have a default value missable/optional.
"""
macro missable(expr)
    _make_nullable(expr, Missable, missing)
end

macro nullable(expr)
    _make_nullable(expr, Nullable, nothing)
end
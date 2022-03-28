struct SpriteSheet{T <: AbstractMatrix}
    image::T
    block_size::Tuple{Int, Int}
    data::Vector{String}
end

function SpriteSheet(filename; gray = true)
    img = load_image("$filename.png", gray = gray)
    block_size, data = open("$filename.yaml") do fi
        data = YAML.load(fi)
        data["block-size"], data["data"]
    end
    SpriteSheet(img, (block_size[1], block_size[2]), data)
end

@forward SpriteSheet.data Base.length, Base.getindex
image(s::SpriteSheet) = s.image

_open_video(open_func, file; gray) = VsStream(
    video = if gray
        open_func(file, target_format=VideoIO.AV_PIX_FMT_GRAY8)
    else
        open_func(file)
    end
)

open_video(file; gray=true) = _open_video(VideoIO.openvideo, file; gray = gray)

open_camera(
    device = VideoIO.DEFAULT_CAMERA_DEVICE[];
    gray=true
) = _open_video(VideoIO.opencamera, device; gray = gray)

to_toml(x::Union{Integer, AbstractFloat, Bool, Dates.DateTime, Dates.Time, Dates.Date}) = x
to_toml(dict::AbstractDict) = Dict(
    key => to_toml(value)
    for (key, value) in dict
)
to_toml(data) = Dict(
    string(key) => to_toml(getfield(data, key))
    for key in fieldnames(typeof(data))
)
to_toml(source::AbstractVsSource) = Dict(
    "type": typeof(source).name.name,
    "data": invoke(to_toml, Tuple{Any}, source)
)
function save_config(config::VsConfig, filename)
    open(filename, "w") do fo
        TOML.save(to_toml, fo, config)
    end
end

_to_generator(d::AbstractDict) = (Symbol(key) => value for (key, value) in d)

function _load_source(source_data)
    type_name = Symbol(source_data["type"])
    data = source_data["data"]
    cmp_type(x) = false
    cmp_type(x::DataType) = x.name.name == type_name
    T = findfirst(_get_type, subtypes(AbstractVsSource))
    T(; _to_generator(data)...)
end

function load_config(filename)
    data = open(filename, "r") do fo
        TOML.parse(fo)
    end
    data["source"] = _load_source(data["source"])
    VsConfig(; _to_generator(data)...)
end

read_frame(stream::VsStream) = VsFrame(
    image = read(stream.video)
)

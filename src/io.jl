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

_to_toml(x::Union{Integer, AbstractFloat, Bool, Dates.DateTime, Dates.Time, Dates.Date}) = x
_to_toml(dict::AbstractDict) = Dict(
    key => _to_toml(value)
    for (key, value) in dict
)
_to_toml(data) = Dict(
    string(key) => _to_toml(getfield(data, key))
    for key in fieldnames(typeof(data))
)
_to_toml(params::Union{AbstractVsSource, AbstractVsStrategy}) = Dict(
    "type": typeof(source).name.name,
    "params": invoke(_to_toml, Tuple{Any}, params)
)
function save_config(config::VsConfig, filename)
    open(filename, "w") do fo
        TOML.save(_to_toml, fo, config)
    end
end

_to_generator(d::AbstractDict) = (Symbol(key) => value for (key, value) in d)

function _load_T(base_type, data)
    type_name = Symbol(data["type"])
    params = data["params"]
    cmp_type(x) = false
    cmp_type(x::DataType) = x.name.name == type_name
    T = findfirst(_get_type, subtypes(base_type))
    T(; _to_generator(params)...)
end

function load_config(filename)
    data = open(filename, "r") do fo
        TOML.parse(fo)
    end
    data["strategy"] = _load_T(AbstractVsStrategy, data["strategy"])
    data["source"] = _load_T(AbstractVsSource, data["source"])
    VsConfig(; _to_generator(data)...)
end

read_frame(stream::VsStream) = VsFrame(
    image = read(stream.video)
)

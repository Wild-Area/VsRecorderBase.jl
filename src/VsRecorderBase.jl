module VsRecorderBase

import Dates, TOML, YAML
using FileIO: @format_str

using Reexport: @reexport

@reexport using VideoIO, Images

using Tesseract, ImageFiltering
using MacroTools: @forward


export AbstractVsStrategy, AbstractVsSource, AbstractVsScene, AbstractVsStream,
    VsStream, VsFrame,
    VsContextData,
    VsConfig,
    VsContext
export image, time
export vs_setup, vs_init!, vs_parse_frame!, vs_update!, vs_result, vs_tryparse_scene
include("types.jl")

export to_gray_image,
    image_rect,
    blur, image_distance,
    tempalte_match_all, tempalte_match,
    table_search
export Missable, Nullable, @missable, @nullable
include("utils.jl")

export SpriteSheet
include("data.jl")

export open_video, open_camera,
    read_frame, load_image,
    save_config, load_config,
    serialize, deserialize
include("io.jl")

export parse_text
include("ocr.jl")

export DefaultStrategy
include("strategies/default.jl")
using .DefaultStrategyModule: DefaultStrategy

include("main.jl")
include("api.jl")

end

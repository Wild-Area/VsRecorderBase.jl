module VsRecorderBase

import Dates, TOML
using FileIO: @format_str

using VideoIO, Images, Tesseract
using ImageFiltering
using MacroTools: @forward

export AbstractVsStrategy, AbstractVsSource, AbstractVsScene, AbstractVsStream,
    VsStream, VsFrame,
    VsContextData,
    VsConfig,
    VsContext
export vs_init!, vs_parse_frame!, vs_update!, vs_result, vs_tryparse_scene
include("types.jl")

export to_gray_image
include("utils.jl")

export open_video, open_camera, save_config, load_config, read_frame
include("io.jl")

export parse_text
include("ocr.jl")

export DefaultStrategy
include("strategies/default.jl")
using .DefaultStrategyModule: DefaultStrategy

include("main.jl")
include("api.jl")

end

module VsRecorderBase

import Dates, TOML
using FileIO: @format_str

using VideoIO, Images, Tesseract
using MacroTools: @forward
using SimpleI18n

export AbstractVsScene, AbstractVsSource
export vs_init
include("types.jl")
export VsConfig
include("config.jl")

export open_video, open_camera, save_config, load_config
include("io.jl")

export parse_text
include("ocr.jl")

include("api.jl")

end

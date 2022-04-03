module VsRecorderBase

import Dates, TOML, YAML
using DataStructures: Queue, enqueue!, dequeue!, OrderedDict
using LinearAlgebra
using FileIO: Stream, @format_str

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

export Missable, Nullable, @missable, @nullable
include("utils/misc.jl")

export to_gray_image, blur,
    color_distance, floodfill, floodfill!,
    draw_outline, draw_outline!,
    cycled_translate,
    blend_color
include("utils/image_transform.jl")

export Rect, subimage, topleft, is_gray
include("utils/data.jl")

export image_distance, block,
    tempalte_match_all, tempalte_match,
    table_search
export SpriteSheet
include("utils/template_match.jl")

export open_video, open_camera,
    read_frame, load_image,
    @type_wrapper,
    save_config, load_config,
    serialize, deserialize
include("io.jl")
include("yaml.jl")

export create_ocr_instance, ocr
include("ocr.jl")

export DefaultStrategy
include("strategies/default.jl")
using .DefaultStrategyModule: DefaultStrategy

include("main.jl")
include("api.jl")

end

module VsRecorderBase

import Dates, TOML
using LinearAlgebra

import DataStructures
import YAML
using DataStructures: Queue, enqueue!, dequeue!,
    OrderedDict
using FileIO: Stream, @format_str

using Reexport: @reexport

@reexport using VideoIO, Images

using StringDistances
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

export Missable, Nullable,
    @missable, @nullable,
    SimpleTypeWrapper, @type_wrapper,
    ∞, ±
include("utils/misc.jl")

export BoundedBinaryHeap, data_search
include("utils/data_search.jl")

export to_gray_image, blur,
    color_distance, floodfill, floodfill!,
    draw_outline, draw_outline!,
    cycled_translate,
    blend_color,
    prepare_text_for_ocr
include("utils/image_transform.jl")

export Rect, subimage, topleft, is_gray
include("utils/image_data.jl")

export image_distance, block,
    template_match_all, template_match,
    table_search
export SpriteSheet
include("utils/template_match.jl")

export open_video, open_camera,
    read_frame, load_image,
    enum_to_string, enum_from_string,
    serialize, deserialize
include("io.jl")
include("yaml.jl")

export create_ocr_instance, ocr,
    download_ocr_language
include("ocr.jl")

export DefaultStrategy
include("strategies/default.jl")
using .DefaultStrategyModule: DefaultStrategy

include("main.jl")
include("api.jl")

function __init__()
    mkpath(OCR_DATA_DIR)
    nothing
end

end

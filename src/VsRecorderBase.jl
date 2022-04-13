module VsRecorderBase

using Reexport: @reexport

import Dates, TOML

import DataStructures
import YAML
@reexport using DataStructures: Queue, enqueue!, dequeue!,
    OrderedDict
using FileIO: Stream, @format_str

@reexport using LinearAlgebra, Statistics
@reexport using VideoIO, Images

import StringDistances
using Tesseract, ImageFiltering
@reexport using MacroTools: @forward

export Missable, Nullable,
    @missable, @nullable,
    SimpleTypeWrapper, @type_wrapper,
    ∞, ±
include("utils/misc.jl")

export AbstractVsStrategy, AbstractVsSource, AbstractVsScene, AbstractVsStream,
    VsStream, VsFrame,
    VsContextData,
    VsConfig,
    VsContext
export image, time
export vs_setup, vs_init!, vs_parse_frame!, vs_update!, vs_result, vs_tryparse_scene
include("types.jl")

export BoundedBinaryHeap,
    find_closest_n, find_closest,
    data_search_n, data_search
include("utils/data_search.jl")

export remove_spaces, parse_int
include("utils/string_utils.jl")

export to_gray_image, blur,
    color_distance, floodfill, floodfill!,
    draw_outline, draw_outline!,
    cycled_translate,
    blend_color,
    bounding_rect, shrink,
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

export create_ocr_instance,
    download_ocr_language,
    default_ocr_instance,
    ocr, ocr_tsv,
    is_cjk,
    init_multiple_ocr!, ocr_multiple_lang
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

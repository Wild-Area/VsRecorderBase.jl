const OCR_DATA_DIR = abspath(joinpath(pathof(@__MODULE__), "../../tessdata"))

@enum PageSegMode begin
    PSM_OSD_ONLY               = 0
    PSM_AUTO_OSD               = 1
    PSM_AUTO_ONLY              = 2
    PSM_AUTO                   = 3
    PSM_SINGLE_COLUMN          = 4
    PSM_SINGLE_BLOCK_VERT_TEXT = 5
    PSM_SINGLE_BLOCK           = 6
    PSM_SINGLE_LINE            = 7
    PSM_SINGLE_WORD            = 8
    PSM_CIRCLE_WORD            = 9
    PSM_SINGLE_CHAR            = 10
    PSM_SPARSE_TEXT            = 11
    PSM_SPARSE_TEXT_OSD        = 12
    PSM_RAW_LINE               = 13
end

download_ocr_language(lang, target = OCR_DATA_DIR) =
    Tesseract.download_languages(lang, target = target)

default_ocr_instance(ctx::VsContext) = ctx.ocr_instances[ctx.config.ocr_language]

function get_pix(img::AbstractMatrix)
    f = IOBuffer()
    s = Stream{format"PNG"}(f)
    save(s, img)
    buffer = take!(f)
    pix = pix_read(buffer)
end

create_ocr_instance(
    language::AbstractString;
    tess_datapath = OCR_DATA_DIR
) = TessInst(language, tess_datapath)

function _set_page_seg_mode(inst::TessInst, mode::PageSegMode)
    ccall(
        (:TessBaseAPISetPageSegMode, Tesseract.TESSERACT),
        Cvoid,
        (Ptr{Cvoid}, PageSegMode),
        inst, mode
    )
end

function _ocr(img::AbstractMatrix, instance::TessInst; resolution = 72, page_seg_mode = PSM_SINGLE_LINE)
    pix = get_pix(img)
    tess_image(instance, pix)
    tess_resolution(instance, resolution)
    _set_page_seg_mode(instance, page_seg_mode)
end

"""
    ocr([Type=String], image, language/instance/context; resolution = 72, strip = true)

Use Tesseract to OCR an image.
"""
function ocr(
    ::Type{String},
    img::AbstractMatrix,
    instance::TessInst;
    resolution = 72,
    strip = true,
    page_seg_mode::PageSegMode = PSM_SINGLE_LINE
)
    _ocr(img, instance; resolution = resolution, page_seg_mode = page_seg_mode)
    text = tess_text(instance)
    if strip
        text = Base.strip(text)
    end
    text
end

function ocr(
    ::Type{String},
    img::AbstractMatrix, language::AbstractString;
    tess_datapath = OCR_DATA_DIR,
    kwargs...
)
    instance = create_ocr_instance(language, tess_datapath = tess_datapath)
    ocr(String, img, instance; kwargs...)
end

ocr(
    ::Type{String},
    img::AbstractMatrix,
    ctx::VsContext;
    language = ctx.config.ocr_language,
    kwargs...
) = let text = ocr(String, img, ctx.ocr_instances[language]; kwargs...)
    is_cjk(language) ? remove_spaces(text) : text
end

function ocr(::Type{Int}, img::AbstractMatrix, args...; default::Int = 0, kwargs...)
    text = ocr(String, img, args...; kwargs...)
    parse_int(text, default)
end

ocr(img::AbstractMatrix, args...; kwargs...) = ocr(String, img, args...; kwargs...)

function ocr_tsv(img, instance; kwargs...)
    _ocr(img, instance; kwargs...)
    tess_parsed_tsv(instance)
end

is_cjk(lang) = split(lang, '+') ∩ ("chi_sim", "chi_tra", "jpn", "kor") |> !isempty
function init_multiple_ocr!(ctx::VsContext, languages::AbstractVector{<:AbstractString}, tess_datapath = OCR_DATA_DIR)
    for lang in languages
        lang in keys(ctx.ocr_instances) && continue
        ctx.ocr_instances[lang] = create_ocr_instance(lang, tess_datapath = tess_datapath)
    end
    ctx
end

function ocr_multiple_lang(img::AbstractMatrix, ctx::VsContext; prepare = true)
    if prepare
        img = prepare_text_for_ocr(img)
    end
    _, best_lang, best_words = find_closest(
        ctx.ocr_instances,
        should_break = (x) -> x[1] < 20  # Set a threshold to break early
    ) do (lang, inst)
        tsvs = [t for t in ocr_tsv(img, inst) if t.level == 5]  # filter the words
        average_conf = if length(tsvs) == 0
            -1.0
        else
            mean(t.conf for t in tsvs)
        end
        100 - average_conf, lang, tsvs
    end
    if length(best_words) == 0
        ""
    else
        join((t.text for t in best_words), is_cjk(best_lang) ? "" : " ")
    end
end

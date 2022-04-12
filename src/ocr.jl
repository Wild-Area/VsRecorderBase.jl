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
    pix = get_pix(img)
    tess_image(instance, pix)
    tess_resolution(instance, resolution)
    _set_page_seg_mode(instance, page_seg_mode)
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
    kwargs...
) = ocr(String, img, ctx.ocr_instance; kwargs...)

function ocr(::Type{Int}, img::AbstractMatrix, args...; default::Int = 0, kwargs...)
    text = ocr(String, img, args...; kwargs...)
    parse_int(text, default)
end

ocr(img::AbstractMatrix, args...; kwargs...) = ocr(String, img, args...; kwargs...)

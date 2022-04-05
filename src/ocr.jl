const OCR_DATA_DIR = abspath(joinpath(pathof(@__MODULE__), "../../tessdata"))

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


"""
    ocr([Type=String], image, language/instance/context; resolution = 72, strip = true)

Use Tesseract to OCR an image.
"""
function ocr(
    ::Type{String},
    img::AbstractMatrix,
    instance::TessInst;
    resolution = 72,
    strip = true
)
    pix = get_pix(img)
    tess_image(instance, pix)
    tess_resolution(instance, resolution)
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
    m = match(r"\d+", text)
    isnothing(m) ? default : parse(Int, m.match)
end

ocr(img::AbstractMatrix, args...; kwargs...) = ocr(String, img, args...; kwargs...)

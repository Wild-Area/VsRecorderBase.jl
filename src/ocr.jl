function get_pix(img::AbstractMatrix)
    f = IOBuffer()
    s = Stream{format"PNG"}(f)
    save(s, img)
    buffer = take!(f)
    pix = pix_read(buffer)
end

create_ocr_instance(
    language::AbstractString;
    tess_datapath = Tesseract.TESS_DATA,
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
    tess_datapath = Tesseract.TESS_DATA,
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

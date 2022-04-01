function get_pix(img)
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

function parse_text(
    img,
    instance::TessInst;
    resolution = 72
)
    pix = get_pix(img)
    tess_image(instance, pix)
    tess_resolution(instance, resolution)
    text = tess_text(instance)
end

function parse_text(
    img, language::AbstractString;
    tess_datapath = Tesseract.TESS_DATA,
    resolution = 72
)
    instance = create_ocr_instance(language, tess_datapath = tess_datapath)
    parse_text(img, instance; resolution = resolution)
end

parse_text(
    img,
    ctx::VsContext;
    resolution = 72
) = parse_text(img, ctx.ocr_instance; resolution = resolution)

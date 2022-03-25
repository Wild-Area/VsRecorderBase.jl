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
    instance,
    image, 
    range = size(image);
    resolution = 72
)
    image = @view image[range]
    pix = get_pix(image)
    tess_image(instance, pix)
    tess_resolution(instance, resolution)
    text = tess_text(instance)
end

function parse_text(
    image, language::AbstractString,
    range = size(image);
    tess_datapath = Tesseract.TESS_DATA,
    resolution = 72
)
    instance = create_ocr_instance(language, tess_datapath = tess_datapath)
    parse_text(instance, image, range; resolution = resolution)
end

parse_text(
    ctx::VsContext, image, 
    range = size(image);
    resolution = 72
) = parse_text(ctx.ocr_instance, image, range; resolution = resolution)

function get_pix(img)
    f = IOBuffer()
    s = Stream{format"PNG"}(f)
    save(s, img)
    buffer = take!(f)
    pix = pix_read(buffer)
end

function parse_text(
    image, language,
    range = size(image);
    tess_datapath = Tesseract.TESS_DATA,
    resolution = 72
)
    instance = TessInst(language, tess_datapath)
    image = @view image[range]
    pix = get_pix(image)
    tess_image(instance, pix)
    tess_resolution(instance, resolution)
    text = tess_text(instance)
end

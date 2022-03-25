function initialize(config::VsConfig, stream::AbstractVsStream = nothing)
    ocr_instance = create_ocr_instance(config.ocr_language)
    ctx = VsContext(
        config = config,
        stream = stream,
        ocr_instance = ocr_instance
    )
    vs_init!(ctx)
    ctx
end

function parse_frame!(ctx, frame)
    ctx.current_frame = frame
    ctx.current_scene = vs_parse_frame!(ctx, frame)
    ctx
end

function parse_stream(config::VsConfig, stream::VsStream)
    ctx = initialize(config, stream)
    num_skip_frames = config.num_skip_frames
    while !eof(stream)
        frame = read_frame(stream)
        scene = parse_frame!(ctx, frame)
        if !isnothing(scene)
            vs_update!(ctx, scene)
        end
        skipframes(stream, num_skip_frames, throwEOF = false)
    end
    vs_result(ctx)
end

parse_video(config::VsConfig, video_file) =
    parse_stream(
        config,
        open_video(video_file; gray = config.use_gray_image)
    )

parse_camera(config::VsConfig, device) =
    parse_stream(
        config,
        open_camera(device; gray = config.use_gray_image)
    )

function parse_frame(config, frame)
    ctx = initialize(config)
    parse_frame!(ctx, frame)
    ctx.current_scene
end

function parse_image(config, image)
    frame = VsFrame(image, 0)
    parse_frame(config, frame)
end

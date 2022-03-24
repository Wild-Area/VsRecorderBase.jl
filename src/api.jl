module API

using VideoIO: skipframes

using ..VsRecorderBase: VsStream, VsConfig,
    vs_init, vs_parse,
    open_video, open_camera,
    read_frame


function parse_stream(config::VsConfig, stream::VsStream)
    ctx = vs_init(config)
    video = stream.video
    while !eof(stream)
        frame = read_frame(stream)
        vs_parse(ctx, frame, config)
        skipframes(video, config.num_skip_frames, throwEOF = false)
    end
    vs_result(ctx, config)
end

parse_video(config::VsConfig, video_file::AbstractString) =
    parse_stream(config, open_video(video_file; gray = config.use_gray_image))

parse_camera(config::VsConfig, camera_index)
    parse_stream(config, open_camera(video_file; gray = config.use_gray_image))

end

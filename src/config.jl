Base.@kwdef mutable struct VsConfig{T <: AbstractVsSource}
    num_skip_frames::Int = 59
    use_gray_image::Bool = true
    language::String = "en"
    ocr_language::String = "eng"
    source::T
end

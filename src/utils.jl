to_gray_image(image::AbstractMatrix{<:Gray}) = image
to_gray_image(image::AbstractMatrix) = Gray.(image)

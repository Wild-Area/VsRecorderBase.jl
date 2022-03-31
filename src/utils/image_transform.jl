to_gray_image(img::AbstractMatrix{<:Gray}) = img
to_gray_image(img::AbstractMatrix) = Gray.(img)

blur(img::AbstractMatrix, σ = 0.5) = imfilter(img, KernelFactors.gaussian((σ, σ)))
blur(img, σ = 0.5) = blur(image(img), σ)

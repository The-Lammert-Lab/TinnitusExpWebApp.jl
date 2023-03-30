module TinnitusReconstructor

include("funcs.jl")
include("StimGens.jl")

export UniformPrior
export GaussianPrior
export Brimijoin
export Bernoulli
export BrimijoinGaussianSmoothed
export GaussianNoise
export UniformNoise
export GaussianNoiseNoBins
export UniformNoiseNoBins
export UniformPriorWeightedSampling
export PowerDistribution
export generate_stimuli_matrix

end

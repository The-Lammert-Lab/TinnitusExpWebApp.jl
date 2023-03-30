module TinnitusReconstructor

include("funcs.jl")
include("StimGens.jl")

export UniformPrior, GaussianPrior
export BrimijoinGaussianSmoothed, Brimijoin
export Bernoulli, BrimijoinGaussianSmoothed
export GaussianNoise, UniformNoise
export GaussianNoiseNoBins, UniformNoiseNoBins
export UniformPriorWeightedSampling
export PowerDistribution
export generate_stimuli_matrix

end

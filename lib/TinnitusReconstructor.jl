module TinnitusReconstructor

using DSP
using FFTW
using FastBroadcast
using FileIO
using LibSndFile
using LinearAlgebra
using Memoize
using PortAudio
using SampledSignals
using Statistics
using StatsBase

include("funcs.jl")
include("StimGens.jl")

export Stimgen
export UniformPrior, GaussianPrior
export generate_stimuli_matrix

function present_stimulus(s::Stimgen)
    stimuli_matrix, Fs, _, _ = generate_stimuli_matrix(s)
    play_scaled_audio.(stimuli_matrix[:, 1], Fs)
    return nothing
end

end
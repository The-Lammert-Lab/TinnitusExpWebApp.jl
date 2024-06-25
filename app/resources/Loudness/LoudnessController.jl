module LoudnessController

using CharacterizeTinnitus
using CharacterizeTinnitus.LoudnessMatching
using SearchLight
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using WAV: wavwrite
using Base64
using Genie.Exceptions
using GenieSession
using TinnitusReconstructor
using TinnitusReconstructor: pure_tone, gen_octaves
using DSP: Windows.tukey

min_tone_freq = 500
max_tone_freq = 16000

# get all the frequencies
freqs = gen_octaves(min_tone_freq, max_tone_freq, 2, "semitone")

function loudness_matching()
    authenticated!()

    html(:Loudness, :loudness; freqs)
end

function get_pure_tone()
    curr_freq_index = parse(Int, params(:curr_freq_index)) + 1
    curr_dB = parse(Int, params(:curr_dB))
    start = parse(Int, params(:start))

    query_str = """
                    SELECT
                        AVG(threshold) as avg_t
                    FROM 
                        thresholds
                    GROUP BY user_id, freq
                    HAVING user_id  = $(current_user_id()) and freq = $(freqs[curr_freq_index])
                """
    avg_df = SearchLight.query(query_str)

    if isempty(avg_df)
        avg_threshold = 60
    else
        avg_threshold = avg_df[1, 1]
    end

    if isnothing(avg_threshold)
        avg_threshold = 0
    end

    if start == 1
        gain = 10^(avg_threshold / 20)
    else
        gain = 10^(curr_dB / 20)
    end

    freq = freqs[curr_freq_index]

    curr_tone = pure_tone(freq, 0.5, 44100)

    win = tukey(length(curr_tone), 0.08)
    window_stim = win .* curr_tone

    scaled_pure_tone = gain * window_stim

    buf = Base.IOBuffer()
    wavwrite(scaled_pure_tone, buf; Fs=44100.0)
    pure_tone_wav = base64encode(take!(buf))
    close(buf)

    return json(pure_tone_wav)

end

function save_lm()
    authenticated!()

    curr_freq_index = parse(Int, params(:curr_freq_index)) + 1
    lm = params(:cant_hear) == "true" ? nothing : parse(Float64, params(:curr_dB))
    user_id = current_user_id()

    save(Loudness(user_id=user_id, freq=freqs[curr_freq_index], LM=lm))
    return json("success")
end
end
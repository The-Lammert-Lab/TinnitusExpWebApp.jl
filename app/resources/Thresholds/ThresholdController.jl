module ThresholdController

using CharacterizeTinnitus
using CharacterizeTinnitus.Thresholds
using SearchLight
using Genie.Renderers, Genie.Renderers.Html, Genie.Renderer.Json
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

function threshold_determination()
    authenticated!()

    html(:Thresholds, :threshold; freqs)
end

function get_pure_tone()
    curr_freq_index = parse(Int, params(:curr_freq_index)) + 1
    curr_dB = parse(Int, params(:curr_dB))

    gain = 10^(curr_dB / 20)

    freq = freqs[curr_freq_index]

    curr_tone = pure_tone(freq, 0.5, 44100)

    win = tukey(length(curr_tone), 0.08)
    window_stim = win .* curr_tone

    scaled_pure_tone = gain .* window_stim

    buf = Base.IOBuffer()
    wavwrite(scaled_pure_tone, buf; Fs=44100.0)
    pure_tone_wav = base64encode(take!(buf))
    close(buf)

    return json(pure_tone_wav)

end

function save_threshold()
    authenticated!()

    payload = jsonpayload()

    curr_freq_index = payload["curr_freq_index"] + 1
    threshold = payload["cant_hear"] ? NaN : payload["curr_dB"]
    user_id = current_user_id()

    return save(Threshold(user_id=user_id, name=payload["test_name"], instance=payload["instance"], freq=freqs[curr_freq_index], threshold=threshold)) ? json("success") : json("save call failed.")
end
end
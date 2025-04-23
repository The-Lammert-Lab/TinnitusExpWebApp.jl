module LoudnessController

using CharacterizeTinnitus
using CharacterizeTinnitus.LoudnessMatching
using CharacterizeTinnitus.Thresholds
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
    instance = parse(Int, params(:instance))
    name = params(:name)


    #=    --- These lines are from the old way of doing these tests... kinda bad 
    query_str = """
                    SELECT
                        AVG(threshold) as avg_t
                    FROM 
                        thresholds
                    GROUP BY user_id, freq
                    HAVING user_id  = $(current_user_id()) and freq = $(freqs[curr_freq_index])
                """
    avg_df = SearchLight.query(query_str) =#

    avg_df = SearchLight.find(Threshold; instance=instance, user_id=current_user_id(), freq=freqs[curr_freq_index], name=name)
    print(avg_df)

    if isempty(avg_df)
        avg_threshold = 60
        print("using avg thresh")
    else
        avg_threshold = avg_df[1, 1].freq
        print("using: ")
        print(avg_df)
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

    payload = jsonpayload()

    curr_freq_index = payload["curr_freq_index"] + 1
    lm = payload["cant_hear"] ? NaN : payload["curr_dB"]
    user_id = current_user_id()

    return save(Loudness(user_id=user_id, name=payload["test_name"], instance=payload["instance"], freq=freqs[curr_freq_index], lm=lm)) ? json("success") : json("save call failed.")
end
end
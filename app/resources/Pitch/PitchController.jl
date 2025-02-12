module PitchController

using CharacterizeTinnitus
using CharacterizeTinnitus.PitchMatching
using CharacterizeTinnitus.OctaveDetermination
using CharacterizeTinnitus.InOctave
using SearchLight
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using WAV: wavwrite
using Base64
using Genie.Exceptions
using GenieSession
using Interpolations
using TinnitusReconstructor
using TinnitusReconstructor: pure_tone, gen_octaves, semitones
using DSP: Windows.tukey

freqL = 3180
freqH = 4000
min_tone_freq = 500
max_tone_freq = 16000

# Number of octaves between freqH and config.max_tone_freq
n_octs_high = floor(log2(max_tone_freq / freqH))

# Number of octaves between config.min_tone_freq and freqL
n_octs_low = floor(log2(freqL / min_tone_freq))

# Get list of all possible octaves from the starting points
possible_octs = [reverse(freqL * 0.5 .^ (0:n_octs_low)); freqH * 2 .^ (0:n_octs_high)]

global in_oct_freqs = []
global oct_conf_freqs = []
global oct_gains = []

function pitch_matching()
    authenticated!()
    min_index = 0  # min/max index of the possible octaves used in javascript code
    max_index = length(possible_octs) - 1

    html(:Pitch, :pitch; possible_octs, freqL, freqH, min_index, max_index)
end

function set_calibrated_value()
    global calibrated_value = parse(Float64, params(:calibrated_value))
    return json("success")
end

"""
get_interpolated_oct_gains()

This function retrieves the dB values for the loudness matching (LM) procedure. The function first retrieves the loudness tones and dB values from the database. If the user has not yet completed the LM procedure, the function returns a vector of 60 dB values. If the user has completed the LM procedure, the function interpolates the loudness values to the possible octaves and returns the gain values for each octave.
"""
function get_interpolated_oct_gains()
    global oct_gains
    if !isempty(oct_gains)
        return oct_gains
    end

    get_loudness_tones = """
        SELECT
            freq
        FROM 
            loudness
        where user_id = $(current_user_id())
    """

    LM = SearchLight.query(get_loudness_tones)
    loudness_tones = LM[:, 1]
    loudness_tones = coalesce.(loudness_tones, 60) # make sure type is of float, not that union missing
    print(loudness_tones)

    if isempty(loudness_tones)
        return fill(60, length(possible_octs))
    end

    get_lm_dBs = """
    SELECT
        lm
    FROM 
        loudness
    where user_id = $(current_user_id())
    """

    loudness_dBs = SearchLight.query(get_lm_dBs)
    loudness_dBs = loudness_dBs[:, 1]

    # Replace missing elements with 0
    loudness_dBs = coalesce.(loudness_dBs, 0)

    loudness_dBs .+= 5

    print(loudness_dBs)

    # Interpolate the loudness matching values
    itp = extrapolate(interpolate((loudness_tones,), loudness_dBs, Gridded(Linear())), Line()) # Make interpolation obj
    oct_dBs = itp(possible_octs) .- calibrated_value # Vector from prev code block, subtract the session calibration value
    oct_gains = 10 .^ (oct_dBs / 20) # convert dBs to gain based on current 
    @. oct_gains[oct_gains>1] = 1 # Make sure nothing will clip

    return oct_gains

end

function find_lm_dB(freq)
    get_lm_dB = """
    SELECT
        lm
    FROM 
        loudness
    where user_id = $(current_user_id()) and freq = $(freq)
    """
    df = SearchLight.query(get_lm_dB)
    if isempty(df)
        return -1
    else
        return df[1, 1]
    end
end

function get_pure_tone_for_oct_determination()
    freq_index_L = parse(Int, params(:freq_index_L))
    freq_index_H = parse(Int, params(:freq_index_H))

    #  ongoing process of the user in PM: 0: octaveDetermination or 1: inOcatave or 2: 
    on_going = parse(Int, params(:on_going))

    lm_dB_low = find_lm_dB(possible_octs[freq_index_L])
    lm_dB_high = find_lm_dB(possible_octs[freq_index_H])

    oct_gains = get_interpolated_oct_gains()

    if lm_dB_low == -1
        lm_dB_low = oct_gains[freq_index_L]
    end
    if lm_dB_high == -1
        lm_dB_high = oct_gains[freq_index_H]
    end

    gain_low = 10^(lm_dB_low / 20)
    gain_high = 10^(lm_dB_high / 20)

    if on_going == 0
        sound_low = pure_tone(possible_octs[freq_index_L], 0.5, 44100)
        sound_high = pure_tone(possible_octs[freq_index_H], 0.5, 44100)
    elseif on_going == 1
        sound_low = pure_tone(in_oct_freqs[freq_index_L], 0.5, 44100)
        sound_high = pure_tone(in_oct_freqs[freq_index_H], 0.5, 44100)
    elseif on_going == 2
        sound_low = pure_tone(oct_conf_freqs[freq_index_L], 0.5, 44100)
        sound_high = pure_tone(oct_conf_freqs[freq_index_H], 0.5, 44100)
    end

    win_low = tukey(length(sound_low), 0.08)
    window_stim_low = win_low .* sound_low

    win_high = tukey(length(sound_high), 0.08)
    window_stim_high = win_high .* sound_high

    scaled_pure_tone_low = gain_low * window_stim_low
    scaled_pure_tone_high = gain_high * window_stim_high

    buf = Base.IOBuffer()
    wavwrite(scaled_pure_tone_high, buf; Fs=44100.0)
    pure_tone_high_wav = base64encode(take!(buf))
    close(buf)

    buf = Base.IOBuffer()
    wavwrite(scaled_pure_tone_low, buf; Fs=44100.0)
    pure_tone_low_wav = base64encode(take!(buf))
    close(buf)

    return json([pure_tone_low_wav, pure_tone_high_wav])
end

function save_sound_for_octave_determination()

    on_going = parse(Int, params(:on_going))

    freq_l = parse(Float64, params(:freq_l))
    freq_h = parse(Float64, params(:freq_h))
    closer_sound = parse(Float64, params(:closer_sound))


    if on_going == 0
        oct_determination = OctDetermination(
            user_id=current_user_id(),
            sound_a=freq_l,
            sound_b=freq_h,
            closer_sound=closer_sound
        )
        save(oct_determination)
    elseif on_going == 1
        in_oct = InOct(
            user_id=current_user_id(),
            sound_a=freq_l,
            sound_b=freq_h,
            closer_sound=closer_sound
        )
        save(in_oct)
    elseif on_going == 2
        matched_pitch = Pitch(
            user_id=current_user_id(),
            sound_a=freq_l,
            sound_b=freq_h,
            PM=closer_sound
        )
        save(matched_pitch)
    end

    return json("success")
end

function get_in_octave_freqs()
    authenticated!()

    f_center = parse(Int, params(:f_center))
    type = params(:type) # type = 'minimum' or 'maximum' or 'reverse'

    if type == "minimum"
        half_steps = semitones(freqL, 12, "up")
        global in_oct_freqs = half_steps[1:2:end]
    elseif type == "maximum"
        half_steps = semitones(freqH, 12, "down")
        global in_oct_freqs = half_steps[1:2:end]
    elseif type == "reverse"
        hs_down = semitones(f_center, 6, "down")
        hs_up = semitones(f_center, 6, "up")
        half_steps = [reverse(hs_down); hs_up[2:end]]
        global in_oct_freqs = half_steps[1:2:end]
    end

    return json(in_oct_freqs)
end

function get_oct_confusion_freqs()
    matched_freq = parse(Float64, params(:matched_freq))

    global oct_conf_freqs = [matched_freq / 2, matched_freq, matched_freq, matched_freq * 2]

    return json(oct_conf_freqs)
end

end
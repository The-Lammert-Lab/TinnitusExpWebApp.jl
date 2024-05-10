module PublicController

using CharacterizeTinnitus
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using WAV: wavwrite
using Base64
using Genie.Exceptions
using GenieSession
using TinnitusReconstructor

using GenieAuthentication

function index()
    is_admin = admin_status()
    html(:public, :index; is_admin)
end

function faq()
    is_admin = admin_status()
    html(:public, :faq; is_admin)
end

function lab()
    is_admin = admin_status()
    html(:public, :lab; is_admin)
end

function calibrate()
    pure_tone_wav = pure_tone(1000, 1, 44100)

    buf = Base.IOBuffer()
    wavwrite(pure_tone_wav, buf; Fs=44100.0)
    pure_tone_wav = base64encode(take!(buf))
    close(buf)

    html(:public, :calibrate; pure_tone_wav)
end

admin_status() = return current_user() isa Nothing ? nothing : current_user().is_admin

end

module PublicController

using CharacterizeTinnitus
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
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

admin_status() = return current_user() isa Nothing ? nothing : current_user().is_admin

end

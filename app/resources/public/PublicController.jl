module PublicController

using CharacterizeTinnitus
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using GenieAuthentication

function index()
    is_admin = current_user() isa Nothing ? nothing : current_user().is_admin
    html(:public, :index; is_admin)
end

function faq()
    is_admin = current_user() isa Nothing ? nothing : current_user().is_admin
    html(:public, :faq; is_admin)
end

end

// Index
function showOptions() {
    document.getElementById("stimgenDropdown").classList.toggle("show");
}

// Main protocol logic
function recordAndPlay(ans) {
    // Log ans
    switch(ans) {
        case 'yes':
            addRespToStorage(1);
            console.log(1);
            break;
        case 'no':
            addRespToStorage(-1);
            console.log(-1);
            break;
    }

    // Collect all stimulus audio elements
    const stimuli = document.getElementsByName("stimulus");

    // Finished this block
    if (stimuli.length === 0) {
        // Get n_blocks and n_trials_per_block from search params
        let params = new Proxy(new URLSearchParams(window.location.search), {
            get: (searchParams, prop) => searchParams.get(prop),
        });
        let n_blocks = params.n_blocks;
        let n_trials_per_block = params.n_trials_per_block;
        let stimgen = params.stimgen;

        // Add one to blocks completed
        let blocks_completed = (parseInt(params.blocks_completed) + 1).toString();

        if (blocks_completed === n_blocks) {
            // TODO: Send responses to server
            sessionStorage.removeItem("responses");
            window.location.replace("/done");
            return;
        } else {
            // Redirect to a rest page with params
            // TODO: Send responses to server
            sessionStorage.removeItem("responses");
            window.location.replace("/rest?" + "n_blocks=" + n_blocks + 
                "&n_trials_per_block=" + n_trials_per_block + 
                "&blocks_completed=" + blocks_completed +
                "&stimgen=" + stimgen
            );
            return;
        }
    }
    
    // Get the next audio element (prev. was deleted)
    const curr_id = Math.min(parseInt(stimuli[0].id));

    // 300ms delay then play sound
    setTimeout(() => {document.getElementById(curr_id).play()}, 300);

    // Disallow answer while the sound plays
    document.getElementById('yes').disabled=true;
    document.getElementById('no').disabled=true;
} // function

// Load html audio elements from local storage
function genAudioFromStorage() {
    // Get data from local storage
    // TODO: Add check clause to be sure the data is there(?)
    var stims = JSON.parse(sessionStorage.getItem('stims'));
    
    // Create the elements
    for (let i = 0; i < stims.length; i++) {
        let audio = document.createElement('audio');
        audio.id = (i + 1).toString();
        audio.src = stims[i];
        audio.preload = 'auto';
        audio.addEventListener("ended", function () {
            document.getElementById('yes').disabled = false;
            document.getElementById('no').disabled = false;
            this.remove();
        });
        document.body.appendChild(audio)
        // Unclear why, but audio.name does not actually add the name attribute.
        document.getElementById((i + 1).toString()).setAttribute("name", "stimulus");
    }
    // Remove audio data from storage.
    sessionStorage.removeItem('stims');
}

// Collect and save audio src's to local storage
function addAudioToStorage() {
    let stim_len = document.getElementsByName("stimulus").length;

    // Collect src's. 
    var stims = new Array(stim_len);
    for (let i = 0; i < stim_len; i++) {
        // Ensures they're in order.
        stims[i] = document.getElementById((i + 1).toString()).src;
    }

    // Create and add JSON file to local storage.
    const stims_json = JSON.stringify(stims);
    sessionStorage.setItem('stims', stims_json);
}

// Redirect from rest page to experiment page
function restToExp() {
    let params = new Proxy(new URLSearchParams(window.location.search), {
            get: (searchParams, prop) => searchParams.get(prop),
        });
    window.location.href = "/experiment?" + "n_blocks=" + params.n_blocks + 
        "&n_trials_per_block=" + params.n_trials_per_block + 
        "&blocks_completed=" + params.blocks_completed + 
        "&stimgen=" + params.stimgen;
    return;
}

function addRespToStorage(ans) {
    var responses = JSON.parse(sessionStorage.getItem("responses"));
    if(responses == null) responses = [];
    responses.push(ans);
    sessionStorage.setItem("responses", JSON.stringify(responses));
}

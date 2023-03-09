// Index
function showOptions() {
    document.getElementById("stimgenDropdown").classList.toggle("show");
}

// Main protocol logic
function recordAndPlay(ans) {
    // Interpret response
    switch (ans) {
        case 'yes': 
            var val = 1;
            break;
        case 'no':
            var val = -1;
            break;
    }
    
    // Save response
    axios.post('/save', {
        resp: val
    })
        .then(function (response) {
            // Collect all stimulus audio elements
            const stimuli = document.getElementsByName("stimulus");

            // Get params (name, instance, from)
            if (parseFloat(response.data.frac_complete.value) >= 1) {
                window.location.replace("/done");
                return;
            } else if (stimuli.length === 0) {
                const params = new URLSearchParams(window.location.search);
                window.location.replace("/rest?" + "name=" + params.get('name') +
                    "&instance=" + params.get('instance')
                );
                return;
            } else {
                // Get the next audio element (prev. was deleted)
                const curr_id = Math.min(parseInt(stimuli[0].id));
                // 300ms delay then play sound
                setTimeout(() => { document.getElementById(curr_id).play() }, 300);
                // Disallow answer while the sound plays
                document.getElementById('yes').disabled = true;
                document.getElementById('no').disabled = true;
            }
        })
        .catch(function (error) {
            if (error.response) {
                // Request made and server responded
                console.log(error.response.data);
                console.log(error.response.status);
                console.log(error.response.headers);
                window.alert(error.response.data.error);
                window.location.replace("/home");
                return;
            } else if (error.request) {
                // The request was made but no response was received
                console.log(error.request);
                return;
            } else {
                // Something happened in setting up the request that triggered an Error
                console.log('Error', error.message);
                return;
            }
        });
} // function

// Load html audio elements from local storage
function getAudioFromStorage() {
    // Get data from local storage
    // TODO: Add check clause to be sure the data is there(?)
    const stims = JSON.parse(sessionStorage.getItem('stims'));

    // Create the elements
    for (let i = 0; i < stims.length; i++) {
        let audio = document.createElement('audio');
        audio.id = (i + 1).toString();
        audio.src = "data:audio/wav;base64," + stims[i];
        audio.preload = 'auto';
        audio.addEventListener("ended", function () {
            document.getElementById('yes').disabled = false;
            document.getElementById('no').disabled = false;
            this.remove();
        });
        document.body.appendChild(audio);
        // Unclear why, but audio.name does not actually add the name attribute.
        document.getElementById((i + 1).toString()).setAttribute("name", "stimulus");
    }
    // Remove audio data from storage.
    sessionStorage.removeItem('stims');
} // function

// Redirect from rest page to experiment page
function restToExp() {
    const params = new URLSearchParams(window.location.search);
    window.location.href = "/experiment?" + "name=" + params.get('name') +
        "&instance=" + params.get('instance') + "&from=rest";
} // function

// function addRespToStorage(ans) {
//     let responses = JSON.parse(sessionStorage.getItem("responses"));
//     if (responses == null) responses = [];
//     responses.push(ans);
//     sessionStorage.setItem("responses", JSON.stringify(responses));
// } // function

// Request server to generate audio elements then save to session storage
function getAndStoreAudio() {
    const params = new URLSearchParams(window.location.search);
    axios.post('/generate', {
        name: params.get('name'),
        instance: params.get('instance')
    })
        .then(function (stimuli) {
            sessionStorage.setItem('stims', JSON.stringify(stimuli.data));
        })
        .then(function () {
            // Only allow continuing once stimuli have been stored. 
            document.getElementById('continue').disabled = false;
        })
        // Debugging purposes.
        // TODO: Do something meaningful on error
        .catch(function (error) {
            if (error.response) {
                // Request made and server responded
                console.log(error.response.data);
                console.log(error.response.status);
                console.log(error.response.headers);
            } else if (error.request) {
                // The request was made but no response was received
                console.log(error.request);
            } else {
                // Something happened in setting up the request that triggered an Error
                console.log('Error', error.message);
            }
        });
} // function

function addExperiment(form) {
    const formData = new FormData(form);
    axios.post('/add', {
        name: formData.get('name'),
    })
        .then(function () {
            window.location.reload();
        });
}

// Post data from experiment to restart to server and refresh page.
function restartExperiment(form) {
    const formData = new FormData(form);
    axios.post('/restart', {
        name: formData.get('name'),
        instance: formData.get('instance')
    })
        .then(function () {
            window.location.reload();
        });
} // function

// Post data from experiment to remove to server and refresh page.
function removeExperiment(form) {
    const formData = new FormData(form);
    axios.post('/remove', {
        name: formData.get('name'),
        instance: formData.get('instance')
    })
        .then(function () {
            window.location.reload();
        })
        .catch(function (error) { 
            if (error.response) {
                // Request made and server responded
                window.alert(error.response.data);
                window.location.reload();
            } else if (error.request) {
                // The request was made but no response was received
                console.log(error.request);
            } else {
                // Something happened in setting up the request that triggered an Error
                console.log('Error', error.message);
            }
        });
} // function

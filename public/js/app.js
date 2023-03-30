/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
// Main protocol logic
function recordAndPlay(ans) {
  // Interpret response
  // TODO: Make more robust (?)
  const val = ans === "yes" ? 1 : -1;

  // Save response
  axios
    .post("/save", {
      resp: val,
    })
    .then(function (response) {
      // Collect all stimulus audio elements
      const stimuli = document.getElementsByName("stimulus");

      // Determine next action (go to done, rest, or play next stimulus)
      if (parseFloat(response.data.frac_complete.value) >= 1) {
        window.location.replace("/done");
        return;
      } else if (stimuli.length === 0) {
        const params = new URLSearchParams(window.location.search);
        window.location.replace(
          "/rest?" +
            "name=" +
            params.get("name") +
            "&instance=" +
            params.get("instance")
        );
        return;
      } else {
        // Get the next audio element (prev. was deleted)
        const curr_id = Math.min(parseInt(stimuli[0].id));
        // 300ms delay then play sound
        setTimeout(() => {
          document.getElementById(curr_id).play();
        }, 300);
        // Disallow answer while the sound plays
        document.getElementById("yes").disabled = true;
        document.getElementById("no").disabled = true;
      }
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.replace("/home");
      } else if (error.request) {
        window.alert(error.request);
        window.location.replace("/home");
      } else {
        window.alert("Error: " + error.message);
        window.location.replace("/home");
      }
      return;
    });
} // function

// Load html audio elements from local storage
function getAudioFromStorage() {
  // Get data from local storage
  const stims = JSON.parse(sessionStorage.getItem("stims"));
  if (stims === null) {
    window.alert("Unable to load stimuli. Click 'OK' to return home.");
    return window.location.replace("/home");
  }

  // Create the elements
  for (let i = 0; i < stims.length; i++) {
    let audio = document.createElement("audio");
    audio.id = (i + 1).toString();
    audio.src = "data:audio/wav;base64," + stims[i];
    audio.preload = "auto";
    audio.setAttribute("name", "stimulus");
    audio.addEventListener("ended", function () {
      document.getElementById("yes").disabled = false;
      document.getElementById("no").disabled = false;
      this.remove();
    });
    document.body.appendChild(audio);
  }
  // Remove audio data from storage.
  sessionStorage.removeItem("stims");
} // function

// Redirect from rest page to experiment page
function restToExp() {
  const params = new URLSearchParams(window.location.search);
  window.location.href =
    "/experiment?" +
    "name=" +
    params.get("name") +
    "&instance=" +
    params.get("instance") +
    "&from=rest";
} // function

// Request server to generate audio elements then save to session storage
function getAndStoreAudio() {
  const params = new URLSearchParams(window.location.search);
  axios
    .post("/generate", {
      name: params.get("name"),
      instance: params.get("instance"),
    })
    .then(function (stimuli) {
      sessionStorage.setItem("stims", JSON.stringify(stimuli.data));
    })
    .then(function () {
      // Only allow continuing once stimuli have been stored.
      document.getElementById("continue").disabled = false;
    })
    // Debugging purposes.
    // TODO: Do something meaningful on error
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.replace("/home");
      } else if (error.request) {
        window.alert(error.request);
        window.location.replace("/home");
      } else {
        window.alert("Error: " + error.message);
        window.location.replace("/home");
      }
      return;
    });
} // function

// Send user_id and name of experiment to add to server
function addExperiment(form) {
  const formData = new FormData(form);
  axios
    .post("/add", {
      experiment: formData.get("experiment"),
      user_id: formData.get("user_id"),
    })
    .then(function (response) {
      sessionStorage.setItem("ToastMsg", response.data);
      window.location.reload();
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.reload();
      } else if (error.request) {
        window.alert(error.request);
        window.location.reload();
      } else {
        window.alert("Error", error.message);
        window.location.reload();
      }
      return;
    });
} // function

// Post data from experiment to restart to server and refresh page.
function restartExperiment(form) {
  const formData = new FormData(form);
  axios
    .post("/restart", {
      name: formData.get("name"),
      instance: formData.get("instance"),
      user_id: formData.get("user_id"),
    })
    .then(function (response) {
      sessionStorage.setItem("ToastMsg", response.data);
      window.location.reload();
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.reload();
      } else if (error.request) {
        window.alert(error.request);
        window.location.reload();
      } else {
        window.alert("Error", error.message);
        window.location.reload();
      }
      return;
    });
} // function

// Post data from experiment to remove to server and refresh page.
function removeExperiment(form) {
  const formData = new FormData(form);
  axios
    .post("/remove", {
      name: formData.get("name"),
      instance: formData.get("instance"),
      user_id: formData.get("user_id"),
    })
    .then(function (response) {
      sessionStorage.setItem("ToastMsg", response.data);
      window.location.reload();
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.reload();
      } else if (error.request) {
        window.alert(error.request);
        window.location.reload();
      } else {
        window.alert("Error", error.message);
        window.location.reload();
      }
      return;
    });
} // function

// Send experiment name to server and build
// table with settings and table with
// status of this experiment for all users from response data.
function viewExperiment(experiment) {
  const result = axios
    .get("/admin/view", {
      params: {
        name: experiment,
      },
    })
    .then(function (response) {
      // Make table for experimental settings
      const ex_table = document.getElementById("experiment-settings");
      ex_table.innerHTML = ""; // Delete old table rows
      const ex_data = response.data.experiment_data.value;
      // Build new table
      for (const element in ex_data) {
        let row = ex_table.insertRow();
        let cell1 = row.insertCell();
        let cell2 = row.insertCell();
        let field = document.createTextNode(element);
        let val = document.createTextNode(ex_data[element]);
        cell1.appendChild(field);
        cell2.appendChild(val);
      }
      // TODO: Sort table
      // NOTE: use innerHTML to get row value

      // Make table with user information for this experiment
      const user_table = document.getElementById("user-experiment-data");
      user_table.innerHTML = ""; // Delete old table rows
      const user_data = response.data.user_data.value;
      for (const element in user_data) {
        let row = user_table.insertRow();
        let cell1 = row.insertCell();
        let cell2 = row.insertCell();
        let cell3 = row.insertCell();
        let username = document.createTextNode(user_data[element].username);
        let instance = document.createTextNode(user_data[element].instance);
        let perc_complete = document.createTextNode(
          100 * user_data[element].frac_complete + "%"
        );
        cell1.appendChild(username);
        cell2.appendChild(instance);
        cell3.appendChild(perc_complete);
      }
      return user_data.length > 0 ? true : false;
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.reload();
      } else if (error.request) {
        window.alert(error.request);
        window.location.reload();
      } else {
        window.alert("Error", error.message);
        window.location.reload();
      }
      return Promise.reject();
    });
  return result;
}

// Populate table with stimgen settings.
function viewStimgen(form) {
  const formData = new FormData(form);
  const type = formData.get("type");
  axios
    .get("/create/get", {
      params: {
        type: type,
      },
    })
    .then(function (response) {
      const sg_tbody = document.getElementById("stimgen-settings");
      // Fully delete stimgen rows (do not know what new ones will be added)
      sg_tbody.innerHTML = "";

      // Clear input values in experiment rows b/c all else stays same.
      const exp_tbody = document.getElementById("experiment-settings");
      for (let input of exp_tbody.getElementsByTagName("input")) {
        input.value = "";
      }
      // Build new table
      const sg_data = response.data;
      for (const element in sg_data) {
        let row = sg_tbody.insertRow();
        let cell1 = row.insertCell();
        let cell2 = row.insertCell();
        let field = document.createTextNode(sg_data[element].label);

        let input = document.createElement("INPUT");
        input.setAttribute("type", sg_data[element].type);
        input.setAttribute("name", "stimgen." + sg_data[element].name);
        input.setAttribute("value", sg_data[element].value);
        input.required = true;

        if (sg_data[element].step !== "nothing") {
          input.setAttribute("step", sg_data[element].step);
        }

        cell1.appendChild(field);
        cell2.appendChild(input);
      }
      // Include stimgen type in form (shown in dropdown on page)
      const _type_input = document.getElementById("_type");
      let input =
        _type_input === null ? document.createElement("INPUT") : _type_input;
      input.setAttribute("id", "_type");
      input.setAttribute("type", "hidden");
      input.setAttribute("name", "_stimgen-type");
      input.setAttribute("value", type);
      document.getElementById("create-form").appendChild(input);

      // Enable the save button
      document.getElementById("saveButton").disabled = false;
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
      } else if (error.request) {
        window.alert(error.request);
      } else {
        window.alert("Error: " + error.message);
      }
    });
} // function

// Post new experiment parameters to server to save.
function saveExperiment(form) {
  const formData = new FormData(form);
  const formObj = Object.fromEntries(formData);

  // Separate experiment settings and stimgen settings for easier processing
  let exp_data = new FormData();
  let sg_data = new FormData();
  for (const [key, value] of Object.entries(formObj)) {
    if (key.startsWith("experiment")) {
      exp_data.append(key.split(".")[1], value);
    } else if (key.startsWith("stimgen")) {
      sg_data.append(key.split(".")[1], value);
    }
  }

  axios
    .post("/create/save", {
      experiment: JSON.stringify(Object.fromEntries(exp_data)),
      stimgen: JSON.stringify(Object.fromEntries(sg_data)),
      stimgen_type: formData.get("_stimgen-type"),
    })
    .then(function (response) {
      sessionStorage.setItem("ToastMsg", response.data);
      // reset to blank create page regardless of if from template or not.
      window.location.href = window.location.pathname;
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
      } else if (error.request) {
        window.alert(error.request);
      } else {
        window.alert("Error: " + error.message);
      }
    });
} // function

// $(document).ready replacement for no jQuery.
function ready(fn) {
  if (document.readyState !== "loading") {
    fn();
    return;
  }
  document.addEventListener("DOMContentLoaded", fn);
} // function

// Gets "ToastMsg" from session storage and displays it for 3s if not null.
function showToast() {
  const msg = sessionStorage.getItem("ToastMsg");
  if (msg !== null) {
    let x = document.getElementById("snackbar");
    x.innerHTML = msg;
    x.className = "show";
    sessionStorage.clear("ToastMsg");
    setTimeout(function () {
      x.className = x.className.replace("show", "");
    }, 3000);
  }
} // function

function deleteExperiment(form) {
  const formData = new FormData(form);
  axios
    .get("/delete", {
      params: {
        name: formData.get("name"),
      },
    })
    .then(function (response) {
      sessionStorage.setItem("ToastMsg", response.data);
      window.location.reload();
    })
    .catch(function (error) {
      if (error.response) {
        // Request made and server responded
        window.alert(error.response.data.error);
        window.location.reload();
      } else if (error.request) {
        // The request was made but no response was received
        console.log(error.request);
      } else {
        // Something happened in setting up the request that triggered an Error
        console.log("Error", error.message);
      }
    });
} // function

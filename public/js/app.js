/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */

// Main protocol logic. Save response and determine next action
function recordAndPlay(ans) {
  // Interpret response
  var val = 0;
  if (ans === "yes") {
    val = 1;
  } else if (ans === "no") {
    val = -1;
  } else {
    window.alert("Unexpected response received. Please restart and try again.");
    window.location.replace("/profile");
  }

  // Save response
  axios
    .post("/save", {
      resp: val,
    })
    .then(function (response) {
      // Collect all stimulus audio elements
      const stimuli = document.getElementsByName("stimulus");

      // Determine next action (go to done, rest, or play next stimulus)
      if (response.data.exp_complete.value) {
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
        window.location.replace("/profile");
      } else if (error.request) {
        window.alert(error.request);
        window.location.replace("/profile");
      } else {
        window.alert("Error: " + error.message);
        window.location.replace("/profile");
      }
      return;
    });
} // function

// Update progress bar on the experiment page
function updateProgress() {
  const bar = document.getElementsByClassName("progress-bar")[0];
  const percent =
    -100 *
    (
      document.getElementsByName("stimulus").length /
        sessionStorage.getItem("init_n_stimuli") -
      1
    ).toFixed(2);
  bar.setAttribute("style", "width: " + percent + "%");
  bar.setAttribute("aria-valuenow", percent);
} // function

// Load html audio elements from local storage
function getAudioFromStorage() {
  // Get data from local storage
  const stims = JSON.parse(sessionStorage.getItem("stims"));
  if (stims === null) {
    window.alert("Unable to load stimuli. Click 'OK' to return home.");
    return window.location.replace("/profile");
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
    .then(function (response) {
      sessionStorage.setItem("stims", JSON.stringify(response.data));
    })
    .then(function () {
      // Only allow continuing once stimuli have been stored.
      document.getElementById("continue").disabled = false;
    })
    .catch(function (error) {
      if (error.response) {
        window.alert(error.response.data.error);
        window.location.replace("/profile");
      } else if (error.request) {
        window.alert(error.request);
        window.location.replace("/profile");
      } else {
        window.alert("Error: " + error.message);
        window.location.replace("/profile");
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

// Post user_id and data from experiment to remove to server and refresh page.
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
          user_data[element].percent_complete + "%"
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
      // const exp_tbody = document.getElementById("experiment-settings");
      // for (let input of exp_tbody.getElementsByTagName("input")) {
      //   input.value = "";
      // }
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

// Creates from template and delete buttons on admin profile page
function createExpButtons() {
  const template_submit = document.getElementById("template-submit");
  const template_input = document.getElementById("template-name");
  const delete_submit = document.getElementById("delete-submit");
  const delete_input = document.getElementById("delete-name");
  if (ddl.value !== "default") {
    viewExperiment(ddl.value) // Returns a Promise
      .then((added_to_a_user) => {
        template_input.setAttribute("value", ddl.value);
        delete_input.setAttribute("value", ddl.value);

        if (template_submit === null) {
          let submit = document.createElement("button");
          submit.setAttribute("id", "template-submit");
          submit.setAttribute("type", "submit");
          submit.setAttribute("class", "btn btn-outline-dark");
          submit.innerHTML = "Create experiment from this template";
          document
            .getElementById("create-from-template-form")
            .appendChild(submit);
        }

        // Only create delete button if it doesn't exist already and
        // experiment is not added to any user
        if (added_to_a_user && delete_submit !== null) {
          delete_submit.remove();
        } else if (!added_to_a_user && delete_submit === null) {
          let submit = document.createElement("button");
          submit.setAttribute("id", "delete-submit");
          submit.setAttribute("type", "submit");
          submit.setAttribute("class", "btn btn-outline-danger");
          submit.innerHTML = "Delete this experiment";
          document.getElementById("delete-form").appendChild(submit);
        }
      })
      // Error handled in viewExperiment. This prevents any code from running.
      .catch((error) => {});
  } else {
    document.getElementById("experiment-settings").innerHTML = "";
    document.getElementById("user-experiment-data").innerHTML = "";
    template_submit.remove();
    template_input.setAttribute("value", "");
    delete_submit.remove();
    delete_input.setAttribute("value", "");
  }
} // function

// $(document).ready replacement for no jQuery.
function ready(fn) {
  if (document.readyState !== "loading") {
    fn();
    return;
  }
  document.addEventListener("DOMContentLoaded", fn);
} // function

// Gets "ToastMsg" from session storage and displays it if not null.
function showToast() {
  const msg = sessionStorage.getItem("ToastMsg");
  if (msg !== null) {
    const body = document.getElementsByClassName("toast-body")[0];
    body.innerHTML = msg;
    const toast = new bootstrap.Toast(document.getElementById("Toast"));
    toast.show();
    sessionStorage.clear("ToastMsg");
  }
}

// Send a request to delete experiment with its name
function deleteExperiment(form) {
  const formData = new FormData(form);
  axios
    .post("/delete", {
      name: formData.get("name"),
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

// Specific function for updating user table on admin profile page
function updateUserTable(
  tbody_id,
  page = sessionStorage.getItem("user-table-page"),
  limit = sessionStorage.getItem("user-table-limit")
) {
  sessionStorage.setItem("user-table-page", page);
  // Request server for data with which to populate table
  axios
    .post("/admin/getpartialdata", {
      datatype: "User",
      page: page,
      limit: limit,
    })
    .then(function (response) {
      updateTablePageBtns(tbody_id, page);

      // Remove existing table rows
      const tbody = document.getElementById(tbody_id);
      tbody.innerHTML = "";
      // Write in new data
      response.data.forEach((username) => {
        const row = tbody.insertRow();
        const cell1 = row.insertCell();
        const cell2 = row.insertCell();

        const form = document.createElement("form");
        form.setAttribute("action", "/manage");

        const input = document.createElement("input");
        input.setAttribute("type", "hidden");
        input.setAttribute("name", "username");
        input.setAttribute("value", username);
        form.appendChild(input);

        const submit = document.createElement("input");
        submit.setAttribute("type", "submit");
        submit.setAttribute("value", "Manage");
        form.appendChild(input);
        form.appendChild(submit);

        cell1.appendChild(document.createTextNode(username));
        cell2.appendChild(form);
      });
    });
} // function

// Generic function for updating table length limit
// Calls the passed `table_update_fn`, which is specific to the table.
// `table_update_fn` must be passed as a function, not a string.
function updateTableLimit(tbody_id, table_update_fn, limit) {
  if (parseInt(limit) < 1) {
    limit = 1;
  } else {
    limit = parseInt(limit);
  }

  sessionStorage.setItem(tbody_id + "-limit", limit);
  table_update_fn(
    tbody_id,
    parseInt(sessionStorage.getItem(tbody_id + "-page")),
    limit
  );
  // Update nav bar
  const max = sessionStorage.getItem(tbody_id + "-max");
  const nav = document.getElementById(tbody_id + "-nav");
  const nav_nums = document.getElementsByName(tbody_id + "-nav-num");
  const next = document.getElementById(tbody_id + "-next-btn");
  const curr_page = parseInt(sessionStorage.getItem(tbody_id + "-page"));

  // Remove old numbers
  while (nav_nums.length > 0) {
    nav_nums[0].remove();
  }

  next.remove();
  for (let i = 1; i < Math.ceil(max / limit) + 1; i++) {
    let li = document.createElement("li");
    li.setAttribute("name", tbody_id + "-nav-num");
    li.setAttribute("onclick", `${table_update_fn.name}('${tbody_id}',${i})`);
    li.innerHTML = i.toString();
    if (i === curr_page) {
      li.setAttribute("class", "page-item page-link active");
    } else {
      li.setAttribute("class", "page-item page-link");
    }
    nav.appendChild(li);
  }
  nav.appendChild(next);
} // function

// Generic function to update the enabled/disabled/active status of pagination buttons
function updateTablePageBtns(tbody_id, page) {
  const nav_btns = document.getElementsByName(tbody_id + "-nav-num");
  const prev_btn = document.getElementById(tbody_id + "-prev-btn");
  const next_btn = document.getElementById(tbody_id + "-next-btn");

  // Update highlighting on nav buttons
  nav_btns.forEach((li) => {
    if (li.innerHTML == page) {
      li.setAttribute("class", "page-item page-link active");
    } else {
      li.setAttribute("class", "page-item page-link");
    }
  });

  // Enable or disable previous button
  if (parseInt(page) > 1) {
    prev_btn.setAttribute("class", "page-item page-link");
  } else {
    prev_btn.setAttribute("class", "page-item page-link disabled");
  }

  // Enable or disable next button
  if (nav_btns.length === parseInt(page)) {
    next_btn.setAttribute("class", "page-item page-link disabled");
  } else {
    next_btn.setAttribute("class", "page-item page-link");
  }
} // function

// Updates the navbar links based on the current page.
function updateNavbarColors() {
  const li = document.getElementById(window.location.pathname);
  if (li !== null) {
    li.setAttribute("class", "nav-link px-2 link-secondary");
  }
} // function

/* Vibe Toolbox picker: renders catalog.json, keeps selection in the URL hash,
   and turns the selection into a short install command via /api/select. */

(function () {
  "use strict";

  var catalog = null;
  var selected = new Set();
  var debounceTimer = null;
  var currentCommand = "";

  var pickerEl = document.getElementById("picker");
  var commandTextEl = document.getElementById("command-text");
  var commandCountEl = document.getElementById("command-count");
  var copyBtn = document.getElementById("copy-btn");
  var presetBtns = document.querySelectorAll(".preset-btn");

  fetch("catalog.json")
    .then(function (r) { return r.json(); })
    .then(function (data) {
      catalog = data;
      render();
      restoreFromHash();
      updateCommand();
    })
    .catch(function () {
      pickerEl.innerHTML =
        '<p class="noscript-note">Could not load the tool catalog. Refresh, or install with: ' +
        "<code>curl -fsSL https://vibetoolbox.dev/install.sh | bash -s -- --all</code></p>";
    });

  function toolById(id) {
    for (var i = 0; i < catalog.tools.length; i++) {
      if (catalog.tools[i].id === id) return catalog.tools[i];
    }
    return null;
  }

  function render() {
    catalog.categories.forEach(function (cat) {
      var tools = catalog.tools.filter(function (t) { return t.category === cat.id; });
      if (!tools.length) return;

      var section = document.createElement("div");
      section.className = "category";
      section.innerHTML =
        '<div class="category-header"><h2>' + cat.name + "</h2>" +
        '<span class="cat-line"></span>' +
        '<span class="cat-count" data-cat="' + cat.id + '"></span></div>';

      var grid = document.createElement("div");
      grid.className = "tool-grid";

      tools.forEach(function (tool) {
        var card = document.createElement("label");
        card.className = "tool-card";
        card.dataset.id = tool.id;
        var badge = "";
        if (tool.requires && tool.requires.length) {
          badge = '<span class="tool-badge dep">needs ' + tool.requires.join(", ") + "</span>";
        }
        card.innerHTML =
          '<input type="checkbox" value="' + tool.id + '">' +
          '<div class="tool-card-top"><span class="tool-name">' + tool.name + "</span>" +
          '<span class="tool-check" aria-hidden="true"></span></div>' +
          '<p class="tool-desc">' + tool.desc + "</p>" + badge;

        card.querySelector("input").addEventListener("change", function (e) {
          toggle(tool.id, e.target.checked);
        });
        grid.appendChild(card);
      });

      section.appendChild(grid);
      pickerEl.appendChild(section);
    });
  }

  function toggle(id, on) {
    if (on) {
      selected.add(id);
      // Pull dependencies in with the tool
      var tool = toolById(id);
      (tool && tool.requires ? tool.requires : []).forEach(function (dep) {
        selected.add(dep);
      });
    } else {
      selected.delete(id);
      // Drop auto-added deps nothing else needs? Leave them; harmless and
      // explicit deselection stays possible.
    }
    syncUI();
    updateHash();
    updateCommand();
  }

  function setSelection(ids) {
    selected = new Set();
    ids.forEach(function (id) {
      if (toolById(id)) selected.add(id);
    });
    // Resolve deps
    var changed = true;
    while (changed) {
      changed = false;
      selected.forEach(function (id) {
        var tool = toolById(id);
        (tool && tool.requires ? tool.requires : []).forEach(function (dep) {
          if (!selected.has(dep)) { selected.add(dep); changed = true; }
        });
      });
    }
    syncUI();
    updateHash();
    updateCommand();
  }

  function syncUI() {
    document.querySelectorAll(".tool-card").forEach(function (card) {
      var on = selected.has(card.dataset.id);
      card.classList.toggle("selected", on);
      card.querySelector("input").checked = on;
    });
    catalog.categories.forEach(function (cat) {
      var tools = catalog.tools.filter(function (t) { return t.category === cat.id; });
      var count = tools.filter(function (t) { return selected.has(t.id); }).length;
      var el = document.querySelector('[data-cat="' + cat.id + '"]');
      if (el) el.textContent = count ? count + " of " + tools.length : tools.length + " tools";
    });
    presetBtns.forEach(function (btn) { btn.classList.remove("active"); });
  }

  function updateHash() {
    var ids = Array.from(selected).sort();
    if (ids.length) {
      history.replaceState(null, "", "#" + ids.join(","));
    } else {
      history.replaceState(null, "", location.pathname);
    }
  }

  function restoreFromHash() {
    var hash = location.hash.replace(/^#/, "");
    if (!hash) return;
    setSelection(hash.split(","));
  }

  function updateCommand() {
    var count = selected.size;
    commandCountEl.textContent = count + (count === 1 ? " tool" : " tools");

    if (!count) {
      currentCommand = "";
      commandTextEl.textContent = "Pick at least one tool to get your command";
      commandTextEl.classList.remove("ready");
      copyBtn.disabled = true;
      return;
    }

    // Fallback command works immediately; the short link replaces it when
    // the API answers.
    var ids = Array.from(selected).sort();
    currentCommand =
      "curl -fsSL " + location.origin + "/install.sh | bash -s -- --with " + ids.join(",");
    showCommand();

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(function () {
      fetch("/api/select", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tools: ids }),
      })
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (data) {
          if (data && data.command && arraysEqual(ids, Array.from(selected).sort())) {
            currentCommand = data.command;
            showCommand();
          }
        })
        .catch(function () { /* fallback command already shown */ });
    }, 350);
  }

  function showCommand() {
    commandTextEl.textContent = currentCommand;
    commandTextEl.classList.add("ready");
    copyBtn.disabled = false;
  }

  function arraysEqual(a, b) {
    return a.length === b.length && a.every(function (v, i) { return v === b[i]; });
  }

  copyBtn.addEventListener("click", function () {
    if (!currentCommand) return;
    navigator.clipboard.writeText(currentCommand).then(function () {
      copyBtn.classList.add("copied");
      copyBtn.textContent = "Copied";
      commandTextEl.textContent = "Copied. Paste in your Terminal and press ENTER";
      setTimeout(function () {
        copyBtn.classList.remove("copied");
        copyBtn.textContent = "Copy";
        showCommand();
      }, 2200);
    });
  });

  presetBtns.forEach(function (btn) {
    btn.addEventListener("click", function () {
      var preset = btn.dataset.preset;
      if (preset === "clear") {
        setSelection([]);
        return;
      }
      if (preset === "everything") {
        setSelection(catalog.tools.map(function (t) { return t.id; }));
      } else if (catalog.presets && catalog.presets[preset]) {
        setSelection(catalog.presets[preset]);
      }
      btn.classList.add("active");
    });
  });
})();

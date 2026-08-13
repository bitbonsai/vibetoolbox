/* Vibe Toolbox picker: Alpine component. Catalog is inlined at build time as
   window.VTB_CATALOG (catalog.js). Selection lives in the URL hash; the short
   install command comes from POST /api/select with an instant curl fallback. */

(function () {
  "use strict";

  /* Tool icons: brand SVGs (public/img) where the product has one,
     Lucide strokes elsewhere. */
  function lucide(color, inner) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="' + color +
      '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      inner + "</svg>";
  }

  function brand(file, cls) {
    return '<img src="img/' + file + '" alt="" loading="lazy"' +
      (cls ? ' class="' + cls + '"' : "") + ">";
  }

  var ICONS = {
    "ghostty": brand("ghostty.svg"),
    "starship": brand("starship.svg"),
    "claude-code": brand("claude-color.svg"),
    "herdr": brand("herdr.svg"),
    "zed": brand("zed.svg"),
    "cursor": brand("cursor.svg"),
    "opencode": brand("opencode.svg"),
    "vscode": brand("vscode.svg"),
    "git": brand("git.svg"),
    "gh": brand("github.svg"),
    "node": brand("node.svg"),
    "bun": brand("bun.svg"),
    "nerd-font": lucide("#fb923c", '<polyline points="4 7 4 4 20 4 20 7"/><line x1="9" x2="15" y1="20" y2="20"/><line x1="12" x2="12" y1="4" y2="20"/>'),
    "codex": lucide("#f5f5f7", '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>'),
    "pi": lucide("#c084fc", '<line x1="9" x2="9" y1="4" y2="20"/><path d="M4 7c0-1.7 1.3-3 3-3h13"/><path d="M18 20c-1.7 0-3-1.3-3-3V4"/>'),
    "crush": lucide("#f472b6", '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>'),
    "orca": lucide("#0ea5e9", '<path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>'),
    "ccpeek": lucide("#86868b", '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>'),
    "caveman": lucide("#fb923c", '<path d="m15 12-8.373 8.373a1 1 0 1 1-3-3L12 9"/><path d="m18 15 4-4"/><path d="m21.5 11.5-1.914-1.914A2 2 0 0 1 19 8.172V7l-2.26-2.26a6 6 0 0 0-4.202-1.756L9 2.96l.92.82A6.18 6.18 0 0 1 12 8.4V10l2 2h1.172a2 2 0 0 1 1.414.586L18.5 14.5"/>'),
    "lazygit": lucide("#4ade80", '<circle cx="18" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><path d="M6 21V9a9 9 0 0 0 9 9"/>'),
    "git-delta": lucide("#c084fc", '<path d="M12 3v14"/><path d="M5 10h14"/><path d="M5 21h14"/>'),
    "eza": lucide("#4ade80", '<line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/>'),
    "bat": lucide("#a78bfa", '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>'),
    "zoxide": lucide("#fbcc17", '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>'),
    "tree": lucide("#4ade80", '<path d="M20 10a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1h-2.5a1 1 0 0 1-.8-.4l-.9-1.2A1 1 0 0 0 15 3h-2a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1Z"/><path d="M20 21a1 1 0 0 0 1-1v-3a1 1 0 0 0-1-1h-2.9a1 1 0 0 1-.88-.55l-.42-.85a1 1 0 0 0-.92-.6H13a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1Z"/><path d="M3 5a2 2 0 0 0 2 2h3"/><path d="M3 3v13a2 2 0 0 0 2 2h3"/>'),
    "fzf": lucide("#fbcc17", '<polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>'),
    "ripgrep": lucide("#0ea5e9", '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>'),
    "jq": lucide("#c084fc", '<path d="M8 3H7a2 2 0 0 0-2 2v5a2 2 0 0 1-2 2 2 2 0 0 1 2 2v5c0 1.1.9 2 2 2h1"/><path d="M16 21h1a2 2 0 0 0 2-2v-5c0-1.1.9-2 2-2a2 2 0 0 1-2-2V5a2 2 0 0 0-2-2h-1"/>'),
    "trash-cli": lucide("#86868b", '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/>'),
  };

  var FALLBACK_ICON = lucide("#86868b", '<polyline points="4 17 10 11 4 5"/><line x1="12" x2="20" y1="19" y2="19"/>');

  document.addEventListener("alpine:init", function () {
    Alpine.data("picker", function () {
      return {
        catalog: window.VTB_CATALOG || { categories: [], tools: [], presets: {} },
        selected: [],
        cartOpen: false,
        copied: false,
        command: "",
        activePreset: "",
        activeSection: "top",
        debounceTimer: null,

        init() {
          var hash = location.hash.replace(/^#/, "");
          if (hash) {
            this.setSelection(hash.split(","));
          } else {
            this.applyPreset("essentials");
          }
          // Track which section the viewport is on for the dot rail
          var self = this;
          this.$nextTick(function () {
            var observer = new IntersectionObserver(function (entries) {
              entries.forEach(function (entry) {
                if (entry.isIntersecting) self.activeSection = entry.target.id;
              });
            }, { rootMargin: "-30% 0px -60% 0px" });
            document.querySelectorAll("[data-section]").forEach(function (el) {
              observer.observe(el);
            });
          });
        },

        get sections() {
          return [{ id: "top", name: "Top" }]
            .concat(this.catalog.categories.map(function (c) {
              return { id: "cat-" + c.id, name: c.name };
            }))
            .concat([{ id: "how", name: "How it works" }]);
        },

        jump(id) {
          var el = document.getElementById(id);
          if (!el) return;
          // scrollIntoView, not an anchor hash - the hash carries the selection
          var reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
          el.scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "start" });
        },

        toolById(id) {
          return this.catalog.tools.find(function (t) { return t.id === id; }) || null;
        },

        toolsFor(catId) {
          return this.catalog.tools.filter(function (t) { return t.category === catId; });
        },

        countLabel(catId) {
          var tools = this.toolsFor(catId);
          var picked = tools.filter(function (t) { return this.isSelected(t.id); }, this).length;
          return picked ? picked + " of " + tools.length : tools.length + " tools";
        },

        iconFor(id) {
          return ICONS[id] || FALLBACK_ICON;
        },

        nameOf(id) {
          var tool = this.toolById(id);
          return tool ? tool.name : id;
        },

        get selectedSorted() {
          return this.selected.slice().sort();
        },

        isSelected(id) {
          return this.selected.includes(id);
        },

        toggle(tool, on) {
          this.activePreset = "";
          if (on) {
            var add = [tool.id].concat(tool.requires || []);
            add.forEach(function (id) {
              if (!this.selected.includes(id)) this.selected.push(id);
            }, this);
          } else {
            this.selected = this.selected.filter(function (id) { return id !== tool.id; });
          }
          this.afterChange();
        },

        remove(id) {
          this.activePreset = "";
          this.selected = this.selected.filter(function (x) { return x !== id; });
          this.afterChange();
        },

        setSelection(ids) {
          var valid = ids.filter(function (id) { return this.toolById(id); }, this);
          // Expand dependencies until stable
          var changed = true;
          while (changed) {
            changed = false;
            valid.forEach(function (id) {
              var tool = this.toolById(id);
              (tool.requires || []).forEach(function (dep) {
                if (valid.indexOf(dep) === -1) { valid.push(dep); changed = true; }
              });
            }, this);
          }
          this.selected = valid;
          this.afterChange();
        },

        applyPreset(name) {
          if (name === "clear") {
            this.activePreset = "";
            this.setSelection([]);
            return;
          }
          this.activePreset = name;
          if (name === "everything") {
            this.setSelection(this.catalog.tools.map(function (t) { return t.id; }));
          } else if (this.catalog.presets && this.catalog.presets[name]) {
            this.setSelection(this.catalog.presets[name].slice());
          }
        },

        afterChange() {
          this.updateHash();
          this.updateCommand();
        },

        updateHash() {
          var ids = this.selectedSorted;
          if (ids.length) {
            history.replaceState(null, "", "#" + ids.join(","));
          } else {
            history.replaceState(null, "", location.pathname);
          }
        },

        updateCommand() {
          if (!this.selected.length) {
            this.command = "";
            return;
          }
          // Fallback command works immediately; the short link replaces it
          // when the API answers.
          var ids = this.selectedSorted;
          var self = this;
          this.command =
            "curl -fsSL " + location.origin + "/install.sh | bash -s -- --with " + ids.join(",");

          clearTimeout(this.debounceTimer);
          this.debounceTimer = setTimeout(function () {
            fetch("/api/select", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ tools: ids }),
            })
              .then(function (r) { return r.ok ? r.json() : null; })
              .then(function (data) {
                if (data && data.command && ids.join(",") === self.selectedSorted.join(",")) {
                  self.command = data.command;
                }
              })
              .catch(function () { /* fallback command already shown */ });
          }, 350);
        },

        copy() {
          if (!this.command) return;
          var self = this;
          navigator.clipboard.writeText(this.command).then(function () {
            self.copied = true;
            setTimeout(function () { self.copied = false; }, 2200);
          });
        },
      };
    });
  });
})();

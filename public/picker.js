/* Vibe Toolbox picker: Alpine component. Catalog is inlined at build time as
   window.VTB_CATALOG (catalog.js). Selection lives in the URL hash; the short
   install command comes from POST /api/select with an instant curl fallback. */

(function () {
  "use strict";

  /* Tool icons: brand SVGs (public/img) where the product has one,
     Lucide strokes elsewhere. */
  var ICON_COLORS = {
    "#f5f5f7": "var(--icon-foreground)",
    "#86868b": "var(--icon-neutral)",
    "#fb923c": "var(--icon-orange)",
    "#c084fc": "var(--icon-purple)",
    "#f472b6": "var(--icon-pink)",
    "#0ea5e9": "var(--icon-blue)",
    "#fbcc17": "var(--icon-yellow)",
    "#4ade80": "var(--icon-green)",
    "#a78bfa": "var(--icon-purple)",
  };

  function lucide(color, inner) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="' + (ICON_COLORS[color] || color) +
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
    "herdr": brand("herdr.svg?v=2"),
    "zed": brand("zed.svg"),
    "cursor": brand("cursor.svg", "theme-invert"),
    "opencode": brand("opencode.svg", "theme-invert"),
    "vscode": brand("vscode.svg"),
    "git": brand("git.svg"),
    "gh": brand("github.svg", "theme-invert"),
    "node": brand("node.svg"),
    "bun": brand("bun.svg", "theme-invert"),
    "nerd-font": lucide("#fb923c", '<polyline points="4 7 4 4 20 4 20 7"/><line x1="9" x2="15" y1="20" y2="20"/><line x1="12" x2="12" y1="4" y2="20"/>'),
    "codex": lucide("#f5f5f7", '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>'),
    "pi": lucide("#c084fc", '<line x1="9" x2="9" y1="4" y2="20"/><path d="M4 7c0-1.7 1.3-3 3-3h13"/><path d="M18 20c-1.7 0-3-1.3-3-3V4"/>'),
    "crush": lucide("#f472b6", '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>'),
    "orca": lucide("#0ea5e9", '<path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>'),
    "ccpeek": lucide("#86868b", '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>'),
    "agent-browser": lucide("#a78bfa", '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>'),
    "mkcert": lucide("#fbcc17", '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>'),
    "shottr": lucide("#0ea5e9", '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/>'),
    "handy": brand("handy.png"),
    "caveman": lucide("#fb923c", '<path d="m15 12-8.373 8.373a1 1 0 1 1-3-3L12 9"/><path d="m18 15 4-4"/><path d="m21.5 11.5-1.914-1.914A2 2 0 0 1 19 8.172V7l-2.26-2.26a6 6 0 0 0-4.202-1.756L9 2.96l.92.82A6.18 6.18 0 0 1 12 8.4V10l2 2h1.172a2 2 0 0 1 1.414.586L18.5 14.5"/>'),
    "lazygit": lucide("#4ade80", '<circle cx="18" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><path d="M6 21V9a9 9 0 0 0 9 9"/>'),
    "git-delta": lucide("#c084fc", '<path d="M12 3v14"/><path d="M5 10h14"/><path d="M5 21h14"/>'),
    "eza": lucide("#4ade80", '<line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/>'),
    "bat": lucide("#a78bfa", '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>'),
    "zoxide": lucide("#fbcc17", '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>'),
    "fzf": lucide("#fbcc17", '<polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>'),
    "ripgrep": lucide("#0ea5e9", '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>'),
    "fd": lucide("#fb923c", '<path d="M10.7 20H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.69.9l.81 1.2a2 2 0 0 0 1.67.9H20a2 2 0 0 1 2 2v4.1"/><circle cx="17" cy="17" r="3"/><path d="m21 21-1.5-1.5"/>'),
    "btop": lucide("#4ade80", '<path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2"/>'),
    "jq": lucide("#c084fc", '<path d="M8 3H7a2 2 0 0 0-2 2v5a2 2 0 0 1-2 2 2 2 0 0 1 2 2v5c0 1.1.9 2 2 2h1"/><path d="M16 21h1a2 2 0 0 0 2-2v-5c0-1.1.9-2 2-2a2 2 0 0 1-2-2V5a2 2 0 0 0-2-2h-1"/>'),
    "trash-cli": lucide("#86868b", '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/>'),
  };

  var FALLBACK_ICON = lucide("#86868b", '<polyline points="4 17 10 11 4 5"/><line x1="12" x2="20" y1="19" y2="19"/>');

  /* Shell syntax highlighting (same tokenizer as scripts/build.ts) */
  function escHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function hlLine(line) {
    var comment = "";
    var ci = line.indexOf("#");
    if (ci === 0 || (ci > 0 && line[ci - 1] === " ")) {
      comment = line.slice(ci);
      line = line.slice(0, ci);
    }
    var expectCmd = true;
    var out = line.split(/(\s+)/).map(function (tok) {
      if (!tok.trim()) return escHtml(tok);
      var e = escHtml(tok);
      if (tok === "|" || tok === "&&" || tok === ";") { expectCmd = true; return '<span class="tok-pipe">' + e + "</span>"; }
      if (/^https?:\/\//.test(tok)) { expectCmd = false; return '<span class="tok-url">' + e + "</span>"; }
      if (/^-/.test(tok)) { expectCmd = false; return '<span class="tok-flag">' + e + "</span>"; }
      if (expectCmd) { expectCmd = false; return '<span class="tok-cmd">' + e + "</span>"; }
      return e;
    });
    if (comment) out.push('<span class="tok-comment">' + escHtml(comment) + "</span>");
    return out.join("");
  }

  function highlightShell(text) {
    return String(text == null ? "" : text).split("\n").map(hlLine).join("\n");
  }

  document.addEventListener("alpine:init", function () {
    // Read-only catalog for tools.html
    Alpine.data("toolsPage", function () {
      return {
        catalog: window.VTB_CATALOG || { categories: [], tools: [] },
        detail: null,
        query: "",
        init() {
          var id = new URLSearchParams(window.location.search).get("tool");
          if (id) this.detail = this.catalog.tools.find(function (tool) { return tool.id === id; }) || null;
        },
        searchTerm() {
          return this.query.trim().toLowerCase();
        },
        isFiltering() {
          return this.searchTerm().length >= 2;
        },
        matches(tool) {
          if (!this.isFiltering()) return true;
          var category = this.catalog.categories.find(function (cat) { return cat.id === tool.category; });
          return [tool.name, tool.id, tool.desc, category && category.name]
            .filter(Boolean).join(" ").toLowerCase().includes(this.searchTerm());
        },
        toolsFor(catId) {
          var self = this;
          return this.catalog.tools.filter(function (tool) {
            return tool.category === catId && self.matches(tool);
          });
        },
        resultCount() {
          var self = this;
          return this.catalog.tools.filter(function (tool) { return self.matches(tool); }).length;
        },
        searchStatus() {
          var length = this.searchTerm().length;
          if (!length) return this.catalog.tools.length + " tools";
          if (length < 2) return "Type one more character to search";
          var count = this.resultCount();
          return count + (count === 1 ? " tool found" : " tools found");
        },
        openDetail(tool) {
          this.detail = tool;
          var url = new URL(window.location.href);
          url.searchParams.set("tool", tool.id);
          history.replaceState(null, "", url.pathname + url.search + url.hash);
        },
        closeDetail() {
          this.detail = null;
          var url = new URL(window.location.href);
          url.searchParams.delete("tool");
          history.replaceState(null, "", url.pathname + url.search + url.hash);
        },
        iconFor(id) {
          return ICONS[id] || FALLBACK_ICON;
        },
        hl(text) {
          return highlightShell(text);
        },
      };
    });

    // next-steps.html: the installer appends the installed ids as a hash
    // (#bat,bun,...) so the page shows only relevant blocks. No hash (a
    // direct visit) shows everything.
    Alpine.data("nextSteps", function () {
      return {
        installed: [],

        init() {
          var hash = location.hash.replace(/^#/, "");
          if (hash) this.installed = hash.split(",").filter(Boolean);
        },

        // True when any of the listed tools was installed; no hash = true
        has() {
          if (!this.installed.length) return true;
          for (var i = 0; i < arguments.length; i++) {
            if (this.installed.indexOf(arguments[i]) !== -1) return true;
          }
          return false;
        },

        tryLines() {
          var lines = [];
          if (this.has("eza")) lines.push("ls        # pretty file listing with icons (eza)");
          if (this.has("zoxide")) lines.push("z dev     # jump to ~/dev from anywhere (zoxide)");
          if (this.has("eza")) lines.push("lt        # tree view of the current folder");
          if (this.has("eza")) lines.push("eza --code # summarize lines of code by language");
          return highlightShell(lines.join("\n"));
        },

        agentCmds() {
          var cmds = [];
          if (this.has("claude-code")) cmds.push("c");
          if (this.has("opencode")) cmds.push("opencode");
          if (this.has("codex")) cmds.push("codex");
          if (this.has("pi")) cmds.push("pi");
          if (this.has("crush")) cmds.push("crush");
          return cmds;
        },

        firstThing() {
          var cmds = this.agentCmds();
          if (!cmds.length) return "";
          var main = cmds.shift();
          var line = cmds.length
            ? (main + "          ").slice(0, Math.max(main.length + 2, 10)) + "# or " + cmds.join(", ")
            : main;
          return highlightShell("cd ~/dev\nmkdir my-first-site && cd my-first-site\n" + line);
        },

        routerSentence() {
          var names = [];
          if (this.has("pi")) names.push("Pi");
          if (this.has("crush")) names.push("Crush");
          if (this.has("opencode")) names.push("OpenCode");
          if (!names.length) return "";
          if (names.length === 1) return names[0] + " accepts it, and you can switch models freely.";
          var last = names.pop();
          var word = names.length === 1 ? "both" : "all";
          return names.join(", ") + " and " + last + " " + word + " accept it, and you can switch models freely.";
        },
      };
    });

    Alpine.data("picker", function () {
      return {
        catalog: window.VTB_CATALOG || { categories: [], tools: [], presets: {} },
        selected: [],
        cartOpen: false,
        mobilePagesOpen: false,
        mobilePagesTimer: null,
        copied: false,
        command: "",
        activePreset: "",
        activeSection: "top",
        debounceTimer: null,
        tip: null,
        guideOpen: false,
        guideDontShow: false,
        cartBump: false,
        bumpTimer: null,

        init() {
          var hash = location.hash.replace(/^#/, "");
          if (hash) {
            this.setSelection(hash.split(","));
            this.detectPreset();
          } else {
            this.applyPreset("essentials");
          }
          // Bump the toolbox icon whenever the selection changes so users
          // notice where their command lives
          var self = this;
          this.$watch("selected", function () {
            self.cartBump = false;
            clearTimeout(self.bumpTimer);
            requestAnimationFrame(function () {
              self.cartBump = true;
              self.bumpTimer = setTimeout(function () { self.cartBump = false; }, 600);
            });
          });
          // Track which section the viewport is on for the dot rail
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

        toggleMobilePages() {
          if (this.mobilePagesOpen) {
            this.closeMobilePages();
            return;
          }
          this.cartOpen = false;
          this.mobilePagesOpen = true;
          clearTimeout(this.mobilePagesTimer);
          var self = this;
          this.mobilePagesTimer = setTimeout(function () { self.mobilePagesOpen = false; }, 5000);
        },

        closeMobilePages() {
          this.mobilePagesOpen = false;
          clearTimeout(this.mobilePagesTimer);
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

        hl(text) {
          return highlightShell(text);
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

        expandIds(ids) {
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
          return valid;
        },

        setSelection(ids) {
          this.selected = this.expandIds(ids);
          this.afterChange();
        },

        detectPreset() {
          var current = this.selectedSorted.join(",");
          if (!current) return;
          if (current === this.catalog.tools.map(function (t) { return t.id; }).sort().join(",")) {
            this.activePreset = "everything";
            return;
          }
          var presets = this.catalog.presets || {};
          for (var name in presets) {
            if (current === this.expandIds(presets[name].slice()).sort().join(",")) {
              this.activePreset = name;
              return;
            }
          }
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
          // Default Essentials selection keeps a clean URL: an empty hash
          // applies the same preset on load, so the state round-trips
          if (ids.length && ids.join(",") !== this.essentialsIds()) {
            history.replaceState(null, "", "#" + ids.join(","));
          } else {
            history.replaceState(null, "", location.pathname);
          }
        },

        essentialsIds() {
          var preset = (this.catalog.presets && this.catalog.presets.essentials) || [];
          return this.expandIds(preset.slice()).sort().join(",");
        },

        updateCommand() {
          clearTimeout(this.debounceTimer);
          if (!this.selected.length) {
            this.command = "";
            return;
          }
          // Short link only; the long --with command is a last resort when
          // the API is unreachable.
          var ids = this.selectedSorted;
          var self = this;
          this.command = "";
          this.debounceTimer = setTimeout(function () {
            fetch("/api/select", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ tools: ids }),
            })
              .then(function (r) { return r.ok ? r.json() : null; })
              .then(function (data) {
                if (ids.join(",") !== self.selectedSorted.join(",")) return;
                self.command = (data && data.command) ||
                  "curl -fsSL " + location.origin + "/install.sh | bash -s -- --with " + ids.join(",");
              })
              .catch(function () {
                if (ids.join(",") !== self.selectedSorted.join(",")) return;
                self.command =
                  "curl -fsSL " + location.origin + "/install.sh | bash -s -- --with " + ids.join(",");
              });
          }, 250);
        },

        copy() {
          if (!this.command) return;
          var self = this;
          navigator.clipboard.writeText(this.command).then(function () {
            self.copied = true;
            setTimeout(function () { self.copied = false; }, 4000);
            var dismissed = false;
            try { dismissed = !!localStorage.getItem("vtb-guide-dismissed"); } catch (_) {}
            if (!dismissed) {
              self.guideOpen = true;
              self.$nextTick(function () { self.$refs.guideOk.focus(); });
            }
          });
        },

        closeGuide() {
          if (this.guideDontShow) {
            try { localStorage.setItem("vtb-guide-dismissed", "1"); } catch (_) {}
          }
          this.guideOpen = false;
        },

        showTip(id, e) {
          var tool = this.toolById(id);
          if (!tool) return;
          var rect = e.currentTarget.getBoundingClientRect();
          // Anchor below the chip, centered, clamped to the viewport so
          // right-edge chips don't push the tooltip offscreen.
          var half = 128; // tooltip max-width 16rem / 2
          var x = Math.min(Math.max(rect.left + rect.width / 2, half + 8), window.innerWidth - half - 8);
          this.tip = { text: tool.desc, x: x, y: rect.bottom + 8 };
        },

        hideTip() {
          this.tip = null;
        },
      };
    });
  });
})();

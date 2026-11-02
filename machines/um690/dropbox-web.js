// Changes to dufs's page for https://dropbox.pelenitsyn.site/ (dropbox-web.nix),
// loaded after dufs's own index.js:
//  - sizes in whole units, "2 MB" and not "2.9 MB" (Artem: "I only need the
//    integer part");
//  - links stay in this tab: dufs opens files, View and Edit in new ones;
//  - each row's action buttons (download, view or edit, move, delete) in a menu
//    of their own behind "⋯", so the names get the row's width. The buttons
//    are moved, not copied, so dufs's handlers still find them. Whether the
//    menu shows is up to dropbox-web.css: on a wide screen its wrapper lays out
//    as if it were not there, and the buttons sit in the row as before.
(() => {
  // dufs's formatFileSize is a global, which addPath looks up on every call,
  // and rows are drawn only once the page has loaded, after this script. Called
  // with a unit, it is an upload's progress against the file's total ("1.4 /
  // 2.9 MB"), which keeps its decimal.
  const formatFileSize = window.formatFileSize;
  if (typeof formatFileSize === "function") {
    window.formatFileSize = (size, unit) => {
      const [value, sizeUnit] = formatFileSize(size, unit);
      return unit ? [value, sizeUnit] : [Math.trunc(Number(value)), sizeUnit];
    };
  }

  const body = document.querySelector(".paths-table tbody");
  if (!body) return;

  // dufs's tooltips, shortened for a menu.
  const labels = {
    "Download file": "Download",
    "Download folder as a .zip file": "Download as .zip",
    "View file": "View",
    "Edit file": "Edit",
    "Move & Rename": "Move or rename",
    "Delete": "Delete",
  };

  function closeAll() {
    for (const td of document.querySelectorAll(".cell-actions.menu-open")) {
      td.classList.remove("menu-open", "menu-up");
      td.querySelector(".row-menu-btn")?.setAttribute("aria-expanded", "false");
    }
  }

  function enhance(td) {
    if (td.querySelector(".row-menu")) return;
    const items = [...td.children];
    if (items.length === 0) return;

    const menu = document.createElement("div");
    menu.className = "row-menu";
    menu.setAttribute("role", "menu");
    for (const item of items) {
      // The download button is a link inside a div, with the tooltip on the
      // link: the label goes where the tap does.
      const target = item.matches("a") ? item : item.querySelector("a") || item;
      const title = target.getAttribute("title") || item.getAttribute("title") || "";
      const label = document.createElement("span");
      label.className = "row-menu-label";
      label.textContent = labels[title] || title;
      target.append(label);
      target.setAttribute("role", "menuitem");
      menu.append(item);
    }

    const button = document.createElement("button");
    button.type = "button";
    button.className = "row-menu-btn";
    button.textContent = "⋯";
    button.setAttribute("aria-label", "Actions");
    button.setAttribute("aria-haspopup", "menu");
    button.setAttribute("aria-expanded", "false");
    button.addEventListener("click", (event) => {
      event.stopPropagation();
      const opening = !td.classList.contains("menu-open");
      closeAll();
      if (!opening) return;
      td.classList.add("menu-open");
      button.setAttribute("aria-expanded", "true");
      // Open upwards when there is no room below.
      if (menu.getBoundingClientRect().bottom > window.innerHeight - 8) {
        td.classList.add("menu-up");
      }
    });

    td.append(button, menu);
  }

  const enhanceAll = () => {
    for (const link of body.querySelectorAll('a[target="_blank"]')) link.removeAttribute("target");
    body.querySelectorAll("td.cell-actions").forEach(enhance);
  };
  // dufs draws the rows after the page loads, and again for a search.
  new MutationObserver(enhanceAll).observe(body, { childList: true });
  enhanceAll();

  // A tap anywhere else, or Escape, closes the menu. A tap on an item runs
  // its own handler first, then this closes the menu behind it.
  document.addEventListener("click", closeAll);
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeAll();
  });
})();

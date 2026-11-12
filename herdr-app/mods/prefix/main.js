// A tmux-style prefix, as the old Herdr config had (alt+q then a key).
// mod.open:prefix shows this panel, takes the keyboard, and runs the command
// for the next key, then closes. Esc (or alt+q again) cancels.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, theme, layout } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const FISH = "/home/linuxbrew/.linuxbrew/bin/fish";
const openTool = (name) =>
  run("pane.split", { direction: "right", argv: [FISH, "-c", name] });

// [keys, label, action]
const ROWS = [
  ["S", "settings", () => run("app.settings")],
  ["n", "new tab", () => run("tab.new")],
  ["L", "next tab", () => run("tab.next")],
  ["H", "previous tab", () => run("tab.prev")],
  ["h", "focus pane left", () => run("pane.go", { direction: "left" })],
  ["j", "focus pane down", () => run("pane.go", { direction: "down" })],
  ["k", "focus pane up", () => run("pane.go", { direction: "up" })],
  ["l", "focus pane right", () => run("pane.go", { direction: "right" })],
  ["v", "split right", () => run("pane.split", { direction: "right" })],
  ["s", "split down", () => run("pane.split", { direction: "down" })],
  ["r", "rename tab", () => run("tab.rename")],
  ["c", "close pane", () => run("pane.close")],
  ["C", "close tab", () => run("tab.close")],
  ["f", "zoom pane", () => run("pane.zoom")],
  ["x", "close space", () => run("space.close")],
  ["K", "previous space", () => run("space.prev")],
  ["J", "next space", () => run("space.next")],
  ["1…9", "go to space", null],
  ["b", "toggle sidebar", () => run("layout.toggle", { id: "sidebar" })],
  ["e", "yazi", () => openTool("yazi")],
  ["/", "btop", () => openTool("btop")],
  ["g", "lazygit", () => openTool("lazygit")],
];

const SHIFTED_DIGITS = {
  "!": 1,
  "@": 2,
  "#": 3,
  $: 4,
  "%": 5,
  "^": 6,
  "&": 7,
  "*": 8,
  "(": 9,
};

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(80, () => this.handle.focus());
  }

  close() {
    closeOverlay(props().overlay);
  }

  press(e, cx) {
    const key = (e.key ?? "").toLowerCase();
    const shift = !!e.modifiers?.shift;

    if (key === "escape") {
      this.close();
      cx.stop_propagation();
      return;
    }

    if (e.modifiers?.control || e.modifiers?.platform || e.modifiers?.alt) {
      this.close();
      cx.stop_propagation();
      return;
    }

    const digit = /^[1-9]$/.test(key) ? Number(key) : SHIFTED_DIGITS[key];
    let act = null;

    if (digit) act = () => run("space.select", { index: digit });
    else if (key === "/" || key === "?") act = () => openTool("btop");
    else if (shift) {
      act =
        {
          s: () => run("app.settings"),
          l: () => run("tab.next"),
          h: () => run("tab.prev"),
          c: () => run("tab.close"),
          k: () => run("space.prev"),
          j: () => run("space.next"),
        }[key] ?? null;
    } else {
      act =
        {
          n: () => run("tab.new"),
          h: () => run("pane.go", { direction: "left" }),
          j: () => run("pane.go", { direction: "down" }),
          k: () => run("pane.go", { direction: "up" }),
          l: () => run("pane.go", { direction: "right" }),
          s: () => run("pane.split", { direction: "right" }),
          v: () => run("pane.split", { direction: "down" }),
          r: () => run("tab.rename"),
          c: () => run("pane.close"),
          f: () => run("pane.zoom"),
          x: () => run("space.close"),
          b: () => {
            if (find(layout(), "sidebar"))
              run("layout.toggle", { id: "sidebar" });
          },
          e: () => openTool("yazi"),
          g: () => openTool("lazygit"),
        }[key] ?? null;
    }

    this.close();
    cx.stop_propagation();
    if (act) act();
  }

  render(cx) {
    const t = theme();
    const chip = (keys) =>
      div()
        .px(6)
        .py(2)
        .rounded(5)
        .bg(t.raised)
        .text_color(t.foreground)
        .text_size(11)
        .child(keys);

    const row = ([keys, label]) =>
      h_flex()
        .h(24)
        .gap(9)
        .items_center()
        .child(chip(keys))
        .child(div().text_color(t.muted).child(label));

    const half = Math.ceil(ROWS.length / 2);
    const columns = [ROWS.slice(0, half), ROWS.slice(half)];

    return v_flex()
      .id("prefix")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.press(e, cx))
      .size_full()
      .min_h(0)
      .p(14)
      .gap(10)
      .rounded(8)
      .bg(t.popover)
      .text_size(12.5)
      .child(
        h_flex()
          .items_center()
          .justify_between()
          .child(
            div()
              .text_size(14)
              .font_semibold()
              .text_color(t.foreground)
              .child("Prefix"),
          )
          .child(div().text_size(11).text_color(t.dim).child("Esc")),
      )
      .child(
        h_flex()
          .flex_1()
          .min_h(0)
          .gap(24)
          .children(
            columns.map((rows) =>
              v_flex().flex_1().gap(2).children(rows.map(row)),
            ),
          ),
      );
  }
}

import { motion } from "framer-motion";
import {
  Sparkles,
  Layers,
  Command,
  Keyboard,
  MonitorSmartphone,
  Cpu,
  Lock,
  Wand2,
  Package,
} from "lucide-react";

const cards = [
  {
    span: "md:col-span-2 md:row-span-2",
    icon: <Package size={20} />,
    title: "Per-profile Dock identities",
    body: "Each Chrome/Edge/Brave profile gets its own generated .app wrapper with a unique bundle ID. Result: independent Dock icon, independent Cmd+Tab entry, independent window group — exactly like Windows.",
    highlight: true,
  },
  {
    icon: <Layers size={20} />,
    title: "Workspaces",
    body: "Bundle a browser profile + VS Code + Terminal + Docker + shell commands into one launch button.",
  },
  {
    icon: <Wand2 size={20} />,
    title: "AI Workspace",
    body: "Type “laravel” or “next.js dashboard” — Claude drafts a plan you can review and edit before saving.",
  },
  {
    icon: <Keyboard size={20} />,
    title: "Global hotkeys",
    body: "⌥⌘1 · ⌥⌘2 · ⌥⌘L. Registered via Carbon EventHotKey so they actually swallow the key.",
  },
  {
    icon: <MonitorSmartphone size={20} />,
    title: "Window layout memory",
    body: "Snapshot open windows across all displays and restore them later. Opt-in Accessibility permission.",
  },
  {
    icon: <Command size={20} />,
    title: "Menu-bar first",
    body: "A native SwiftUI MenuBarExtra popover. Everything is 1–2 keystrokes away — no dock icon required if you want.",
  },
  {
    icon: <Cpu size={20} />,
    title: "Fast & tiny",
    body: "<100 ms cold start · <50 MB idle RAM · ~5 MB binary. Pure Swift, no Electron, no Node.",
  },
  {
    icon: <Lock size={20} />,
    title: "Offline & private",
    body: "Zero telemetry. Reads Chrome's Local State but never touches history, cookies or passwords.",
  },
  {
    icon: <Sparkles size={20} />,
    title: "Auto-detect everything",
    body: "Chrome, Chrome Canary, Edge, Brave, Chromium, Arc, Firefox on first launch. Nothing to configure.",
  },
];

export default function FeatureBento() {
  return (
    <section id="features" className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-2xl mb-14">
          <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
            Features
          </div>
          <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
            Small app. Nine focused ideas. All of them respect macOS.
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 auto-rows-[minmax(180px,auto)] gap-4">
          {cards.map((c, i) => (
            <motion.div
              key={c.title}
              initial={{ opacity: 0, y: 12 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.45, delay: i * 0.03 }}
              className={`relative rounded-2xl border border-white/10 p-6 flex flex-col justify-between overflow-hidden hover:-translate-y-1 transition-transform duration-300 ${
                c.highlight
                  ? "bg-gradient-to-br from-white/[0.08] to-white/[0.02]"
                  : "bg-white/[0.02]"
              } ${c.span ?? ""}`}
            >
              {c.highlight && (
                <div className="absolute -top-24 -right-24 w-56 h-56 rounded-full bg-white/10 blur-3xl pointer-events-none" />
              )}
              <div className="text-white/70">{c.icon}</div>
              <div className="relative">
                <h3 className="mt-6 text-lg font-medium text-white tracking-tight">{c.title}</h3>
                <p className="mt-2 text-sm text-white/60 leading-relaxed">{c.body}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}

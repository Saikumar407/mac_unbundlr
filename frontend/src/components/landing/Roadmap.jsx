const milestones = [
  {
    tag: "0.1 · now",
    title: "Profile Pilot",
    items: [
      "Chrome / Edge / Brave / Chromium detection",
      "Per-profile .app wrappers",
      "Workspaces + shell / URL / app items",
      "Menu-bar mode + global hotkeys",
      "AI Workspace via companion API",
    ],
  },
  {
    tag: "0.2 · next",
    title: "Workspace Pro",
    items: [
      "Window Layout Memory (Accessibility API)",
      "Session Restore on reboot",
      "Import / export workspaces as JSON",
      "iTerm2 / Warp / Ghostty targeting",
    ],
  },
  {
    tag: "0.3",
    title: "Polish & signing",
    items: [
      "Custom wrapper icon designer",
      "Sparkle auto-updater",
      "Command palette (⌘K)",
      "Notarised nightlies",
    ],
  },
  {
    tag: "0.4",
    title: "Beyond Chromium",
    items: ["Arc profiles", "Firefox profiles", "Safari macOS 14+ Profiles"],
  },
  {
    tag: "0.5",
    title: "Team & sync",
    items: ["iCloud sync (CloudKit)", "profilepilot:// share URLs", "Git-based team templates"],
  },
  {
    tag: "1.0",
    title: "GA",
    items: ["App Store subset (sandboxed)", "Localisation", "Full a11y audit"],
  },
];

export default function Roadmap() {
  return (
    <section id="roadmap" className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-2xl mb-14">
          <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
            Roadmap
          </div>
          <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
            Small releases. Real shipping.
          </h2>
        </div>

        <div className="relative pl-6 md:pl-8">
          <div className="absolute left-1.5 md:left-2.5 top-1 bottom-1 w-px bg-white/10" />
          <div className="space-y-10">
            {milestones.map((m) => (
              <div key={m.tag} className="relative">
                <div className="absolute -left-[19px] md:-left-[23px] top-1.5 w-3 h-3 rounded-full bg-white/70 ring-4 ring-black" />
                <div className="mono text-[11px] uppercase tracking-widest text-white/50 mb-1">
                  {m.tag}
                </div>
                <div className="text-xl font-medium text-white tracking-tight">{m.title}</div>
                <ul className="mt-3 space-y-1 text-sm text-white/60">
                  {m.items.map((i) => (
                    <li key={i}>· {i}</li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

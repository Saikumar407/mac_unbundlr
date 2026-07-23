import { useState } from "react";
import { LANDING } from "@/constants/testIds";
import { ChevronDown } from "lucide-react";

const qas = [
  {
    q: "Is this just Unbundle with more steps?",
    a: "Unbundle is a great tool that popularised the wrapper trick. ProfilePilot extends the idea into a full workspace launcher — browser profiles are only one item type in a workspace, and everything (menu bar, hotkeys, AI, layouts) is built around that.",
  },
  {
    q: "Do I need to reinstall my Chrome profiles?",
    a: "No. ProfilePilot never touches your Chrome data. Profiles are detected read-only from `~/Library/Application Support/Google/Chrome/Local State`.",
  },
  {
    q: "Will Chrome updates break the wrappers?",
    a: "No. Wrappers only call `open -na 'Google Chrome' --args --profile-directory=…` — Chrome updates itself in place and the wrappers keep working.",
  },
  {
    q: "Why doesn't macOS just do this natively?",
    a: "macOS keys Dock identity, Cmd+Tab identity and window grouping on the launching bundle's `CFBundleIdentifier`. When you launch Chrome yourself, there is only one bundle. Our wrappers give macOS what it needs to treat each profile independently.",
  },
  {
    q: "Does the AI Workspace feature send my browser data anywhere?",
    a: "No. It sends only the free-text prompt you type (e.g. `laravel`) to whichever endpoint you configure in Settings — never any profile names, URLs, cookies or history.",
  },
  {
    q: "Is it free / open-source?",
    a: "Yes, MIT-licensed. A future 1.0 may offer an optional paid Pro tier for iCloud sync and team templates, but the core will always be free.",
  },
  {
    q: "Windows and Linux?",
    a: "Not planned. On Windows the underlying problem doesn't exist, and on Linux distributions already handle multi-app workspaces well.",
  },
];

export default function Faq() {
  const [open, setOpen] = useState(0);
  return (
    <section id="faq" className="relative py-24 border-t border-white/5">
      <div className="max-w-3xl mx-auto px-6">
        <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">FAQ</div>
        <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white mb-10">
          Questions we keep getting.
        </h2>
        <div className="divide-y divide-white/10 border-y border-white/10">
          {qas.map((qa, i) => {
            const isOpen = open === i;
            return (
              <div key={qa.q} className="py-2" data-testid={LANDING.faqItem}>
                <button
                  onClick={() => setOpen(isOpen ? -1 : i)}
                  className="w-full flex items-center justify-between text-left py-3 group"
                >
                  <span className="text-white group-hover:text-white/90 transition-colors duration-200">
                    {qa.q}
                  </span>
                  <ChevronDown
                    size={16}
                    className={`text-white/40 transition-transform duration-200 ${
                      isOpen ? "rotate-180" : ""
                    }`}
                  />
                </button>
                {isOpen && (
                  <div className="pb-4 text-sm text-white/60 leading-relaxed">{qa.a}</div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

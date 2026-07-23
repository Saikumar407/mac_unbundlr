import { useState } from "react";
import { Download, Github, Copy, Check, Package } from "lucide-react";
import { LANDING } from "@/constants/testIds";

const cmd = `# 1. Clone
git clone https://github.com/yourname/ProfilePilot.git
cd ProfilePilot

# 2. Build (Swift Package Manager)
swift build -c release

# 3. Launch
open .build/release/ProfilePilot`;

export default function Downloads() {
  const [copied, setCopied] = useState(false);

  function copy() {
    try {
      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(cmd).catch(() => fallbackCopy(cmd));
      } else {
        fallbackCopy(cmd);
      }
    } catch {
      fallbackCopy(cmd);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }

  function fallbackCopy(text) {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand("copy"); } catch { /* noop */ }
    document.body.removeChild(ta);
  }

  return (
    <section id="download" className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-2xl mb-14">
          <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
            Get it
          </div>
          <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
            Two ways to run ProfilePilot today.
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="relative rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.06] to-white/[0.01] p-8 overflow-hidden">
            <div className="absolute -top-16 -right-16 w-56 h-56 rounded-full bg-white/5 blur-3xl" />
            <div className="relative">
              <div className="mono text-[11px] uppercase tracking-widest text-white/40 mb-3">
                macOS 14 · Universal
              </div>
              <div className="text-2xl font-medium text-white tracking-tight">ProfilePilot.dmg</div>
              <div className="mt-1 text-sm text-white/50 mono">v0.1.0-preview · 5.4 MB</div>
              <p className="mt-4 text-sm text-white/60 leading-relaxed">
                Notarised, hardened-runtime, universal binary. Drop into <span className="mono">/Applications</span>,
                first launch scans your browsers.
              </p>
              <a
                href="#"
                className="mt-6 inline-flex items-center gap-2 bg-white text-black text-sm font-medium px-5 py-2.5 rounded-full hover:bg-white/90 transition-colors duration-200"
              >
                <Download size={15} /> Download .dmg
              </a>
              <div className="mt-3 text-[11px] mono text-white/40">
                Coming soon — currently source-build only.
              </div>
            </div>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-8">
            <div className="mono text-[11px] uppercase tracking-widest text-white/40 mb-3">
              Build from source
            </div>
            <div className="text-2xl font-medium text-white tracking-tight">
              Swift Package Manager
            </div>
            <p className="mt-2 text-sm text-white/60 leading-relaxed">
              Ship-ready code lives in <span className="mono">/ProfilePilot</span> of this repo. Requires Xcode 15+.
            </p>
            <div className="mt-5 rounded-xl bg-black/40 border border-white/10 p-4 relative">
              <pre className="text-[12px] mono text-white/80 whitespace-pre overflow-x-auto">
                {cmd}
              </pre>
              <button
                data-testid={LANDING.buildScriptCopy}
                onClick={copy}
                className="absolute top-3 right-3 inline-flex items-center gap-1.5 text-[11px] text-white/60 hover:text-white border border-white/10 hover:border-white/25 rounded-md px-2 py-1 transition-colors duration-200"
              >
                {copied ? <Check size={12} /> : <Copy size={12} />}
                {copied ? "Copied" : "Copy"}
              </button>
            </div>
            <div className="mt-5 flex flex-wrap gap-3 text-xs text-white/50">
              <a
                href="https://github.com/"
                className="inline-flex items-center gap-1.5 border border-white/10 hover:border-white/25 rounded-full px-3 py-1.5 hover:text-white transition-colors duration-200"
              >
                <Github size={12} /> Source on GitHub
              </a>
              <a
                href="#"
                className="inline-flex items-center gap-1.5 border border-white/10 hover:border-white/25 rounded-full px-3 py-1.5 hover:text-white transition-colors duration-200"
              >
                <Package size={12} /> XcodeGen manifest
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

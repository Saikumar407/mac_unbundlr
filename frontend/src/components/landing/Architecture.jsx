import { motion } from "framer-motion";
import { Terminal, Cpu, Boxes, Lock } from "lucide-react";

const pseudo = `// The critical two lines that make macOS give the wrapper its own Dock icon:
let cfg = NSWorkspace.OpenConfiguration()
cfg.arguments = ["--profile-directory=Profile 1"]
cfg.createsNewApplicationInstance = true   // ← forces a fresh NSApplication

NSWorkspace.shared.openApplication(
    at: URL(fileURLWithPath: "/Applications/Google Chrome.app"),
    configuration: cfg
)`;

const bundle = `~/Applications/ProfilePilot/
└── Chrome — FG Designs.app/
    └── Contents/
        ├── Info.plist          ← unique CFBundleIdentifier
        ├── PkgInfo             ← "APPL????"
        ├── MacOS/launcher      ← shim: exec open -na Chrome --args --profile-directory=Profile\\ 1
        └── Resources/AppIcon.icns`;

export default function Architecture() {
  return (
    <section id="architecture" className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-2xl mb-14">
          <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
            How it actually works
          </div>
          <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
            The Unbundle trick, done natively.
          </h2>
          <p className="mt-4 text-white/60">
            Everything below is documented in the repo&apos;s <span className="mono">ARCHITECTURE.md</span>.
            We do not fork Chrome, do not touch its profile data, and do not require any
            special macOS entitlements beyond writing to <span className="mono">~/Applications</span>.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="rounded-2xl border border-white/10 bg-white/[0.02] overflow-hidden"
          >
            <div className="flex items-center gap-2 px-5 py-3 border-b border-white/10">
              <Terminal size={14} className="text-white/70" />
              <span className="mono text-[11px] uppercase tracking-widest text-white/50">
                Bundle wrapper skeleton
              </span>
            </div>
            <pre className="p-5 text-[12px] leading-relaxed mono text-white/80 whitespace-pre overflow-x-auto">
              {bundle}
            </pre>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.05 }}
            className="rounded-2xl border border-white/10 bg-white/[0.02] overflow-hidden"
          >
            <div className="flex items-center gap-2 px-5 py-3 border-b border-white/10">
              <Cpu size={14} className="text-white/70" />
              <span className="mono text-[11px] uppercase tracking-widest text-white/50">
                Launcher — Swift pseudo-code
              </span>
            </div>
            <pre className="p-5 text-[12px] leading-relaxed mono text-white/80 whitespace-pre overflow-x-auto">
              {pseudo}
            </pre>
          </motion.div>
        </div>

        <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
          <StepCard
            n="01"
            icon={<Boxes size={18} />}
            title="Detect profiles"
            body="Read every browser's on-disk Local State JSON, extract profile names, emails, avatars."
          />
          <StepCard
            n="02"
            icon={<Terminal size={18} />}
            title="Generate wrapper"
            body="Write a tiny .app to ~/Applications/ProfilePilot/ with a unique CFBundleIdentifier and a shim launcher."
          />
          <StepCard
            n="03"
            icon={<Lock size={18} />}
            title="Register with LaunchServices"
            body="LSRegisterURL so macOS sees the wrapper in Cmd+Tab and Dock immediately — no logout required."
          />
        </div>
      </div>
    </section>
  );
}

function StepCard({ n, icon, title, body }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6">
      <div className="flex items-center justify-between text-white/60">
        <div>{icon}</div>
        <div className="mono text-[11px]">{n}</div>
      </div>
      <div className="mt-6 text-white font-medium tracking-tight">{title}</div>
      <div className="mt-1 text-sm text-white/60 leading-relaxed">{body}</div>
    </div>
  );
}

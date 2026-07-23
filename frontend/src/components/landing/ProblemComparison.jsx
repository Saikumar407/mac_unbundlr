import { motion } from "framer-motion";
import { Check, X, MonitorSmartphone } from "lucide-react";

const winProfiles = [
  { name: "Chrome — Work", tabs: 8 },
  { name: "Chrome — Personal", tabs: 3 },
  { name: "Chrome — Client", tabs: 5 },
];

const macProfilesFused = ["Work", "Personal", "Client"];

export default function ProblemComparison() {
  return (
    <section className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="mb-14 max-w-2xl">
          <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
            The problem
          </div>
          <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
            macOS treats every Chrome profile as the same app. Windows doesn&apos;t.
          </h2>
          <p className="mt-4 text-white/60">
            On Windows, each Chrome profile is basically its own app — separate taskbar icon, its own
            Alt+Tab entry. On macOS, everything fuses into one Dock icon. Developers lose focus,
            wrong windows come forward, and Cmd+Tab becomes useless.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* WINDOWS */}
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="rounded-2xl border border-white/10 bg-neutral-950/60 p-6"
          >
            <div className="flex items-center gap-2 mb-4">
              <div className="w-2 h-2 rounded-full bg-emerald-400" />
              <span className="mono text-[11px] uppercase tracking-widest text-white/50">
                Windows · works fine
              </span>
            </div>
            <div className="flex gap-3 items-end">
              {winProfiles.map((p) => (
                <div
                  key={p.name}
                  className="flex-1 aspect-[3/4] rounded-xl bg-gradient-to-b from-white/5 to-white/[0.02] border border-white/10 p-3 flex flex-col justify-between"
                >
                  <div className="text-[11px] mono text-white/50">{p.tabs} tabs</div>
                  <div>
                    <div className="text-sm text-white">{p.name}</div>
                    <div className="text-[10px] mono text-white/30 mt-1">its own Dock icon</div>
                  </div>
                </div>
              ))}
            </div>
            <ul className="mt-6 space-y-2 text-sm text-white/60">
              {[
                "Separate taskbar icons",
                "Alt+Tab treats each profile independently",
                "One-click launch",
              ].map((t) => (
                <li key={t} className="flex items-center gap-2">
                  <Check size={14} className="text-emerald-400" /> {t}
                </li>
              ))}
            </ul>
          </motion.div>

          {/* MAC — bad */}
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.05 }}
            className="rounded-2xl border border-white/10 bg-neutral-950/60 p-6"
          >
            <div className="flex items-center gap-2 mb-4">
              <div className="w-2 h-2 rounded-full bg-rose-400" />
              <span className="mono text-[11px] uppercase tracking-widest text-white/50">
                macOS · everything fused
              </span>
            </div>
            <div className="rounded-xl bg-gradient-to-b from-white/5 to-white/[0.02] border border-white/10 p-5">
              <div className="flex items-center gap-3">
                <MonitorSmartphone size={28} className="text-white/70" />
                <div>
                  <div className="text-sm text-white">Google Chrome</div>
                  <div className="text-[11px] mono text-white/40">1 Dock icon · 3 profiles inside</div>
                </div>
              </div>
              <div className="mt-4 flex flex-wrap gap-2">
                {macProfilesFused.map((p) => (
                  <span
                    key={p}
                    className="text-[11px] mono text-white/60 border border-white/10 px-2 py-1 rounded-md"
                  >
                    {p}
                  </span>
                ))}
              </div>
            </div>
            <ul className="mt-6 space-y-2 text-sm text-white/60">
              {[
                "Clicking Chrome activates the wrong window",
                "Cmd+Tab treats all profiles as one app",
                "Switching profiles is 3–5 clicks deep",
              ].map((t) => (
                <li key={t} className="flex items-center gap-2">
                  <X size={14} className="text-rose-400" /> {t}
                </li>
              ))}
            </ul>
          </motion.div>
        </div>

        {/* Answer strip */}
        <div className="mt-10 rounded-2xl border border-white/10 bg-white/[0.02] p-6 md:p-8 flex flex-col md:flex-row md:items-center gap-6">
          <div className="mono text-[11px] uppercase tracking-widest text-white/40 md:w-40 shrink-0">
            ProfilePilot&apos;s fix
          </div>
          <p className="text-white/80 leading-relaxed">
            We generate a tiny <span className="mono text-white">.app</span> wrapper per profile with a
            unique bundle identifier. macOS then routes Dock identity, Cmd+Tab and window grouping
            through <em>the wrapper</em> — giving each profile the independent identity you always
            wanted. Chrome itself is never modified.
          </p>
        </div>
      </div>
    </section>
  );
}

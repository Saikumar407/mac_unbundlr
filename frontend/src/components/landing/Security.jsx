import { Shield, WifiOff, EyeOff, KeyRound, Fingerprint } from "lucide-react";

const commitments = [
  {
    icon: <WifiOff size={18} />,
    title: "Runs offline",
    body: "Zero network calls in the default configuration. The only optional exception is the AI Workspace endpoint you configure yourself.",
  },
  {
    icon: <EyeOff size={18} />,
    title: "Never touches history",
    body: "We read profile names, emails and avatars from Chrome's Local State. We never read cookies, bookmarks, history, passwords or session tokens.",
  },
  {
    icon: <KeyRound size={18} />,
    title: "Never modifies Chrome",
    body: "Wrappers only launch Chrome with a CLI flag. Chrome's binary and profile data are untouched.",
  },
  {
    icon: <Fingerprint size={18} />,
    title: "No telemetry, no analytics",
    body: "There is nothing to opt out of. There is no analytics SDK, no crash-reporting cloud, no vendored trackers.",
  },
];

export default function Security() {
  return (
    <section className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-[300px_1fr] gap-12">
          <div>
            <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
              Security & privacy
            </div>
            <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
              Written like you&apos;re inspecting the source.
            </h2>
            <div className="mt-6 inline-flex items-center gap-2 mono text-xs text-emerald-400/80 border border-emerald-400/20 rounded-full px-3 py-1">
              <Shield size={12} /> Verifiable in <span className="text-white/80">/ProfilePilot</span>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {commitments.map((c) => (
              <div
                key={c.title}
                className="rounded-2xl border border-white/10 bg-white/[0.02] p-6"
              >
                <div className="text-white/70">{c.icon}</div>
                <div className="mt-5 text-white font-medium tracking-tight">{c.title}</div>
                <div className="mt-1 text-sm text-white/60 leading-relaxed">{c.body}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

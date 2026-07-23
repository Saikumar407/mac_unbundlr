import { useState } from "react";
import axios from "axios";
import { AnimatePresence, motion } from "framer-motion";
import { LANDING } from "@/constants/testIds";
import { Sparkles, Wand2, ChevronRight, Terminal, Link as LinkIcon, AppWindow, User } from "lucide-react";
import MacWindow from "@/components/landing/MacWindow";

const API = `${process.env.REACT_APP_BACKEND_URL}/api`;
const seed = {
  name: "Laravel Dev",
  symbol: "hammer.fill",
  items: [
    { kind: "browserProfile", value: "com.google.Chrome::Work", delayMs: 0, note: "localhost + GitHub" },
    { kind: "app",  value: "/Applications/Visual Studio Code.app", delayMs: 800, note: "editor" },
    { kind: "app",  value: "/Applications/iTerm.app",              delayMs: 1200, note: "shell" },
    { kind: "shell", value: "php artisan serve",                    delayMs: 500,  note: "dev server" },
    { kind: "url",  value: "http://localhost:8000",                  delayMs: 1400, note: "app" },
    { kind: "app",  value: "/Applications/Docker.app",              delayMs: 1600, note: "containers" },
  ],
};

const kindIcon = {
  browserProfile: <User size={13} />,
  app: <AppWindow size={13} />,
  shell: <Terminal size={13} />,
  url: <LinkIcon size={13} />,
};

export default function InteractiveDemo() {
  const [prompt, setPrompt] = useState("laravel");
  const [plan, setPlan] = useState(seed);
  const [loading, setLoading] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState(null);

  async function run() {
    setLoading(true);
    setError(null);
    setSaved(false);
    try {
      const { data } = await axios.post(`${API}/ai-workspace`, { prompt });
      setPlan(data);
    } catch (e) {
      setError("The API is offline. Showing the cached example plan.");
      setPlan(seed);
    } finally {
      setLoading(false);
    }
  }

  async function save() {
    try {
      await axios.post(`${API}/workspaces/export`, {
        name: plan.name,
        symbol: plan.symbol,
        items: plan.items,
      });
      setSaved(true);
    } catch (e) {
      setError("Failed to save workspace.");
    }
  }

  return (
    <section id="demo" className="relative py-24 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-2xl mb-12">
          <div className="mono text-[11px] uppercase tracking-[0.2em] text-white/40 mb-3">
            Try it in the browser
          </div>
          <h2 className="text-3xl md:text-4xl font-medium tracking-tight text-white">
            Type <span className="mono">laravel</span>. Get a workspace.
          </h2>
          <p className="mt-4 text-white/60">
            This is a live preview of the AI Workspace planner running against the ProfilePilot
            companion API. Everything you see gets exported as JSON and imported into the Mac app.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-start">
          {/* prompt */}
          <div>
            <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-5">
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-white/70" />
                <span className="mono text-[11px] uppercase tracking-widest text-white/50">
                  Prompt
                </span>
              </div>
              <div className="mt-3 flex items-center gap-3">
                <input
                  data-testid={LANDING.demoAIInput}
                  value={prompt}
                  onChange={(e) => setPrompt(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && run()}
                  placeholder="laravel, nextjs, data-science, streaming setup…"
                  className="flex-1 bg-transparent border border-white/10 focus:border-white/25 rounded-full px-4 py-2.5 text-white placeholder-white/30 text-sm outline-none transition-colors duration-200"
                />
                <button
                  data-testid={LANDING.demoAIRun}
                  onClick={run}
                  disabled={loading || !prompt.trim()}
                  className="inline-flex items-center gap-2 bg-white text-black text-sm font-medium px-4 py-2.5 rounded-full hover:bg-white/90 transition-colors duration-200 disabled:opacity-50"
                >
                  <Wand2 size={14} />
                  {loading ? "Thinking…" : "Draft plan"}
                </button>
              </div>
              <div className="mt-3 flex flex-wrap gap-2">
                {["laravel", "next.js", "python data science", "streaming", "flutter"].map((s) => (
                  <button
                    key={s}
                    onClick={() => setPrompt(s)}
                    className="mono text-[11px] text-white/50 hover:text-white border border-white/10 hover:border-white/25 rounded-full px-2.5 py-1 transition-colors duration-200"
                  >
                    {s}
                  </button>
                ))}
              </div>
              {error && (
                <div className="mt-4 text-xs text-amber-400/80 mono">{error}</div>
              )}
            </div>

            <div className="mt-6 rounded-2xl border border-white/10 bg-white/[0.02] p-5 text-sm text-white/70">
              <div className="mono text-[11px] uppercase tracking-widest text-white/40 mb-2">
                What ProfilePilot will do
              </div>
              1. Open your Chrome <span className="mono text-white">Work</span> profile.<br />
              2. Wait, then launch VS Code and iTerm in sequence.<br />
              3. Start <span className="mono text-white">php artisan serve</span>.<br />
              4. Open <span className="mono text-white">http://localhost:8000</span> in the same profile.<br />
              5. Boot Docker in the background.
            </div>
          </div>

          {/* preview */}
          <MacWindow title={`ProfilePilot — ${plan.name}`}>
            <div className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
                    <Sparkles size={16} />
                  </div>
                  <div>
                    <div className="text-sm font-medium text-white">{plan.name}</div>
                    <div className="text-[11px] mono text-white/40">{plan.items.length} steps</div>
                  </div>
                </div>
                <button
                  data-testid={LANDING.demoAISave}
                  onClick={save}
                  className="text-xs text-white/70 hover:text-white border border-white/10 hover:border-white/25 rounded-full px-3 py-1.5 transition-colors duration-200"
                >
                  {saved ? "Saved ✓" : "Save workspace"}
                </button>
              </div>

              <div className="mt-4 space-y-2">
                <AnimatePresence initial={false}>
                  {plan.items.map((it, i) => (
                    <motion.div
                      key={`${it.kind}-${it.value}-${i}`}
                      initial={{ opacity: 0, x: 8 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0 }}
                      transition={{ delay: i * 0.04 }}
                      className="flex items-center gap-3 rounded-xl bg-white/[0.03] border border-white/5 p-2.5"
                    >
                      <div className="w-7 h-7 rounded-md bg-white/5 flex items-center justify-center text-white/70">
                        {kindIcon[it.kind] || <ChevronRight size={13} />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm text-white truncate">{it.value}</div>
                        {it.note && (
                          <div className="text-[11px] text-white/40 truncate">{it.note}</div>
                        )}
                      </div>
                      <div className="mono text-[10px] text-white/40">
                        +{it.delayMs || 0}ms
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>
            </div>
          </MacWindow>
        </div>
      </div>
    </section>
  );
}

import { motion } from "framer-motion";
import { LANDING } from "@/constants/testIds";
import { ArrowRight, BookOpen, Command } from "lucide-react";
import MacWindow from "@/components/landing/MacWindow";
import MenuBarPreview from "@/components/landing/MenuBarPreview";

export default function Hero() {
  return (
    <section id="top" className="relative pt-24 pb-32">
      <div className="hero-glow" aria-hidden="true" />
      <div className="max-w-6xl mx-auto px-6 relative z-10">
        <div className="flex flex-col lg:flex-row items-start gap-16">
          <div className="flex-1 max-w-2xl">
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-2 mono text-[11px] uppercase tracking-[0.2em] text-white/50 border border-white/10 rounded-full px-3 py-1 mb-8"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              Native macOS · SwiftUI · Not Electron
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55, delay: 0.05 }}
              className="text-5xl md:text-6xl font-medium tracking-tighter leading-[1.02] text-white"
            >
              Fix macOS&apos;s broken
              <br />
              multi-profile Chrome
              <br />
              <span className="text-white/40">— and launch your whole stack.</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55, delay: 0.15 }}
              className="mt-7 text-white/60 text-lg leading-relaxed max-w-xl"
            >
              ProfilePilot gives every Chrome, Edge, Brave and Chromium profile its own
              Dock icon, its own Cmd+Tab entry and a single-click workspace launcher for VS Code,
              Terminal, Docker, Postman — whatever you need.
              <br />
              <span className="text-white/40 text-base">
                &lt;100 ms cold start · &lt;50 MB RAM · zero telemetry.
              </span>
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55, delay: 0.25 }}
              className="mt-9 flex flex-wrap items-center gap-3"
            >
              <a
                href="#download"
                data-testid={LANDING.ctaHeroDownload}
                className="inline-flex items-center gap-2 bg-white text-black text-sm font-medium px-5 py-2.5 rounded-full hover:bg-white/90 transition-colors duration-200"
              >
                Download for macOS
                <ArrowRight size={15} />
              </a>
              <a
                href="#architecture"
                data-testid={LANDING.ctaHeroDocs}
                className="inline-flex items-center gap-2 text-sm text-white/70 border border-white/15 hover:border-white/30 hover:text-white px-5 py-2.5 rounded-full transition-colors duration-200"
              >
                <BookOpen size={15} />
                Read the architecture
              </a>
            </motion.div>

            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="mt-10 flex flex-wrap items-center gap-x-6 gap-y-3 text-xs text-white/40"
            >
              <span className="inline-flex items-center gap-2">
                <Command size={12} /> Global hotkeys
              </span>
              <span>Menu-bar mode</span>
              <span>Per-profile Dock icons</span>
              <span>AI Workspaces</span>
              <span>Window layout memory</span>
            </motion.div>
          </div>

          <motion.div
            initial={{ opacity: 0, x: 20, scale: 0.98 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            transition={{ duration: 0.7, delay: 0.15 }}
            className="w-full lg:w-[480px] shrink-0"
          >
            <MacWindow title="ProfilePilot">
              <MenuBarPreview />
            </MacWindow>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

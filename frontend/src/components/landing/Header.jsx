import { LANDING } from "@/constants/testIds";
import { Sparkles, Github } from "lucide-react";

export default function Header() {
  return (
    <header
      className="sticky top-0 z-50 backdrop-blur-xl bg-black/60 border-b border-white/10"
      data-testid={LANDING.navHome}
    >
      <div className="max-w-6xl mx-auto flex items-center justify-between px-6 py-3">
        <a href="#top" className="flex items-center gap-2 group">
          <div className="relative">
            <div className="absolute inset-0 bg-white/10 blur-md rounded-md group-hover:bg-white/20 transition-colors duration-300" />
            <Sparkles size={18} className="relative text-white" />
          </div>
          <span className="font-medium tracking-tight text-white">ProfilePilot</span>
          <span className="text-[10px] mono uppercase tracking-widest text-white/40 border border-white/10 rounded px-1.5 py-0.5 ml-1">
            v0.1
          </span>
        </a>

        <nav className="hidden md:flex items-center gap-7 text-sm text-white/60">
          <a href="#features" data-testid={LANDING.navFeatures} className="hover:text-white transition-colors duration-200">Features</a>
          <a href="#demo" data-testid={LANDING.navDemo} className="hover:text-white transition-colors duration-200">Demo</a>
          <a href="#architecture" data-testid={LANDING.navArchitecture} className="hover:text-white transition-colors duration-200">Architecture</a>
          <a href="#roadmap" className="hover:text-white transition-colors duration-200">Roadmap</a>
          <a href="#faq" className="hover:text-white transition-colors duration-200">FAQ</a>
        </nav>

        <div className="flex items-center gap-2">
          <a
            href="https://github.com/"
            target="_blank"
            rel="noreferrer"
            className="hidden sm:inline-flex items-center gap-1.5 text-xs text-white/60 hover:text-white transition-colors duration-200 px-3 py-1.5 rounded-full border border-white/10 hover:border-white/20"
            data-testid={LANDING.githubLink}
          >
            <Github size={13} />
            GitHub
          </a>
          <a
            href="#download"
            data-testid={LANDING.navDownload}
            className="inline-flex items-center gap-1.5 text-xs font-medium bg-white text-black px-3.5 py-1.5 rounded-full hover:bg-white/90 transition-colors duration-200"
          >
            Download
          </a>
        </div>
      </div>
    </header>
  );
}

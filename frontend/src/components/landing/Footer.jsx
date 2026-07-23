import { Github } from "lucide-react";
import { LANDING } from "@/constants/testIds";

export default function Footer() {
  return (
    <footer className="relative border-t border-white/10 py-20 mt-10">
      <div className="max-w-6xl mx-auto px-6">
        <div className="text-6xl md:text-8xl font-medium tracking-tighter text-white/90 leading-none">
          ProfilePilot.
        </div>
        <div className="mt-3 text-white/50 max-w-xl">
          One native app, one menu bar icon, every profile and workspace one keystroke away.
        </div>
        <div className="mt-10 flex flex-wrap items-center gap-6 text-sm text-white/50">
          <a
            href="https://github.com/"
            target="_blank"
            rel="noreferrer"
            data-testid={LANDING.githubLink}
            className="inline-flex items-center gap-2 hover:text-white transition-colors duration-200"
          >
            <Github size={14} /> GitHub
          </a>
          <a href="#architecture" className="hover:text-white transition-colors duration-200">
            Architecture
          </a>
          <a href="#roadmap" className="hover:text-white transition-colors duration-200">
            Roadmap
          </a>
          <a href="#faq" className="hover:text-white transition-colors duration-200">
            FAQ
          </a>
          <span className="ml-auto mono text-[11px] text-white/30">
            © 2026 · MIT · built for macOS
          </span>
        </div>
      </div>
    </footer>
  );
}

import { LANDING } from "@/constants/testIds";
import { Globe, Chrome, Shield, Sparkles, Square, Terminal, Layers } from "lucide-react";

/** A miniature preview of the ProfilePilot menu-bar popover. */
export default function MenuBarPreview() {
  return (
    <div className="p-3 bg-gradient-to-b from-neutral-950 to-black text-white">
      <div className="flex items-center justify-between px-2 py-2 border-b border-white/5">
        <div className="flex items-center gap-2">
          <Sparkles size={14} className="text-white/80" />
          <span className="text-sm font-medium">ProfilePilot</span>
        </div>
        <div className="text-[10px] mono text-white/40">4 browsers · 12 profiles</div>
      </div>

      <div className="px-2 pt-3 pb-1 text-[10px] mono uppercase tracking-widest text-white/40">
        Workspaces
      </div>
      <Row
        icon={<Layers size={14} />}
        title="Laravel"
        subtitle="6 items"
        shortcut="⌥⌘L"
        testid={LANDING.workspaceRow}
      />
      <Row
        icon={<Sparkles size={14} />}
        title="Next.js focus"
        subtitle="5 items"
        shortcut="⌥⌘N"
      />

      <div className="px-2 pt-3 pb-1 text-[10px] mono uppercase tracking-widest text-white/40">
        Chrome
      </div>
      <Row
        icon={<Chrome size={14} className="text-white/80" />}
        title="FG Designs"
        subtitle="fgdesigns@work.co"
        shortcut="⌥⌘1"
        testid={LANDING.profileRow}
      />
      <Row
        icon={<Chrome size={14} className="text-white/80" />}
        title="Sai Kumar"
        subtitle="sai@personal.dev"
        shortcut="⌥⌘2"
      />
      <Row
        icon={<Chrome size={14} className="text-white/80" />}
        title="Repalle"
        subtitle="repalle@studio.io"
        shortcut="⌥⌘3"
      />

      <div className="px-2 pt-3 pb-1 text-[10px] mono uppercase tracking-widest text-white/40">
        Edge
      </div>
      <Row
        icon={<Globe size={14} className="text-white/80" />}
        title="Client"
        subtitle="Profile 1"
      />

      <div className="px-2 pt-3 pb-1 text-[10px] mono uppercase tracking-widest text-white/40">
        Brave
      </div>
      <Row
        icon={<Shield size={14} className="text-white/80" />}
        title="Personal"
        subtitle="Default"
      />
    </div>
  );
}

function Row({ icon, title, subtitle, shortcut, testid }) {
  return (
    <button
      data-testid={testid}
      className="w-full flex items-center gap-3 px-2 py-1.5 rounded-md hover:bg-white/5 transition-colors duration-200 text-left"
    >
      <div className="text-white/70">{icon}</div>
      <div className="flex-1 min-w-0">
        <div className="text-sm truncate">{title}</div>
        {subtitle && <div className="text-[11px] text-white/40 truncate">{subtitle}</div>}
      </div>
      {shortcut && <kbd>{shortcut}</kbd>}
    </button>
  );
}

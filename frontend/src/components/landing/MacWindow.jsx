export default function MacWindow({ title, children, className = "" }) {
  return (
    <div className={`mac-window ${className}`}>
      <div className="mac-titlebar">
        <span className="mac-dot red" />
        <span className="mac-dot yellow" />
        <span className="mac-dot green" />
        <span className="mono text-[11px] text-white/40 ml-3">{title}</span>
      </div>
      <div>{children}</div>
    </div>
  );
}

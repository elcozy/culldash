"use client";

import { useEffect, useState } from "react";
import { Logo } from "./Logo";
import { PhotoTile } from "./PhotoTile";

/** The views the hero mock cycles through, like the app's own modes. */
enum MockView {
    Grid = "Grid",
    Similar = "Similar",
    Photo = "Photo",
}

enum Mark {
    None = "none",
    Pick = "pick",
    Reject = "reject",
}

const tiles = Array.from({ length: 12 }, (_, i) => i);
const startMarks: Mark[] = tiles.map((i) => (i === 1 || i === 6 ? Mark.Pick : i === 4 ? Mark.Reject : Mark.None));

/**
 * A coded, live mini CullDash in a laptop frame: the window bar with search,
 * the tool strip, and a grid where frames get picked and rejected on their
 * own. The view tabs switch Grid, Similar and Photo, and move on every five
 * seconds while the pointer is away.
 */
export function MacMock() {
    const [view, setView] = useState(MockView.Grid);
    const [cursor, setCursor] = useState(0);
    const [marks, setMarks] = useState(startMarks);
    const [hovering, setHovering] = useState(false);

    useEffect(() => {
        if (hovering) return;
        const views = Object.values(MockView);
        const step = setInterval(() => setView((v) => views[(views.indexOf(v) + 1) % views.length]), 5000);
        return () => clearInterval(step);
    }, [hovering]);

    useEffect(() => {
        const tick = setInterval(() => {
            setCursor((c) => {
                const next = (c + 1) % tiles.length;
                setMarks((m) => m.map((mark, i) => (i === c ? (c % 3 === 2 ? Mark.Reject : c % 2 ? Mark.Pick : mark) : mark)));
                return next;
            });
        }, 900);
        return () => clearInterval(tick);
    }, []);

    return (
        <div className="tilt-in mx-auto w-full max-w-5xl" onMouseEnter={() => setHovering(true)} onMouseLeave={() => setHovering(false)}>
            <div className="rounded-[1.6rem] bg-[#1d1d1f] p-2.5 shadow-[0_40px_120px_-30px_rgb(0_113_227_/_0.45)] ring-1 ring-black/10 sm:p-3.5">
                <div className="overflow-hidden rounded-[1rem] bg-app-canvas text-app-text">
                    <WindowBar />
                    <ToolStrip view={view} onView={setView} picks={marks.filter((m) => m === Mark.Pick).length} />
                    <div className="h-[300px] sm:h-[420px]">
                        {view === MockView.Photo ? <PhotoView seed={cursor} /> : <Grid view={view} cursor={cursor} marks={marks} />}
                    </div>
                    <div className="flex gap-4 border-t border-app-hairline px-4 py-2 text-[10px] text-app-subtle">
                        {["P pick", "X reject", "1–5 stars", "R reject rest", "Del trash"].map((hint) => (
                            <span key={hint}>{hint}</span>
                        ))}
                    </div>
                </div>
            </div>
            <div className="mx-auto h-3 w-[78%] rounded-b-2xl bg-gradient-to-b from-[#c7c7cc] to-[#8e8e93] shadow-lg" />
        </div>
    );
}

function WindowBar() {
    return (
        <div className="relative flex h-10 items-center gap-3 border-b border-app-hairline px-3">
            <div className="flex gap-1.5">
                {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
                    <span key={c} className="h-2.5 w-2.5 rounded-full" style={{ background: c }} />
                ))}
            </div>
            <Logo size={16} />
            <span className="text-[11px] font-semibold">Rey 256</span>
            <span className="absolute left-1/2 hidden w-56 -translate-x-1/2 rounded-md bg-app-raised px-2.5 py-1 text-[10px] text-app-subtle sm:block">
                Search photos by name
            </span>
            <span className="ml-auto rounded-md bg-app-accent px-2.5 py-1 text-[10px] font-semibold">Send 12</span>
        </div>
    );
}

function ToolStrip({ view, onView, picks }: { view: MockView; onView: (v: MockView) => void; picks: number }) {
    return (
        <div className="flex items-center gap-2 border-b border-app-hairline px-3 py-2 text-[10px]">
            <div className="flex rounded-md bg-app-raised p-0.5">
                {Object.values(MockView).map((v) => (
                    <button
                        key={v}
                        onClick={() => onView(v)}
                        className={`rounded px-2 py-0.5 font-semibold transition ${v === view ? "bg-app-accent text-white" : "text-app-muted hover:text-white"}`}
                    >
                        {v}
                    </button>
                ))}
            </div>
            <span className="ml-1 text-app-muted">
                Picks <span className="text-app-keeper">{picks}</span>
            </span>
            <span className="ml-auto text-app-reject">Trash rejects</span>
        </div>
    );
}

function Grid({ view, cursor, marks }: { view: MockView; cursor: number; marks: Mark[] }) {
    const similar = view === MockView.Similar;
    return (
        <div className="h-full overflow-hidden p-3">
            {similar && <p className="mb-2 text-[10px] font-semibold text-app-muted">Similar · 4 photos · reject the rest</p>}
            <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
                {tiles.map((i) => (
                    <div
                        key={i}
                        className={`rounded-lg p-1 transition ${i === cursor ? "bg-app-raised ring-2 ring-app-accent" : ""} ${similar && i > 3 ? "opacity-30" : ""}`}
                    >
                        <PhotoTile seed={similar && i < 4 ? 2 : i} className={`aspect-[3/2] w-full rounded ${marks[i] === Mark.Reject ? "opacity-30" : ""}`} />
                        <div className="mt-1 flex items-center gap-1 text-[8px]">
                            {marks[i] === Mark.Pick && <span className="text-app-keeper">●</span>}
                            {marks[i] === Mark.Reject && <span className="text-app-reject">✕</span>}
                            <span className="text-app-star">{"★".repeat(marks[i] === Mark.Pick ? 3 : 0)}</span>
                            <span className="ml-auto text-app-subtle">DSC0{1612 + i}</span>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

function PhotoView({ seed }: { seed: number }) {
    return (
        <div className="flex h-full flex-col">
            <div className="flex flex-1 items-center justify-center p-4">
                <PhotoTile seed={seed} className="h-full max-h-[340px] w-auto rounded-md" />
            </div>
            <div className="flex gap-4 border-t border-app-hairline px-4 py-2 text-[10px] text-app-muted">
                <span className="font-semibold text-white">DSC0{1612 + seed}.ARW</span>
                <span>3 Oct 2026, 14:03</span>
                <span>Shoreditch, London</span>
                <span className="ml-auto">ƒ/1.7 · 1/160 s · ISO 400</span>
            </div>
        </div>
    );
}

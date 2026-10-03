"use client";

import { useEffect, useState } from "react";
import { PhotoTile } from "./PhotoTile";

/** What each key does to the frame in focus, so the filmstrip can react. */
enum Effect {
    Pick = "pick",
    Reject = "reject",
    Stars = "stars",
    RejectRest = "reject-rest",
    Trash = "trash",
    Undo = "undo",
}

const keyset = [
    { key: "P", effect: Effect.Pick, title: "Pick a keeper", note: "A green badge, and on to the next frame." },
    { key: "X", effect: Effect.Reject, title: "Reject", note: "It fades back; nothing is deleted yet." },
    { key: "1–5", effect: Effect.Stars, title: "Rate it", note: "Stars go into the XMP sidecar Lightroom reads." },
    { key: "R", effect: Effect.RejectRest, title: "Reject the rest", note: "Keep your pick, reject every other frame of the burst." },
    { key: "Del", effect: Effect.Trash, title: "Trash this one", note: "To the Trash on that drive, with its JPEG and sidecar." },
    { key: "⌘Z", effect: Effect.Undo, title: "Undo", note: "Back where it was, as if nothing happened." },
];

/**
 * The page's one colour band. Big keycaps press themselves in turn (or on
 * hover and click), and a small filmstrip shows what each key does to the
 * frame in focus. Concentric rings from one corner are this band's pattern.
 */
export function KeysBand() {
    const [active, setActive] = useState(0);
    const [paused, setPaused] = useState(false);

    useEffect(() => {
        if (paused) return;
        const timer = setInterval(() => setActive((a) => (a + 1) % keyset.length), 2200);
        return () => clearInterval(timer);
    }, [paused]);

    const current = keyset[active];

    return (
        <section
            id="keys"
            className="section relative overflow-hidden bg-black text-white"
            onMouseLeave={() => setPaused(false)}
        >
            <div
                aria-hidden
                className="absolute -right-48 -bottom-48 h-[46rem] w-[46rem] rounded-full opacity-[0.12] [background:repeating-radial-gradient(circle,transparent_0_46px,rgb(255_255_255_/_0.35)_47px_48px)] [mask-image:radial-gradient(circle,black_30%,transparent_70%)]"
            />
            <div className="wrap relative grid items-center gap-14 lg:grid-cols-[1fr_1.1fr]">
                <div>
                    <p className="eyebrow !text-[#86868b]">Keys</p>
                    <h2 className="headline-sm mt-3">Your keyboard is the whole interface.</h2>
                    <p className="lede mt-5 max-w-md !text-[#a1a1a6]">
                        One hand on the keys, eyes on the photo. No menus, no dragging, no dialogs in the way.
                    </p>
                    <div className="mt-10 min-h-[6.5rem] border-l-2 border-[#2997ff] pl-5" aria-live="polite">
                        <p className="font-mono text-sm text-[#86868b]">{current.key}</p>
                        <p className="mt-1 text-2xl font-semibold">{current.title}</p>
                        <p className="mt-1 text-[#a1a1a6]">{current.note}</p>
                    </div>
                </div>

                <div className="rounded-[28px] bg-[#1d1d1f] p-6 sm:p-8">
                    <Filmstrip effect={current.effect} />
                    <div className="mt-8 grid grid-cols-3 gap-3 sm:gap-4">
                        {keyset.map((k, i) => (
                            <button
                                key={k.key}
                                onMouseEnter={() => {
                                    setPaused(true);
                                    setActive(i);
                                }}
                                onClick={() => setActive(i)}
                                className={`group flex h-20 flex-col items-center justify-center rounded-2xl bg-white text-[#0b1b33] transition duration-150 sm:h-24 ${
                                    i === active
                                        ? "translate-y-[3px] shadow-[0_1px_0_#b9c6dc,0_0_0_4px_rgb(41_151_255_/_0.6)]"
                                        : "shadow-[0_5px_0_#b9c6dc,0_10px_24px_rgb(0_0_0_/_0.18)] hover:-translate-y-0.5"
                                }`}
                                aria-label={`${k.key}: ${k.title}`}
                            >
                                <span className="font-mono text-2xl font-semibold sm:text-3xl">{k.key}</span>
                                <span className="mt-1 hidden text-[11px] font-medium text-[#5b6475] sm:block">{k.title}</span>
                            </button>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
}

/** Five frames of a burst; the middle one is in focus and shows the key's effect. */
function Filmstrip({ effect }: { effect: Effect }) {
    return (
        <div className="grid grid-cols-5 gap-2">
            {[0, 1, 2, 3, 4].map((i) => {
                const focus = i === 2;
                const gone = focus && effect === Effect.Trash;
                const faded = (focus && effect === Effect.Reject) || (!focus && effect === Effect.RejectRest);
                const picked = focus && (effect === Effect.Pick || effect === Effect.RejectRest || effect === Effect.Undo);
                return (
                    <div
                        key={i}
                        className={`relative rounded-xl p-1 transition duration-300 ${focus ? "bg-white/10 ring-2 ring-[#2997ff]" : ""} ${gone ? "scale-75 opacity-0" : ""}`}
                    >
                        <PhotoTile seed={4} className={`aspect-[2/3] w-full rounded-lg transition duration-300 ${faded ? "opacity-25" : ""}`} />
                        {picked && (
                            <span className="absolute top-2 right-2 flex h-5 w-5 items-center justify-center rounded-full bg-[#30d158] text-[11px] font-bold">✓</span>
                        )}
                        {faded && <span className="absolute top-2 right-2 flex h-5 w-5 items-center justify-center rounded-full bg-[#ff6b57] text-[11px] font-bold">✕</span>}
                        <p className={`mt-1 h-3 text-center text-[10px] tracking-widest text-[#ffc043] ${focus && effect === Effect.Stars ? "" : "invisible"}`}>
                            ★★★★
                        </p>
                    </div>
                );
            })}
        </div>
    );
}

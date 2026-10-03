"use client";

import { useState } from "react";
import { PhotoTile } from "./PhotoTile";

/** The small live mocks inside the feature tiles, in the app's dark look. */

function Screen({ children, className = "" }: { children: React.ReactNode; className?: string }) {
    return <div className={`rounded-2xl bg-app-canvas p-4 text-[12px] text-app-text ${className}`}>{children}</div>;
}

/** Five near-identical frames: click one to keep it; the rest fade as rejects. */
export function SimilarMock() {
    const [kept, setKept] = useState<number | null>(null);
    return (
        <Screen>
            <div className="flex justify-between">
                <span className="font-semibold">Similar · 5 photos</span>
                <span className={kept === null ? "text-app-subtle" : "text-app-keeper"}>{kept === null ? "click your keeper" : "kept 1 · rejected 4"}</span>
            </div>
            <div className="mt-3 grid grid-cols-5 gap-2">
                {[0, 1, 2, 3, 4].map((i) => (
                    <button
                        key={i}
                        onClick={() => setKept(kept === i ? null : i)}
                        aria-label={`Keep frame ${i + 1}`}
                        className={`relative rounded-lg p-1 transition ${kept === i ? "ring-2 ring-app-keeper" : "hover:ring-2 hover:ring-app-accent"}`}
                    >
                        <PhotoTile seed={2} className={`aspect-[2/3] w-full rounded transition duration-300 ${kept !== null && kept !== i ? "opacity-25" : ""}`} />
                        {kept === i && <span className="absolute top-2 right-2 h-4 w-4 rounded-full bg-app-keeper text-[10px] leading-4">✓</span>}
                    </button>
                ))}
            </div>
        </Screen>
    );
}

export function SendMock() {
    return (
        <Screen>
            <p className="pb-2 font-semibold">Send 24 photos to</p>
            {["Lightroom Classic", "Capture One", "Photoshop"].map((app, i) => (
                <div key={app} className={`flex items-center gap-2 rounded-md px-2 py-2 ${i === 0 ? "bg-app-raised" : ""}`}>
                    <span className="h-4 w-4 rounded bg-app-accent" />
                    {app}
                </div>
            ))}
        </Screen>
    );
}

export function CardsMock() {
    return (
        <Screen>
            {[["SD CARD", "Rey 256", 76], ["DRIVE", "One Touch", 4]].map(([kind, name, used]) => (
                <div key={name as string} className="border-b border-app-hairline py-2 last:border-0">
                    <div className="flex gap-2">
                        <span className="font-semibold">{name}</span>
                        <span className="text-[10px] text-app-subtle">{kind}</span>
                        <span className="ml-auto text-app-accent">Open all</span>
                    </div>
                    <div className="mt-2 h-1 w-32 rounded-full bg-app-raised">
                        <div className="h-1 rounded-full bg-app-accent" style={{ width: `${used}%` }} />
                    </div>
                </div>
            ))}
        </Screen>
    );
}

export function VideoMock() {
    return (
        <Screen className="grid grid-cols-3 gap-2">
            {["0:42", "9:42", "1:15"].map((length, i) => (
                <div key={length} className="relative">
                    <PhotoTile seed={i + 3} className="aspect-video w-full rounded" />
                    <span className="absolute bottom-1 left-1 rounded-full bg-black/60 px-1.5 text-[9px]">▶ {length}</span>
                </div>
            ))}
        </Screen>
    );
}

/** Trash a frame and put it back. */
export function UndoMock() {
    const [trashed, setTrashed] = useState(false);
    return (
        <Screen className="flex items-center gap-4">
            <PhotoTile seed={5} className={`aspect-[3/2] w-28 rounded transition duration-300 ${trashed ? "scale-75 opacity-0" : ""}`} />
            <div className="flex-1">
                <p className="text-app-muted">{trashed ? "DSC01617.ARW moved to the Trash" : "DSC01617.ARW"}</p>
                <button onClick={() => setTrashed(!trashed)} className="mt-2 rounded-md bg-app-raised px-3 py-1 font-mono">
                    {trashed ? "⌘Z" : "Delete"}
                </button>
            </div>
        </Screen>
    );
}

export function InfoMock() {
    return (
        <Screen className="flex gap-4">
            <PhotoTile seed={1} className="aspect-[3/2] w-2/5 rounded" />
            <div className="space-y-2">
                <p className="font-semibold">DSC01612.ARW</p>
                <p className="text-app-muted">3 October 2026 at 14:03</p>
                <p className="text-app-muted">Shoreditch, London</p>
                <p className="text-app-muted">ILCE-6400 · Viltrox 25mm F1.7</p>
                <p className="text-app-muted">ƒ/1.7 · 1/160 s · ISO 400</p>
            </div>
        </Screen>
    );
}

"use client";

import { useState } from "react";
import { FadeUp } from "./FadeUp";
import { PhotoTile } from "./PhotoTile";

/** The features as a bento: big cards with small live mocks, not a grid of icons. */
export function Bento() {
    return (
        <section id="features" className="py-20 sm:py-24">
            <div className="mx-auto max-w-[1400px] px-4 sm:px-8">
                <FadeUp className="mx-auto max-w-2xl text-center">
                    <p className="text-[13px] font-semibold tracking-[0.18em] text-accent uppercase">Features</p>
                    <h2 className="mt-4 text-3xl font-semibold tracking-tight text-navy sm:text-4xl">Everything a cull needs. Nothing it doesn&apos;t.</h2>
                    <p className="mt-4 text-lg text-muted">Built for the hour after the shoot, when all you want is the keepers.</p>
                </FadeUp>
                <div className="mt-12 grid gap-5 lg:grid-cols-3">
                    <Card className="lg:col-span-2" title="Similar shots, side by side" body="Bursts and re-takes of a pose are grouped with Apple's on-device Vision. Click the one you love; the rest are rejected.">
                        <SimilarMock />
                    </Card>
                    <Card title="Send to Lightroom" body="Open the keepers in Lightroom, Capture One or any editor. Stars and labels go with them in XMP sidecars.">
                        <div className="mt-6 flex flex-wrap gap-2">
                            {["Lightroom Classic", "Capture One", "Photoshop", "darktable"].map((app) => (
                                <span key={app} className="glass rounded-full px-3 py-1.5 text-[13px] font-medium text-navy">
                                    {app}
                                </span>
                            ))}
                        </div>
                    </Card>
                    <Card title="Cards, drives and this Mac" body="SD cards in the Mac's own slot, external drives and your folders, with every photo and video folder found for you." />
                    <Card title="Videos too" body="MP4 and MOV clips sit beside the stills, with a frame to judge, their length, and playback when opened." />
                    <Card title="Undo every delete" body="Rejects go to the Trash with their JPEG and sidecar. ⌘Z puts them back where they were." />
                </div>
            </div>
        </section>
    );
}

function Card({ title, body, className = "", children }: { title: string; body: string; className?: string; children?: React.ReactNode }) {
    return (
        <FadeUp className={className}>
            <div className="h-full rounded-[2rem] border border-outline bg-card p-8 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-[0_20px_50px_-20px_rgb(0_113_227_/_0.35)]">
                <h3 className="text-2xl font-semibold tracking-tight text-navy">{title}</h3>
                <p className="mt-3 leading-relaxed text-muted">{body}</p>
                {children}
            </div>
        </FadeUp>
    );
}

/** Four near-identical frames: click one to keep it and watch the rest fade as rejects. */
function SimilarMock() {
    const [kept, setKept] = useState<number | null>(null);
    return (
        <div className="mt-6 rounded-2xl bg-app-canvas p-4 text-app-text">
            <div className="flex items-center justify-between text-xs">
                <span className="font-semibold">Similar · 4 photos</span>
                <span className={kept === null ? "text-app-subtle" : "text-app-keeper"}>
                    {kept === null ? "click your keeper" : "kept 1, rejected 3"}
                </span>
            </div>
            <div className="mt-3 grid grid-cols-4 gap-2">
                {[0, 1, 2, 3].map((i) => (
                    <button
                        key={i}
                        onClick={() => setKept(i)}
                        className={`relative rounded-lg p-1 transition ${kept === i ? "ring-2 ring-app-keeper" : "hover:ring-2 hover:ring-app-accent"}`}
                        aria-label={`Keep frame ${i + 1}`}
                    >
                        <PhotoTile seed={2} className={`aspect-[3/2] w-full rounded transition ${kept !== null && kept !== i ? "opacity-25" : ""}`} />
                        {kept === i && <span className="absolute top-2 right-2 h-4 w-4 rounded-full bg-app-keeper text-[10px] leading-4 text-white">✓</span>}
                    </button>
                ))}
            </div>
        </div>
    );
}

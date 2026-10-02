"use client";

import { useState } from "react";
import { FadeUp } from "./FadeUp";
import { Logo } from "./Logo";
import { faqs, keys, links } from "./content";

/** The page's one colour band: the keys as a timeline, rings from a corner. */
export function KeysBand() {
    return (
        <section id="keys" className="relative overflow-hidden bg-primary py-20 text-white sm:py-24">
            <div
                aria-hidden
                className="absolute -top-40 -right-40 h-[40rem] w-[40rem] rounded-full opacity-20 [background:repeating-radial-gradient(circle,transparent_0_38px,rgb(255_255_255_/_0.5)_39px_40px)] [mask-image:radial-gradient(circle,black,transparent_70%)]"
            />
            <div className="relative mx-auto max-w-[1400px] px-4 sm:px-8">
                <p className="text-[13px] font-semibold tracking-[0.18em] text-white/70 uppercase">Keys</p>
                <h2 className="mt-4 max-w-2xl text-3xl font-semibold tracking-tight sm:text-4xl">Your keyboard is the whole interface.</h2>
                <ol className="mt-14 grid gap-8 sm:grid-cols-3 lg:grid-cols-6">
                    {keys.map((k) => (
                        <li key={k.key} className="relative border-t border-white/30 pt-6">
                            <span className="absolute -top-[5px] left-0 h-2.5 w-2.5 rounded-full bg-white" />
                            <kbd className="rounded-lg bg-white/15 px-3 py-1.5 font-mono text-lg font-semibold backdrop-blur">{k.key}</kbd>
                            <p className="mt-3 text-white/85">{k.label}</p>
                        </li>
                    ))}
                </ol>
            </div>
        </section>
    );
}

export function Faq() {
    const [open, setOpen] = useState(0);
    return (
        <section id="faq" className="py-20 sm:py-24">
            <div className="mx-auto max-w-[1400px] px-4 sm:px-8">
                <FadeUp className="mx-auto max-w-3xl">
                    <p className="text-center text-[13px] font-semibold tracking-[0.18em] text-accent uppercase">FAQ</p>
                    <h2 className="mt-4 text-center text-3xl font-semibold tracking-tight text-navy sm:text-4xl">Questions photographers ask.</h2>
                    <div className="mt-12 divide-y divide-outline border-y border-outline">
                        {faqs.map((f, i) => (
                            <div key={f.q}>
                                <button onClick={() => setOpen(open === i ? -1 : i)} className="flex w-full items-center justify-between gap-6 py-5 text-left">
                                    <span className="text-lg font-semibold text-navy">{f.q}</span>
                                    <span className={`text-2xl text-muted transition ${open === i ? "rotate-45" : ""}`}>+</span>
                                </button>
                                {open === i && <p className="pb-6 leading-relaxed text-muted">{f.a}</p>}
                            </div>
                        ))}
                    </div>
                </FadeUp>
            </div>
        </section>
    );
}

/** The next step: a dotted card with the download and the Homebrew line. */
export function Cta() {
    const [copied, setCopied] = useState(false);
    const command = "brew install --cask elcozy/tap/culldash";
    return (
        <section className="pb-24">
            <div className="mx-auto max-w-[1400px] px-4 sm:px-8">
                <FadeUp>
                    <div className="group relative overflow-hidden rounded-[2rem] border border-outline bg-card p-10 text-center shadow-[0_40px_100px_-40px_rgb(0_113_227_/_0.5)] sm:p-16">
                        <div
                            aria-hidden
                            className="absolute inset-0 opacity-50 transition-[background-position] duration-[3s] [background-image:radial-gradient(var(--outline)_1px,transparent_1px)] [background-size:18px_18px] group-hover:[background-position:18px_18px]"
                        />
                        <div aria-hidden className="absolute -top-24 -right-24 h-72 w-72 rounded-full bg-primary opacity-20 blur-3xl" />
                        <div className="relative">
                            <Logo size={64} className="mx-auto" />
                            <h2 className="mt-6 text-3xl font-semibold tracking-tight text-navy sm:text-4xl">Your next shoot, culled before dinner.</h2>
                            <p className="mx-auto mt-4 max-w-xl text-lg text-muted">
                                CullDash is in early development. Build it from GitHub today; a signed download and Homebrew are on the way.
                            </p>
                            <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
                                <a href={links.repo} className="rounded-full bg-primary px-6 py-3 font-semibold text-primary-ink transition hover:-translate-y-0.5">
                                    Get it on GitHub
                                </a>
                                <button
                                    onClick={() => {
                                        navigator.clipboard?.writeText(command);
                                        setCopied(true);
                                    }}
                                    className="glass rounded-full px-5 py-3 font-mono text-sm text-navy"
                                    title="Coming soon"
                                >
                                    {copied ? "Copied · coming soon" : `${command}  (soon)`}
                                </button>
                            </div>
                        </div>
                    </div>
                </FadeUp>
            </div>
        </section>
    );
}

export function Footer() {
    return (
        <footer className="border-t border-outline py-12">
            <div className="mx-auto grid max-w-[1400px] gap-8 px-4 text-sm sm:grid-cols-4 sm:px-8">
                <div>
                    <div className="flex items-center gap-2 font-semibold text-navy">
                        <Logo size={22} /> CullDash
                    </div>
                    <p className="mt-3 text-muted">Cull RAW shoots fast on your Mac.</p>
                </div>
                {[
                    ["Product", [["Features", "#features"], ["How it works", "#how"], ["Keys", "#keys"]]],
                    ["Project", [["GitHub", links.repo], ["FAQ", "#faq"]]],
                    ["Trust", [["No account, no upload", "#how"], ["Undo every delete", "#features"]]],
                ].map(([title, items]) => (
                    <div key={title as string}>
                        <p className="font-semibold text-navy">{title as string}</p>
                        <ul className="mt-3 space-y-2">
                            {(items as string[][]).map(([label, href]) => (
                                <li key={label}>
                                    <a href={href} className="text-muted hover:text-navy">
                                        {label}
                                    </a>
                                </li>
                            ))}
                        </ul>
                    </div>
                ))}
            </div>
            <p className="mx-auto mt-10 max-w-[1400px] px-4 text-xs text-muted sm:px-8">© 2026 Chiemeka Madufor. Lightroom, Capture One and Photoshop are trademarks of their owners.</p>
        </footer>
    );
}

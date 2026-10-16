"use client";

import { useState } from "react";
import { FadeUp } from "./FadeUp";
import { Logo } from "./Logo";
import { faqs, links } from "./content";

export function Faq() {
    const [open, setOpen] = useState(0);
    return (
        <section id="faq" className="section">
            <div className="wrap max-w-[760px]">
                <FadeUp>
                    <h2 className="headline-sm text-center">Questions, answered.</h2>
                    <div className="mt-14 divide-y divide-hairline border-y border-hairline">
                        {faqs.map((f, i) => (
                            <div key={f.q}>
                                <button
                                    onClick={() => setOpen(open === i ? -1 : i)}
                                    className="flex w-full items-center justify-between gap-6 py-5 text-left"
                                    aria-expanded={open === i}
                                >
                                    <span className="text-[19px] font-semibold tracking-[-0.015em]">{f.q}</span>
                                    <span className={`text-2xl font-light text-tertiary transition ${open === i ? "rotate-45" : ""}`}>+</span>
                                </button>
                                {open === i && <p className="pb-6 text-secondary">{f.a}</p>}
                            </div>
                        ))}
                    </div>
                </FadeUp>
            </div>
        </section>
    );
}

/**
 * The last word, the way Apple ends a product page: no box, no glow, just
 * the icon, the name, one line and how to get it, on a plain full-width
 * section.
 */
export function Cta() {
    return (
        <section className="section bg-alt text-center">
            <div className="wrap">
                <FadeUp>
                    <Logo size={120} className="mx-auto" />
                    <p className="eyebrow mt-8">CullDash</p>
                    <h2 className="headline mx-auto mt-2 max-w-[12em]">Your next shoot, culled before dinner.</h2>
                    <div className="mt-10 flex flex-wrap items-center justify-center gap-x-8 gap-y-4">
                        <a href={links.download} className="btn">
                            Download for Mac
                        </a>
                        <a href={links.repo} className="link">
                            View the source ›
                        </a>
                    </div>
                    <p className="mt-10 text-sm text-tertiary">
                        Free and open source under the MIT licence. macOS 14 or later, on Apple silicon and Intel.
                    </p>
                </FadeUp>
            </div>
        </section>
    );
}

export function Footer() {
    const groups: [string, [string, string][]][] = [
        ["Product", [["Features", "#features"], ["How it works", "#how"], ["Keys", "#keys"]]],
        ["Trust", [["Privacy", "#privacy"], ["Compare", "#compare"]]],
        ["Project", [["GitHub", links.repo], ["FAQ", "#faq"]]],
    ];
    return (
        <footer className="bg-alt pt-2 pb-9 text-xs text-secondary">
            <div className="wrap border-t border-hairline pt-6">
                <div className="grid gap-6 sm:grid-cols-4">
                    <div className="flex items-center gap-2 font-semibold text-ink">
                        <Logo size={18} /> CullDash
                    </div>
                    {groups.map(([title, items]) => (
                        <div key={title}>
                            <p className="font-semibold text-ink">{title}</p>
                            <ul className="mt-2 space-y-1.5">
                                {items.map(([label, href]) => (
                                    <li key={label}>
                                        <a href={href} className="hover:text-ink hover:underline">
                                            {label}
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </div>
                <p className="mt-8 border-t border-hairline pt-4">
                    © 2026 Chiemeka Madufor. Lightroom, Capture One and Photoshop are trademarks of their owners.
                </p>
            </div>
        </footer>
    );
}

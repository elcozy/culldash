"use client";

import { useEffect, useState } from "react";
import { FadeUp } from "./FadeUp";
import { StepMock, Variant } from "./StepMock";
import { principles, steps } from "./content";

/**
 * How a cull goes, as a live walkthrough: a Photos / Videos switch and the
 * five steps on a line on the left, the screen each step lands on at the
 * right. It moves on by itself every few seconds until the pointer is over it.
 */
export function Walkthrough() {
    const [variant, setVariant] = useState(Variant.Photos);
    const [active, setActive] = useState(0);
    const [paused, setPaused] = useState(false);

    useEffect(() => {
        if (paused) return;
        const timer = setInterval(() => setActive((a) => (a + 1) % steps.length), 4500);
        return () => clearInterval(timer);
    }, [paused]);

    return (
        <section id="how" className="section bg-alt" onMouseEnter={() => setPaused(true)} onMouseLeave={() => setPaused(false)}>
            <div className="wrap">
                <FadeUp className="text-center">
                    <h2 className="headline">Full card to keepers.</h2>
                    <p className="lede mx-auto mt-5 max-w-[26em]">Five steps, most of them <strong>a single key</strong>.</p>
                </FadeUp>
                <div className="mt-16 grid items-start gap-10 lg:grid-cols-[1fr_1.15fr]">
                    <div>
                        <div className="inline-flex rounded-full bg-tile p-1">
                            {Object.values(Variant).map((v) => (
                                <button
                                    key={v}
                                    onClick={() => setVariant(v)}
                                    className={`rounded-full px-4 py-1.5 text-sm font-semibold transition ${variant === v ? "bg-ink text-page" : "text-secondary hover:text-ink"}`}
                                >
                                    {v}
                                </button>
                            ))}
                        </div>
                        <p className="mt-4 text-secondary">
                            {variant === Variant.Photos
                                ? "A portrait session on a Sony card: RAWs with their JPEGs."
                                : "A day of clips: Sony MP4s and phone MOVs, judged from a frame and played when opened."}
                        </p>
                        <ol className="relative mt-8 border-l border-hairline">
                            {steps.map((step, index) => (
                                <li key={step.title} className="relative pb-3 pl-8">
                                    <span
                                        className={`absolute top-3 -left-[9px] flex h-[17px] w-[17px] items-center justify-center rounded-full border text-[10px] font-semibold ${
                                            index <= active ? "border-blue bg-blue text-white" : "border-hairline bg-alt text-tertiary"
                                        }`}
                                    >
                                        {index + 1}
                                    </span>
                                    <button
                                        onClick={() => setActive(index)}
                                        className={`w-full rounded-2xl px-4 py-3 text-left transition ${index === active ? "bg-tile" : "hover:bg-tile/60"}`}
                                    >
                                        <span className={`font-semibold ${index === active ? "text-ink" : "text-secondary"}`}>{step.title}</span>
                                        {index === active && <span className="mt-1.5 block leading-relaxed text-secondary">{step.body}</span>}
                                    </button>
                                </li>
                            ))}
                        </ol>
                    </div>
                    <FadeUp delay={100}>
                        <div className="tile !p-3">
                            <StepMock kind={steps[active].kind} variant={variant} />
                        </div>
                    </FadeUp>
                </div>
                <div className="mt-20 grid gap-8 border-t border-hairline pt-10 sm:grid-cols-3">
                    {principles.map((p) => (
                        <div key={p.title}>
                            <p className="font-semibold">{p.title}</p>
                            <p className="mt-1.5 text-secondary">{p.body}</p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

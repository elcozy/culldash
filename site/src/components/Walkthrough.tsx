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
        <section id="how" className="py-20 sm:py-24" onMouseEnter={() => setPaused(true)} onMouseLeave={() => setPaused(false)}>
            <div className="mx-auto max-w-[1400px] px-4 sm:px-8">
                <FadeUp className="max-w-2xl">
                    <p className="text-[13px] font-semibold tracking-[0.18em] text-accent uppercase">How it works</p>
                    <h2 className="mt-4 text-3xl font-semibold tracking-tight text-navy sm:text-4xl">From full card to keepers in five steps.</h2>
                </FadeUp>
                <div className="mt-12 grid items-start gap-10 lg:grid-cols-[1fr_1.15fr]">
                    <div>
                        <div className="inline-flex rounded-full border border-outline bg-card p-1">
                            {Object.values(Variant).map((v) => (
                                <button
                                    key={v}
                                    onClick={() => setVariant(v)}
                                    className={`rounded-full px-4 py-1.5 text-sm font-semibold transition ${variant === v ? "bg-primary text-primary-ink" : "text-muted hover:text-navy"}`}
                                >
                                    {v}
                                </button>
                            ))}
                        </div>
                        <p className="mt-4 text-muted">
                            {variant === Variant.Photos
                                ? "A portrait session on a Sony card: RAWs with their JPEGs."
                                : "A day of clips: Sony MP4s and phone MOVs, judged from a frame and played when opened."}
                        </p>
                        <ol className="relative mt-8 border-l border-outline">
                            {steps.map((step, index) => (
                                <li key={step.title} className="relative pb-3 pl-8">
                                    <span
                                        className={`absolute top-3 -left-[9px] flex h-[17px] w-[17px] items-center justify-center rounded-full border text-[10px] font-semibold ${
                                            index <= active ? "border-primary bg-primary text-primary-ink" : "border-outline bg-background text-muted"
                                        }`}
                                    >
                                        {index + 1}
                                    </span>
                                    <button
                                        onClick={() => setActive(index)}
                                        className={`w-full rounded-2xl px-4 py-3 text-left transition ${index === active ? "bg-primary/[0.07]" : "hover:bg-raised"}`}
                                    >
                                        <span className={`font-semibold ${index === active ? "text-navy" : "text-muted"}`}>{step.title}</span>
                                        {index === active && <span className="mt-1.5 block leading-relaxed text-muted">{step.body}</span>}
                                    </button>
                                </li>
                            ))}
                        </ol>
                    </div>
                    <FadeUp delay={100}>
                        <div className="rounded-[2rem] border border-outline bg-card p-3 shadow-[0_30px_80px_-30px_rgb(11_27_51_/_0.35)]">
                            <StepMock kind={steps[active].kind} variant={variant} />
                        </div>
                    </FadeUp>
                </div>
                <div className="mt-16 grid gap-8 border-t border-outline pt-10 sm:grid-cols-3">
                    {principles.map((p) => (
                        <div key={p.title}>
                            <p className="font-semibold text-navy">{p.title}</p>
                            <p className="mt-1.5 leading-relaxed text-muted">{p.body}</p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

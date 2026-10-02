import { FadeUp } from "./FadeUp";

/** The problem, told left-aligned, with the one measured number beside it. */
export function Story() {
    return (
        <section className="py-20 sm:py-24">
            <div className="mx-auto grid max-w-[1400px] items-center gap-12 px-4 sm:px-8 lg:grid-cols-[1.2fr_1fr]">
                <FadeUp>
                    <p className="text-[13px] font-semibold tracking-[0.18em] text-accent uppercase">The problem</p>
                    <h2 className="mt-4 text-4xl leading-tight font-semibold tracking-tight text-navy sm:text-5xl">
                        Importing two thousand RAWs to delete eighteen hundred of them.
                    </h2>
                    <p className="mt-6 max-w-xl text-lg leading-relaxed text-muted">
                        Lightroom builds a preview for every frame before you can judge one. The free viewers look like 2009.
                        CullDash reads the preview your camera already stored inside each RAW, so the next frame is on screen
                        before your finger leaves the key.
                    </p>
                </FadeUp>
                <FadeUp delay={150}>
                    <div className="rounded-[2rem] border border-outline bg-card p-10 shadow-sm">
                        <p className="text-7xl font-semibold tracking-tight text-foreground sm:text-8xl">
                            30<span className="text-4xl text-muted sm:text-5xl"> ms</span>
                        </p>
                        <p className="mt-4 text-lg text-muted">to show a Sony a6400 RAW, measured on the card it was shot to.</p>
                        <div className="mt-8 space-y-3 text-sm">
                            <Bar label="CullDash, embedded preview" width="4%" tone="bg-accent" value="30 ms" />
                            <Bar label="Decoding the full RAW" width="100%" tone="bg-muted/40" value="~750 ms" />
                        </div>
                    </div>
                </FadeUp>
            </div>
        </section>
    );
}

function Bar({ label, width, tone, value }: { label: string; width: string; tone: string; value: string }) {
    return (
        <div>
            <div className="flex justify-between text-muted">
                <span>{label}</span>
                <span className="font-semibold text-foreground">{value}</span>
            </div>
            <div className="mt-1.5 h-2 rounded-full bg-raised">
                <div className={`h-2 rounded-full ${tone}`} style={{ width }} />
            </div>
        </div>
    );
}

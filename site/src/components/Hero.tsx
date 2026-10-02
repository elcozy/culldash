import { MacMock } from "./MacMock";
import { editors, formats, links } from "./content";

/** The hero: the promise, the two actions, and the app itself, live. */
export function Hero() {
    return (
        <section id="top" className="relative pt-32 pb-16 sm:pt-40">
            <div className="mx-auto max-w-[1400px] px-4 text-center sm:px-8">
                <p className="text-[13px] font-semibold tracking-[0.18em] text-accent uppercase">For photographers on a Mac</p>
                <h1 className="mx-auto mt-5 max-w-4xl text-5xl leading-[1.02] font-semibold tracking-tight text-navy sm:text-6xl lg:text-7xl">
                    Cull a whole shoot in <span className="hero-accent">minutes</span>, not evenings.
                </h1>
                <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-muted">
                    Plug in the card, flick through every RAW and clip, keep the best and trash the rest. Then send only the keepers to Lightroom.
                </p>
                <div className="mt-9 flex flex-wrap items-center justify-center gap-4">
                    <a
                        href={links.download}
                        className="rounded-full bg-primary px-6 py-3 font-semibold text-primary-ink shadow-[0_10px_30px_-10px_rgb(0_113_227_/_0.7)] transition hover:-translate-y-0.5"
                    >
                        Get CullDash for Mac
                    </a>
                    <a href="#how" className="font-semibold text-navy underline decoration-outline underline-offset-4 hover:decoration-accent">
                        See how a cull goes
                    </a>
                </div>
                <div className="mt-8 flex flex-wrap justify-center gap-2">
                    {["Native on Apple silicon", "No import", "Nothing leaves your Mac"].map((chip) => (
                        <span key={chip} className="glass rounded-full px-3.5 py-1.5 text-[13px] font-medium text-navy">
                            {chip}
                        </span>
                    ))}
                </div>
                <div className="mt-16">
                    <MacMock />
                </div>
            </div>
            <Ticker />
        </section>
    );
}

/** Formats and editors scrolling past; pauses on hover. */
function Ticker() {
    const items = [...formats, ...editors.map((e) => `Send to ${e}`)];
    return (
        <div className="ticker mt-20 overflow-hidden border-y border-outline py-5 [mask-image:linear-gradient(90deg,transparent,black_12%,black_88%,transparent)]">
            <div className="ticker-track flex w-max gap-12 text-[15px] font-medium whitespace-nowrap text-muted">
                {[...items, ...items].map((item, i) => (
                    <span key={i}>{item}</span>
                ))}
            </div>
        </div>
    );
}

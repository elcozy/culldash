import { FadeUp } from "./FadeUp";
import { links, reasons } from "./content";

/** Why CullDash, after maccy.app's "Why?": six short reasons in a grid, each
 * with a coloured icon. The last says it is open source, with the link. */
export function Why() {
    return (
        <section id="why" className="section">
            <div className="wrap">
                <FadeUp className="text-center">
                    <h2 className="headline">Why CullDash?</h2>
                    <p className="lede mx-auto mt-5 max-w-[26em]">
                        Made for the hour after the shoot, when <strong>all you want is the keepers</strong>.
                    </p>
                </FadeUp>
                <div className="mt-16 grid gap-x-10 gap-y-14 sm:grid-cols-2 lg:grid-cols-3">
                    {reasons.map((r) => (
                        <FadeUp key={r.title}>
                            <span
                                className="grid h-12 w-12 place-items-center rounded-2xl"
                                style={{ background: `color-mix(in srgb, ${r.tone} 14%, transparent)`, color: r.tone }}
                            >
                                <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                                    <path d={r.icon} />
                                </svg>
                            </span>
                            <h3 className="mt-5 text-[15px] font-bold tracking-[0.06em] text-ink uppercase">{r.title}</h3>
                            <p className="mt-2 text-secondary">
                                {r.body}
                                {r.title === "Open source" && (
                                    <>
                                        {" "}
                                        <a href={links.repo} className="text-blue hover:underline">
                                            See the code ›
                                        </a>
                                    </>
                                )}
                            </p>
                        </FadeUp>
                    ))}
                </div>
            </div>
        </section>
    );
}

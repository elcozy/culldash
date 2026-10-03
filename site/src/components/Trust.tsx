import { FadeUp } from "./FadeUp";

const promises = [
    {
        title: "Nothing is imported.",
        body: "Your files stay on the card or drive. CullDash reads them and writes small sidecars beside them.",
        icon: "M4 7h16M4 12h16M4 17h10",
    },
    {
        title: "Nothing is uploaded.",
        body: "Similar shots are found with Apple's on-device Vision. No account, no cloud, no tracking.",
        icon: "M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3z",
    },
    {
        title: "Nothing is lost by mistake.",
        body: "Every delete goes to the Trash on that drive, and every Trash can be undone with ⌘Z.",
        icon: "M9 14l-4-4 4-4M5 10h9a5 5 0 010 10h-2",
    },
];

/** Privacy, Apple style: one big statement and three plain promises. */
export function Privacy() {
    return (
        <section id="privacy" className="section text-center">
            <div className="wrap">
                <FadeUp>
                    <h2 className="headline">
                        Privacy.
                        <br />
                        <span className="text-secondary">That&apos;s CullDash.</span>
                    </h2>
                    <p className="lede mx-auto mt-6 max-w-[26em]">
                        Your photos are yours. Everything happens <strong>on your Mac</strong>, and stays there.
                    </p>
                </FadeUp>
                <div className="mt-16 grid gap-12 text-left sm:grid-cols-3">
                    {promises.map((p) => (
                        <FadeUp key={p.title}>
                            <svg viewBox="0 0 24 24" className="h-8 w-8 text-blue" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                                <path d={p.icon} />
                            </svg>
                            <p className="mt-4 text-[21px] font-semibold tracking-[-0.015em]">{p.title}</p>
                            <p className="mt-2 text-secondary">{p.body}</p>
                        </FadeUp>
                    ))}
                </div>
            </div>
        </section>
    );
}

/** How the ways of culling compare. Rows say only what each one actually does. */
const columns = [
    {
        name: "CullDash",
        highlight: true,
        rows: ["Instant, from the stored preview", "Straight off the card", "Bursts and re-takes, by look", "Stars and labels in XMP", "Photos and clips together", "Trash with undo"],
    },
    {
        name: "Importing into Lightroom",
        rows: ["After previews are built", "After an import", "Stacks by capture time", "Its own catalogue", "Photos and clips", "Removes from the catalogue"],
    },
    {
        name: "A basic viewer",
        rows: ["Varies", "Wherever the files are", "None", "Rarely", "Usually photos only", "Deletes, usually no undo"],
    },
];
const rowNames = ["First frame", "Works from", "Groups similar shots", "Ratings carry to editors", "Videos", "Deleting"];

export function Compare() {
    return (
        <section id="compare" className="section bg-alt text-center">
            <div className="wrap">
                <FadeUp>
                    <h2 className="headline">Which way to cull?</h2>
                </FadeUp>
                <div className="mt-16 grid gap-5 text-left md:grid-cols-3">
                    {columns.map((column) => (
                        <FadeUp key={column.name}>
                            <div className={`tile h-full ${column.highlight ? "ring-2 ring-blue" : ""}`}>
                                <p className="text-[24px] font-semibold tracking-[-0.02em]">{column.name}</p>
                                <dl className="mt-6 divide-y divide-hairline">
                                    {column.rows.map((value, i) => (
                                        <div key={rowNames[i]} className="py-3">
                                            <dt className="text-xs text-tertiary">{rowNames[i]}</dt>
                                            <dd className={`mt-0.5 ${column.highlight ? "font-semibold" : "text-secondary"}`}>{value}</dd>
                                        </div>
                                    ))}
                                </dl>
                            </div>
                        </FadeUp>
                    ))}
                </div>
            </div>
        </section>
    );
}

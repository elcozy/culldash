import { FadeUp } from "./FadeUp";

/** How the ways of culling compare. Rows say only what each one actually does. */
const columns = [
    {
        name: "CullDash",
        highlight: true,
        rows: ["Instant, from the stored preview", "Straight off the card", "Bursts and re-takes, by look", "Stars and labels in XMP", "Photos and clips together", "Trash with undo", "Yes, free under the MIT licence"],
    },
    {
        name: "Importing into Lightroom",
        rows: ["After previews are built", "After an import", "Stacks by capture time", "Its own catalogue", "Photos and clips", "Removes from the catalogue", "No, a paid subscription"],
    },
    {
        name: "A basic viewer",
        rows: ["Varies", "Wherever the files are", "None", "Rarely", "Usually photos only", "Deletes, usually no undo", "Rarely"],
    },
];
const rowNames = ["First frame", "Works from", "Groups similar shots", "Ratings carry to editors", "Videos", "Deleting", "Open source"];

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

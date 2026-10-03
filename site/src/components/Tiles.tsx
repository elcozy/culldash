import { FadeUp } from "./FadeUp";
import { CardsMock, InfoMock, SendMock, SimilarMock, UndoMock, VideoMock } from "./TileMocks";

const tiles = [
    { title: "Twelve takes. One keeper.", body: "Bursts and re-takes of a pose sit side by side. Pick the one you love; the rest are rejected.", mock: <SimilarMock />, wide: true },
    { title: "Straight to Lightroom.", body: "Keepers open in Lightroom, Capture One or any editor, stars and labels included.", mock: <SendMock /> },
    { title: "Every card. Every drive.", body: "SD cards, even in the Mac's own slot, external drives and your folders. Folders are found for you.", mock: <CardsMock /> },
    { title: "Clips, too.", body: "MP4 and MOV beside the stills, with a frame to judge, the length, and playback.", mock: <VideoMock /> },
    { title: "Oops-proof.", body: "Delete sends a photo to the Trash with its JPEG and sidecar. ⌘Z brings it back.", mock: <UndoMock /> },
    { title: "When and where.", body: "Date taken and the place it was shot, read from the photo, one key away.", mock: <InfoMock />, wide: true },
];

/** The features: white tiles on grey, each a short line and a small live mock. */
export function Tiles() {
    return (
        <section id="features" className="section bg-alt">
            <div className="wrap">
                <FadeUp className="text-center">
                    <h2 className="headline">Everything a cull needs.</h2>
                    <p className="lede mx-auto mt-5 max-w-[28em]">
                        Built for the hour after the shoot, when <strong>all you want is the keepers</strong>.
                    </p>
                </FadeUp>
                <div className="mt-16 grid gap-5 md:grid-cols-2">
                    {tiles.map((tile) => (
                        <FadeUp key={tile.title} className={tile.wide ? "md:col-span-2" : ""}>
                            <div className={`tile flex h-full flex-col gap-7 ${tile.wide ? "md:flex-row md:items-center" : ""}`}>
                                <div className={tile.wide ? "md:w-2/5" : ""}>
                                    <h3 className="text-[28px] leading-tight font-semibold tracking-[-0.02em]">{tile.title}</h3>
                                    <p className="mt-3 text-secondary">{tile.body}</p>
                                </div>
                                <div className={`mt-auto ${tile.wide ? "md:mt-0 md:flex-1" : ""}`}>{tile.mock}</div>
                            </div>
                        </FadeUp>
                    ))}
                </div>
            </div>
        </section>
    );
}

/** The one big number on the page, with what it means. */
export function Speed() {
    return (
        <section className="section text-center">
            <div className="wrap">
                <FadeUp>
                    <h2 className="headline-sm">Fast enough to keep up with you.</h2>
                    <p className="mt-12 text-[clamp(72px,9vw,120px)] leading-none font-semibold tracking-[-0.04em]">
                        30<span className="text-[0.45em] text-secondary"> ms</span>
                    </p>
                    <p className="lede mx-auto mt-6 max-w-[26em]">
                        to show a Sony a6400 RAW. CullDash reads the preview your camera already stored inside it, so the
                        next frame is up <strong>before your finger leaves the key</strong>.
                    </p>
                    <div className="mx-auto mt-14 max-w-xl space-y-5 text-left text-sm">
                        <Bar label="CullDash, the stored preview" value="30 ms" width="4%" tone="bg-blue" />
                        <Bar label="Decoding the whole RAW" value="about 750 ms" width="100%" tone="bg-hairline" />
                    </div>
                </FadeUp>
            </div>
        </section>
    );
}

function Bar({ label, value, width, tone }: { label: string; value: string; width: string; tone: string }) {
    return (
        <div>
            <div className="flex justify-between text-secondary">
                <span>{label}</span>
                <span className="font-semibold text-ink">{value}</span>
            </div>
            <div className="mt-2 h-1.5 rounded-full bg-alt">
                <div className={`h-1.5 rounded-full ${tone}`} style={{ width }} />
            </div>
        </div>
    );
}

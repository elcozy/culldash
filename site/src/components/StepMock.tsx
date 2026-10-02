import { PhotoTile } from "./PhotoTile";
import { StepKind } from "./content";

/** What the walkthrough shows: a photo shoot or a day of video clips. */
export enum Variant {
    Photos = "Photos",
    Videos = "Videos",
}

/** A mini CullDash screen for one step of the walkthrough, in the app's dark look. */
export function StepMock({ kind, variant }: { kind: StepKind; variant: Variant }) {
    const video = variant === Variant.Videos;
    return (
        <div className="h-[380px] overflow-hidden rounded-[1.5rem] bg-app-canvas p-5 text-app-text">
            <div className="mb-4 flex items-center gap-1.5">
                {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
                    <span key={c} className="h-2.5 w-2.5 rounded-full" style={{ background: c }} />
                ))}
                <span className="ml-3 text-[11px] text-app-subtle">CullDash</span>
            </div>
            {kind === StepKind.Storage && <Storage video={video} />}
            {kind === StepKind.Flag && <Flags video={video} />}
            {kind === StepKind.Similar && <Similar />}
            {kind === StepKind.Trash && <Trash />}
            {kind === StepKind.Send && <Send />}
        </div>
    );
}

function Storage({ video }: { video: boolean }) {
    const rows = video
        ? [["PRIVATE/M4ROOT/CLIP", "42 videos"], ["DCIM/100MSDCF", "3,311 photos"]]
        : [["DCIM/100MSDCF", "3,311 photos"], ["DCIM/101MSDCF", "2,005 photos"]];
    return (
        <div className="text-sm">
            <p className="text-[10px] font-semibold tracking-widest text-app-subtle">STORAGE</p>
            {[["Rey 256", "SD CARD", "58 GB free of 249 GB", 76], ["One Touch", "DRIVE", "4.8 TB free of 5 TB", 4]].map(([name, kind, free, used]) => (
                <div key={name as string} className="mt-3 border-t border-app-hairline pt-3">
                    <div className="flex items-center gap-2">
                        <span className="font-semibold">{name}</span>
                        <span className="text-[10px] text-app-subtle">{kind}</span>
                        <span className="ml-auto rounded-md bg-app-raised px-2 py-1 text-[11px] font-semibold">Open all</span>
                    </div>
                    <div className="mt-2 h-1 w-40 rounded-full bg-app-raised">
                        <div className="h-1 rounded-full bg-app-accent" style={{ width: `${used}%` }} />
                    </div>
                    <p className="mt-1 text-[11px] text-app-subtle">{free}</p>
                </div>
            ))}
            <div className="mt-3 ml-4 space-y-1.5">
                {rows.map(([path, count]) => (
                    <div key={path} className="flex justify-between rounded-md bg-app-raised/60 px-3 py-1.5 text-[12px]">
                        <span>{path}</span>
                        <span className="text-app-subtle">{count}</span>
                    </div>
                ))}
            </div>
        </div>
    );
}

function Flags({ video }: { video: boolean }) {
    const marks = ["pick", "", "reject", "pick", "", "", "reject", ""];
    return (
        <div className="grid grid-cols-4 gap-2">
            {marks.map((mark, i) => (
                <div key={i} className={`relative rounded-lg p-1 ${i === 4 ? "ring-2 ring-app-accent" : ""}`}>
                    <PhotoTile seed={i + 1} className={`aspect-[3/2] w-full rounded ${mark === "reject" ? "opacity-30" : ""}`} />
                    {video && <span className="absolute bottom-6 left-2 rounded-full bg-black/60 px-1.5 text-[8px]">▶ 0:{12 + i * 7}</span>}
                    <div className="mt-1 flex gap-1 text-[9px]">
                        {mark === "pick" && <span className="text-app-keeper">● pick</span>}
                        {mark === "reject" && <span className="text-app-reject">✕ reject</span>}
                    </div>
                </div>
            ))}
        </div>
    );
}

function Similar() {
    return (
        <div>
            <div className="flex justify-between border-t border-app-hairline pt-3 text-xs">
                <span className="font-semibold">Similar · 5 photos · 1 picked</span>
                <span className="rounded-md px-2 text-app-accent">Reject the rest</span>
            </div>
            <div className="mt-3 grid grid-cols-5 gap-2">
                {[0, 1, 2, 3, 4].map((i) => (
                    <div key={i} className={`rounded-lg p-1 ${i === 2 ? "ring-2 ring-app-keeper" : ""}`}>
                        <PhotoTile seed={3} className={`aspect-[2/3] w-full rounded ${i === 2 ? "" : "opacity-30"}`} />
                    </div>
                ))}
            </div>
            <p className="mt-4 text-[11px] text-app-subtle">Grouped by capture time and how alike the frames look, on this Mac.</p>
        </div>
    );
}

function Trash() {
    return (
        <div className="flex h-[280px] items-center justify-center">
            <div className="w-72 rounded-xl border border-app-hairline bg-app-raised p-5 text-center shadow-2xl">
                <p className="text-sm font-semibold">Move 31 rejects to the Trash?</p>
                <p className="mt-2 text-[11px] text-app-muted">Their RAW, JPEG and XMP files go to the Trash on that drive. ⌘Z puts them back.</p>
                <div className="mt-4 flex justify-center gap-2 text-[12px]">
                    <span className="rounded-md bg-app-canvas px-3 py-1">Cancel</span>
                    <span className="rounded-md bg-app-reject px-3 py-1 font-semibold">Move to Trash</span>
                </div>
            </div>
        </div>
    );
}

function Send() {
    return (
        <div className="flex justify-end">
            <div className="w-64 rounded-xl border border-app-hairline bg-app-raised p-3 text-[12px] shadow-2xl">
                <p className="px-2 pb-2 font-semibold">Send 24 photos to</p>
                {["Lightroom Classic", "Capture One", "Photoshop", "darktable"].map((app, i) => (
                    <div key={app} className={`flex items-center gap-2 rounded-md px-2 py-2 ${i === 0 ? "bg-app-hairline" : ""}`}>
                        <span className="h-4 w-4 rounded bg-app-accent/80" />
                        {app}
                    </div>
                ))}
                <p className="mt-2 border-t border-app-hairline px-2 pt-2 text-[10px] text-app-subtle">Stars and labels travel in XMP sidecars.</p>
            </div>
        </div>
    );
}

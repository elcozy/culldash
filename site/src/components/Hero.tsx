import { GitHubRibbon } from "./GitHubRibbon";
import { Logo } from "./Logo";
import { MacMock } from "./MacMock";
import { links } from "./content";

/** The hero, after maccy.app: the icon, the name, what it does in one
 * sentence, three words of attitude, the download and the app itself, live. */
export function Hero() {
    return (
        <section id="top" className="relative overflow-clip pt-16 pb-24 text-center sm:pt-20">
            <GitHubRibbon />
            <div className="wrap">
                <Logo size={112} className="rise mx-auto drop-shadow-[0_12px_28px_rgb(10_132_255_/_0.35)]" />
                <h1 className="headline mt-7">CullDash</h1>
                <p className="lede mx-auto mt-5 max-w-[30em]">
                    Photo culler for macOS which does one job: get you from a full card to <strong>the keepers</strong>.
                    Flick through every RAW and clip, keep the best, trash the rest.
                </p>
                <p className="mt-5 text-[19px] font-semibold tracking-[-0.01em] text-ink">Fast. Open source. No fluff.</p>
                <div className="mt-9 flex flex-wrap items-center justify-center gap-4">
                    <a href={links.download} className="btn">
                        <AppleMark />
                        Download now
                    </a>
                    <a href={links.repo} className="btn btn-outline">
                        <GitHubMark />
                        View on GitHub
                    </a>
                </div>
                <p className="mt-5 text-sm text-tertiary">
                    Requires macOS Sonoma 14 or later · Apple silicon and Intel · Free, MIT licence
                </p>
            </div>
            <div className="rise mt-16 px-4 sm:mt-20">
                <MacMock />
            </div>
        </section>
    );
}

function AppleMark() {
    return (
        <svg viewBox="0 0 814 1000" className="h-[18px] w-[15px] -translate-y-px" fill="currentColor" aria-hidden>
            <path d="M788 341c-6 4-108 62-108 190 0 149 131 201 135 203-1 3-21 72-69 142-43 62-88 124-156 124s-86-40-165-40c-77 0-104 41-166 41s-106-57-156-127C45 792 0 668 0 551c0-189 123-289 244-289 64 0 118 42 158 42 38 0 98-45 171-45 28 0 128 3 215 82zM554 165c31-37 53-88 53-139 0-7-1-14-2-20-50 2-110 34-146 76-28 32-55 83-55 135 0 8 1 16 2 18 3 1 8 1 13 1 45 0 102-30 135-71z" />
        </svg>
    );
}

export function GitHubMark({ className = "h-[18px] w-[18px]" }: { className?: string }) {
    return (
        <svg viewBox="0 0 16 16" className={className} fill="currentColor" aria-hidden>
            <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z" />
        </svg>
    );
}

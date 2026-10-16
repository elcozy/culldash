import { links } from "./content";

/** The classic "Fork me on GitHub" corner ribbon, as maccy.app has it. Kept
 * to the hero's top corner (not fixed) so it never covers the nav's button,
 * and hidden on phones, where it would sit over the icon. */
export function GitHubRibbon() {
    return (
        <div className="pointer-events-none absolute top-0 right-0 hidden h-40 w-40 overflow-hidden sm:block">
            <a
                href={links.repo}
                className="pointer-events-auto absolute top-[42px] right-[-48px] block w-[210px] rotate-45 bg-button py-1.5 text-center text-[13px] font-semibold text-button-ink shadow-[0_2px_8px_rgb(37_44_97_/_0.3)] outline outline-1 -outline-offset-4 outline-dashed outline-button-ink/40 transition hover:opacity-90"
            >
                Fork me on GitHub
            </a>
        </div>
    );
}

import { Logo } from "./Logo";
import { links, nav } from "./content";

/** Apple-style nav: a 52px glass bar, the name on the left, small links,
 * and a small pill to get the app. */
export function Header() {
    return (
        <header className="sticky top-0 z-50 h-[52px] border-b border-black/[0.08] bg-[var(--nav)] backdrop-blur-xl backdrop-saturate-[1.8] dark:border-white/10">
            <div className="wrap flex h-full items-center gap-7">
                <a href="#top" className="mr-auto flex items-center gap-2 text-[21px] font-semibold tracking-[-0.01em] text-ink">
                    <Logo size={26} />
                    CullDash
                </a>
                <ul className="hidden gap-6 text-xs md:flex">
                    {nav.map((item) => (
                        <li key={item.id}>
                            <a href={`#${item.id}`} className="text-ink opacity-80 transition hover:opacity-100">
                                {item.label}
                            </a>
                        </li>
                    ))}
                </ul>
                <a href={links.download} className="btn !px-3 !py-1.5 !text-xs">
                    Get CullDash
                </a>
            </div>
        </header>
    );
}

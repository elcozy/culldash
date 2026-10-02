"use client";

import { useEffect, useState } from "react";
import { Logo } from "./Logo";
import { links, nav } from "./content";

/** The fixed glass header: logo, plain-text nav (the section in view gets
 * a 2px accent bar), and the download button on the right. */
export function Header() {
    const [active, setActive] = useState("");

    useEffect(() => {
        const sections = nav.map((item) => document.getElementById(item.id)).filter(Boolean) as HTMLElement[];
        const observer = new IntersectionObserver(
            (entries) => {
                const visible = entries.filter((e) => e.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
                if (visible) setActive(visible.target.id);
            },
            { rootMargin: "-40% 0px -50% 0px", threshold: [0, 0.25, 0.5] },
        );
        sections.forEach((s) => observer.observe(s));
        return () => observer.disconnect();
    }, []);

    return (
        <header className="glass fixed inset-x-0 top-0 z-50 border-x-0 border-t-0">
            <div className="mx-auto flex h-16 max-w-[1400px] items-center gap-8 px-4 sm:px-8">
                <a href="#top" className="flex items-center gap-2.5 font-semibold tracking-tight text-navy">
                    <Logo size={28} />
                    CullDash
                </a>
                <nav className="hidden items-center gap-7 text-[15px] md:flex">
                    {nav.map((item) => (
                        <a
                            key={item.id}
                            href={`#${item.id}`}
                            className={`relative py-5 transition-colors ${active === item.id ? "text-navy" : "text-muted hover:text-navy"}`}
                        >
                            {item.label}
                            {active === item.id && (
                                <span className="absolute inset-x-0 bottom-3 h-0.5 rounded-full bg-accent" />
                            )}
                        </a>
                    ))}
                </nav>
                <a
                    href={links.download}
                    className="ml-auto rounded-full bg-primary px-4 py-2 text-sm font-semibold text-primary-ink shadow-sm transition hover:-translate-y-px hover:shadow-md"
                >
                    Get CullDash
                </a>
            </div>
        </header>
    );
}

"use client";

import { useEffect, useRef, type ReactNode } from "react";

/** Fades its children up once they scroll into view (see .fade-up in globals.css). */
export function FadeUp({ children, delay = 0, className = "" }: { children: ReactNode; delay?: number; className?: string }) {
    const ref = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const element = ref.current;
        if (!element) return;
        const observer = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    element.classList.add("is-visible");
                    observer.disconnect();
                }
            },
            { rootMargin: "0px 0px -10% 0px" },
        );
        observer.observe(element);
        return () => observer.disconnect();
    }, []);

    return (
        <div ref={ref} className={`fade-up ${className}`} style={{ transitionDelay: `${delay}ms` }}>
            {children}
        </div>
    );
}

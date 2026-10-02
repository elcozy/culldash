/**
 * A made-up photo for the product mocks: sky, sun and hills in one of a few
 * palettes. Drawn rather than real pictures, so the mocks never show
 * anyone's photos and always match the theme.
 */
const palettes = [
    { sky: "#f6c89f", sun: "#fff3d6", far: "#c98b72", near: "#6d4c41" },
    { sky: "#a9d6f5", sun: "#ffffff", far: "#6fa8c9", near: "#2f6f8f" },
    { sky: "#d7c6f2", sun: "#fff6e0", far: "#9b87c9", near: "#5b4a8b" },
    { sky: "#bfe3c8", sun: "#fffbe6", far: "#79b58b", near: "#3f7a52" },
    { sky: "#f3d9a4", sun: "#fffdf2", far: "#d1a35c", near: "#8a5a2b" },
    { sky: "#9fb7d9", sun: "#f5f7ff", far: "#5f7fb0", near: "#2b4470" },
];

export function PhotoTile({ seed, className = "" }: { seed: number; className?: string }) {
    const p = palettes[seed % palettes.length];
    const shift = (seed * 37) % 40;
    return (
        <svg viewBox="0 0 120 80" preserveAspectRatio="xMidYMid slice" className={className} aria-hidden>
            <rect width="120" height="80" fill={p.sky} />
            <circle cx={30 + shift * 1.5} cy={24 + (seed % 3) * 4} r="9" fill={p.sun} />
            <path d={`M0 60 L${25 + shift} 34 L${55 + shift / 2} 52 L${80 + shift / 3} 30 L120 56 L120 80 L0 80 Z`} fill={p.far} />
            <path d={`M0 70 L${40 - shift / 2} 54 L${70} 66 L${100 - shift / 3} 50 L120 64 L120 80 L0 80 Z`} fill={p.near} />
        </svg>
    );
}

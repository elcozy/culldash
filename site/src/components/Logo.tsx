/**
 * The CullDash mark: a fanned stack of photos on Apple blue, the front one
 * a picture with a green keeper badge. The same shapes and numbers as
 * LogoDrawing.swift in the Mac app, so the site and the Dock icon match.
 */
export function Logo({ size = 28, className = "" }: { size?: number; className?: string }) {
    return (
        <svg
            width={size}
            height={size}
            viewBox="0 0 1024 1024"
            className={className}
            role="img"
            aria-label="CullDash"
        >
            <rect width="1024" height="1024" rx="230" fill="#0a84ff" />
            <g transform="translate(512 540)">
                <rect x="-230" y="-290" width="460" height="580" rx="54" fill="#fff" opacity="0.32" transform="rotate(-14)" />
                <rect x="-230" y="-290" width="460" height="580" rx="54" fill="#fff" opacity="0.58" transform="rotate(-5)" />
                <g transform="rotate(6)">
                    <rect x="-230" y="-290" width="460" height="580" rx="54" fill="#fff" />
                    <clipPath id="logo-picture">
                        <rect x="-186" y="-246" width="372" height="400" rx="26" />
                    </clipPath>
                    <g clipPath="url(#logo-picture)">
                        <rect x="-186" y="-246" width="372" height="400" fill="#0a84ff" opacity="0.16" />
                        <circle cx="97" cy="-143" r="43" fill="#0a84ff" />
                        <path d="M-230 160 L-64 -40 L40 60 L104 0 L230 160 Z" fill="#0a84ff" />
                    </g>
                    <circle cx="201" cy="255" r="127" fill="#0a84ff" />
                    <circle cx="201" cy="255" r="105" fill="#30d158" />
                    <path
                        d="M150 256 L186 292 L252 222"
                        fill="none"
                        stroke="#fff"
                        strokeWidth="30"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    />
                </g>
            </g>
        </svg>
    );
}

import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({ variable: "--font-inter", subsets: ["latin"] });
const mono = JetBrains_Mono({ variable: "--font-mono-fallback", subsets: ["latin"] });

export const metadata: Metadata = {
    title: "CullDash · Cull RAW shoots fast on your Mac",
    description:
        "Flick through a card of RAW photos and videos, keep the best, trash the rest and send the keepers to Lightroom. Native, fast and private.",
};

export const viewport: Viewport = {
    themeColor: [
        { media: "(prefers-color-scheme: light)", color: "#fbf9f4" },
        { media: "(prefers-color-scheme: dark)", color: "#0b0d12" },
    ],
};

export default function RootLayout({ children }: LayoutProps<"/">) {
    return (
        <html lang="en" className={`${inter.variable} ${mono.variable} antialiased`}>
            <body className="min-h-dvh">
                <Backdrop />
                {children}
            </body>
        </html>
    );
}

/** Two or three faint blurred colour fields behind the whole page, fixed so
 * they never clip at a section edge, and so the glass has colour to show. */
function Backdrop() {
    return (
        <div aria-hidden className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
            <div className="absolute -top-40 left-[10%] h-[36rem] w-[36rem] rounded-full bg-[#0071e3] opacity-[0.07] blur-[120px]" />
            <div className="absolute top-[30%] -right-32 h-[30rem] w-[30rem] rounded-full bg-[#5e5ce6] opacity-[0.06] blur-[120px]" />
            <div className="absolute bottom-[-10rem] left-[30%] h-[28rem] w-[28rem] rounded-full bg-[#30d158] opacity-[0.05] blur-[120px]" />
        </div>
    );
}

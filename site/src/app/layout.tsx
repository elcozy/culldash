import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({ variable: "--font-inter", subsets: ["latin"] });
const mono = JetBrains_Mono({ variable: "--font-mono-fallback", subsets: ["latin"] });

export const metadata: Metadata = {
    title: "CullDash · Free, open-source photo culling for Mac",
    description:
        "Flick through a card of RAW photos and videos, keep the best, trash the rest and send the keepers to Lightroom. Native, fast, private and open source.",
};

export const viewport: Viewport = {
    themeColor: [
        { media: "(prefers-color-scheme: light)", color: "#fdfdfd" },
        { media: "(prefers-color-scheme: dark)", color: "#0f1120" },
    ],
};

export default function RootLayout({ children }: LayoutProps<"/">) {
    return (
        <html lang="en" className={`${inter.variable} ${mono.variable} antialiased`}>
            <body className="min-h-dvh">
                {children}
            </body>
        </html>
    );
}

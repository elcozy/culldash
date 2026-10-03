import { Cta, Faq, Footer } from "@/components/Closing";
import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { KeysBand } from "@/components/KeysBand";
import { Speed, Tiles } from "@/components/Tiles";
import { Compare, Privacy } from "@/components/Trust";
import { Walkthrough } from "@/components/Walkthrough";

/** The CullDash page, in the rhythm of Apple's product pages: white and
 * light-grey sections in turn, one black section for the keys. */
export default function Home() {
    return (
        <>
            <Header />
            <main>
                <Hero />
                <Tiles />
                <Speed />
                <Walkthrough />
                <KeysBand />
                <Privacy />
                <Compare />
                <Faq />
                <Cta />
            </main>
            <Footer />
        </>
    );
}

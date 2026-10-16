import { Cta, Faq, Footer } from "@/components/Closing";
import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { KeysBand } from "@/components/KeysBand";
import { Speed, Tiles } from "@/components/Tiles";
import { Compare } from "@/components/Trust";
import { Walkthrough } from "@/components/Walkthrough";
import { Why } from "@/components/Why";

/** The CullDash page, after maccy.app: the icon and download up top, six
 * reasons why, then the app shown working. Off-white and pale-grey sections
 * alternate, with one dark section for the keys. */
export default function Home() {
    return (
        <>
            <Header />
            <main>
                <Hero />
                <Why />
                <Tiles />
                <Speed />
                <Walkthrough />
                <KeysBand />
                <Compare />
                <Faq />
                <Cta />
            </main>
            <Footer />
        </>
    );
}

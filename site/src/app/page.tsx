import { Bento } from "@/components/Bento";
import { Cta, Faq, Footer, KeysBand } from "@/components/Closing";
import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { Story } from "@/components/Story";
import { Walkthrough } from "@/components/Walkthrough";

/** The CullDash landing page: hero and live mock, the problem, features,
 * the walkthrough, the keys band, questions, and the next step. */
export default function Home() {
    return (
        <>
            <Header />
            <main>
                <Hero />
                <Story />
                <Bento />
                <Walkthrough />
                <KeysBand />
                <Faq />
                <Cta />
            </main>
            <Footer />
        </>
    );
}

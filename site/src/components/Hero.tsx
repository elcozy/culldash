import { MacMock } from "./MacMock";
import { links } from "./content";

/** The hero: the name, the promise in three words, and the app itself, live. */
export function Hero() {
    return (
        <section id="top" className="overflow-clip pt-16 pb-24 text-center sm:pt-24">
            <div className="wrap">
                <p className="eyebrow">CullDash for Mac</p>
                <h1 className="headline mt-3">Your shoot. Culled.</h1>
                <p className="lede mx-auto mt-6 max-w-[30em]">
                    The Mac app that flicks through every RAW and clip on your card, keeps the best and trashes the rest,
                    so you can <strong>get to the editing</strong>.
                </p>
                <div className="mt-9 flex flex-wrap items-center justify-center gap-x-8 gap-y-4">
                    <a href={links.download} className="btn">
                        Get CullDash
                    </a>
                    <a href="#how" className="link">
                        See how a cull goes ›
                    </a>
                </div>
            </div>
            <div className="rise mt-16 px-4 sm:mt-20">
                <MacMock />
            </div>
        </section>
    );
}

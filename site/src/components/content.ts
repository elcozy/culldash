/**
 * The site's words and lists in one place, kept apart from the layout so
 * copy can change without touching components. Only claims the app backs:
 * the 30 ms preview time was measured on a Sony a6400 ARW.
 */

export const links = {
    repo: "https://github.com/elcozy/culldash",
    download: "https://github.com/elcozy/culldash/releases/latest",
};

export const nav = [
    { id: "why", label: "Why" },
    { id: "features", label: "Features" },
    { id: "how", label: "How it works" },
    { id: "keys", label: "Keys" },
    { id: "compare", label: "Compare" },
];

export const formats = [
    "Sony ARW",
    "Fujifilm RAF",
    "Canon CR3",
    "Nikon NEF",
    "Adobe DNG",
    "Olympus ORF",
    "Panasonic RW2",
    "JPEG & HEIC",
    "MP4 & MOV clips",
];

export const editors = ["Lightroom Classic", "Lightroom", "Capture One", "Photoshop", "darktable", "FUJIFILM X RAW STUDIO"];

/** Kinds of step in the walkthrough. */
export enum StepKind {
    Storage = "storage",
    Flag = "flag",
    Similar = "similar",
    Trash = "trash",
    Send = "send",
}

export const steps = [
    {
        kind: StepKind.Storage,
        title: "Plug in the card",
        body: "CullDash lists your cards and drives, with every photo and video folder on them. Open one folder, or the whole card at once.",
    },
    {
        kind: StepKind.Flag,
        title: "Flick through and flag",
        body: "P keeps, X rejects, 1 to 5 adds stars. It moves to the next frame by itself, so a decision is one key.",
    },
    {
        kind: StepKind.Similar,
        title: "Group the near-duplicates",
        body: "Similar puts bursts and re-takes of a pose side by side. Pick the one or two you love, press R, the rest are rejected.",
    },
    {
        kind: StepKind.Trash,
        title: "Trash the rejects",
        body: "Rejects go to the Trash with their JPEG and sidecar, never straight to deletion. ⌘Z brings them back.",
    },
    {
        kind: StepKind.Send,
        title: "Send the keepers on",
        body: "Open the photos you kept in Lightroom, Capture One or any editor. Stars and labels travel with them in XMP sidecars.",
    },
];

/** The six reasons in the "Why" grid, after maccy.app's. `tone` colours the icon. */
export const reasons = [
    { title: "No fluff", tone: "#0a84ff", icon: "M4 6h16M4 12h10M4 18h6", body: "CullDash does one job: get you from a full card to the keepers. No catalogue, no import, no editing tools you already have elsewhere." },
    { title: "Fast", tone: "#ff9f0a", icon: "M13 2L4 14h7l-1 8 9-12h-7l1-8z", body: "It shows the preview your camera already stored inside each RAW, about 30 ms a frame. Hold an arrow key and the shoot flies past." },
    { title: "Keyboard-first", tone: "#bf5af2", icon: "M3 7h18v10H3zM7 11h.01M11 11h.01M15 11h.01M7 14h10", body: "P keeps, X rejects, 1 to 5 adds stars. Every decision is one key and it moves on by itself, so your hands never leave the keyboard." },
    { title: "Private", tone: "#30d158", icon: "M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3z", body: "Everything happens on your Mac. Similar shots are found with Apple's on-device Vision. No account, no upload, no tracking." },
    { title: "Native", tone: "#ff375f", icon: "M4 5h16v11H4zM9 20h6M12 16v4", body: "Built in Swift and SwiftUI. It looks and feels like a Mac app, runs natively on Apple silicon and Intel, and the download is about 2 MB." },
    { title: "Open source", tone: "var(--ink)", icon: "M8 7l-5 5 5 5M16 7l5 5-5 5M14 4l-4 16", body: "CullDash is open source under the MIT licence, and free. The full source is on GitHub, to read, build or change however you like." },
];

export const principles = [
    { title: "Nothing is imported.", body: "Your files stay on the card or drive. CullDash only reads them and writes small sidecars." },
    { title: "Nothing leaves your Mac.", body: "Grouping similar shots uses Apple's on-device Vision. No account, no upload." },
    { title: "Nothing is lost by mistake.", body: "Every delete goes to the Trash and every Trash can be undone." },
];

export const faqs = [
    {
        q: "Which cameras does it support?",
        a: "Any RAW format macOS can read, which covers current Sony, Fujifilm (including X-Trans), Canon, Nikon, Olympus, Panasonic and DNG files, plus JPEG, HEIC and MP4 or MOV clips.",
    },
    {
        q: "Does it replace Lightroom?",
        a: "No. It is the step before. You cull in CullDash, then send only the keepers to Lightroom or another editor, with your stars and labels.",
    },
    {
        q: "Why does Lightroom not show my picks?",
        a: "Lightroom keeps picks only inside its own catalogue and does not read them from other apps. Stars and colour labels do carry over, so give keepers a star or label.",
    },
    {
        q: "Will it delete my photos?",
        a: "Only when you ask, and only to the Trash on that drive, together with the matching JPEG and sidecar. ⌘Z puts them back.",
    },
    {
        q: "What does it cost?",
        a: "Nothing. CullDash is free and open source under the MIT licence. Download it from GitHub Releases, or build it from the source.",
    },
];

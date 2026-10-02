/**
 * The site's words and lists in one place, kept apart from the layout so
 * copy can change without touching components. Only claims the app backs:
 * the 30 ms preview time was measured on a Sony a6400 ARW.
 */

export const links = {
    repo: "https://github.com/elcozy/sortRaw.app",
    download: "https://github.com/elcozy/sortRaw.app",
};

export const nav = [
    { id: "features", label: "Features" },
    { id: "how", label: "How it works" },
    { id: "keys", label: "Keys" },
    { id: "faq", label: "FAQ" },
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

export const principles = [
    { title: "Nothing is imported.", body: "Your files stay on the card or drive. CullDash only reads them and writes small sidecars." },
    { title: "Nothing leaves your Mac.", body: "Grouping similar shots uses Apple's on-device Vision. No account, no upload." },
    { title: "Nothing is lost by mistake.", body: "Every delete goes to the Trash and every Trash can be undone." },
];

export const keys = [
    { key: "P", label: "Pick a keeper" },
    { key: "X", label: "Reject" },
    { key: "1–5", label: "Stars" },
    { key: "R", label: "Reject the rest of a burst" },
    { key: "Del", label: "Trash this one" },
    { key: "⌘Z", label: "Undo" },
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
        a: "CullDash is in early development. The source is on GitHub; a signed download and Homebrew install are on the way.",
    },
];

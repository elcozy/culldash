# How CullDash works

CullDash is a native Mac app for culling photo and video shoots: open a card,
flick through every frame, keep the best, trash the rest, and send the keepers
to an editor. This document explains what each part does and how the main
flows run. The diagrams are drawn in PlantUML (`docs/diagrams/*.puml`) and
rendered with `scripts/diagrams.py`.

## The pieces

The app has two Swift modules and a website:

- **CullDashCore** does everything that touches files and has no UI, so it can
  be tested on its own: listing drives and photo folders (`StorageScanner`),
  pairing RAW and JPEG files (`FolderScanner`), fast previews from the JPEG a
  camera embeds in each RAW and frames from video clips (`PreviewLoader`),
  EXIF, GPS and clip length (`ExposureInfo`), XMP sidecars (`XMPSidecar`),
  grouping similar shots (`SimilarityPrints`, `BurstGrouper`) and the Trash
  with undo (`PhotoTrash`).
- **CullDash** is the SwiftUI app. `LibraryStore` holds the open shoot, the
  selection, filters, the trash history and burst groups; the views draw it;
  `KeyCommands` turns keys into decisions; `EditorLauncher` hands photos to
  Lightroom or another editor; `PlaceNames` turns GPS into a place name.
- **site/** is the Next.js landing page. It does not talk to the app.

<!-- diagram:architecture -->
![architecture](diagrams/architecture.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml architecture
!pragma layout smetana
title CullDash: the pieces and how they connect
skinparam componentStyle rectangle
skinparam shadowing false

package "CullDash.app (SwiftUI)" {
  [Views\nStart screen, grid, full view,\ninfo column, top bar] as Views
  [LibraryStore\nshoot, selection, filters,\ntrash history, bursts] as Store
  [KeyCommands\nP X U 0-9 R Del Esc] as Keys
  [EditorLauncher\nSend to Lightroom...] as Launcher
  [PlaceNames\nGPS to place (MapKit)] as Places
}

package "CullDashCore (no UI)" {
  [StorageScanner\ndrives and photo folders] as Storage
  [FolderScanner\nRAW + JPEG pairs] as Scanner
  [PreviewLoader\nembedded previews, video frames] as Previews
  [XMPSidecar\nstars, labels, flags] as XMP
  [ExposureInfo\nEXIF, GPS, duration] as Exif
  [SimilarityPrints + BurstGrouper] as Bursts
  [PhotoTrash\ntrash and restore] as Trash
}

database "Card / drive / this Mac\nARW RAF JPG MP4 + .xmp" as Disk
node "Lightroom, Capture One,\nany editor" as Editors
cloud "Apple Maps" as Maps

Keys --> Store
Views --> Store
Store --> Storage
Store --> Scanner
Views --> Previews
Store --> XMP
Views --> Exif
Store --> Bursts
Store --> Trash
Store --> Launcher
Views --> Places
Storage --> Disk
Scanner --> Disk
Previews --> Disk
XMP --> Disk
Trash --> Disk
Bursts --> Previews
Launcher --> Editors
Places --> Maps
@enduml
```

</details>
<!-- /diagram -->

## Opening a shoot

The start screen lists cards (including the Mac's own SD slot), drives and
folders on this Mac. Opening a drive searches at most three levels and 400
folders, and skips camera housekeeping folders. A folder, or every folder on a
card at once, is then scanned in the background and its thumbnails are warmed
so the grid never waits.

Every folder is read through `DirectoryListing`, which asks the file system for
names, kinds and modification dates together, in batches, with
`getattrlistbulk`. `FileManager.contentsOfDirectory` fetches attributes one
file at a time, and on an external drive that is a seek each: a 5,352-file card
folder on a USB hard drive took 54 seconds to list that way, cold, against
33 milliseconds in bulk. Opening a whole 8,240-photo drive went from 175
seconds to under half a second on the same hardware. The same listing also
tells `FolderScanner` which photos have an XMP sidecar, so it opens only those
rather than probing for a file beside every frame.

<!-- diagram:open-shoot -->
![open-shoot](diagrams/open-shoot.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml open-shoot
title Opening a shoot: from the start screen to the grid
actor Photographer as P
participant "Start screen" as Start
participant StorageScanner as SS
participant DirectoryListing as DL
participant LibraryStore as Store
participant FolderScanner as FS
participant XMPSidecar as XMP
participant PreviewLoader as PL
database "Card" as Card

P -> Start: launch
Start -> SS: locations()
SS -> Card: mounted volumes (external, removable, SD slot)
Start <-- SS: cards, drives, Pictures, Movies...
P -> Start: open a drive / Open all
Start -> SS: shootFolders(in: drive)
SS -> DL: entries(of: folder)
DL -> Card: getattrlistbulk: names, kind and\nmodified date, a few thousand per call
note right of DL
  Never FileManager.contentsOfDirectory: that
  fetches attributes a file at a time, which on
  a USB drive is a seek each. A 5,352-file card
  folder took 54 s that way, 33 ms this way.
end note
SS -> SS: up to 3 levels, 400 folders,\nskip THMBNL / SUB / GENERAL
Start <-- SS: DCIM/100MSDCF 3,311 photos\nPRIVATE/M4ROOT/CLIP 42 videos
P -> Start: pick folder(s)
Start -> Store: open(folders)
Store -> FS: scan(folders) (background)
FS -> DL: entries(of: folder)
FS -> FS: pair same-named RAW + JPEG,\nmodified date came with the listing
FS -> XMP: read only the sidecars the listing saw
Store <-- FS: photos in capture order
Store -> PL: one background pass: every thumbnail,\nand the camera out of EXIF while the file is open
PL -> Card: embedded JPEG preview (~30 ms), video frame
Store --> P: grid, and the camera filter fills in as it goes
@enduml
```

</details>
<!-- /diagram -->

## Culling

Every decision is one key. A flag or rating moves to the next photo by itself;
with several photos selected it applies to all of them. Each change is saved to
the photo's XMP sidecar through a queue that writes one file at a time, so two
quick presses can never land out of order. Neighbouring previews load ahead in
both directions; Z decodes the full RAW for a focus check.

The flag segments, the star rating, the file kinds, the cameras and the name
search all narrow the same list, so they combine: 3-stars-and-up RAW frames
from one body is a single view. Ticking more than one choice inside a group
widens that group instead — two cameras shows photos from either. The Filters
button carries a count of the groups in play, and clears them all in one go.
Cameras come from EXIF, which means opening each file, so they are collected by
the background pass that is already loading thumbnails rather than by a pass of
their own: a separate pass over an 8,240-photo drive took over two minutes even
spread across every core, because it is a seek per file. The menu shows how far
that reading has got while it runs.

<!-- diagram:cull-loop -->
![cull-loop](diagrams/cull-loop.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml cull-loop
title Culling: one key per decision
actor Photographer as P
participant KeyCommands as K
participant LibraryStore as S
participant PhotoFilter as F
participant "Save queue\n(one write at a time)" as Q
participant XMPSidecar as X
participant PreviewLoader as L

P -> K: P / X / 1-5 / 6-9
K -> S: setFlag / setRating / setLabel
alt several photos selected (cmd or shift click)
  S -> S: change all of them, stay put
else one photo
  S -> S: change it, move to the next (auto-advance)
end
S -> Q: save(photo)
Q -> X: write culldash:Flag, xmp:Rating, xmp:Label\n(reject = rating -1, Bridge's convention)
S -> L: preload 5 neighbours each side
L --> P: next photo shows at once

group Narrowing the shoot
  P -> S: flag segment, stars, file kinds, cameras, search
  S -> F: matches(photo)
  note right of F
    Each part narrows what the one before it left,
    so they combine. Ticking several inside one
    part widens it: two cameras means either.
  end note
  F --> P: the photos left
end

P -> K: Z
K -> S: toggleZoom
S -> L: decode the full RAW (~750 ms)
@enduml
```

</details>
<!-- /diagram -->

## Looking closely

Z, or a double-click, decodes the RAW whole and shows it pixel for pixel. From
there a mouse wheel zooms around the pointer, a pinch zooms, a two-finger
trackpad scroll pans, and dragging moves the photo under the pointer; the
photo goes from fitting the window to eight times its own pixels, drawn
unsmoothed above 100% so grain and focus read true. Once there is more photo
than fits, a minimap appears in the corner with a box around the part on
screen, and clicking or dragging inside it jumps there.

<!-- diagram:zoom -->
![zoom](diagrams/zoom.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml zoom
title Looking closely: zoom, pan and the minimap
actor Photographer as P
participant LoupeView as Loupe
participant PreviewLoader as PL
participant ZoomScrollView as Scroll
participant ZoomController as Ctl
participant ZoomMinimap as Map

P -> Loupe: Z, or double-click
Loupe -> PL: fullResolution(for: url)
PL --> Loupe: the RAW decoded whole (~750 ms)
Loupe -> Scroll: show(image) at 100%, pixel for pixel

group Zooming
  P -> Scroll: mouse wheel (or cmd/alt + scroll)
  Scroll -> Scroll: scale around the pointer,\nso the pixel under it stays put
  P -> Scroll: pinch on a trackpad
  Scroll -> Scroll: AppKit magnification
  P -> Scroll: two-finger scroll on a trackpad
  Scroll -> Scroll: pan, as everywhere else
end

group Panning
  P -> Scroll: drag
  Scroll -> Scroll: move the photo under the pointer
end

Scroll -> Ctl: scale, fit scale, visible rect
Ctl -> Map: the part on screen, as a fraction
Map --> P: the whole photo small, with a box round where you are
P -> Map: click or drag inside it
Map -> Ctl: centre(on:)
Ctl -> Scroll: scroll there
@enduml
```

</details>
<!-- /diagram -->

## Trimming a clip

A video opened full screen plays like any other clip: Space plays and pauses it
rather than leaving the view, and Return still goes back to the grid. Space
reaches the player through a counter on the store, because the player belongs
to the view while the keys are read from the window.

Editing starts with the pencil button under the clip, which brings out a row of
pieces; until then the row stays out of the way, since most clips are only
watched.

`ClipEdit` holds the clip as the pieces that are **kept**, not the parts cut
away, so a hole is not a thing it can represent: dropping a piece shortens the
row and everything after it slides left. That makes two kinds of position, and
the names say which is which. A *source* time is a moment in the original file;
an *output* time is a moment in what is left, which is what the row draws and
the playhead runs along. `locate(output:)` turns one into the other.

Splitting divides the piece under the playhead in two, which changes nothing
about the result — the row still adds up to the whole clip — so saving stays
unavailable until a piece is dropped. Dropping one removes it; what remains is
already flush, because the pieces are simply concatenated.

Leaving the clip silences it. Stepping to a photo, going back to the grid or
trashing the clip mid-play all take the view away, and a player nobody can see
carries on playing: the periodic time observer keeps it alive, so the sound of
a clip that is no longer on screen, or has just gone to the Trash, goes on. The
view therefore pauses, drops its item and removes that observer as it goes.

The player is handed an `AVComposition` of the pieces rather than the file, so
it plays the edit back and its clock runs in output time. Without that the
playhead would be measuring the original while the row measured the result, and
the two would drift apart the moment anything was cut.

Saving writes the pieces end to end through `AVAssetExportPresetPassthrough`,
which copies the streams rather than re-encoding them: a 4K clip is written
about as fast as it can be read and comes out identical to the source. The cost
is that each cut lands on the keyframe before the mark, which on long-GOP
footage can be a second early — the same trade QuickTime makes. The result goes
beside the original as `<name>-trimmed.MOV`, or takes the original's place, in
which case the original goes to that drive's Trash and joins the undo history,
so ⌘Z brings the full-length clip back.

Either way the shoot is told about it. A new clip is inserted beside the one it
came from, carrying that clip's capture date and its decisions, so it sorts in
next to its source and arrives already flagged and rated the same; the
selection does not move. Without that the file would exist only on the card
until the folder was opened again.

<!-- diagram:trim-clip -->
![trim-clip](diagrams/trim-clip.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml trim-clip
title Editing a clip: split, drop, save
actor Photographer as P
participant ClipEditor as Editor
participant ClipTrimBar as Row
participant ClipEdit as Edit
participant ClipExporter as Exporter
participant PhotoTrash as Trash
participant LibraryStore as Store

P -> Editor: open a clip full screen
Editor --> P: the clip, its length, and a pencil button
P -> Editor: Space
Editor -> Editor: play or pause
note right of Editor
  Space reaches the player through the store:
  the player is the view's own, the keys are read
  from the window. Return still goes back to the grid.
end note

P -> Editor: pencil
Editor -> Edit: ClipEdit(duration:) — the whole clip, in one piece
Editor --> P: the row of pieces appears

group Splitting and dropping
  P -> Row: drag along the row
  Row -> Editor: scrub to that output time
  P -> Editor: scissors
  Editor -> Edit: split(atOutput: the playhead)
  note right of Edit
    The row still adds up to the whole clip,
    so there is still nothing to save.
  end note
  P -> Row: click a piece
  P -> Editor: trash
  Editor -> Edit: remove(at: that piece)
  Edit --> Row: a shorter row; what followed slides left
  note right of Edit
    Pieces are the parts KEPT, so a hole is not
    something this can hold. They are simply
    laid end to end.
  end note
  Editor -> Exporter: preview(of:edit:)
  Exporter --> Editor: an AVComposition of the pieces
  Editor -> Editor: play that, not the file
  note right of Editor
    So the player's clock runs in output time,
    the same time the row is drawn in. Otherwise
    the playhead would measure the original while
    the row measured the result.
  end note
end

group Saving
  P -> Editor: save, then a new clip or the original's place
  Editor -> Exporter: export(url, edit, to:)
  Exporter -> Exporter: the pieces end to end, written with\nAVAssetExportPresetPassthrough
  note right of Exporter
    Streams are copied, never re-encoded: as fast
    as the clip reads, identical to the source. Cuts
    land on the keyframe before the mark, as in
    QuickTime.
  end note

  alt saved as a new clip
    Exporter --> Editor: <name>-trimmed.MOV beside the original
    Editor -> Store: noteNewClip(at:from:)
    Store -> Store: insert beside the source, with its\ncapture date and its decisions
    Store --> P: it is in the grid, next to the one it came from
  else replacing the original
    Exporter -> Trash: trash(original)
    Exporter -> Exporter: move the edit to the original's name
    Editor -> Store: noteReplacedClip(trashed)
    Store --> P: "C0007.MP4 replaced · Cmd-Z to undo"
    P -> Store: Cmd-Z
    Store -> Trash: trash the edit, then restore the original
    note right of Store
      In that order: the edit holds the name the
      original wants back, so it has to move first.
    end note
  end
end
@enduml
```

</details>
<!-- /diagram -->

## A photo's states

<!-- diagram:photo-states -->
![photo-states](diagrams/photo-states.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml photo-states
title A photo's states
[*] --> Unflagged : found on the card
Unflagged --> Picked : P
Unflagged --> Rejected : X
Picked --> Rejected : X
Rejected --> Picked : P
Picked --> Unflagged : U
Rejected --> Unflagged : U or a star rating
Rejected --> Rejected : R (rest of a burst)
Unflagged --> Trashed : Delete
Picked --> Trashed : Delete
Rejected --> Trashed : Delete / Trash rejects
Trashed --> Unflagged : Cmd-Z (back where it was,\nflag kept in its sidecar)
Picked --> Sent : Send to (with stars and labels)
Sent --> [*]
Trashed --> [*] : Trash emptied
@enduml
```

</details>
<!-- /diagram -->

## Similar shots

Grouping uses capture time and Apple's on-device Vision feature prints. The
thresholds were measured on real Sony a6400 portraits: re-takes of one pose were
0.21 to 0.49 apart, different set-ups 0.56 and more.

<!-- diagram:similar -->
![similar](diagrams/similar.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml similar
title Similar: grouping bursts and re-takes
start
:Similar switched on;
:Read each photo's capture time\n(EXIF with hundredths, else file date);
:Sort by time;
repeat :Next frame;
  if (More than 60 s after the previous?) then (yes)
    :Start a new group;
  else (no)
    :Vision feature print of both previews\n(on this Mac);
    if (Distance under 0.6 within 1.5 s,\nor under 0.5 otherwise?) then (yes)
      :Same group;
    else (no)
      :Start a new group;
    endif
  endif
repeat while (frames left?) is (yes)
:Grid shows each group as a section;
:Photographer picks keepers, presses R;
:The rest of the group is rejected;
stop
@enduml
```

</details>
<!-- /diagram -->

## Trash and Send to

Files only ever go to the Trash on their own drive, with their JPEG and sidecar,
and ⌘Z moves them back. Sending opens exactly the photos shown in the chosen
editor after all sidecars are written, so stars and labels arrive with them.
Lightroom does not read picks from other apps, so keepers should carry a star or
a label.

<!-- diagram:handoffs -->
![handoffs](diagrams/handoffs.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml handoffs
title Hand-offs: Trash with undo, and Send to an editor
actor Photographer as P
participant LibraryStore as S
participant PhotoTrash as T
participant EditorLauncher as E
participant "Lightroom" as LR
database "Drive" as D

== Trash ==
P -> S: Delete, or Trash rejects
S -> S: finish pending sidecar writes
S -> T: trash(photo)
T -> D: move RAW, JPEG and .xmp to that drive's Trash
S <-- T: where each file went
S -> S: remember for undo
P -> S: Cmd-Z
S -> T: restore(files)
T -> D: move them back

== Send to ==
P -> S: Send N to... Lightroom
S -> S: finish pending sidecar writes
S -> E: open(shown photos, in: Lightroom)
E -> LR: open files (starts an import of exactly these)
LR -> D: reads stars and labels from the sidecars
@enduml
```

</details>
<!-- /diagram -->

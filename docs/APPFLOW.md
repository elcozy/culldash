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
folders, so even a large archive drive answers in seconds, and skips camera
housekeeping folders. A folder, or every folder on a card at once, is then
scanned in the background and its thumbnails are warmed so the grid never waits.

<!-- diagram:open-shoot -->
![open-shoot](diagrams/open-shoot.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml open-shoot
title Opening a shoot: from the start screen to the grid
actor Photographer as P
participant "Start screen" as Start
participant StorageScanner as SS
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
SS -> Card: read up to 3 levels, 400 folders,\nskip THMBNL / SUB / GENERAL
Start <-- SS: DCIM/100MSDCF 3,311 photos\nPRIVATE/M4ROOT/CLIP 42 videos
P -> Start: pick folder(s)
Start -> Store: open(folders)
Store -> FS: scan(folders) (background)
FS -> Card: list files, pair same-named RAW + JPEG
FS -> XMP: read existing sidecars
Store <-- FS: photos in capture order
Store -> PL: warm every thumbnail (background)
PL -> Card: embedded JPEG preview (~30 ms), video frame
Store --> P: grid
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

<!-- diagram:cull-loop -->
![cull-loop](diagrams/cull-loop.svg)

<details><summary>PlantUML source</summary>

```plantuml
@startuml cull-loop
title Culling: one key per decision
actor Photographer as P
participant KeyCommands as K
participant LibraryStore as S
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
P -> K: Z
K -> S: toggleZoom
S -> L: decode the full RAW (~750 ms)
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

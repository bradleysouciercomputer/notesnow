# NotesNow

A clean, personal notes workspace built with Google's official Material 3 Web Components.

## Features

- Create, edit, and organize notes
- Pin important notes
- Add labels and choose from six note colors
- Archive notes or move them to Trash; restore or permanently delete them later
- Search note titles, text, and labels
- Sort by last edited, creation date, or title
- Switch between grid and list layouts
- Light and dark themes
- Export a JSON backup and import it again later
- Responsive layout for desktop, tablet, and mobile

## Run locally

This is a static website. Open `index.html` through a local web server, or publish the repository with GitHub Pages. There is no build step and no backend is required.

The app uses the official `@material/web` package from the `esm.run` CDN, with Google's Roboto typeface and Material Symbols.

Interactive controls use official Material Web components (buttons, FABs, chips, selects, text fields, checkboxes, dialogs, and icon buttons). Material Web does not currently ship dedicated card, navigation-drawer, or snackbar components, so those app-specific surfaces are composed from Material 3 system color, typography, and shape tokens rather than being presented as library components.

## GitHub Pages

In the repository, open **Settings → Pages** and choose:

1. **Deploy from a branch**
2. Branch: **main**
3. Folder: **/(root)**
4. Select **Save**

The site will be available at:

https://bradleysouciercomputer.github.io/notesnow/

## Privacy and backups

Notes are stored in this browser's local storage on this device. They are not uploaded to a server and do not automatically sync across browsers or devices. Clearing this browser's site data can remove locally stored notes, so use **Export notes** periodically to keep a backup. Use **Import notes** to add a backup to the current browser.

Because Material Web and the fonts are loaded from their CDNs, an internet connection is required for the full Material 3 styling and controls to load.

# Browser theme: Kuro Nezumi

## Use Dark Reader for all websites

Use **Dark Reader** in **Dynamic** mode. Unlike one global stylesheet, it
analyzes each site and keeps images/media readable while adapting page colors.

Set its custom dark colors to:

| Setting | Value |
|---|---|
| Background | `#080808` |
| Text | `#D7D2C8` |
| Contrast | `90` |
| Brightness | `100` |
| Sepia | `0` |

If a page already has a good native dark mode (such as X), turn Dark Reader off
for that site from its popup. This avoids applying two dark themes at once.

## Stylus is now safe

The global [kuro-nezumi.user.css](kuro-nezumi.user.css) intentionally contains
only a `color-scheme` hint. It no longer recolors arbitrary page cards, buttons,
or text. Disable the old active Kuro Nezumi style in Stylus and re-import this
file if you want to retain the harmless global hint.

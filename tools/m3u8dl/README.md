# m3u8dl

Minimal interactive HLS (`.m3u8`) downloader. Reads a master playlist, shows the
available qualities, queues what you pick, and downloads the queue in order with
`ffmpeg -c copy`, waiting for each item's scheduled start time.

Two dependencies: `go` (build) and `ffmpeg` + `ffprobe`-free runtime (just `ffmpeg`).

## Build

```sh
cd tools/m3u8dl && go build -o ~/.local/bin/m3u8dl .
# or simply:
go install ./tools/m3u8dl
```

## Use

```sh
m3u8dl                     # interactive prompt
m3u8dl add <url>           # inspect, pick quality, schedule, queue
m3u8dl list                # show the queue
m3u8dl run                 # download in queue order, honouring schedule times
```

Interactive session:

```
m3u8dl> add https://host/path/master.m3u8
  #  RESOLUTION   BITRATE     CODECS
  1  256x144      265 kbps    avc1.4d400c,mp4a.40.2
  ...
  6  1920x1080    3.7 Mbps    avc1.4d4028,mp4a.40.2

select quality (number, 1080p, best, worst, all) [best]: 1080p
schedule start (now, +30m, 21:30, '2026-11-18 09:00') [now]: +45m
```

Quality selectors: index (`3`), list (`1,3`), resolution (`1080p`, `1920x1080`),
or `best` / `worst` / `all`.

### Scheduling

`run` downloads strictly in queue order and sleeps until each item's own time, so
a queue can be spread across the evening:

```sh
m3u8dl add <url> -q best  -at now
m3u8dl add <url> -q best  -at +30m
m3u8dl add <url> -q 720p  -at 23:00
m3u8dl add <url> -q best  -at '2026-11-18 09:00'
m3u8dl run
```

Accepted forms: `now`, `+30m`, `+1h15m`, `21:30` (rolls to tomorrow if past),
`2026-11-18 09:00`, `tomorrow`. Re-schedule later with `sched <id> <when>`.

Because items download sequentially, an item whose time is already past starts as
soon as the previous one finishes — the schedule is a "not before" time, never a
skip.

### Metadata and naming

Whatever the playlist exposes is captured:

- `#EXT-X-SESSION-DATA:…VALUE="…"` → title, used for the filename
- `#EXT-X-PROGRAM-DATE-TIME` → stream timestamp, prefixed to the filename
  (`2026-11-18_093000 Lecture 4- Intro to Algebra.mp4`) and shown in `list`
- `#EXTINF` sums → duration shown in the queue

Anything missing is derived from the URL (`…/720P_4000K_389762651.mp4/master.m3u8`
→ `720P_4000K_389762651.mp4`). Override with `-o NAME`.

### Headers

Some CDNs check `Referer`/`Origin`, and some reject a non-browser
`User-Agent`. Configure a default set once, naming the origin the stream expects:

```sh
m3u8dl preset referer https://example.com   # Origin + Referer + desktop UA
m3u8dl preset browser                       # UA only
m3u8dl header list
m3u8dl header add 'Referer: https://example.com/'
```

Or set them per item, which overrides the configured set:

```sh
m3u8dl add <url> -H 'Origin: https://example.com/' \
                 -H 'Referer: https://example.com/' \
                 -H 'User-Agent: Mozilla/5.0 …'
```

Headers are sent both by the playlist fetcher and by ffmpeg (for the media
segments). A default desktop UA is used when none is configured.

## Other commands

| command | purpose |
| --- | --- |
| `probe <url>` | show qualities/metadata without queueing |
| `sched <id> <when>` | change an item's start time (also retries failed items) |
| `retry <id...>` | requeue failed items |
| `rm <id...>` | remove items |
| `clear [done\|failed\|all]` | drop finished items (default `done`) |
| `dir [path]` | show/set the download directory (default `~/Downloads/m3u8dl`) |

## Files

- queue: `$XDG_STATE_HOME/m3u8dl/queue.json` (default `~/.local/state/m3u8dl/`)
- config: `$XDG_CONFIG_HOME/m3u8dl/config.json` (default `~/.config/m3u8dl/`)

Writes are atomic, so an interrupted `run` leaves the queue intact. Ctrl-C stops
the current ffmpeg and keeps the item pending; `run` again resumes from it.
Partial output is written as `.<name>.partial.mp4` and renamed only on success,
so an interrupted download never leaves a truncated file in place.

## Notes

- Downloads are a straight remux (`-c copy`); nothing is re-encoded.
- AES-128 (`#EXT-X-KEY`) playlists are handled by ffmpeg.
- Separate-audio masters (audio renditions) are merged as a second input.
- Live playlists (no `#EXT-X-ENDLIST`) are flagged by `probe`.
- Local progress is drawn on a TTY only, so piped logs stay clean.

## Test

```sh
cd tools/m3u8dl && go test ./...
```

Tests cover attribute/playlist parsing, quality selection, schedule parsing,
naming collisions, and queue recovery. They do not hit the network.

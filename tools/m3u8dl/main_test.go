package main

import (
	"net/url"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func mustURL(t *testing.T, s string) *url.URL {
	t.Helper()
	u, err := url.Parse(s)
	if err != nil {
		t.Fatalf("parse %q: %v", s, err)
	}
	return u
}

func TestParseAttrs(t *testing.T) {
	got := parseAttrs(`PROGRAM-ID=1,BANDWIDTH=2734048,RESOLUTION=1280x720,CODECS="avc1.4d401f,mp4a.40.2",AUDIO="aud",DEFAULT=YES`)
	want := map[string]string{
		"PROGRAM-ID": "1",
		"BANDWIDTH":  "2734048",
		"RESOLUTION": "1280x720",
		"CODECS":     "avc1.4d401f,mp4a.40.2",
		"AUDIO":      "aud",
		"DEFAULT":    "YES",
	}
	for k, v := range want {
		if got[k] != v {
			t.Errorf("%s = %q, want %q", k, got[k], v)
		}
	}
	if len(got) != len(want) {
		t.Errorf("got %d attrs, want %d: %v", len(got), len(want), got)
	}
}

func TestParsePlaylistMaster(t *testing.T) {
	base := mustURL(t, "https://cdn.example/x/h_,144_200,1080_3395,k.mp4.list/master.m3u8")
	body := []byte(`#EXTM3U
#EXT-X-SESSION-DATA:DATA-ID="title",VALUE="Lecture 4: Algebra"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="Persian",LANGUAGE="fa",DEFAULT=YES,URI="audio/fa.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="English",LANGUAGE="en",URI="audio/en.m3u8"
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=265843,RESOLUTION=256x144
index-f1.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=3675716,RESOLUTION=1920x1080,AUDIO="aud"
index-f6.m3u8
`)
	p, err := parsePlaylist(body, base)
	if err != nil {
		t.Fatal(err)
	}
	if !p.isMaster {
		t.Fatal("expected master playlist")
	}
	if len(p.variants) != 2 || len(p.renditions) != 2 {
		t.Fatalf("variants=%d renditions=%d", len(p.variants), len(p.renditions))
	}
	if p.title != "Lecture 4: Algebra" {
		t.Errorf("title = %q", p.title)
	}
	if want := "https://cdn.example/x/h_,144_200,1080_3395,k.mp4.list/index-f1.m3u8"; p.variants[0].URL != want {
		t.Errorf("variant URL = %q, want %q", p.variants[0].URL, want)
	}
	if want := "https://cdn.example/x/h_,144_200,1080_3395,k.mp4.list/audio/fa.m3u8"; p.renditions[0].URI != want {
		t.Errorf("rendition URI = %q, want %q", p.renditions[0].URI, want)
	}
	if got := audioURIFor(p, p.variants[1]); got != p.renditions[0].URI {
		t.Errorf("audioURIFor = %q, want default rendition %q", got, p.renditions[0].URI)
	}
	if got := audioURIFor(p, p.variants[0]); got != "" {
		t.Errorf("audioURIFor variant without AUDIO = %q, want empty", got)
	}
}

func TestParsePlaylistMedia(t *testing.T) {
	base := mustURL(t, "https://cdn.example/x/index-f6.m3u8")
	body := []byte(`#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-KEY:METHOD=AES-128,URI="enc.key"
#EXT-X-PROGRAM-DATE-TIME:2026-11-18T09:30:00+03:30
#EXTINF:6.000,
seg-1.ts
#EXTINF:1.323,
seg-2.ts
#EXT-X-ENDLIST
`)
	p, err := parsePlaylist(body, base)
	if err != nil {
		t.Fatal(err)
	}
	if p.isMaster {
		t.Fatal("did not expect a master playlist")
	}
	if p.segments != 2 {
		t.Errorf("segments = %d, want 2", p.segments)
	}
	if p.duration < 7 || p.duration > 8 {
		t.Errorf("duration = %v, want ~7.3", p.duration)
	}
	if !p.encrypted {
		t.Error("expected encrypted")
	}
	if p.live {
		t.Error("expected VOD (ENDLIST present)")
	}
	if p.date == nil || p.date.UTC().Format(time.RFC3339) != "2026-11-18T06:00:00Z" {
		t.Errorf("date = %v", p.date)
	}
}

func TestParsePlaylistRejectsNonHLS(t *testing.T) {
	base := mustURL(t, "https://cdn.example/")
	if _, err := parsePlaylist([]byte("<html><body>error</body></html>"), base); err == nil {
		t.Fatal("expected error for HTML body")
	}
}

func TestSelectVariants(t *testing.T) {
	p := &playlist{variants: []variant{
		{URL: "low", Bandwidth: 265843, Resolution: "256x144"},
		{URL: "mid", Bandwidth: 2734048, Resolution: "1280x720"},
		{URL: "high", Bandwidth: 3675716, Resolution: "1920x1080"},
	}}

	cases := []struct {
		sel  string
		want []string
	}{
		{"best", []string{"high"}},
		{"worst", []string{"low"}},
		{"all", []string{"high", "mid", "low"}},
		{"1", []string{"low"}},
		{"1,3", []string{"low", "high"}},
		{"720p", []string{"mid"}},
		{"1920x1080", []string{"high"}},
		{"1080", []string{"high"}},
	}
	for _, c := range cases {
		idxs, err := selectVariants(p, c.sel)
		if err != nil {
			t.Errorf("%q: %v", c.sel, err)
			continue
		}
		var got []string
		for _, i := range idxs {
			got = append(got, p.variants[i].URL)
		}
		if len(got) != len(c.want) {
			t.Errorf("%q: got %v, want %v", c.sel, got, c.want)
			continue
		}
		for i := range got {
			if got[i] != c.want[i] {
				t.Errorf("%q: got %v, want %v", c.sel, got, c.want)
			}
		}
	}

	for _, bad := range []string{"9999", "4k", "0"} {
		if _, err := selectVariants(p, bad); err == nil {
			t.Errorf("%q: expected error", bad)
		}
	}
}

func TestParseWhen(t *testing.T) {
	now := time.Date(2026, 11, 17, 21, 0, 0, 0, time.Local)

	if got, _ := parseWhen("", now); !got.Equal(now) {
		t.Errorf("empty = %v, want now", got)
	}
	if got, _ := parseWhen("now", now); !got.Equal(now) {
		t.Errorf("now = %v", got)
	}
	if got, _ := parseWhen("+30m", now); !got.Equal(now.Add(30 * time.Minute)) {
		t.Errorf("+30m = %v", got)
	}
	if got, _ := parseWhen("23:30", now); !got.Equal(time.Date(2026, 11, 17, 23, 30, 0, 0, time.Local)) {
		t.Errorf("23:30 = %v", got)
	}
	// A time already past today rolls to tomorrow.
	if got, _ := parseWhen("09:00", now); !got.Equal(time.Date(2026, 11, 18, 9, 0, 0, 0, time.Local)) {
		t.Errorf("09:00 = %v, want tomorrow", got)
	}
	if got, _ := parseWhen("2026-12-01 08:15", now); !got.Equal(time.Date(2026, 12, 1, 8, 15, 0, 0, time.Local)) {
		t.Errorf("absolute = %v", got)
	}
	for _, bad := range []string{"soon", "+xyz", "25:00"} {
		if _, err := parseWhen(bad, now); err == nil {
			t.Errorf("%q: expected error", bad)
		}
	}
}

func TestNamingHelpers(t *testing.T) {
	if got := sanitize("Lecture 4: Intro/Outro?"); got != "Lecture 4- Intro-Outro" {
		t.Errorf("sanitize = %q", got)
	}
	if got := sanitize("  ..name.  "); got != "name" {
		t.Errorf("sanitize trim = %q", got)
	}
	if got := shortQuality(variant{Resolution: "1920x1080"}); got != "1080p" {
		t.Errorf("shortQuality = %q", got)
	}
	if got := shortQuality(variant{Bandwidth: 265843}); got != "265k" {
		t.Errorf("shortQuality by bandwidth = %q", got)
	}
	if base, ext := splitExt("show.mkv"); base != "show" || ext != ".mkv" {
		t.Errorf("splitExt mkv = %q %q", base, ext)
	}
	if base, ext := splitExt("weird.txt"); base != "weird.txt" || ext != ".mp4" {
		t.Errorf("splitExt unknown = %q %q", base, ext)
	}
	cases := map[string]string{
		"https://cdn.example/hls/videos/202106/17/389762651/720P_4000K_389762651.mp4/master.m3u8": "720P_4000K_389762651",
		"https://site.example/abc123/GmXWQ2LPgx/index-f6-v1-a1.m3u8":                              "GmXWQ2LPgx",
		"https://site.example/abc123/GmXWQ2LPgx/h_,144_200,1080_3395,k.mp4.list/master.m3u8":      "GmXWQ2LPgx",
	}
	for raw, want := range cases {
		if got := nameFromURL(raw); got != want {
			t.Errorf("nameFromURL(%q) = %q, want %q", raw, got, want)
		}
	}
}

func TestSplitArgs(t *testing.T) {
	got, err := splitArgs(`add "https://x.test/a b.m3u8" -q 720p -o 'my show'`)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"add", "https://x.test/a b.m3u8", "-q", "720p", "-o", "my show"}
	if len(got) != len(want) {
		t.Fatalf("got %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("[%d] = %q, want %q", i, got[i], want[i])
		}
	}
	if _, err := splitArgs(`add "unterminated`); err == nil {
		t.Error("expected error for unbalanced quotes")
	}
}

func TestParseAddFlagsURLPosition(t *testing.T) {
	f, err := parseAddFlags([]string{"-q", "worst", "https://x.test/m.m3u8", "-at", "+5m"})
	if err != nil {
		t.Fatal(err)
	}
	if f.url != "https://x.test/m.m3u8" {
		t.Errorf("url = %q", f.url)
	}
	if f.quality != "worst" {
		t.Errorf("quality = %q", f.quality)
	}
	if f.when != "+5m" {
		t.Errorf("when = %q", f.when)
	}
}

func TestHeaders(t *testing.T) {
	hs := []string{"Referer: https://a.test/", "User-Agent: X/1.0"}
	want := "Referer: https://a.test/\r\nUser-Agent: X/1.0\r\n"
	if got := headerBlock(hs); got != want {
		t.Errorf("headerBlock = %q, want %q", got, want)
	}
	if !hasHeader(hs, "user-agent") {
		t.Error("hasHeader should be case-insensitive")
	}
	if hasHeader(hs, "Origin") {
		t.Error("hasHeader false positive")
	}
}

func TestUniqueFilename(t *testing.T) {
	dir := t.TempDir()
	q := &queue{Items: []item{{Filename: "a.mp4", Status: stPending}}}
	taken := map[string]bool{}

	if got := uniqueFilename(dir, "a.mp4", q, taken); got != "a (2).mp4" {
		t.Errorf("queue collision = %q", got)
	}
	if got := uniqueFilename(dir, "b.mp4", q, taken); got != "b.mp4" {
		t.Errorf("first b = %q", got)
	}
	if got := uniqueFilename(dir, "b.mp4", q, taken); got != "b (2).mp4" {
		t.Errorf("batch collision = %q", got)
	}

	if err := os.WriteFile(filepath.Join(dir, "c.mp4"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	if got := uniqueFilename(dir, "c.mp4", q, taken); got != "c (2).mp4" {
		t.Errorf("disk collision = %q", got)
	}
}

func TestQueueLoadDropsStaleDownloading(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_STATE_HOME", dir)
	path := queuePath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	body := `{"version":1,"next_id":2,"items":[{"id":1,"status":"downloading","filename":"a.mp4"}]}`
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	q, err := loadQueue()
	if err != nil {
		t.Fatal(err)
	}
	if q.Items[0].Status != stPending {
		t.Errorf("status = %q, want pending", q.Items[0].Status)
	}
	if q.NextID != 2 {
		t.Errorf("next id = %d, want 2", q.NextID)
	}
}

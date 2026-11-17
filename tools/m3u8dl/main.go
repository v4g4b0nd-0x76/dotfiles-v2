// Command m3u8dl is a small interactive HLS (m3u8) downloader.
//
// It inspects a master playlist, shows the available renditions, lets you queue
// one or all of them, and downloads the queue in order with ffmpeg, waiting for
// each item's scheduled start time. Whatever metadata the playlist exposes
// (session title, program date-time, duration) is captured and used for naming.
//
// Run with no arguments for the interactive prompt, or:
//
//	m3u8dl add <url> [-q best|worst|all|1080p|1,3] [-o NAME] [-at WHEN] [-H 'K: V'] [-y]
//	m3u8dl list
//	m3u8dl run
package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const version = "0.1.0"

const defaultUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36"

const (
	stPending     = "pending"
	stDownloading = "downloading"
	stDone        = "done"
	stFailed      = "failed"
)

var (
	errInterrupted = errors.New("interrupted")
	httpc          = &http.Client{Timeout: 90 * time.Second}
)

// ---------------------------------------------------------------- metadata --

type rendition struct {
	Group   string `json:"group"`
	Name    string `json:"name"`
	Lang    string `json:"lang"`
	URI     string `json:"uri"`
	Default bool   `json:"default"`
}

type variant struct {
	URL        string `json:"url"`
	Attrs      string `json:"attrs"`
	Bandwidth  int    `json:"bandwidth"`
	Resolution string `json:"resolution"`
	Codecs     string `json:"codecs"`
	AudioGroup string `json:"audio_group"`
}

type playlist struct {
	isMaster   bool
	variants   []variant
	renditions []rendition
	title      string
	date       *time.Time
	duration   float64
	segments   int
	encrypted  bool
	live       bool
}

// ------------------------------------------------------------------ config --

type config struct {
	Dir     string   `json:"download_dir"`
	Headers []string `json:"headers"`
	Retries int      `json:"retries"`
	FFmpeg  string   `json:"ffmpeg"`
}

func defaultConfig() *config {
	return &config{Dir: "~/Downloads/m3u8dl", Retries: 2, FFmpeg: "ffmpeg"}
}

func loadConfig() *config {
	cfg := defaultConfig()
	b, err := os.ReadFile(configPath())
	if err == nil {
		_ = json.Unmarshal(b, cfg)
	}
	if cfg.Dir == "" {
		cfg.Dir = defaultConfig().Dir
	}
	if cfg.FFmpeg == "" {
		cfg.FFmpeg = "ffmpeg"
	}
	if cfg.Retries < 0 {
		cfg.Retries = 0
	}
	return cfg
}

func saveConfig(cfg *config) error {
	if err := os.MkdirAll(filepath.Dir(configPath()), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return writeFileAtomic(configPath(), append(b, '\n'), 0o644)
}

// ------------------------------------------------------------------- queue --

type item struct {
	ID         int        `json:"id"`
	URL        string     `json:"url"`
	VariantURL string     `json:"variant_url"`
	AudioURL   string     `json:"audio_url,omitempty"`
	Quality    string     `json:"quality"`
	Bandwidth  int        `json:"bandwidth,omitempty"`
	Codecs     string     `json:"codecs,omitempty"`
	Title      string     `json:"title,omitempty"`
	StreamTime *time.Time `json:"stream_time,omitempty"`
	Duration   float64    `json:"duration,omitempty"`
	Filename   string     `json:"filename"`
	Dir        string     `json:"dir"`
	Headers    []string   `json:"headers,omitempty"`
	Status     string     `json:"status"`
	ScheduleAt time.Time  `json:"schedule_at"`
	AddedAt    time.Time  `json:"added_at"`
	DoneAt     *time.Time `json:"done_at,omitempty"`
	Error      string     `json:"error,omitempty"`
}

type queue struct {
	Version int    `json:"version"`
	NextID  int    `json:"next_id"`
	Items   []item `json:"items"`
}

func loadQueue() (*queue, error) {
	q := &queue{Version: 1, NextID: 1}
	b, err := os.ReadFile(queuePath())
	if errors.Is(err, os.ErrNotExist) {
		return q, nil
	}
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(b, q); err != nil {
		return nil, fmt.Errorf("queue file %s: %w", queuePath(), err)
	}
	if q.NextID < 1 {
		q.NextID = 1
	}
	for i := range q.Items {
		if q.Items[i].Status == stDownloading {
			q.Items[i].Status = stPending
		}
		if q.Items[i].ID >= q.NextID {
			q.NextID = q.Items[i].ID + 1
		}
	}
	return q, nil
}

func saveQueue(q *queue) error {
	if err := os.MkdirAll(filepath.Dir(queuePath()), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(q, "", "  ")
	if err != nil {
		return err
	}
	return writeFileAtomic(queuePath(), append(b, '\n'), 0o644)
}

func writeFileAtomic(path string, data []byte, mode os.FileMode) error {
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".tmp*")
	if err != nil {
		return err
	}
	name := tmp.Name()
	defer os.Remove(name)
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Chmod(name, mode); err != nil {
		return err
	}
	return os.Rename(name, path)
}

// ------------------------------------------------------------------- paths --

func homeDir() string {
	if h, err := os.UserHomeDir(); err == nil {
		return h
	}
	return "."
}

func xdgDir(env, fallback string) string {
	if p := os.Getenv(env); p != "" {
		return p
	}
	return filepath.Join(homeDir(), fallback)
}

func configPath() string {
	return filepath.Join(xdgDir("XDG_CONFIG_HOME", ".config"), "m3u8dl", "config.json")
}

func queuePath() string {
	return filepath.Join(xdgDir("XDG_STATE_HOME", filepath.Join(".local", "state")), "m3u8dl", "queue.json")
}

func expandPath(p string) string {
	p = strings.TrimSpace(p)
	if p == "~" {
		return homeDir()
	}
	if strings.HasPrefix(p, "~/") {
		return filepath.Join(homeDir(), p[2:])
	}
	return p
}

// ------------------------------------------------------------------ parsing --

func parseAttrs(s string) map[string]string {
	m := map[string]string{}
	i := 0
	for i < len(s) {
		for i < len(s) && (s[i] == ',' || s[i] == ' ' || s[i] == '\t') {
			i++
		}
		start := i
		for i < len(s) && s[i] != '=' && s[i] != ',' {
			i++
		}
		key := strings.TrimSpace(s[start:i])
		if i >= len(s) || s[i] != '=' {
			if key != "" {
				m[key] = ""
			}
			break
		}
		i++ // '='
		var val string
		if i < len(s) && s[i] == '"' {
			i++
			var b strings.Builder
			for i < len(s) && s[i] != '"' {
				if s[i] == '\\' && i+1 < len(s) {
					i++
				}
				b.WriteByte(s[i])
				i++
			}
			i++ // closing quote
			val = b.String()
		} else {
			start = i
			for i < len(s) && s[i] != ',' {
				i++
			}
			val = strings.TrimSpace(s[start:i])
		}
		if key != "" {
			m[key] = val
		}
	}
	return m
}

func atoi(s string) int {
	n, _ := strconv.Atoi(strings.TrimSpace(s))
	return n
}

func parsePlaylist(body []byte, base *url.URL) (*playlist, error) {
	trimmed := bytes.TrimSpace(body)
	if !bytes.HasPrefix(trimmed, []byte("#EXTM3U")) {
		return nil, errors.New("not an HLS playlist (missing #EXTM3U)")
	}
	p := &playlist{}
	var pending *variant
	ended := false

	sc := bufio.NewScanner(bytes.NewReader(body))
	sc.Buffer(make([]byte, 0, 64*1024), 8<<20)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		switch {
		case line == "" || line == "#EXTM3U":
		case strings.HasPrefix(line, "#EXT-X-STREAM-INF:"):
			attrs := line[len("#EXT-X-STREAM-INF:"):]
			m := parseAttrs(attrs)
			v := variant{
				Attrs:      attrs,
				Bandwidth:  atoi(m["BANDWIDTH"]),
				Resolution: m["RESOLUTION"],
				Codecs:     m["CODECS"],
				AudioGroup: m["AUDIO"],
			}
			p.variants = append(p.variants, v)
			pending = &p.variants[len(p.variants)-1]
		case strings.HasPrefix(line, "#EXT-X-MEDIA:"):
			m := parseAttrs(line[len("#EXT-X-MEDIA:"):])
			r := rendition{
				Group:   m["GROUP-ID"],
				Name:    m["NAME"],
				Lang:    m["LANGUAGE"],
				Default: strings.EqualFold(m["DEFAULT"], "YES"),
			}
			if raw := m["URI"]; raw != "" {
				if u, err := base.Parse(raw); err == nil {
					r.URI = u.String()
				}
			}
			p.renditions = append(p.renditions, r)
		case strings.HasPrefix(line, "#EXT-X-SESSION-DATA:"):
			m := parseAttrs(line[len("#EXT-X-SESSION-DATA:"):])
			if p.title == "" && m["VALUE"] != "" {
				p.title = m["VALUE"]
			}
		case strings.HasPrefix(line, "#EXT-X-PROGRAM-DATE-TIME:"):
			if p.date == nil {
				p.date = parseDateTime(strings.TrimSpace(line[len("#EXT-X-PROGRAM-DATE-TIME:"):]))
			}
		case strings.HasPrefix(line, "#EXTINF:"):
			spec := line[len("#EXTINF:"):]
			if c := strings.IndexByte(spec, ','); c >= 0 {
				spec = spec[:c]
			}
			if f, err := strconv.ParseFloat(strings.TrimSpace(spec), 64); err == nil && f > 0 {
				p.duration += f
			}
		case strings.HasPrefix(line, "#EXT-X-KEY:"):
			m := parseAttrs(line[len("#EXT-X-KEY:"):])
			if method := strings.ToUpper(m["METHOD"]); method != "" && method != "NONE" {
				p.encrypted = true
			}
		case line == "#EXT-X-ENDLIST":
			ended = true
		case strings.HasPrefix(line, "#"):
			// ignore other tags
		default:
			u, err := base.Parse(line)
			if err != nil {
				continue
			}
			if pending != nil {
				pending.URL = u.String()
				pending = nil
				p.isMaster = true
			} else {
				p.segments++
			}
		}
	}
	if err := sc.Err(); err != nil {
		return nil, err
	}
	if len(p.variants) > 0 || len(p.renditions) > 0 {
		p.isMaster = true
	}
	p.live = !p.isMaster && !ended
	return p, nil
}

func parseDateTime(s string) *time.Time {
	layouts := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05.000Z0700",
		"2006-01-02T15:04:05Z0700",
	}
	for _, l := range layouts {
		if t, err := time.Parse(l, s); err == nil {
			return &t
		}
	}
	return nil
}

// -------------------------------------------------------------------- fetch --

func fetch(ctx context.Context, rawURL string, headers []string) ([]byte, *url.URL, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
	if err != nil {
		return nil, nil, err
	}
	for _, h := range headers {
		k, v := splitHeader(h)
		if k == "" {
			continue
		}
		req.Header.Set(k, v)
	}
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", defaultUA)
	}
	resp, err := httpc.Do(req)
	if err != nil {
		return nil, nil, fmt.Errorf("fetch: %w", err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 32<<20))
	if err != nil {
		return nil, nil, fmt.Errorf("fetch: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		hint := ""
		if bytes.HasPrefix(bytes.TrimSpace(body), []byte("<")) {
			hint = " (server returned an HTML page: wrong URL, expired token, or missing Referer/Origin headers)"
		}
		return nil, nil, fmt.Errorf("fetch %s: HTTP %d%s", rawURL, resp.StatusCode, hint)
	}
	return body, resp.Request.URL, nil
}

func splitHeader(h string) (string, string) {
	if i := strings.IndexByte(h, ':'); i > 0 {
		return strings.TrimSpace(h[:i]), strings.TrimSpace(h[i+1:])
	}
	return "", ""
}

func headerBlock(headers []string) string {
	var b strings.Builder
	for _, h := range headers {
		k, v := splitHeader(h)
		if k == "" {
			continue
		}
		fmt.Fprintf(&b, "%s: %s\r\n", k, v)
	}
	return b.String()
}

func hasHeader(headers []string, name string) bool {
	for _, h := range headers {
		if k, _ := splitHeader(h); strings.EqualFold(k, name) {
			return true
		}
	}
	return false
}

// -------------------------------------------------------------- quality UI --

func heightOf(v variant) int {
	if v.Resolution == "" {
		return 0
	}
	parts := strings.SplitN(strings.ToLower(v.Resolution), "x", 2)
	return atoi(parts[len(parts)-1])
}

func shortQuality(v variant) string {
	if h := heightOf(v); h > 0 {
		return fmt.Sprintf("%dp", h)
	}
	if v.Bandwidth > 0 {
		return fmt.Sprintf("%dk", v.Bandwidth/1000)
	}
	return "source"
}

func qualityLabel(v variant) string {
	if v.Resolution != "" {
		return v.Resolution
	}
	return shortQuality(v)
}

func humanBitrate(bits int) string {
	switch {
	case bits <= 0:
		return "-"
	case bits < 1_000_000:
		return fmt.Sprintf("%d kbps", bits/1000)
	default:
		return fmt.Sprintf("%.1f Mbps", float64(bits)/1_000_000)
	}
}

func humanBytes(n int64) string {
	f := float64(n)
	switch {
	case n < 1024:
		return fmt.Sprintf("%d B", n)
	case n < 1024*1024:
		return fmt.Sprintf("%.1f KB", f/1024)
	case n < 1024*1024*1024:
		return fmt.Sprintf("%.1f MB", f/(1024*1024))
	default:
		return fmt.Sprintf("%.2f GB", f/(1024*1024*1024))
	}
}

func fmtDur(sec float64) string {
	if sec <= 0 {
		return "0:00"
	}
	s := int(sec + 0.5)
	h, m, s2 := s/3600, (s%3600)/60, s%60
	if h > 0 {
		return fmt.Sprintf("%d:%02d:%02d", h, m, s2)
	}
	return fmt.Sprintf("%d:%02d", m, s2)
}

func shortDur(d time.Duration) string {
	if d < 0 {
		d = 0
	}
	d = d.Round(time.Second)
	h := int(d.Hours())
	m := int(d.Minutes()) % 60
	s := int(d.Seconds()) % 60
	switch {
	case h > 0:
		return fmt.Sprintf("%dh%02dm", h, m)
	case m > 0:
		return fmt.Sprintf("%dm%02ds", m, s)
	default:
		return fmt.Sprintf("%ds", s)
	}
}

func rankedIndices(vs []variant) []int {
	idx := make([]int, len(vs))
	for i := range idx {
		idx[i] = i
	}
	sort.SliceStable(idx, func(a, b int) bool {
		return vs[idx[a]].Bandwidth < vs[idx[b]].Bandwidth
	})
	return idx
}

func printQualities(p *playlist) {
	fmt.Printf("%3s  %-12s %-11s %s\n", "#", "RESOLUTION", "BITRATE", "CODECS")
	ranked := rankedIndices(p.variants)
	for i, vi := range ranked {
		v := p.variants[vi]
		res := v.Resolution
		if res == "" {
			res = "audio"
		}
		codecs := v.Codecs
		if codecs == "" {
			codecs = "-"
		}
		fmt.Printf("%3d  %-12s %-11s %s\n", i+1, res, humanBitrate(v.Bandwidth), codecs)
	}
}

func selectVariants(p *playlist, sel string) ([]int, error) {
	if len(p.variants) == 0 {
		return nil, errors.New("playlist has no variants")
	}
	ranked := rankedIndices(p.variants)
	n := len(ranked)
	norm := strings.ToLower(strings.TrimSpace(sel))
	switch norm {
	case "", "best", "max", "highest":
		return []int{ranked[n-1]}, nil
	case "worst", "min", "lowest":
		return []int{ranked[0]}, nil
	case "all":
		out := make([]int, 0, n)
		for i := n - 1; i >= 0; i-- { // best first
			out = append(out, ranked[i])
		}
		return out, nil
	}
	var out []int
	seen := map[int]bool{}
	for _, part := range strings.Split(norm, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if pos, err := strconv.Atoi(part); err == nil && pos >= 1 && pos <= n {
			if vi := ranked[pos-1]; !seen[vi] {
				seen[vi] = true
				out = append(out, vi)
			}
			continue
		}
		vi, ok := matchResolution(p.variants, part)
		if !ok {
			return nil, fmt.Errorf("unknown quality %q", part)
		}
		if !seen[vi] {
			seen[vi] = true
			out = append(out, vi)
		}
	}
	if len(out) == 0 {
		return nil, errors.New("no quality selected")
	}
	return out, nil
}

func matchResolution(vs []variant, sel string) (int, bool) {
	want := strings.TrimSuffix(strings.ToLower(sel), "p")
	best := -1
	for i, v := range vs {
		rv := strings.ToLower(v.Resolution)
		if rv == "" {
			continue
		}
		if rv == want || strings.HasSuffix(rv, "x"+want) || strings.TrimSuffix(rv, "p") == want {
			if best < 0 || vs[i].Bandwidth > vs[best].Bandwidth {
				best = i
			}
		}
	}
	if best >= 0 {
		return best, true
	}
	return 0, false
}

// audioURIFor returns the audio rendition URL a variant depends on, if the
// master playlist splits audio into its own rendition group.
func audioURIFor(p *playlist, v variant) string {
	if v.AudioGroup == "" {
		return ""
	}
	var fallback string
	for _, r := range p.renditions {
		if r.Group != v.AudioGroup || r.URI == "" {
			continue
		}
		if r.Default {
			return r.URI
		}
		if fallback == "" {
			fallback = r.URI
		}
	}
	return fallback
}

// ---------------------------------------------------------------- naming --

func sanitize(name string) string {
	name = strings.TrimSpace(name)
	replacer := strings.NewReplacer(
		"/", "-", "\\", "-", ":", "-", "*", "-", "?", "-",
		"\"", "-", "<", "-", ">", "-", "|", "-", "\n", " ", "\r", " ", "\t", " ",
	)
	name = replacer.Replace(name)
	name = strings.Join(strings.Fields(name), " ")
	name = strings.Trim(name, " .-")
	if len([]rune(name)) > 120 {
		name = string([]rune(name)[:120])
	}
	return name
}

var outputExts = map[string]bool{
	".mp4": true, ".mkv": true, ".ts": true, ".m4a": true, ".m4v": true, ".mov": true, ".webm": true,
}

func splitExt(name string) (string, string) {
	ext := strings.ToLower(filepath.Ext(name))
	if outputExts[ext] {
		return strings.TrimSuffix(name, filepath.Ext(name)), ext
	}
	return name, ".mp4"
}

func nameFromURL(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	parts := strings.Split(strings.Trim(u.Path, "/"), "/")
	for i := len(parts) - 1; i >= 0; i-- {
		p := strings.TrimSpace(parts[i])
		lp := strings.ToLower(p)
		switch {
		case p == "", p == "hls", p == "videos", p == "vod":
			continue
		case strings.HasSuffix(lp, ".m3u8"), strings.HasSuffix(lp, ".list"):
			continue
		case strings.Contains(p, ",") && strings.Contains(lp, ".mp4"):
			continue
		case isNumeric(p):
			continue
		}
		if base, ext := splitExt(p); ext != ".mp4" || strings.HasSuffix(lp, ".mp4") {
			p = base
		}
		if p != "" {
			return p
		}
	}
	return ""
}

func isNumeric(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

func fileExists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

func uniqueFilename(dir, name string, q *queue, taken map[string]bool) string {
	base, ext := splitExt(name)
	try := name
	for i := 2; ; i++ {
		used := taken[try]
		if !used {
			for _, it := range q.Items {
				if it.Filename == try && it.Status != stFailed {
					used = true
					break
				}
			}
		}
		if !used && !fileExists(filepath.Join(dir, try)) {
			taken[try] = true
			return try
		}
		try = fmt.Sprintf("%s (%d)%s", base, i, ext)
	}
}

// ------------------------------------------------------------------ prompts --

type prompter struct {
	rd  *bufio.Reader
	tty bool
}

func newPrompter(rd *bufio.Reader) *prompter {
	return &prompter{rd: rd, tty: isTTY(os.Stdin)}
}

func (p *prompter) ask(label, def string) (string, error) {
	if !p.tty && def == "" {
		return "", errors.New("missing value for " + label)
	}
	fmt.Printf("%s", label)
	if def != "" {
		fmt.Printf(" [%s]", def)
	}
	fmt.Print(": ")
	line, err := p.rd.ReadString('\n')
	if err != nil && err != io.EOF {
		return "", err
	}
	line = strings.TrimSpace(line)
	if line == "" {
		return def, nil
	}
	return line, nil
}

func (p *prompter) confirm(label string, def bool) bool {
	suffix := " [Y/n]: "
	if !def {
		suffix = " [y/N]: "
	}
	fmt.Print(label + suffix)
	line, err := p.rd.ReadString('\n')
	if err != nil && err != io.EOF {
		return def
	}
	line = strings.ToLower(strings.TrimSpace(line))
	if line == "" {
		return def
	}
	return line == "y" || line == "yes"
}

// ------------------------------------------------------------------- add --

type addFlags struct {
	url     string
	quality string
	name    string
	dir     string
	when    string
	headers []string
	yes     bool
}

type headerList []string

func (h *headerList) String() string     { return strings.Join(*h, ", ") }
func (h *headerList) Set(v string) error { *h = append(*h, v); return nil }

func parseAddFlags(args []string) (*addFlags, error) {
	fs := flag.NewFlagSet("add", flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	f := &addFlags{}
	fs.StringVar(&f.quality, "q", "", "quality: best, worst, all, 1080p, 1920x1080, or list of indexes (1,3)")
	fs.StringVar(&f.name, "o", "", "output filename (default: playlist title or derived from URL)")
	fs.StringVar(&f.dir, "d", "", "download directory")
	fs.StringVar(&f.when, "at", "", "scheduled start: now, +30m, 21:30, '2026-11-18 09:00'")
	fs.BoolVar(&f.yes, "y", false, "do not ask for confirmation")
	var hdrs headerList
	fs.Var(&hdrs, "H", "HTTP header 'Name: Value' (repeatable; replaces configured headers)")
	// Go's flag package stops at the first positional, so pull the URL out and
	// let flags appear on either side of it.
	positional, flags := splitPositional(args)
	if err := fs.Parse(append(append([]string{}, flags...), positional...)); err != nil {
		return nil, err
	}
	f.headers = hdrs
	if rest := fs.Args(); len(rest) > 0 {
		f.url = strings.TrimSpace(rest[0])
	}
	return f, nil
}

func splitPositional(args []string) (positional, flags []string) {
	valueFlags := map[string]bool{"-q": true, "-o": true, "-d": true, "-at": true, "-H": true, "--q": true, "--o": true, "--d": true, "--at": true, "--H": true}
	for i := 0; i < len(args); i++ {
		a := args[i]
		if strings.HasPrefix(a, "-") && a != "-" {
			flags = append(flags, a)
			if valueFlags[a] && i+1 < len(args) {
				i++
				flags = append(flags, args[i])
			}
			continue
		}
		positional = append(positional, a)
	}
	return positional, flags
}

type option struct {
	variant  variant
	quality  string
	audioURL string
	duration float64
}

func cmdAdd(ctx context.Context, args []string, q *queue, cfg *config, p *prompter) error {
	f, err := parseAddFlags(args)
	if err != nil {
		return err
	}
	raw := f.url
	if raw == "" {
		if raw, err = p.ask("playlist URL", ""); err != nil {
			return err
		}
	}
	if raw == "" {
		return errors.New("no URL given")
	}
	raw = normalizeURL(raw)

	headers := cfg.Headers
	if len(f.headers) > 0 {
		headers = f.headers
	}
	for _, h := range headers {
		if k, v := splitHeader(h); k == "" || v == "" {
			return fmt.Errorf("bad header %q (want 'Name: Value')", h)
		}
	}

	fmt.Printf("fetching %s\n", shortURL(raw))
	body, finalURL, err := fetch(ctx, raw, headers)
	if err != nil {
		return err
	}
	pl, err := parsePlaylist(body, finalURL)
	if err != nil {
		return err
	}

	var chosen []option
	if pl.isMaster {
		fmt.Printf("\n%s\n", shortURL(finalURL.String()))
		printQualities(pl)
		fmt.Printf("\n")
		if pl.encrypted {
			fmt.Println("encryption: AES (ffmpeg handles it)")
		}

		sel := f.quality
		if sel == "" {
			if !p.tty {
				sel = "best"
			} else {
				if sel, err = p.ask("select quality (number, 1080p, best, worst, all)", "best"); err != nil {
					return err
				}
			}
		}
		idxs, err := selectVariants(pl, sel)
		if err != nil {
			return err
		}
		for _, vi := range idxs {
			v := pl.variants[vi]
			op := option{variant: v, quality: qualityLabel(v), audioURL: audioURIFor(pl, v)}
			probe, perr := probePlaylist(ctx, v.URL, headers)
			if perr != nil {
				fmt.Printf("warning: could not probe %s: %v\n", op.quality, perr)
			} else {
				op.duration = probe.duration
				if pl.date == nil && probe.date != nil {
					pl.date = probe.date
				}
				if pl.title == "" && probe.title != "" {
					pl.title = probe.title
				}
			}
			chosen = append(chosen, op)
		}
	} else {
		chosen = []option{{variant: variant{URL: finalURL.String()}, quality: "source", duration: pl.duration}}
	}

	if len(chosen) == 0 {
		return errors.New("nothing to download")
	}

	// Schedule time.
	when, err := parseWhen(f.when, time.Now())
	if err != nil {
		return err
	}
	if f.when == "" && p.tty {
		s, err := p.ask("schedule start (now, +30m, 21:30, '2026-11-18 09:00')", "now")
		if err != nil {
			return err
		}
		if when, err = parseWhen(s, time.Now()); err != nil {
			return err
		}
	}

	// Output name.
	dir := expandPath(cfg.Dir)
	if f.dir != "" {
		dir = expandPath(f.dir)
	}
	ext := ".mp4"
	stem := ""
	if f.name != "" {
		stem, ext = splitExt(f.name)
		stem = sanitize(stem)
	}
	title := pl.title
	if stem == "" {
		stem = sanitize(title)
	}
	if stem == "" {
		stem = sanitize(nameFromURL(raw))
	}
	if stem == "" {
		stem = "video-" + time.Now().Format("20060102-150405")
	}

	var newItems []*item
	taken := map[string]bool{}
	for _, op := range chosen {
		name := stem
		if len(chosen) > 1 {
			name += " [" + shortQuality(op.variant) + "]"
		}
		if pl.date != nil && f.name == "" {
			name = pl.date.Format("2006-01-02_150405") + " " + name
		}
		filename := uniqueFilename(dir, name+ext, q, taken)
		it := &item{
			URL:        raw,
			VariantURL: op.variant.URL,
			AudioURL:   op.audioURL,
			Quality:    op.quality,
			Bandwidth:  op.variant.Bandwidth,
			Codecs:     op.variant.Codecs,
			Title:      title,
			StreamTime: pl.date,
			Duration:   op.duration,
			Filename:   filename,
			Dir:        dir,
			Headers:    headers,
			Status:     stPending,
			ScheduleAt: when,
			AddedAt:    time.Now(),
		}
		newItems = append(newItems, it)
	}

	fmt.Printf("\n%s\n", strings.Repeat("-", 68))
	if title != "" {
		fmt.Printf("title:      %s\n", title)
	}
	if pl.date != nil {
		fmt.Printf("stream time: %s\n", pl.date.Format("2006-01-02 15:04:05"))
	}
	for _, op := range chosen {
		fmt.Printf("quality:    %s (%s)\n", op.quality, humanBitrate(op.variant.Bandwidth))
	}
	if d := chosen[0].duration; d > 0 {
		fmt.Printf("duration:   %s\n", fmtDur(d))
	}
	for _, it := range newItems {
		fmt.Printf("output:     %s\n", filepath.Join(dir, it.Filename))
	}
	fmt.Printf("schedule:   %s\n", whenLabel(when))
	fmt.Printf("headers:    %d\n", len(headers))
	fmt.Printf("%s\n", strings.Repeat("-", 68))

	if p.tty && !f.yes {
		if !p.confirm(fmt.Sprintf("add %d item(s) to the queue?", len(newItems)), true) {
			return errors.New("cancelled")
		}
	}

	for _, it := range newItems {
		it.ID = q.NextID
		q.NextID++
		q.Items = append(q.Items, *it)
		fmt.Printf("queued #%d  %s  (%s)\n", it.ID, it.Filename, whenLabel(when))
	}
	if err := saveQueue(q); err != nil {
		return err
	}
	fmt.Println("run the queue with 'run'")
	return nil
}

func probePlaylist(ctx context.Context, rawURL string, headers []string) (*playlist, error) {
	body, finalURL, err := fetch(ctx, rawURL, headers)
	if err != nil {
		return nil, err
	}
	return parsePlaylist(body, finalURL)
}

func normalizeURL(raw string) string {
	if strings.HasPrefix(raw, "http://") || strings.HasPrefix(raw, "https://") {
		return raw
	}
	return "https://" + raw
}

func shortURL(raw string) string {
	if len(raw) <= 96 {
		return raw
	}
	return raw[:60] + "..." + raw[len(raw)-32:]
}

// ------------------------------------------------------------------ times --

func parseWhen(s string, now time.Time) (time.Time, error) {
	s = strings.TrimSpace(s)
	if s == "" || strings.EqualFold(s, "now") {
		return now, nil
	}
	if strings.HasPrefix(s, "+") {
		d, err := time.ParseDuration(s[1:])
		if err != nil {
			return time.Time{}, fmt.Errorf("bad delay %q (try +30m or +1h15m)", s)
		}
		return now.Add(d), nil
	}
	for _, l := range []string{time.RFC3339, "2006-01-02 15:04:05", "2006-01-02 15:04", "2006-01-02T15:04:05", "2006-01-02T15:04"} {
		if t, err := time.ParseInLocation(l, s, time.Local); err == nil {
			return t, nil
		}
	}
	for _, l := range []string{"15:04:05", "15:04"} {
		if t, err := time.ParseInLocation(l, s, time.Local); err == nil {
			at := time.Date(now.Year(), now.Month(), now.Day(), t.Hour(), t.Minute(), t.Second(), 0, time.Local)
			if !at.After(now) {
				at = at.AddDate(0, 0, 1)
			}
			return at, nil
		}
	}
	if strings.EqualFold(s, "tomorrow") {
		return time.Date(now.Year(), now.Month(), now.Day()+1, 9, 0, 0, 0, time.Local), nil
	}
	return time.Time{}, fmt.Errorf("can't parse time %q (use now, +30m, 21:30, or '2026-11-18 09:00')", s)
}

func whenLabel(t time.Time) string {
	d := time.Until(t)
	switch {
	case d <= 0:
		return "now"
	case d < time.Minute:
		return fmt.Sprintf("in %ds", int(d.Seconds()))
	case d < 24*time.Hour:
		return fmt.Sprintf("in %s (%s)", shortDur(d), t.Format("15:04"))
	default:
		return t.Format("2006-01-02 15:04")
	}
}

func waitUntil(ctx context.Context, t time.Time) error {
	if !time.Now().Before(t) {
		return nil
	}
	fmt.Printf("waiting until %s (%s from now)\n", t.Format("2006-01-02 15:04:05"), shortDur(time.Until(t)))
	timer := time.NewTimer(time.Until(t))
	defer timer.Stop()
	tick := time.NewTicker(5 * time.Minute)
	defer tick.Stop()
	for {
		select {
		case <-timer.C:
			return nil
		case <-tick.C:
			fmt.Printf("  still waiting: %s left\n", shortDur(time.Until(t)))
		case <-ctx.Done():
			return errInterrupted
		}
	}
}

// ------------------------------------------------------------------ runner --

func cmdRun(q *queue, cfg *config, ids []string) error {
	if _, err := exec.LookPath(cfg.FFmpeg); err != nil {
		return fmt.Errorf("%s not found in PATH", cfg.FFmpeg)
	}
	targets, err := runTargets(q, ids)
	if err != nil {
		return err
	}
	if len(targets) == 0 {
		fmt.Println("nothing to download (queue is empty or all items are done)")
		return nil
	}

	ctx, cancel := withInterrupt(context.Background())
	defer cancel()

	failed := 0
	for i, it := range targets {
		if ctx.Err() != nil {
			fmt.Println("stopped.")
			return nil
		}
		if it.Status == stDone {
			continue
		}
		fmt.Printf("\n[%d/%d] #%d %s  %s\n", i+1, len(targets), it.ID, it.Quality, it.Filename)
		if err := waitUntil(ctx, it.ScheduleAt); err != nil {
			return nil
		}
		if err := runItem(ctx, cfg, it, func() { _ = saveQueue(q) }); err != nil {
			if errors.Is(err, errInterrupted) || errors.Is(err, context.Canceled) {
				fmt.Println("\ninterrupted; item kept in the queue.")
				return nil
			}
			fmt.Printf("  failed: %v\n", err)
			failed++
		}
	}
	if failed > 0 {
		return fmt.Errorf("%d item(s) failed; see 'list'", failed)
	}
	fmt.Println("\nqueue finished.")
	return nil
}

func runTargets(q *queue, ids []string) ([]*item, error) {
	if len(ids) == 0 {
		out := make([]*item, 0, len(q.Items))
		for i := range q.Items {
			out = append(out, &q.Items[i])
		}
		return out, nil
	}
	want := map[int]bool{}
	for _, s := range ids {
		n, err := strconv.Atoi(s)
		if err != nil {
			return nil, fmt.Errorf("bad id %q", s)
		}
		want[n] = true
	}
	var out []*item
	for i := range q.Items {
		if want[q.Items[i].ID] {
			out = append(out, &q.Items[i])
		}
	}
	return out, nil
}

func runItem(ctx context.Context, cfg *config, it *item, save func()) error {
	it.Status = stDownloading
	it.Error = ""
	save()
	err := download(ctx, cfg, it)
	now := time.Now()
	switch {
	case err == nil:
		it.Status = stDone
		it.DoneAt = &now
		it.Error = ""
	case errors.Is(err, errInterrupted) || errors.Is(err, context.Canceled):
		it.Status = stPending
		it.Error = ""
	default:
		it.Status = stFailed
		it.Error = err.Error()
	}
	save()
	return err
}

func download(ctx context.Context, cfg *config, it *item) error {
	dir := expandPath(it.Dir)
	if dir == "" {
		dir = expandPath(cfg.Dir)
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	base, ext := splitExt(it.Filename)
	final := filepath.Join(dir, base+ext)
	partial := filepath.Join(dir, "."+base+".partial"+ext)

	input := it.VariantURL
	if input == "" {
		return errors.New("item has no stream URL")
	}

	attempts := cfg.Retries + 1
	var lastErr error
	for attempt := 1; attempt <= attempts; attempt++ {
		if ctx.Err() != nil {
			return errInterrupted
		}
		if attempts > 1 {
			fmt.Printf("  attempt %d/%d\n", attempt, attempts)
		}
		start := time.Now()
		lastErr = runFFmpeg(ctx, cfg.FFmpeg, it, input, partial, ext)
		if lastErr == nil {
			fi, err := os.Stat(partial)
			if err != nil || fi.Size() == 0 {
				os.Remove(partial)
				return errors.New("ffmpeg produced an empty file")
			}
			if err := os.Rename(partial, final); err != nil {
				return err
			}
			fmt.Printf("  done in %s  (%s)\n", shortDur(time.Since(start)), humanBytes(fi.Size()))
			return nil
		}
		if errors.Is(lastErr, errInterrupted) || errors.Is(lastErr, context.Canceled) {
			os.Remove(partial)
			return errInterrupted
		}
		os.Remove(partial)
		if attempt < attempts {
			fmt.Printf("  error: %v\n", lastErr)
			select {
			case <-time.After(3 * time.Second):
			case <-ctx.Done():
				return errInterrupted
			}
		}
	}
	return lastErr
}

func runFFmpeg(ctx context.Context, ffmpeg string, it *item, input, out, ext string) error {
	args := []string{
		"-hide_banner", "-loglevel", "error", "-nostdin", "-y",
		"-progress", "pipe:1", "-nostats",
		"-protocol_whitelist", "file,http,https,tcp,tls,crypto",
		"-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "10",
	}
	args = append(args, "-headers", headerBlock(it.Headers))
	if !hasHeader(it.Headers, "User-Agent") {
		args = append(args, "-user_agent", defaultUA)
	}
	args = append(args, "-i", input)
	if it.AudioURL != "" {
		args = append(args, "-headers", headerBlock(it.Headers))
		if !hasHeader(it.Headers, "User-Agent") {
			args = append(args, "-user_agent", defaultUA)
		}
		args = append(args, "-i", it.AudioURL, "-map", "0:v:0", "-map", "1:a:0")
	}
	args = append(args, "-c", "copy")
	if ext == ".mp4" || ext == ".m4v" || ext == ".mov" {
		args = append(args, "-movflags", "+faststart")
	}
	args = append(args, out)

	cmd := exec.CommandContext(ctx, ffmpeg, args...)
	cmd.Cancel = func() error { return cmd.Process.Signal(os.Interrupt) }
	cmd.WaitDelay = 5 * time.Second
	lw := &limitedWriter{limit: 8192}
	cmd.Stderr = lw
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	if err := cmd.Start(); err != nil {
		return err
	}
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		scanProgress(stdout, it.Duration)
	}()
	err = cmd.Wait()
	wg.Wait()

	if err != nil && ctx.Err() != nil {
		return errInterrupted
	}
	if err != nil {
		msg := strings.TrimSpace(lw.String())
		if msg == "" {
			return err
		}
		return errors.New(lastLines(msg, 6))
	}
	return nil
}

func scanProgress(r io.Reader, total float64) {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 0, 16*1024), 1<<20)
	tty := isTTY(os.Stdout)
	var out time.Duration
	var size int64
	speed := "-"

	draw := func() {
		pct := ""
		if total > 0 {
			p := math.Min(100, out.Seconds()/total*100)
			pct = fmt.Sprintf("%5.1f%% ", p)
		}
		line := fmt.Sprintf("  %s%s / %s  %6s  %8s", pct, fmtDur(out.Seconds()), fmtDur(total), speed, humanBytes(size))
		fmt.Printf("\r%s\033[K", line)
	}

	for sc.Scan() {
		key, val, ok := strings.Cut(sc.Text(), "=")
		if !ok {
			continue
		}
		switch key {
		case "out_time_us", "out_time_ms":
			if us, err := strconv.ParseInt(val, 10, 64); err == nil && us >= 0 {
				out = time.Duration(us) * time.Microsecond
			}
		case "total_size":
			if n, err := strconv.ParseInt(val, 10, 64); err == nil {
				size = n
			}
		case "speed":
			if v := strings.TrimSpace(val); v != "" {
				speed = v
			}
		case "progress":
			if tty {
				draw()
			}
		}
	}
	if tty {
		fmt.Print("\r\033[K")
	}
}

func lastLines(s string, n int) string {
	lines := strings.Split(strings.TrimSpace(s), "\n")
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.Join(lines, "\n")
}

type limitedWriter struct {
	mu    sync.Mutex
	buf   []byte
	limit int
}

func (w *limitedWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.buf = append(w.buf, p...)
	if len(w.buf) > w.limit {
		w.buf = append([]byte(nil), w.buf[len(w.buf)-w.limit:]...)
	}
	return len(p), nil
}

func (w *limitedWriter) String() string {
	w.mu.Lock()
	defer w.mu.Unlock()
	return string(w.buf)
}

func withInterrupt(parent context.Context) (context.Context, context.CancelFunc) {
	ctx, cancel := context.WithCancel(parent)
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt, syscall.SIGTERM)
	go func() {
		select {
		case <-ch:
			cancel()
		case <-ctx.Done():
		}
		signal.Stop(ch)
	}()
	return ctx, cancel
}

// ------------------------------------------------------------------- list --

func cmdList(q *queue) {
	if len(q.Items) == 0 {
		fmt.Println("queue is empty — add something with 'add <url>'")
		return
	}
	fmt.Printf("%3s  %-11s %-18s %-12s %-8s %s\n", "ID", "STATUS", "SCHEDULED", "QUALITY", "LENGTH", "FILE")
	for _, it := range q.Items {
		scheduled := "-"
		switch it.Status {
		case stDone:
			if it.DoneAt != nil {
				scheduled = it.DoneAt.Format("01-02 15:04")
			}
		case stFailed:
			scheduled = "failed"
		case stDownloading:
			scheduled = "now"
		default:
			scheduled = whenLabel(it.ScheduleAt)
		}
		fmt.Printf("%3d  %-11s %-18s %-12s %-8s %s\n",
			it.ID, it.Status, scheduled, it.Quality, fmtDur(it.Duration), it.Filename)
		if it.Title != "" && sanitize(it.Title) != strings.TrimSuffix(it.Filename, filepath.Ext(it.Filename)) {
			fmt.Printf("     title: %s\n", it.Title)
		}
		if it.StreamTime != nil {
			fmt.Printf("     stream time: %s\n", it.StreamTime.Format("2006-01-02 15:04:05"))
		}
		if it.Error != "" {
			fmt.Printf("     error: %s\n", firstLine(it.Error))
		}
	}
}

func firstLine(s string) string {
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		return s[:i]
	}
	return s
}

func cmdRemove(q *queue, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: rm <id...>")
	}
	drop := map[int]bool{}
	for _, s := range args {
		n, err := strconv.Atoi(s)
		if err != nil {
			return fmt.Errorf("bad id %q", s)
		}
		drop[n] = true
	}
	kept := q.Items[:0]
	removed := 0
	for _, it := range q.Items {
		if drop[it.ID] {
			if it.Status == stDownloading {
				return fmt.Errorf("#%d is downloading; stop the runner first", it.ID)
			}
			removed++
			continue
		}
		kept = append(kept, it)
	}
	q.Items = kept
	if err := saveQueue(q); err != nil {
		return err
	}
	fmt.Printf("removed %d item(s)\n", removed)
	return nil
}

func cmdClear(q *queue, args []string) error {
	what := "done"
	if len(args) > 0 {
		what = strings.ToLower(args[0])
	}
	kept := q.Items[:0]
	removed := 0
	for _, it := range q.Items {
		drop := false
		switch what {
		case "done":
			drop = it.Status == stDone
		case "failed":
			drop = it.Status == stFailed
		case "all":
			drop = it.Status != stDownloading
		default:
			return fmt.Errorf("usage: clear [done|failed|all]")
		}
		if drop {
			removed++
			continue
		}
		kept = append(kept, it)
	}
	q.Items = kept
	if err := saveQueue(q); err != nil {
		return err
	}
	fmt.Printf("removed %d item(s)\n", removed)
	return nil
}

func cmdSched(q *queue, args []string) error {
	if len(args) < 2 {
		return errors.New("usage: sched <id> <when>")
	}
	id, err := strconv.Atoi(args[0])
	if err != nil {
		return fmt.Errorf("bad id %q", args[0])
	}
	when, err := parseWhen(strings.Join(args[1:], " "), time.Now())
	if err != nil {
		return err
	}
	for i := range q.Items {
		if q.Items[i].ID == id {
			q.Items[i].ScheduleAt = when
			if q.Items[i].Status == stFailed {
				q.Items[i].Status = stPending
				q.Items[i].Error = ""
			}
			if err := saveQueue(q); err != nil {
				return err
			}
			fmt.Printf("#%d scheduled: %s\n", id, whenLabel(when))
			return nil
		}
	}
	return fmt.Errorf("no item #%d", id)
}

func cmdRetry(q *queue, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: retry <id...>")
	}
	n := 0
	for i := range q.Items {
		for _, s := range args {
			if strconv.Itoa(q.Items[i].ID) == s && q.Items[i].Status == stFailed {
				q.Items[i].Status = stPending
				q.Items[i].Error = ""
				n++
			}
		}
	}
	if err := saveQueue(q); err != nil {
		return err
	}
	fmt.Printf("requeued %d item(s)\n", n)
	return nil
}

func cmdDir(cfg *config, args []string) error {
	if len(args) == 0 {
		fmt.Println(expandPath(cfg.Dir))
		return nil
	}
	cfg.Dir = args[0]
	if err := saveConfig(cfg); err != nil {
		return err
	}
	fmt.Printf("download directory: %s\n", expandPath(cfg.Dir))
	return nil
}

// ---------------------------------------------------------------- headers --

// presets holds header sets that don't depend on a particular site. The
// "referer" preset is handled separately because it builds Origin/Referer from
// a host you supply.
var presets = map[string][]string{
	"browser": {"User-Agent: " + defaultUA},
	"none":    nil,
}

// originFromArg turns "https://example.com/some/path" (or a bare host) into a
// scheme://host/ origin usable for both Origin and Referer.
func originFromArg(arg string) (string, error) {
	raw := arg
	if !strings.Contains(raw, "://") {
		raw = "https://" + raw
	}
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" {
		return "", fmt.Errorf("bad origin %q (want https://example.com/)", arg)
	}
	scheme := u.Scheme
	if scheme != "http" && scheme != "https" {
		return "", fmt.Errorf("bad origin %q (want http or https)", arg)
	}
	return scheme + "://" + u.Host + "/", nil
}

func cmdHeader(cfg *config, args []string) error {
	if len(args) == 0 {
		printHeaders(cfg)
		return nil
	}
	switch strings.ToLower(args[0]) {
	case "list", "ls":
		printHeaders(cfg)
	case "add":
		h := strings.TrimSpace(strings.Join(args[1:], " "))
		k, v := splitHeader(h)
		if k == "" || v == "" {
			return errors.New("usage: header add 'Name: Value'")
		}
		cfg.Headers = append(cfg.Headers, k+": "+v)
		return saveConfig(cfg)
	case "rm", "del":
		if len(args) < 2 {
			return errors.New("usage: header rm <n>")
		}
		n, err := strconv.Atoi(args[1])
		if err != nil || n < 1 || n > len(cfg.Headers) {
			return fmt.Errorf("bad header number %q", args[1])
		}
		cfg.Headers = append(cfg.Headers[:n-1], cfg.Headers[n:]...)
		return saveConfig(cfg)
	case "clear":
		cfg.Headers = nil
		return saveConfig(cfg)
	default:
		return fmt.Errorf("usage: header [list | add 'Name: Value' | rm <n> | clear]")
	}
	return nil
}

func printHeaders(cfg *config) {
	if len(cfg.Headers) == 0 {
		fmt.Println("no default headers")
		return
	}
	for i, h := range cfg.Headers {
		fmt.Printf("%2d. %s\n", i+1, h)
	}
}

func cmdPreset(cfg *config, args []string) error {
	if len(args) == 0 {
		names := append([]string{"referer <origin>"}, sortedKeys(presets)...)
		fmt.Printf("presets: %s\n", strings.Join(names, ", "))
		return nil
	}
	name := strings.ToLower(args[0])
	if name == "referer" || name == "origin" {
		if len(args) < 2 {
			return errors.New("usage: preset referer <origin>   e.g. preset referer https://example.com/")
		}
		origin, err := originFromArg(args[1])
		if err != nil {
			return err
		}
		cfg.Headers = []string{
			"Origin: " + origin,
			"Referer: " + origin,
			"User-Agent: " + defaultUA,
		}
		if err := saveConfig(cfg); err != nil {
			return err
		}
		fmt.Printf("applied preset %q for %s (%d header(s))\n", "referer", origin, len(cfg.Headers))
		return nil
	}
	hs, ok := presets[name]
	if !ok {
		return fmt.Errorf("unknown preset %q (try: referer <origin>, %s)", name, strings.Join(sortedKeys(presets), ", "))
	}
	cfg.Headers = append([]string(nil), hs...)
	if err := saveConfig(cfg); err != nil {
		return err
	}
	fmt.Printf("applied preset %q (%d header(s))\n", name, len(cfg.Headers))
	return nil
}

func sortedKeys(m map[string][]string) []string {
	names := make([]string, 0, len(m))
	for k := range m {
		names = append(names, k)
	}
	sort.Strings(names)
	return names
}

// ------------------------------------------------------------------- probe --

func cmdProbe(ctx context.Context, args []string, cfg *config) error {
	fs := flag.NewFlagSet("probe", flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	var hdrs headerList
	fs.Var(&hdrs, "H", "HTTP header 'Name: Value' (repeatable)")
	if err := fs.Parse(args); err != nil {
		return err
	}
	raw := strings.TrimSpace(fs.Arg(0))
	if raw == "" {
		return errors.New("usage: probe <url> [-H 'Name: Value']")
	}
	raw = normalizeURL(raw)
	headers := cfg.Headers
	if len(hdrs) > 0 {
		headers = hdrs
	}
	body, finalURL, err := fetch(ctx, raw, headers)
	if err != nil {
		return err
	}
	pl, err := parsePlaylist(body, finalURL)
	if err != nil {
		return err
	}
	fmt.Printf("playlist:   %s\n", shortURL(finalURL.String()))
	if pl.title != "" {
		fmt.Printf("title:      %s\n", pl.title)
	}
	if pl.date != nil {
		fmt.Printf("stream time: %s\n", pl.date.Format("2006-01-02 15:04:05"))
	}
	if pl.isMaster {
		fmt.Printf("type:       master (%d variant(s), %d rendition(s))\n", len(pl.variants), len(pl.renditions))
		fmt.Println()
		printQualities(pl)
	} else {
		fmt.Printf("type:       media\n")
		fmt.Printf("duration:   %s (%d segments)\n", fmtDur(pl.duration), pl.segments)
	}
	if pl.encrypted {
		fmt.Println("encryption: yes (AES, ffmpeg handles it)")
	}
	if pl.live {
		fmt.Println("live:       yes (no #EXT-X-ENDLIST)")
	}
	return nil
}

// ------------------------------------------------------------------- shell --

func shell(q *queue, cfg *config) {
	rd := bufio.NewReader(os.Stdin)
	p := newPrompter(rd)
	fmt.Printf("m3u8dl %s — interactive HLS downloader\n", version)
	fmt.Printf("queue: %d item(s)  dir: %s\n", len(q.Items), expandPath(cfg.Dir))
	fmt.Println("type 'help' for commands")

	for {
		fmt.Print("\nm3u8dl> ")
		line, err := rd.ReadString('\n')
		if err != nil && strings.TrimSpace(line) == "" {
			fmt.Println()
			return
		}
		args, perr := splitArgs(line)
		if perr != nil {
			fmt.Println("error:", perr)
			continue
		}
		if len(args) == 0 {
			continue
		}
		cmd, rest := strings.ToLower(args[0]), args[1:]
		var runErr error
		switch cmd {
		case "add", "a":
			runErr = cmdAdd(context.Background(), rest, q, cfg, p)
		case "list", "ls", "l":
			cmdList(q)
		case "run", "start", "r":
			runErr = cmdRun(q, cfg, rest)
		case "probe", "p":
			runErr = cmdProbe(context.Background(), rest, cfg)
		case "rm", "del", "remove":
			runErr = cmdRemove(q, rest)
		case "clear":
			runErr = cmdClear(q, rest)
		case "sched", "schedule", "at":
			runErr = cmdSched(q, rest)
		case "retry":
			runErr = cmdRetry(q, rest)
		case "dir":
			runErr = cmdDir(cfg, rest)
		case "header", "headers":
			runErr = cmdHeader(cfg, rest)
		case "preset":
			runErr = cmdPreset(cfg, rest)
		case "help", "h", "?":
			printHelp()
		case "quit", "exit", "q":
			_ = saveQueue(q)
			return
		default:
			fmt.Printf("unknown command %q (try 'help')\n", cmd)
		}
		if runErr != nil && !errors.Is(runErr, errInterrupted) {
			fmt.Println("error:", runErr)
		}
	}
}

func splitArgs(s string) ([]string, error) {
	var args []string
	var b strings.Builder
	var quote rune
	has := false
	for _, r := range s {
		switch {
		case quote != 0:
			if r == quote {
				quote = 0
			} else {
				b.WriteRune(r)
			}
			has = true
		case r == '\'' || r == '"':
			quote = r
			has = true
		case r == ' ' || r == '\t' || r == '\n' || r == '\r':
			if has {
				args = append(args, b.String())
				b.Reset()
				has = false
			}
		default:
			b.WriteRune(r)
			has = true
		}
	}
	if quote != 0 {
		return nil, errors.New("unbalanced quotes")
	}
	if has {
		args = append(args, b.String())
	}
	return args, nil
}

func printHelp() {
	fmt.Print(`commands:
  add <url>                  inspect the playlist, pick quality, schedule, queue it
       [-q best|worst|all|1080p|1920x1080|1,3]  [-o NAME] [-at WHEN] [-d DIR] [-H 'K: V'] [-y]
  probe <url>                show qualities/metadata without queueing
  list                       show the queue
  run [id...]                download in queue order, waiting for each schedule time
  sched <id> <when>          reschedule: now | +30m | 21:30 | '2026-11-18 09:00'
  retry <id...>              requeue failed items
  rm <id...>                 remove items from the queue
  clear [done|failed|all]    drop finished items (default: done)
  dir [path]                 show/set the download directory
  header [list|add 'K: V'|rm <n>|clear]   default HTTP headers
  preset [referer <origin> | browser | none]   apply/see header presets
  help, quit
`)
}

// -------------------------------------------------------------------- main --

func isTTY(f *os.File) bool {
	fi, err := f.Stat()
	if err != nil || fi.Mode()&os.ModeCharDevice == 0 {
		return false
	}
	if devNull, err := os.Stat(os.DevNull); err == nil && os.SameFile(fi, devNull) {
		return false
	}
	return true
}

func main() {
	cfg := loadConfig()
	q, err := loadQueue()
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
	if len(os.Args) > 1 {
		if err := dispatch(os.Args[1], os.Args[2:], q, cfg); err != nil {
			fmt.Fprintln(os.Stderr, "error:", err)
			os.Exit(1)
		}
		return
	}
	shell(q, cfg)
}

func dispatch(cmd string, args []string, q *queue, cfg *config) error {
	rd := bufio.NewReader(os.Stdin)
	switch strings.ToLower(cmd) {
	case "add", "a":
		return cmdAdd(context.Background(), args, q, cfg, newPrompter(rd))
	case "run", "start", "r":
		return cmdRun(q, cfg, args)
	case "list", "ls", "l":
		cmdList(q)
		return nil
	case "probe", "p":
		return cmdProbe(context.Background(), args, cfg)
	case "rm", "del", "remove":
		return cmdRemove(q, args)
	case "clear":
		return cmdClear(q, args)
	case "sched", "schedule", "at":
		return cmdSched(q, args)
	case "retry":
		return cmdRetry(q, args)
	case "dir":
		return cmdDir(cfg, args)
	case "header", "headers":
		return cmdHeader(cfg, args)
	case "preset":
		return cmdPreset(cfg, args)
	case "help", "-h", "--help", "h":
		printHelp()
		return nil
	case "version", "-v", "--version":
		fmt.Printf("m3u8dl %s\n", version)
		return nil
	default:
		return fmt.Errorf("unknown command %q (try 'help')", cmd)
	}
}

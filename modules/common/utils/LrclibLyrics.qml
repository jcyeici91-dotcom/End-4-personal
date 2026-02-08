pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root
    visible: false

    // Inputs
    property bool enabled: false
    property string title: ""
    property string artist: ""

    // Accept seconds, ms, or µs; normalized internally
    property real duration: 0
    property real position: 0

    // If user selected an exact result id
    property int selectedId: 0

    property int manualOffsetMs: 0
// sincronizacon
    property bool adaptiveSync: true
    property int adaptiveMaxAbsMs: 2500
    property real adaptiveAlpha: 0.12
    property int autoOffsetMs: 0

    property bool smoothPosition: true
    property int smoothSlackMs: 160
      property int smoothWindowMs: smoothSlackMs
    onSmoothWindowMsChanged: smoothSlackMs = smoothWindowMs
    property int smoothMaxForwardJumpMs: 2000

    property real minTitleSim: 0.45
    property real minArtistSim: 0.50
    property int maxDurationDiffSec: 3
    property int minAcceptScore: 240

    // State
    property bool loading: false
    property string error: ""
    property bool instrumental: false

    // [{ timeMs: int, text: string }]
    property var lines: []

    // value = { bestId, instrumental, lines, meta: { trackName, artistName, duration } }
    property var _cache: ({})
    property var _negCache: ({})
    property int negativeCacheTtlMs: 5 * 60 * 1000

    property string loadedKey: ""
    property string requestKey: ""
    property int requestId: 0
    property int attempt: 0
    property bool startPending: false

    // internal
    property int _lastIndexForAdapt: -1
    property int _lastPosMsForSmoothing: -1
    property int _lastPosEpochMs: 0

    property int _preferredId: 0

    // Normalized query
    readonly property string queryTitle: normalizeTitle(title)
    readonly property string queryArtist: normalizeArtist(artist)
    readonly property int queryDuration: Math.round(durationSeconds())

    readonly property string queryKey: `${queryTitle}||${queryArtist}||${queryDuration}`
    readonly property string fetchKey: `${queryKey}||${selectedId}`

    // Sync outputs
    readonly property int currentIndex: syncedLyricIndexForPositionMs(effectivePositionMs())
    readonly property string currentLineText: currentIndex >= 0 ? (root.lines[currentIndex]?.text ?? "") : ""
    readonly property int prevIndex: prevNonEmptyIndex(currentIndex)
    readonly property string prevLineText: prevIndex >= 0 ? (root.lines[prevIndex]?.text ?? "") : ""
    readonly property int nextIndex: nextNonEmptyIndex(currentIndex)
    readonly property string nextLineText: nextIndex >= 0 ? (root.lines[nextIndex]?.text ?? "") : ""

    readonly property string displayText: {
        if (!root.enabled) return ""
        if (root.loading) return "Fetching lyrics…"
        if (root.instrumental) return "Instrumental"
        if (root.error && root.error.length > 0) return root.error
        return (root.currentLineText && root.currentLineText.length > 0) ? root.currentLineText : "♪"
    }

     // Time normalization (sec/ms/us)
    function looksLikeUs(x) { return x >= 100000000 } // >= 100s in µs
    function looksLikeMs(x) { return x >= 20000 }     // >= 20s in ms

    function durationSeconds() {
        if (!duration || isNaN(duration) || duration < 0) return 0
        if (looksLikeUs(duration)) return duration / 1000000.0
        if (looksLikeMs(duration)) return duration / 1000.0
        return duration
    }

    function rawPositionMs() {
        if (!position || isNaN(position) || position < 0) return 0
        if (looksLikeUs(position)) return Math.round(position / 1000.0)
        if (looksLikeMs(position)) return Math.round(position)
        return Math.round(position * 1000.0)
    }

    function nowEpochMs() { return Date.now ? Date.now() : 0 }

    // Smooth position without freezing: clamp forward by elapsed wall time (+slack)
    function positionMs() {
        const ms = rawPositionMs()
        if (!root.smoothPosition) return ms

        const now = nowEpochMs()

        if (root._lastPosMsForSmoothing < 0 || root._lastPosEpochMs <= 0) {
            root._lastPosMsForSmoothing = ms
            root._lastPosEpochMs = now
            return ms
        }

        if (ms < root._lastPosMsForSmoothing) {
            root._lastPosMsForSmoothing = ms
            root._lastPosEpochMs = now
            return ms
        }

        const elapsed = Math.max(0, now - root._lastPosEpochMs)
        const allowedForward = (elapsed > 0) ? (elapsed + root.smoothSlackMs) : root.smoothMaxForwardJumpMs
        const maxTarget = root._lastPosMsForSmoothing + allowedForward
        const clamped = Math.min(ms, maxTarget)

        root._lastPosMsForSmoothing = clamped
        root._lastPosEpochMs = now
        return clamped
    }

    function effectivePositionMs() {
        var ms = positionMs()
        ms = ms + root.manualOffsetMs
        if (root.adaptiveSync) ms = ms + root.autoOffsetMs
        if (ms < 0) ms = 0
        return ms
    }

    // Normalizers (strong)
    function normalizeTitle(rawTitle) {
        if (!rawTitle) return ""

        let cleaned = StringUtils.cleanMusicTitle(rawTitle).toString()

        cleaned = cleaned.replace(/[’‘]/g, "'").replace(/[“”]/g, '"')
        cleaned = cleaned.replace(/[–—]/g, "-")

        // Keep useful suffixes after dash, drop most others
        const parts = cleaned.split(" - ")
        const main = (parts[0] ?? "").trim()
        const suffix = parts.slice(1).join(" - ").trim()

        if (suffix && /\b(remix|version|edit|mix|rework)\b/i.test(suffix))
            cleaned = `${main} ${suffix}`
        else
            cleaned = main

        // Remove bracket content except feat
        cleaned = cleaned.replace(/\s*[\(\[\{]([^\)\]\}]*)[\)\]\}]\s*/g, function(_, inner) {
            if (/(?:feat\.?|ft\.?|featuring)/i.test(inner)) {
                const m = inner.replace(/^(?:feat\.?|ft\.?|featuring)\s*/i, "").trim()
                return m ? ` feat. ${m} ` : " "
            }
            return " "
        }).replace(/\s+/g, " ").trim()

        // Extra cleanup for common junk
        cleaned = cleaned
            .replace(/\b(official|video|audio|lyrics?|lyric video|visualizer|mv|hd|4k|explicit|clean)\b/ig, " ")
            .replace(/\s+/g, " ")
            .trim()

        return cleaned
    }

    function normalizeArtist(rawArtist) {
        if (!rawArtist) return ""

        let cleaned = rawArtist.toString().trim().replace(/[’‘]/g, "'")
        cleaned = cleaned.replace(/[–—]/g, "-")

        cleaned = cleaned.split(",")[0]
        cleaned = cleaned.split(/ feat\.? /i)[0]
        cleaned = cleaned.split(/ ft\.? /i)[0]
        cleaned = cleaned.split(/ featuring /i)[0]
        cleaned = cleaned.split(/ & /)[0]
        cleaned = cleaned.split(/ x /i)[0]

        return cleaned.trim()
    }

    function normalizeResultTitle(raw) { return normalizeTitle((raw ?? "").toString()) }
    function normalizeResultArtist(raw) { return normalizeArtist((raw ?? "").toString()) }

    function stripDiacritics(s) {
        try {
            return s.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        } catch (e) {
            return s
        }
    }

    function tokenize(s) {
        if (!s) return []
        let x = s.toLowerCase()
        x = stripDiacritics(x)
        x = x.replace(/[–—]/g, "-")

        x = x.replace(/\b(official|video|audio|lyrics?|lyric video|visualizer|mv|hd|4k|explicit|clean|remastered?|remaster|version)\b/g, " ")

        return x
            .replace(/[^\p{L}\p{N}]+/gu, " ")
            .trim()
            .split(/\s+/)
            .filter(t => t.length > 0 && t !== "the" && t !== "a" && t !== "an")
    }

    function jaccard(aTokens, bTokens) {
        if (!aTokens.length || !bTokens.length) return 0
        const a = {}
        const b = {}
        for (const t of aTokens) a[t] = true
        for (const t2 of bTokens) b[t2] = true
        let inter = 0
        let uni = 0
        for (const k in a) { uni += 1; if (b[k]) inter += 1 }
        for (const k2 in b) { if (!a[k2]) uni += 1 }
        return uni > 0 ? (inter / uni) : 0
    }

    // Attempt-based strictness (relax on later attempts)
    function minTitleSimForAttempt(att) {
        if (att <= 1) return root.minTitleSim
        if (att === 2) return Math.max(0.30, root.minTitleSim - 0.10)
        return Math.max(0.20, root.minTitleSim - 0.18)
    }

    function minArtistSimForAttempt(att) {
        if (att <= 1) return root.minArtistSim
        if (att === 2) return Math.max(0.30, root.minArtistSim - 0.12)
        return Math.max(0.20, root.minArtistSim - 0.20)
    }

    function maxDurationDiffForAttempt(att) {
        if (att <= 1) return root.maxDurationDiffSec
        if (att === 2) return Math.max(root.maxDurationDiffSec, 6)
        return Math.max(root.maxDurationDiffSec, 10)
    }

    function minAcceptScoreForAttempt(att) {
        if (att <= 1) return root.minAcceptScore
        if (att === 2) return Math.max(170, root.minAcceptScore - 60)
        return Math.max(120, root.minAcceptScore - 90)
    }

    // LRC parsing (ms) + [offset:]
    function parseSyncedLyrics(lrcText) {
        if (!lrcText)
            return { offsetMs: 0, lines: [] }

        const parsed = []
        const rawLines = lrcText.split(/\r?\n/)
        const timeTag = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g

        let offsetMs = 0

        for (const rawLine of rawLines) {
            if (!rawLine) continue

            const meta = rawLine.match(/^\s*\[(\w+)\s*:\s*([^\]]*)\]\s*$/)
            if (meta) {
                const key = (meta[1] ?? "").toLowerCase()
                const val = (meta[2] ?? "").trim()
                if (key === "offset") {
                    const n = parseInt(val, 10)
                    if (!isNaN(n)) offsetMs = n
                }
                continue
            }

            timeTag.lastIndex = 0
            const timesMs = []
            let match

            while ((match = timeTag.exec(rawLine)) !== null) {
                const minutes = parseInt(match[1], 10)
                const seconds = parseInt(match[2], 10)
                const fraction = match[3]

                let millis = 0
                if (fraction !== undefined) {
                    if (fraction.length === 1) millis = parseInt(fraction, 10) * 100
                    else if (fraction.length === 2) millis = parseInt(fraction, 10) * 10
                    else millis = parseInt(fraction.padEnd(3, "0").slice(0, 3), 10)
                }

                const tMs = (minutes * 60 + seconds) * 1000 + millis
                timesMs.push(tMs)
            }

            if (timesMs.length === 0) continue

            const text = rawLine.replace(timeTag, "").trim()
            for (const tMs of timesMs) parsed.push({ timeMs: tMs, text: text })
        }

        parsed.sort((a, b) => a.timeMs - b.timeMs)

        const compact = []
        for (let i = 0; i < parsed.length; i++) {
            const cur = parsed[i]
            if (compact.length === 0) compact.push(cur)
            else {
                const last = compact[compact.length - 1]
                if (last.timeMs === cur.timeMs) compact[compact.length - 1] = cur
                else compact.push(cur)
            }
        }

        return { offsetMs: offsetMs, lines: compact }
    }

    // Indexing
    function syncedLyricIndexForPositionMs(posMs) {
        if (!root.lines || root.lines.length === 0) return -1
        if (isNaN(posMs) || posMs < 0) posMs = 0

        let lo = 0
        let hi = root.lines.length - 1
        let idx = -1

        while (lo <= hi) {
            const mid = (lo + hi) >> 1
            if ((root.lines[mid]?.timeMs ?? 0) <= posMs) {
                idx = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }

        for (let i = idx; i >= 0; --i) {
            const text = root.lines[i]?.text ?? ""
            if (text && text.length > 0) return i
        }
        return -1
    }

    function nextNonEmptyIndex(fromIndex) {
        if (!root.lines || root.lines.length === 0) return -1
        let startIndex = fromIndex
        if (startIndex < -1) startIndex = -1
        for (let i = startIndex + 1; i < root.lines.length; ++i) {
            const text = root.lines[i]?.text ?? ""
            if (text && text.length > 0) return i
        }
        return -1
    }

    function prevNonEmptyIndex(fromIndex) {
        if (!root.lines || root.lines.length === 0) return -1
        if (fromIndex <= 0) return -1
        for (let i = fromIndex - 1; i >= 0; --i) {
            const text = root.lines[i]?.text ?? ""
            if (text && text.length > 0) return i
        }
        return -1
    }

      // Adaptive sync (learn offset on line transitions)
    function applyAdaptiveOffsetIfNeeded() {
        if (!root.adaptiveSync) return
        if (!root.lines || root.lines.length === 0) return

        const idx = root.currentIndex
        if (idx < 0) return
        if (idx === root._lastIndexForAdapt) return

        root._lastIndexForAdapt = idx

        const lineTime = root.lines[idx]?.timeMs ?? 0
        const posNow = positionMs() + root.manualOffsetMs // learn without auto offset
        const err = lineTime - posNow

        const clampedErr = Math.max(-root.adaptiveMaxAbsMs, Math.min(root.adaptiveMaxAbsMs, Math.round(err)))
        const newOffset = Math.round((1.0 - root.adaptiveAlpha) * root.autoOffsetMs + root.adaptiveAlpha * clampedErr)
        root.autoOffsetMs = Math.max(-root.adaptiveMaxAbsMs, Math.min(root.adaptiveMaxAbsMs, newOffset))
    }

    onCurrentIndexChanged: applyAdaptiveOffsetIfNeeded()

       // Fetch strategy + cache bestId
     function buildLyricsSearchUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search"
        const baseGet = "https://lrclib.net/api/get"

        const t = root.queryTitle
        const a = root.queryArtist
        const d = root.queryDuration

        if (!t || !a) return ""

        // 0) explicit selectedId
        if (root.selectedId > 0) {
            if (attempt === 0) return `${baseGet}/${root.selectedId}`
            attempt -= 1
        }

        // 1) preferredId from cache
        if (root._preferredId > 0) {
            if (attempt === 0) return `${baseGet}/${root._preferredId}`
            attempt -= 1
        }

        // 2) strict get by params (fast)
        if (attempt === 0) {
            let url = `${baseGet}?track_name=${encodeURIComponent(t)}&artist_name=${encodeURIComponent(a)}`
            if (d > 0) url += `&duration=${d}`
            return url
        }

        // 3) search track+artist (+duration)
        if (attempt === 1) {
            let url = `${baseSearch}?track_name=${encodeURIComponent(t)}&artist_name=${encodeURIComponent(a)}`
            if (d > 0) url += `&duration=${d}`
            return url
        }

        // 4) combined q
        if (attempt === 2)
            return `${baseSearch}?q=${encodeURIComponent(`${t} ${a}`)}`

        // 5) title only (last resort)
        if (attempt === 3)
            return `${baseSearch}?q=${encodeURIComponent(t)}`

        return ""
    }

    function scoreResult(item) {
        const syncedLyrics = (item?.syncedLyrics ?? "").toString()
        if (!syncedLyrics || syncedLyrics.length < 16) return { ok: false, score: -1e9, titleSim: 0, artistSim: 0 }
        if (item?.instrumental) return { ok: false, score: -1e9, titleSim: 0, artistSim: 0 }

        const att = (typeof fetcher?.attempt === "number") ? fetcher.attempt : root.attempt
        const minT = minTitleSimForAttempt(att)
        const minA = minArtistSimForAttempt(att)
        const maxDurDiff = maxDurationDiffForAttempt(att)
        const minScore = minAcceptScoreForAttempt(att)

        const qT = root.queryTitle
        const qA = root.queryArtist
        const qTn = stripDiacritics(qT.toLowerCase())
        const qAn = stripDiacritics(qA.toLowerCase())
        const qDur = root.queryDuration

        const itTitle = normalizeResultTitle(item?.trackName ?? item?.name ?? "")
        const itArtist = normalizeResultArtist(item?.artistName ?? "")

        const itTitleLower = stripDiacritics(itTitle.toLowerCase())
        const itArtistLower = stripDiacritics(itArtist.toLowerCase())

        const titleSim = jaccard(tokenize(itTitle), tokenize(qT))
        const artistSim = jaccard(tokenize(itArtist), tokenize(qA))

        // Hard rejection rules: relax as attempt increases
        if (qA && (itArtistLower !== qAn) && artistSim < minA)
            return { ok: false, score: -1e9, titleSim: titleSim, artistSim: artistSim }

        if (qT && (itTitleLower !== qTn) && titleSim < minT)
            return { ok: false, score: -1e9, titleSim: titleSim, artistSim: artistSim }

        // Duration: only if both sides have it; relax on later attempts
        if (qDur > 0 && typeof item?.duration === "number" && item.duration > 0) {
            const diff = Math.abs(item.duration - qDur)
            if (diff > maxDurDiff)
                return { ok: false, score: -1e9, titleSim: titleSim, artistSim: artistSim }
        }

        function badnessPenalty(s) {
            const bad = /\b(live|karaoke|cover|remaster|remastered|demo|tribute|piano|instrumental|slowed|reverb|nightcore)\b/i
            return bad.test(s) ? 90 : 0
        }

        let score = 0

        if (itArtistLower && itArtistLower === qAn) score += 260
        if (itTitleLower && itTitleLower === qTn) score += 220

        score += titleSim * 180
        score += artistSim * 170

        if (qDur > 0 && typeof item?.duration === "number" && item.duration > 0) {
            const diff2 = Math.abs(item.duration - qDur)
            if (diff2 <= 1) score += 120
            else if (diff2 <= 2) score += 70
            else if (diff2 <= 3) score += 35
            else if (diff2 <= 6) score += 10
        }

        score -= badnessPenalty(itTitleLower)
        score -= badnessPenalty(itArtistLower)

        score += Math.min(syncedLyrics.length, 7000) / 35

        if (typeof item?.id === "number" && item.id > 0) score += 12

        const ok = score >= minScore
        return { ok: ok, score: score, titleSim: titleSim, artistSim: artistSim }
    }

    function pickBestLyricsResult(results) {
        if (!Array.isArray(results) || results.length === 0) return null

        let best = null
        let bestScore = -1e9

        for (const item of results) {
            const s = scoreResult(item)
            if (!s.ok) continue
            if (s.score > bestScore) {
                bestScore = s.score
                best = item
            }
        }

        return best
    }

    function validateDirectGetObject(obj) {
        if (!obj || typeof obj !== "object") return null
        const s = scoreResult(obj)
        return s.ok ? obj : null
    }

    // Negative cache
    function negCacheKey() {
        return `${root.queryTitle}||${root.queryArtist}||${root.queryDuration}||${root.selectedId}`
    }

    function isNegCachedFresh() {
        const k = negCacheKey()
        const entry = root._negCache[k]
        if (!entry) return false
        const ts = entry.ts ?? 0
        if (!ts) return false
        const age = nowEpochMs() - ts
        return age >= 0 && age < root.negativeCacheTtlMs
    }

    function setNegCache(reason) {
        const k = negCacheKey()
        root._negCache[k] = { ts: nowEpochMs(), reason: reason || "fail" }
    }

    // Lifecycle
    function resetState() {
        root.loading = false
        root.error = ""
        root.instrumental = false
        root.lines = []
        root.loadedKey = ""
        root.requestKey = ""
        root.attempt = 0
        root.startPending = false

        root._lastIndexForAdapt = -1
        root.autoOffsetMs = 0

        root._lastPosMsForSmoothing = -1
        root._lastPosEpochMs = 0

        root._preferredId = 0
    }

    function ensureFetched() {
        if (!root.enabled) return

        if (!root.queryTitle || !root.queryArtist) {
            root.error = "No track info"
            return
        }

        if (root.loadedKey === root.fetchKey) return
        if (root.loading && root.requestKey === root.fetchKey) return
        if (fetcher.running && fetcher.requestKey === root.fetchKey) return

        if (isNegCachedFresh()) {
            root.loading = false
            root.error = "No synced lyrics"
            return
        }

        root.requestId += 1
        root.attempt = 0
        root.requestKey = root.fetchKey

        root.loading = true
        root.error = ""
        root.instrumental = false
        root.lines = []

        if (fetcher.running) {
            root.startPending = true
            return
        }

        root.fetchAttempt(root.requestId)
    }

    function fetchAttempt(requestId) {
        if (requestId !== root.requestId) return
        if (root.requestKey !== root.fetchKey) return

        const url = root.buildLyricsSearchUrl(root.attempt)
        if (!url) {
            root.loading = false
            root.error = "No synced lyrics"
            setNegCache("no-url")
            return
        }

        fetcher.requestId = requestId
        fetcher.requestKey = root.requestKey
        fetcher.attempt = root.attempt

        fetcher.command = [
            "curl",
            "-fsSL",
            "--compressed",
            "--connect-timeout", "2",
            "--max-time", "6",
            "--retry", "1",
            "--retry-delay", "0",
            "--retry-max-time", "6",
            "-H", "Accept: application/json",
            url
        ]
        fetcher.running = true
    }

    Timer {
        id: fetchDebounce
        interval: 140
        repeat: false
        onTriggered: root.ensureFetched()
    }

    // Cache
    function cacheKey(track, artist, durationSec) {
        return `${track}||${artist}||${durationSec}`
    }

    function getCached(track, artist, durationSec) {
        const key = cacheKey(track, artist, durationSec)
        return root._cache[key] || null
    }

    function setCache(track, artist, durationSec, data) {
        const key = cacheKey(track, artist, durationSec)
        root._cache[key] = data
        saveCache()
    }

    function saveCache() {
        lyricFileView.setText(JSON.stringify(root._cache, null, 2))
    }

    FileView {
        id: lyricFileView
        path: Directories.lyricsPath
        property bool isInitialLoad: true

        onLoaded: {
            if (isInitialLoad) {
                try {
                    const loaded = JSON.parse(lyricFileView.text() || "{}")
                    root._cache = loaded
                } catch (e) {
                    root._cache = {}
                }
                isInitialLoad = false
            }
        }
    }

    // Reactivity
    onFetchKeyChanged: {
        root.resetState()

        const cached = getCached(root.queryTitle, root.queryArtist, root.queryDuration)
        if (cached) {
            const cachedLines = cached.lines || []
            if (Array.isArray(cachedLines) && cachedLines.length > 0) {
                root.instrumental = cached.instrumental || false
                root.lines = cachedLines
                root.loading = false
                root.error = ""
                root.loadedKey = root.fetchKey
                root._preferredId = cached.bestId || 0
                return
            }

            root._preferredId = cached.bestId || 0
        }

        if (root.enabled) fetchDebounce.restart()
    }

    onSelectedIdChanged: {
        root.resetState()
        if (root.enabled) fetchDebounce.restart()
    }

    onEnabledChanged: {
        if (root.enabled) fetchDebounce.restart()
        else {
            root.loading = false
            root.startPending = false
        }
    }

    // Fetcher
    Process {
        id: fetcher
        property int requestId: 0
        property string requestKey: ""
        property int attempt: 0

        running: false
        command: ["curl", "-fsSL", "https://lrclib.net/api/search?q="]

        stdout: StdioCollector {
            onStreamFinished: {
                const requestId = fetcher.requestId
                const requestKey = fetcher.requestKey

                if (requestKey !== root.fetchKey) {
                    if (root.startPending) {
                        root.startPending = false
                        if (root.enabled) root.fetchAttempt(root.requestId)
                    }
                    return
                }

                if (!text || text.length === 0) {
                    root.attempt += 1
                    if (root.attempt > 3) {
                        root.loading = false
                        root.error = "No synced lyrics"
                        setNegCache("empty")
                        return
                    }
                    root.fetchAttempt(requestId)
                    return
                }

                try {
                    const parsed = JSON.parse(text)

                    let results = []
                    if (Array.isArray(parsed)) {
                        results = parsed
                    } else if (parsed && typeof parsed === "object" && !parsed.code && !parsed.error) {
                        const okObj = validateDirectGetObject(parsed)
                        if (okObj) results = [okObj]
                        else results = []
                    }

                    let filtered = results
                    if (fetcher.attempt === 3 && root.queryArtist) {
                        const want = stripDiacritics(root.queryArtist.toLowerCase())
                        filtered = results.filter(item => stripDiacritics(normalizeResultArtist(item?.artistName ?? "").toLowerCase()) === want)
                    }

                    const best = root.pickBestLyricsResult(filtered)
                    if (!best) {
                        root.attempt += 1
                        if (root.attempt > 3) {
                            root.loading = false
                            root.error = "No synced lyrics"
                            setNegCache("no-best-or-rejected")
                            return
                        }
                        root.fetchAttempt(requestId)
                        return
                    }

                    const bestInstrumental = best.instrumental ?? false
                    const parsedLrc = root.parseSyncedLyrics(best.syncedLyrics ?? "")
                    const offsetMs = (parsedLrc.offsetMs ?? 0)

                    const finalLines = (parsedLrc.lines ?? [])
                        .map(function(it) {
                            return {
                                timeMs: Math.max(0, Math.round((it.timeMs ?? 0) + offsetMs)),
                                text: (it.text ?? "").toString()
                            }
                        })
                        .sort(function(a, b) { return a.timeMs - b.timeMs })

                    if (finalLines.length === 0 && !bestInstrumental) {
                        root.attempt += 1
                        if (root.attempt > 3) {
                            root.loading = false
                            root.error = "No synced lyrics"
                            setNegCache("empty-lines")
                            return
                        }
                        root.fetchAttempt(requestId)
                        return
                    }

                    root.instrumental = bestInstrumental
                    root.lines = finalLines

                    root.loading = false
                    root.error = (root.lines.length === 0 && root.instrumental) ? "Instrumental" : ""
                    root.loadedKey = requestKey

                    const bestId = (typeof best?.id === "number") ? best.id : 0
                    root.setCache(root.queryTitle, root.queryArtist, root.queryDuration, {
                        bestId: bestId,
                        instrumental: root.instrumental,
                        lines: root.lines,
                        meta: {
                            trackName: (best?.trackName ?? best?.name ?? "").toString(),
                            artistName: (best?.artistName ?? "").toString(),
                            duration: (typeof best?.duration === "number") ? best.duration : 0
                        }
                    })
                } catch (e) {
                    root.attempt += 1
                    if (root.attempt > 3) {
                        root.loading = false
                        root.error = "No synced lyrics"
                        setNegCache("json")
                        return
                    }
                    root.fetchAttempt(requestId)
                }
            }
        }
    }
}


pragma ComponentBehavior: Bound
pragma Singleton

import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    // =========================
    // OCR: CONFIG (SOLO INGLÉS + ESPAÑOL)
    // =========================
    property string ocrLangMode: "latin"
    property string ocrLangLatin: "eng+spa"

    // Compat: no se usan en este modo
    property string ocrLangHebrew: "heb+eng"
    property string ocrLangMixed: "heb+eng+spa"

    // PSMs
    property int ocrPsmPrimary: 6
    property int ocrPsmFallback: 4
    property int ocrPsmSparseLast: 11

    property int ocrUserDefinedDpi: 450
    property bool ocrNormalizeText: true
    property bool ocrNotifyOnComplete: true
    property bool ocrEnglishFixups: true

    // TSV merge superscripts -> ^N (antes de la palabra)
    property bool ocrSuperscriptsCaret: true

    function shQuote(s) {
        return "'" + StringUtils.shellSingleQuoteEscape(s) + "'";
    }

    function getCommand(x, y, width, height, screenshotPath, action, saveDir) {
        if (saveDir === undefined || saveDir === null)
            saveDir = "";

        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);

        const qShot = shQuote(screenshotPath);

        const cropBase = "magick " + qShot + " -crop " + rw + "x" + rh + "+" + rx + "+" + ry;
        const cropToStdout = cropBase + " png:-";
        const cropInPlace = cropBase + " " + qShot;
        const cleanup = "rm -f " + qShot;
        const slurpRegion = rx + "," + ry + " " + rw + "x" + rh;

        function uploadAndGetUrl(filePath) {
            const qFile = shQuote(filePath);
            return "curl -sF files[]=@"+ qFile + " " + root.fileUploadApiEndpoint + " | jq -r '.files[0].url'";
        }

        const annotationCommand = (Config.options.regionSelector.annotation.useSatty ? "satty" : "swappy") + " -f -";

        switch (action) {
            case ScreenshotAction.Action.Copy: {
                if (saveDir === "") {
                    return ["bash", "-c", cropToStdout + " | wl-copy && " + cleanup];
                }

                const qSaveDir = shQuote(saveDir);
                const cmd =
                    "mkdir -p " + qSaveDir + " && " +
                    "saveFileName=\"screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png\" && " +
                    "savePath=\"" + saveDir + "/$saveFileName\" && " +
                    cropToStdout + " | tee >(wl-copy) > \"$savePath\" && " +
                    cleanup;

                return ["bash", "-c", cmd];
            }

            case ScreenshotAction.Action.Edit: {
                return ["bash", "-c", cropToStdout + " | " + annotationCommand + " && " + cleanup];
            }

            case ScreenshotAction.Action.Search: {
                const cmd2 =
                    cropInPlace + " && " +
                    "xdg-open \"" + root.imageSearchEngineBaseUrl + "$(" + uploadAndGetUrl(screenshotPath) + ")\" && " +
                    cleanup;
                return ["bash", "-c", cmd2];
            }

            case ScreenshotAction.Action.CharRecognition: {
                const qLatin = shQuote(root.ocrLangLatin);

                const dpi = Math.max(70, Math.round(root.ocrUserDefinedDpi || 300));
                const notifyFlag = root.ocrNotifyOnComplete ? "1" : "0";
                const engFixFlag = root.ocrEnglishFixups ? "1" : "0";
                const supFlag = root.ocrSuperscriptsCaret ? "1" : "0";

                // =========================
                // PREPROCESS
                //  - Tu caso es texto blanco sobre negro => NEGATE suele mejorar muchísimo.
                // =========================

                // Body (normal)
                const preprocessBody =
                    cropBase + " " +
                    "-alpha off " +
                    "-colorspace Gray " +
                    "-filter Lanczos -resize 520% " +
                    "-auto-level " +
                    "-deskew 40% " +
                    "-unsharp 0x0.9+0.8+0.02 " +
                    "png:-";

                // Body (negado: negro sobre blanco)
                const preprocessBodyNeg =
                    cropBase + " " +
                    "-alpha off " +
                    "-colorspace Gray " +
                    "-negate " +
                    "-filter Lanczos -resize 520% " +
                    "-auto-level " +
                    "-deskew 40% " +
                    "-unsharp 0x0.9+0.8+0.02 " +
                    "png:-";

                // Supers (normal): súper agresivo para numeritos pequeñitos
                const preprocessSup =
                    cropBase + " " +
                    "-alpha off " +
                    "-colorspace Gray " +
                    "-filter Lanczos -resize 1600% " +
                    "-auto-level " +
                    "-contrast-stretch 0x0.7% " +
                    "-adaptive-threshold 21x21+8% " +
                    "-morphology dilate diamond:1 " +
                    "-unsharp 0x1.1+1.5+0.01 " +
                    "png:-";

                // Supers (negado)
                const preprocessSupNeg =
                    cropBase + " " +
                    "-alpha off " +
                    "-colorspace Gray " +
                    "-negate " +
                    "-filter Lanczos -resize 1600% " +
                    "-auto-level " +
                    "-contrast-stretch 0x0.7% " +
                    "-adaptive-threshold 21x21+8% " +
                    "-morphology dilate diamond:1 " +
                    "-unsharp 0x1.1+1.5+0.01 " +
                    "png:-";

                // Fallback simple
                const preprocessFallback =
                    cropBase + " " +
                    "-alpha off " +
                    "-colorspace Gray " +
                    "-negate " +
                    "-filter Lanczos -resize 420% " +
                    "-auto-level " +
                    "-deskew 40% " +
                    "-unsharp 0x0.8+0.7+0.02 " +
                    "-morphology close octagon:1 " +
                    "png:-";

                // =========================
                // POST
                // =========================
                const perlPost = root.ocrNormalizeText
                    ? "perl -CS -pe " + root.shQuote(
                        "s/\\r$//;" +
                        "s/\\x{00A0}/ /g;" +
                        "s/[\\x{2010}\\x{2011}\\x{2012}\\x{2013}\\x{2014}\\x{2212}]/-/g;" +
                        "s/[\\x{201C}\\x{201D}]/\\\"/g;" +
                        "s/[\\x{2018}\\x{2019}]/'/g;" +
                        "s/\\x{FB01}/fi/g; s/\\x{FB02}/fl/g; s/\\x{FB00}/ff/g; s/\\x{FB03}/ffi/g; s/\\x{FB04}/ffl/g;" +
                        "s/[\\t ]+/ /g;" +
                        "s/[\\x{200E}\\x{200F}]//g;" +
                        "s/[\\x{202A}-\\x{202E}]//g;" +
                        "s/[\\x{2066}-\\x{2069}]//g;" +
                        "s/^ +| +$//g;"
                      )
                    : "cat";

                const perlEnglishFix = "perl -CS -pe " + root.shQuote(
                    // Tu caso: I leída como | o 1
                    "s/(^|\\s)\\|(\\s)/$1I$2/g;" +              // ' | ' -> ' I '
                    "s/\\b\\|(?=\\p{L})/I/g;" +                 // '|cause' -> 'Icause'
                    "s/(?<=\\p{L})\\|\\b/I/g;" +                // 'live|' -> 'liveI' (raro pero por si acaso)
                    "s/\\b1t\\b/it/g;" +
                    "s/\\b1f\\b/If/g;" +
                    "s/(?<=\\p{L})1(?=\\p{L})/i/g;" +
                    "s/\\bIT\\b/I/g;" +
                    "s/\\b1s\\b/is/g;"
                );

                const bash =
                    "set -uo pipefail; " +
                    "export LC_ALL=C.UTF-8; export LANG=C.UTF-8; " +
                    "export PATH=\"$PATH:/usr/bin:/usr/local/bin\"; " +

                    "log=/tmp/qs-ocr.log; mkdir -p /tmp; touch \"$log\"; " +
                    "echo \"--- qs-ocr $(date -Is) ---\" >> \"$log\"; " +
                    "echo \"[bin] magick=$(command -v magick || echo none)\" >> \"$log\"; " +
                    "echo \"[bin] tesseract=$(command -v tesseract || echo none)\" >> \"$log\"; " +
                    "echo \"[bin] python3=$(command -v python3 || echo none)\" >> \"$log\"; " +

                    "lang_latin=" + qLatin + "; " +
                    "dpi=" + dpi + "; " +
                    "notify=" + notifyFlag + "; " +
                    "engfix=" + engFixFlag + "; " +
                    "supers=" + supFlag + "; " +

                    "pre_body(){ " + preprocessBody + "; }; " +
                    "pre_body_neg(){ " + preprocessBodyNeg + "; }; " +
                    "pre_sup(){ " + preprocessSup + "; }; " +
                    "pre_sup_neg(){ " + preprocessSupNeg + "; }; " +
                    "pre_fallback(){ " + preprocessFallback + "; }; " +

                    "post(){ " + perlPost + "; }; " +
                    "english_fix(){ " + perlEnglishFix + "; }; " +

                    "fixups(){ perl -CS -pe 's/\\s+([,.;:\\)\\]\\}])/\\1/g; s/([,;:])(?=[\\p{L}\\p{N}\\(\\[])/$1 /g; s/[\\t ]{2,}/ /g; s/^ +| +$//g;'; }; " +

                    "copy_file_to_clipboard(){ " +
                    "  local f=\"$1\"; " +
                    "  if command -v wl-copy >/dev/null 2>&1; then wl-copy --type text/plain\\;charset=utf-8 < \"$f\"; return 0; " +
                    "  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard < \"$f\"; return 0; " +
                    "  elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input < \"$f\"; return 0; " +
                    "  else echo \"[copy][ERR] no clipboard tool\" >> \"$log\"; return 1; fi; " +
                    "}; " +

                    "notify_done(){ " +
                    "  local msg=\"$1\"; " +
                    "  [ \"$notify\" = \"1\" ] || return 0; " +
                    "  if command -v notify-send >/dev/null 2>&1; then notify-send \"OCR\" \"$msg\"; fi; " +
                    "}; " +

                    "postpipe(){ post | fixups | { if [ \"$engfix\" = \"1\" ]; then english_fix; else cat; fi; }; }; " +

                    "ocr_tsv(){ " +
                    "  local stream=\"$1\"; local lang=\"$2\"; local psm=\"$3\"; " +
                    "  $stream | tesseract - stdout -l \"$lang\" --oem 1 --psm \"$psm\" --dpi \"$dpi\" " +
                    "    -c user_defined_dpi=\"$dpi\" " +
                    "    -c preserve_interword_spaces=1 " +
                    "    -c textord_tabfind_find_tables=0 " +
                    "    -c load_system_dawg=0 " +
                    "    -c load_freq_dawg=0 " +
                    "    -c tessedit_enable_dict_correction=0 " +
                    "    -c tessedit_enable_bigram_correction=0 " +
                    "    tsv 2>>\"$log\"; " +
                    "}; " +

                    "ocr_tsv_digits(){ " +
                    "  local stream=\"$1\"; local lang=\"$2\"; local psm=\"$3\"; " +
                    "  $stream | tesseract - stdout -l \"$lang\" --oem 1 --psm \"$psm\" --dpi \"$dpi\" " +
                    "    -c user_defined_dpi=\"$dpi\" " +
                    "    -c preserve_interword_spaces=1 " +
                    "    -c classify_bln_numeric_mode=1 " +
                    "    -c tessedit_char_whitelist=0123456789 " +
                    "    -c load_system_dawg=0 " +
                    "    -c load_freq_dawg=0 " +
                    "    -c tessedit_enable_dict_correction=0 " +
                    "    -c tessedit_enable_bigram_correction=0 " +
                    "    tsv 2>>\"$log\"; " +
                    "}; " +

                    // Elige el TSV (normal vs negado) con más tokens útiles
                    "choose_best_tsv(){ " +
                    "  local a=\"$1\"; local b=\"$2\"; " +
                    "  local ca cb; " +
                    "  ca=$(awk -F'\\t' 'NR>1 && $1==5 && $12!=\"\"{c++} END{print c+0}' \"$a\" 2>/dev/null || echo 0); " +
                    "  cb=$(awk -F'\\t' 'NR>1 && $1==5 && $12!=\"\"{c++} END{print c+0}' \"$b\" 2>/dev/null || echo 0); " +
                    "  if [ \"$cb\" -gt \"$ca\" ]; then echo \"$b\"; else echo \"$a\"; fi; " +
                    "}; " +

                    "merge_superscripts_from_tsv(){ " +
                    "  local body_tsv=\"$1\"; local sup_tsv=\"$2\"; " +
                    "  python3 - \"$body_tsv\" \"$sup_tsv\" << 'PY'\n" +
                    "import sys, re, statistics\n" +
                    "body_path, sup_path = sys.argv[1], sys.argv[2]\n" +
                    "\n" +
                    "def read_tsv(path):\n" +
                    "    out=[]\n" +
                    "    with open(path,'r',encoding='utf-8',errors='replace') as f:\n" +
                    "        for i,line in enumerate(f):\n" +
                    "            line=line.rstrip('\\n')\n" +
                    "            if i==0 and line.lower().startswith('level'):\n" +
                    "                continue\n" +
                    "            p=line.split('\\t')\n" +
                    "            if len(p)<12: continue\n" +
                    "            try:\n" +
                    "                level=int(p[0])\n" +
                    "                page=int(p[1]); block=int(p[2]); par=int(p[3]); line_no=int(p[4]); word_no=int(p[5])\n" +
                    "                left=int(p[6]); top=int(p[7]); w=int(p[8]); h=int(p[9])\n" +
                    "                conf=float(p[10])\n" +
                    "                text=p[11]\n" +
                    "            except Exception:\n" +
                    "                continue\n" +
                    "            if level!=5: continue\n" +
                    "            if not text or text.strip()==\"\": continue\n" +
                    "            out.append({\n" +
                    "                'page':page,'block':block,'par':par,'line':line_no,'word':word_no,\n" +
                    "                'l':left,'t':top,'w':w,'h':h,'r':left+w,'b':top+h,\n" +
                    "                'conf':conf,'text':text,'pre':[]\n" +
                    "            })\n" +
                    "    return out\n" +
                    "\n" +
                    "body=read_tsv(body_path)\n" +
                    "sup=read_tsv(sup_path)\n" +
                    "\n" +
                    "lines={}\n" +
                    "for t in body:\n" +
                    "    k=(t['page'],t['block'],t['par'],t['line'])\n" +
                    "    lines.setdefault(k,[]).append(t)\n" +
                    "for k in lines:\n" +
                    "    lines[k].sort(key=lambda x:(x['l'],x['t']))\n" +
                    "\n" +
                    "sup_by_line={}\n" +
                    "for s in sup:\n" +
                    "    k=(s['page'],s['block'],s['par'],s['line'])\n" +
                    "    sup_by_line.setdefault(k,[]).append(s)\n" +
                    "for k in sup_by_line:\n" +
                    "    sup_by_line[k].sort(key=lambda x:(x['l'],x['t']))\n" +
                    "\n" +
                    "digit_re=re.compile(r'^\\d{1,3}$')\n" +
                    "def is_sup(s):\n" +
                    "    return bool(digit_re.match(s['text'])) and s['conf']>=18 and s['h']>0 and s['w']>0\n" +
                    "\n" +
                    "def y_overlap(a,b):\n" +
                    "    return max(0, min(a['b'], b['b']) - max(a['t'], b['t']))\n" +
                    "\n" +
                    "# Insertar ^N antes de la palabra más cercana a la derecha (idealmente 'if')\n" +
                    "for k, body_line in lines.items():\n" +
                    "    sups=[s for s in sup_by_line.get(k,[]) if is_sup(s)]\n" +
                    "    if not sups or not body_line:\n" +
                    "        continue\n" +
                    "    heights=[t['h'] for t in body_line if t['h']>0]\n" +
                    "    if not heights:\n" +
                    "        continue\n" +
                    "    med_h=statistics.median(heights)\n" +
                    "    line_top=min(t['t'] for t in body_line)\n" +
                    "    line_bot=max(t['b'] for t in body_line)\n" +
                    "    line_h=max(1, line_bot-line_top)\n" +
                    "\n" +
                    "    for s in sups:\n" +
                    "        if s['h'] > med_h*0.85:\n" +
                    "            continue\n" +
                    "        if s['t'] > line_top + line_h*0.65:\n" +
                    "            continue\n" +
                    "        scx=s['l'] + s['w']/2.0\n" +
                    "        best=None\n" +
                    "        best_score=None\n" +
                    "        for t in body_line:\n" +
                    "            ov=y_overlap(s,t)\n" +
                    "            if ov==0 and not (s['b']<=t['b'] and s['b']>=t['t']):\n" +
                    "                continue\n" +
                    "            dx = t['l'] - scx\n" +
                    "            right_penalty = 0 if dx>=-3 else 2500\n" +
                    "            dy = abs((s['t']+s['h']/2.0) - (t['t']+t['h']/2.0))\n" +
                    "            score = right_penalty + abs(dx) + 0.25*dy\n" +
                    "            # bonus si la palabra es 'if' (muy típico en tu libro)\n" +
                    "            if t['text'].lower() == 'if':\n" +
                    "                score -= 200\n" +
                    "            if best_score is None or score < best_score:\n" +
                    "                best_score=score\n" +
                    "                best=t\n" +
                    "        if best is not None:\n" +
                    "            caret='^'+s['text']\n" +
                    "            if caret not in best['pre']:\n" +
                    "                best['pre'].append(caret)\n" +
                    "\n" +
                    "punct_no_space_before=set('.,;:!?)]}')\n" +
                    "punct_no_space_after=set('([{')\n" +
                    "def emit_line(toks):\n" +
                    "    out=[]\n" +
                    "    for tok in toks:\n" +
                    "        for pre in tok.get('pre',[]):\n" +
                    "            out.append(pre)\n" +
                    "        s=tok['text']\n" +
                    "        if not out:\n" +
                    "            out.append(s)\n" +
                    "            continue\n" +
                    "        prev=out[-1]\n" +
                    "        if s and s[0] in punct_no_space_before:\n" +
                    "            out[-1]=prev+s\n" +
                    "        elif prev and prev[-1] in punct_no_space_after:\n" +
                    "            out[-1]=prev+s\n" +
                    "        else:\n" +
                    "            out.append(s)\n" +
                    "    return ' '.join(out).strip()\n" +
                    "\n" +
                    "for k in sorted(lines.keys(), key=lambda k:(k[0],k[1],k[2],k[3])):\n" +
                    "    txt=emit_line(lines[k])\n" +
                    "    if txt:\n" +
                    "        print(txt)\n" +
                    "PY\n" +
                    "}; " +

                    "run_ocr(){ " +
                    "  body_a=\"$(mktemp /tmp/qs-ocr.bodyA.XXXXXX.tsv)\"; " +
                    "  body_b=\"$(mktemp /tmp/qs-ocr.bodyB.XXXXXX.tsv)\"; " +
                    "  sup_a=\"$(mktemp /tmp/qs-ocr.supA.XXXXXX.tsv)\"; " +
                    "  sup_b=\"$(mktemp /tmp/qs-ocr.supB.XXXXXX.tsv)\"; " +
                    "  trap 'rm -f \"$body_a\" \"$body_b\" \"$sup_a\" \"$sup_b\"' RETURN; " +

                    "  # Body TSV (normal vs negado)\n" +
                    "  ocr_tsv pre_body \"$lang_latin\" 6 > \"$body_a\" || true; " +
                    "  ocr_tsv pre_body_neg \"$lang_latin\" 6 > \"$body_b\" || true; " +
                    "  body_best=$(choose_best_tsv \"$body_a\" \"$body_b\"); " +

                    "  if [ \"$supers\" = \"1\" ] && command -v python3 >/dev/null 2>&1; then " +
                    "    # Supers TSV digits (normal vs negado) usando PSM 11 (sparse)\n" +
                    "    ocr_tsv_digits pre_sup \"$lang_latin\" 11 > \"$sup_a\" || true; " +
                    "    ocr_tsv_digits pre_sup_neg \"$lang_latin\" 11 > \"$sup_b\" || true; " +
                    "    sup_best=$(choose_best_tsv \"$sup_a\" \"$sup_b\"); " +
                    "    merge_superscripts_from_tsv \"$body_best\" \"$sup_best\" | postpipe; " +
                    "    return 0; " +
                    "  fi; " +

                    "  # Fallback: convertir TSV body->texto simple si no hay python/supers\n" +
                    "  awk -F'\\t' 'NR>1 && $1==5{print $12}' \"$body_best\" | sed -e 's/^ *//; s/ *$//' | tr '\\n' ' ' | sed 's/  */ /g' | postpipe; " +
                    "}; " +

                    "txtfile=\"$(mktemp /tmp/qs-ocr.XXXXXX.txt)\"; " +
                    "trap 'rm -f \"$txtfile\"' EXIT; " +
                    "run_ocr > \"$txtfile\" || true; " +
                    "bytes=$(wc -c < \"$txtfile\" | tr -d ' '); " +
                    "echo \"[end] bytes=$bytes\" >> \"$log\"; " +
                    "if [ \"$bytes\" -gt 0 ]; then " +
                    "  copy_file_to_clipboard \"$txtfile\" || true; " +
                    "  notify_done \"Texto copiado ($bytes bytes)\"; " +
                    "else " +
                    "  notify_done \"OCR falló (0 bytes). Revisa /tmp/qs-ocr.log\"; " +
                    "fi; " +
                    cleanup;

                return ["bash", "-c", bash];
            }

            case ScreenshotAction.Action.Record: {
                return ["bash", "-c", Directories.recordScriptPath + " --region " + shQuote(slurpRegion)];
            }

            case ScreenshotAction.Action.RecordWithSound: {
                return ["bash", "-c", Directories.recordScriptPath + " --region " + shQuote(slurpRegion) + " --sound"];
            }

            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                return;
        }
    }
}


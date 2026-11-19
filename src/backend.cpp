#include <archive.h>
#include <archive_entry.h>

#include "backend.h"

#include <QClipboard>
#include <QColor>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QDrag>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QFontMetrics>
#include <QGuiApplication>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QLocale>
#include <QMetaObject>
#include <QMimeData>
#include <QMimeDatabase>
#include <QMimeType>
#include <QPainter>
#include <QPixmap>
#include <QPointer>
#include <QProcess>
#include <QRegularExpression>
#include <QRunnable>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTemporaryDir>
#include <QThread>
#include <QThreadPool>
#include <QUrl>
#include <QtEndian>

#include <algorithm>
#include <functional>
#include <memory>
#include <sys/stat.h>
#include <unistd.h>

namespace {

bool isTaskCancelled(const std::atomic<bool> *flag)
{
    return flag && flag->load(std::memory_order_relaxed);
}

bool waitProcessCancelable(QProcess &proc, int timeoutMs, const std::atomic<bool> *cancelFlag = nullptr)
{
    if (!cancelFlag)
        return proc.waitForFinished(timeoutMs);

    int elapsed = 0;
    constexpr int stepMs = 40;
    while (proc.state() != QProcess::NotRunning && elapsed < timeoutMs) {
        if (cancelFlag->load(std::memory_order_relaxed)) {
            proc.kill();
            proc.waitForFinished(200);
            return false;
        }
        if (proc.waitForFinished(stepMs))
            return true;
        elapsed += stepMs;
    }
    if (proc.state() != QProcess::NotRunning) {
        proc.kill();
        proc.waitForFinished(200);
        return false;
    }
    return true;
}

bool itemExistsOrLink(const QFileInfo &fi)
{
    return fi.exists() || fi.isSymLink();
}

QString trashInfoForTrashFile(const QString &pathInTrash)
{
    const QFileInfo trashFi(pathInTrash);
    QDir dir = trashFi.dir();
    if (dir.dirName() != QLatin1String("files") || !dir.cdUp())
        return {};
    const QString candidate = dir.filePath(QStringLiteral("info/") + trashFi.fileName() + QStringLiteral(".trashinfo"));
    return QFileInfo::exists(candidate) ? candidate : QString();
}

bool isImageExtension(const QString &ext)
{
    const QString lower = ext.toLower();
    return lower == QLatin1String("png") || lower == QLatin1String("jpg") ||
           lower == QLatin1String("jpeg") || lower == QLatin1String("svg") ||
           lower == QLatin1String("webp") || lower == QLatin1String("gif");
}

QString computeFileSha256Hex(const QString &filePath, bool quickPrehash = false)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly))
        return {};

    QCryptographicHash hasher(QCryptographicHash::Sha256);
    if (quickPrehash && f.size() > 32768) {
        hasher.addData(f.read(16384));
        if (f.seek(f.size() - 16384))
            hasher.addData(f.read(16384));
        return QString::fromLatin1(hasher.result().toHex());
    }

    char buf[65536];
    qint64 bytesRead = 0;
    while ((bytesRead = f.read(buf, sizeof(buf))) > 0)
        hasher.addData(QByteArrayView(buf, bytesRead));
    return QString::fromLatin1(hasher.result().toHex());
}

struct SearchSpec {
    QString nameQuery;
    QString contentQuery;
    bool caseSensitive = false;
    bool useRegex = false;
    bool includeHidden = true;
    QString typeFilter = QStringLiteral("all"); // "all", "files", "dirs"
    qint64 minSizeBytes = 0;
    qint64 maxSizeBytes = -1;
    int modifiedWithinDays = 0;
    int maxResults = 1000;
};

SearchSpec parseSearchOptions(const QVariantMap &options)
{
    SearchSpec spec;
    spec.nameQuery = options.value(QStringLiteral("nameQuery")).toString().trimmed();
    spec.contentQuery = options.value(QStringLiteral("contentQuery")).toString();
    spec.caseSensitive = options.value(QStringLiteral("caseSensitive"), false).toBool();
    spec.useRegex = options.value(QStringLiteral("useRegex"), false).toBool();
    spec.includeHidden = options.value(QStringLiteral("includeHidden"), true).toBool();
    spec.typeFilter = options.value(QStringLiteral("typeFilter"), QStringLiteral("all")).toString();
    spec.minSizeBytes = options.value(QStringLiteral("minSizeBytes"), 0).toLongLong();
    spec.maxSizeBytes = options.value(QStringLiteral("maxSizeBytes"), -1).toLongLong();
    spec.modifiedWithinDays = options.value(QStringLiteral("modifiedWithinDays"), 0).toInt();
    spec.maxResults = std::max(1, options.value(QStringLiteral("maxResults"), 1000).toInt());
    return spec;
}

bool searchFileContent(const QString &filePath, const SearchSpec &spec, const QRegularExpression &contentRe,
                       std::atomic<bool> *cancelFlag, int *outLine, QString *outPreview)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly))
        return false;

    const QByteArray head = f.peek(4096);
    if (head.contains('\0'))
        return false;

    const Qt::CaseSensitivity cs = spec.caseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive;
    const bool useRe = contentRe.isValid() && spec.useRegex;
    int lineNum = 0;

    while (!f.atEnd()) {
        if (cancelFlag && (lineNum & 127) == 0 && cancelFlag->load(std::memory_order_relaxed))
            return false;

        QByteArray raw = f.readLine(65536);
        ++lineNum;
        if (raw.contains('\0'))
            return false;

        while (raw.endsWith('\n') || raw.endsWith('\r'))
            raw.chop(1);

        const QString line = QString::fromUtf8(raw);
        const bool hit = useRe ? contentRe.match(line).hasMatch() : line.contains(spec.contentQuery, cs);
        if (hit) {
            if (outLine)
                *outLine = lineNum;
            if (outPreview) {
                QString preview = line.trimmed();
                if (preview.size() > 140)
                    preview = preview.left(139) + QStringLiteral("…");
                *outPreview = preview;
            }
            return true;
        }
    }
    return false;
}

template <typename ProgressFn>
QVariantList runSearchImpl(const QString &rootPath, const SearchSpec &spec,
                           std::atomic<bool> *cancelFlag, ProgressFn onProgress,
                           int *outScanned = nullptr)
{
    QVariantList allResults;
    if (rootPath.isEmpty() || !QFileInfo(rootPath).isDir())
        return allResults;

    const Qt::CaseSensitivity cs = spec.caseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive;
    const QRegularExpression::PatternOptions reOpts =
        spec.caseSensitive ? QRegularExpression::NoPatternOption : QRegularExpression::CaseInsensitiveOption;

    QRegularExpression nameRe;
    bool useNameRe = false;
    if (!spec.nameQuery.isEmpty()) {
        if (spec.useRegex) {
            nameRe = QRegularExpression(spec.nameQuery, reOpts);
            useNameRe = nameRe.isValid();
        } else if (spec.nameQuery.contains('*') || spec.nameQuery.contains('?')) {
            nameRe = QRegularExpression(QRegularExpression::wildcardToRegularExpression(spec.nameQuery), reOpts);
            useNameRe = nameRe.isValid();
        }
    }

    QRegularExpression contentRe;
    if (!spec.contentQuery.isEmpty() && spec.useRegex)
        contentRe = QRegularExpression(spec.contentQuery, reOpts);

    const bool hasContentQuery = !spec.contentQuery.isEmpty();
    const bool onlyFiles = hasContentQuery || spec.typeFilter == QLatin1String("files")
                           || spec.minSizeBytes > 0 || spec.maxSizeBytes >= 0;
    const bool onlyDirs = !hasContentQuery && spec.typeFilter == QLatin1String("dirs");
    const QDateTime mtimeCutoff = (spec.modifiedWithinDays > 0)
                                      ? QDateTime::currentDateTime().addDays(-spec.modifiedWithinDays)
                                      : QDateTime();

    QDir::Filters entryFilters = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::System;
    if (spec.includeHidden)
        entryFilters |= QDir::Hidden;

    const QDir rootDir(rootPath);
    QStringList queue{rootDir.absolutePath()};
    QVariantList pendingBatch;
    int scanned = 0;

    while (!queue.isEmpty() && allResults.size() < spec.maxResults) {
        if (cancelFlag && cancelFlag->load(std::memory_order_relaxed))
            break;

        const QString dirPath = queue.takeFirst();
        const QFileInfoList entries = QDir(dirPath).entryInfoList(entryFilters);
        for (const QFileInfo &fi : entries) {
            if (cancelFlag && cancelFlag->load(std::memory_order_relaxed))
                break;

            const bool isDir = fi.isDir();
            if (isDir && !fi.isSymLink())
                queue.append(fi.absoluteFilePath());

            ++scanned;
            if ((scanned % 60) == 0 && (!pendingBatch.isEmpty() || (scanned % 240) == 0)) {
                onProgress(scanned, pendingBatch);
                pendingBatch.clear();
            }

            if (onlyFiles && isDir)
                continue;
            if (onlyDirs && !isDir)
                continue;

            const QString fileName = fi.fileName();
            if (!spec.nameQuery.isEmpty()) {
                const bool nameMatched = useNameRe ? nameRe.match(fileName).hasMatch()
                                                   : fileName.contains(spec.nameQuery, cs);
                if (!nameMatched)
                    continue;
            }

            const qint64 sz = isDir ? 0 : fi.size();
            if (spec.minSizeBytes > 0 && sz < spec.minSizeBytes)
                continue;
            if (spec.maxSizeBytes >= 0 && sz > spec.maxSizeBytes)
                continue;
            if (mtimeCutoff.isValid() && fi.lastModified() < mtimeCutoff)
                continue;

            int matchLine = 0;
            QString matchPreview;
            if (hasContentQuery) {
                constexpr qint64 kMaxSearchFileBytes = 64LL * 1024 * 1024;
                if (isDir || sz > kMaxSearchFileBytes)
                    continue;
                if (!searchFileContent(fi.absoluteFilePath(), spec, contentRe, cancelFlag, &matchLine, &matchPreview))
                    continue;
            }

            QVariantMap row;
            row[QStringLiteral("path")] = fi.absoluteFilePath();
            row[QStringLiteral("name")] = fileName;
            row[QStringLiteral("relPath")] = rootDir.relativeFilePath(fi.absoluteFilePath());
            row[QStringLiteral("isDir")] = isDir;
            row[QStringLiteral("size")] = sz;
            row[QStringLiteral("formattedSize")] = PanelModel::formatSize(sz, isDir);
            row[QStringLiteral("modified")] = fi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm"));
            row[QStringLiteral("matchLine")] = matchLine;
            row[QStringLiteral("matchPreview")] = matchPreview;
            allResults.append(row);
            pendingBatch.append(row);

            if (pendingBatch.size() >= 15) {
                onProgress(scanned, pendingBatch);
                pendingBatch.clear();
            }
            if (allResults.size() >= spec.maxResults)
                break;
        }
    }

    if (!pendingBatch.isEmpty())
        onProgress(scanned, pendingBatch);
    if (outScanned)
        *outScanned = scanned;
    return allResults;
}

QString formatHexDumpText(const QByteArray &chunk, const QString &formattedSize, qint64 totalSize)
{
    const QByteArray sample = chunk.left(512);
    QString hexDump = QObject::tr("[Binary file — %1 (%2 bytes)]\n\n").arg(formattedSize).arg(totalSize);
    for (int offset = 0; offset < sample.size(); offset += 16) {
        QString hexPart;
        QString asciiPart;
        for (int j = 0; j < 16; ++j) {
            if (offset + j < sample.size()) {
                unsigned char c = static_cast<unsigned char>(sample.at(offset + j));
                hexPart += QString("%1 ").arg(c, 2, 16, QLatin1Char('0')).toUpper();
                asciiPart += (c >= 32 && c < 127) ? QChar(c) : QChar('.');
            } else {
                hexPart += "   ";
            }
            if (j == 7)
                hexPart += " ";
        }
        hexDump += QString("%1  %2 |%3|\n")
                       .arg(offset, 6, 16, QLatin1Char('0')).toUpper()
                       .arg(hexPart, asciiPart);
    }
    return hexDump;
}

QString formatEtaSeconds(qint64 secs)
{
    if (secs < 0)
        return {};
    if (secs == 0)
        return QStringLiteral("< 1s");
    if (secs < 60)
        return QStringLiteral("%1s").arg(secs);
    if (secs < 3600) {
        return QStringLiteral("%1:%2")
            .arg(secs / 60, 2, 10, QLatin1Char('0'))
            .arg(secs % 60, 2, 10, QLatin1Char('0'));
    }
    return QStringLiteral("%1h %2m").arg(secs / 3600).arg((secs % 3600) / 60);
}

QString formatDurationMs(qint64 ms)
{
    if (ms <= 0)
        return {};
    const qint64 totalSecs = ms / 1000;
    const qint64 hrs = totalSecs / 3600;
    const qint64 mins = (totalSecs % 3600) / 60;
    const qint64 secs = totalSecs % 60;
    if (hrs > 0) {
        return QStringLiteral("%1:%2:%3")
            .arg(hrs)
            .arg(mins, 2, 10, QLatin1Char('0'))
            .arg(secs, 2, 10, QLatin1Char('0'));
    }
    return QStringLiteral("%1:%2")
        .arg(mins, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

bool isFontExtension(const QString &ext)
{
    const QString l = ext.toLower();
    return l == QLatin1String("ttf") || l == QLatin1String("otf") || l == QLatin1String("ttc")
           || l == QLatin1String("woff") || l == QLatin1String("woff2");
}

bool isAudioExtension(const QString &ext)
{
    const QString l = ext.toLower();
    return l == QLatin1String("mp3") || l == QLatin1String("wav") || l == QLatin1String("flac")
           || l == QLatin1String("ogg") || l == QLatin1String("opus") || l == QLatin1String("aac")
           || l == QLatin1String("m4a") || l == QLatin1String("wma") || l == QLatin1String("aiff");
}

bool isVideoExtension(const QString &ext)
{
    const QString l = ext.toLower();
    return l == QLatin1String("mp4") || l == QLatin1String("mkv") || l == QLatin1String("avi")
           || l == QLatin1String("mov") || l == QLatin1String("webm") || l == QLatin1String("flv")
           || l == QLatin1String("wmv") || l == QLatin1String("m4v") || l == QLatin1String("mpg")
           || l == QLatin1String("mpeg") || l == QLatin1String("ts");
}

QString syntaxLanguageForFile(const QString &fileName, const QString &ext)
{
    const QString lowerName = fileName.toLower();
    if (lowerName == QLatin1String("cmakelists.txt"))
        return QStringLiteral("CMake");
    if (lowerName == QLatin1String("makefile") || lowerName == QLatin1String("gnumakefile"))
        return QStringLiteral("Makefile");
    if (lowerName == QLatin1String("dockerfile"))
        return QStringLiteral("Dockerfile");

    static const QHash<QString, QString> langMap = {
        {QStringLiteral("cpp"), QStringLiteral("C++")},       {QStringLiteral("cc"), QStringLiteral("C++")},
        {QStringLiteral("cxx"), QStringLiteral("C++")},       {QStringLiteral("hpp"), QStringLiteral("C++")},
        {QStringLiteral("hh"), QStringLiteral("C++")},        {QStringLiteral("c"), QStringLiteral("C")},
        {QStringLiteral("h"), QStringLiteral("C/C++")},       {QStringLiteral("qml"), QStringLiteral("QML")},
        {QStringLiteral("js"), QStringLiteral("JavaScript")}, {QStringLiteral("mjs"), QStringLiteral("JavaScript")},
        {QStringLiteral("jsx"), QStringLiteral("JSX")},       {QStringLiteral("ts"), QStringLiteral("TypeScript")},
        {QStringLiteral("tsx"), QStringLiteral("TSX")},       {QStringLiteral("py"), QStringLiteral("Python")},
        {QStringLiteral("rs"), QStringLiteral("Rust")},       {QStringLiteral("go"), QStringLiteral("Go")},
        {QStringLiteral("java"), QStringLiteral("Java")},     {QStringLiteral("kt"), QStringLiteral("Kotlin")},
        {QStringLiteral("cs"), QStringLiteral("C#")},         {QStringLiteral("json"), QStringLiteral("JSON")},
        {QStringLiteral("toml"), QStringLiteral("TOML")},     {QStringLiteral("yaml"), QStringLiteral("YAML")},
        {QStringLiteral("yml"), QStringLiteral("YAML")},      {QStringLiteral("xml"), QStringLiteral("XML")},
        {QStringLiteral("html"), QStringLiteral("HTML")},     {QStringLiteral("htm"), QStringLiteral("HTML")},
        {QStringLiteral("css"), QStringLiteral("CSS")},       {QStringLiteral("scss"), QStringLiteral("SCSS")},
        {QStringLiteral("sh"), QStringLiteral("Shell")},      {QStringLiteral("bash"), QStringLiteral("Bash")},
        {QStringLiteral("zsh"), QStringLiteral("Zsh")},       {QStringLiteral("sql"), QStringLiteral("SQL")},
        {QStringLiteral("cmake"), QStringLiteral("CMake")},   {QStringLiteral("pro"), QStringLiteral("QMake")},
        {QStringLiteral("pri"), QStringLiteral("QMake")},     {QStringLiteral("ini"), QStringLiteral("INI")},
        {QStringLiteral("conf"), QStringLiteral("Config")},   {QStringLiteral("md"), QStringLiteral("Markdown")},
        {QStringLiteral("markdown"), QStringLiteral("Markdown")}
    };
    return langMap.value(ext.toLower());
}

QString highlightCodeToHtml(const QString &code, const QString &ext, bool isDark)
{
    const QString cComment = isDark ? QStringLiteral("#7f848e") : QStringLiteral("#64748b");
    const QString cKeyword = isDark ? QStringLiteral("#c678dd") : QStringLiteral("#7c3aed");
    const QString cType    = isDark ? QStringLiteral("#e5c07b") : QStringLiteral("#b45309");
    const QString cString  = isDark ? QStringLiteral("#98c379") : QStringLiteral("#047857");
    const QString cNumber  = isDark ? QStringLiteral("#d19a66") : QStringLiteral("#c2410c");
    const QString cPreproc = isDark ? QStringLiteral("#61afef") : QStringLiteral("#1d4ed8");
    const QString cPlain   = isDark ? QStringLiteral("#d4d4d8") : QStringLiteral("#1e293b");

    static const QSet<QString> keywords = {
        QStringLiteral("if"), QStringLiteral("else"), QStringLiteral("for"), QStringLiteral("while"),
        QStringLiteral("do"), QStringLiteral("switch"), QStringLiteral("case"), QStringLiteral("default"),
        QStringLiteral("break"), QStringLiteral("continue"), QStringLiteral("return"), QStringLiteral("class"),
        QStringLiteral("struct"), QStringLiteral("enum"), QStringLiteral("union"), QStringLiteral("namespace"),
        QStringLiteral("using"), QStringLiteral("public"), QStringLiteral("private"), QStringLiteral("protected"),
        QStringLiteral("virtual"), QStringLiteral("override"), QStringLiteral("final"), QStringLiteral("const"),
        QStringLiteral("constexpr"), QStringLiteral("static"), QStringLiteral("inline"), QStringLiteral("explicit"),
        QStringLiteral("template"), QStringLiteral("typename"), QStringLiteral("auto"), QStringLiteral("nullptr"),
        QStringLiteral("true"), QStringLiteral("false"), QStringLiteral("null"), QStringLiteral("None"),
        QStringLiteral("True"), QStringLiteral("False"), QStringLiteral("function"), QStringLiteral("property"),
        QStringLiteral("signal"), QStringLiteral("import"), QStringLiteral("from"), QStringLiteral("def"),
        QStringLiteral("async"), QStringLiteral("await"), QStringLiteral("fn"), QStringLiteral("let"),
        QStringLiteral("mut"), QStringLiteral("pub"), QStringLiteral("impl"), QStringLiteral("var"),
        QStringLiteral("SELECT"), QStringLiteral("FROM"), QStringLiteral("WHERE"), QStringLiteral("INSERT"),
        QStringLiteral("UPDATE"), QStringLiteral("DELETE"), QStringLiteral("JOIN"), QStringLiteral("AND"),
        QStringLiteral("OR"), QStringLiteral("try"), QStringLiteral("catch"), QStringLiteral("throw"),
        QStringLiteral("new"), QStringLiteral("export"), QStringLiteral("readonly"), QStringLiteral("id")
    };
    static const QSet<QString> types = {
        QStringLiteral("void"), QStringLiteral("bool"), QStringLiteral("int"), QStringLiteral("qint64"),
        QStringLiteral("quint64"), QStringLiteral("double"), QStringLiteral("float"), QStringLiteral("char"),
        QStringLiteral("size_t"), QStringLiteral("string"), QStringLiteral("QString"), QStringLiteral("QStringList"),
        QStringLiteral("QVariant"), QStringLiteral("QVariantMap"), QStringLiteral("QVariantList"),
        QStringLiteral("QObject"), QStringLiteral("Rectangle"), QStringLiteral("Item"), QStringLiteral("Text"),
        QStringLiteral("RowLayout"), QStringLiteral("ColumnLayout"), QStringLiteral("ListView"),
        QStringLiteral("AppDialog"), QStringLiteral("Button"), QStringLiteral("real"), QStringLiteral("color")
    };

    const QString lowerExt = ext.toLower();
    const bool usesHashComment = (lowerExt == QLatin1String("py") || lowerExt == QLatin1String("sh")
                                  || lowerExt == QLatin1String("bash") || lowerExt == QLatin1String("zsh")
                                  || lowerExt == QLatin1String("yaml") || lowerExt == QLatin1String("yml")
                                  || lowerExt == QLatin1String("toml") || lowerExt == QLatin1String("cmake")
                                  || lowerExt == QLatin1String("pro") || lowerExt == QLatin1String("pri")
                                  || lowerExt == QLatin1String("ini") || lowerExt == QLatin1String("conf")
                                  || lowerExt == QLatin1String("txt"));

    auto emitSpan = [](QString &out, const QString &color, const QString &text, bool italic = false, bool bold = false) {
        out += QStringLiteral("<span style=\"color:") + color;
        if (italic) out += QStringLiteral("; font-style:italic");
        if (bold) out += QStringLiteral("; font-weight:600");
        out += QStringLiteral(";\">") + text.toHtmlEscaped() + QStringLiteral("</span>");
    };

    QString html = QStringLiteral("<pre style=\"margin:0; font-family:monospace; white-space:pre-wrap; color:%1;\">").arg(cPlain);
    const QStringList lines = code.split('\n');
    bool inBlockComment = false;

    for (int li = 0; li < lines.size(); ++li) {
        const QString &line = lines.at(li);
        if (li > 0)
            html += '\n';

        const QString trimmed = line.trimmed();
        if (!inBlockComment && !usesHashComment && trimmed.startsWith('#')) {
            emitSpan(html, cPreproc, line, false, true);
            continue;
        }

        int i = 0;
        const int n = line.size();
        while (i < n) {
            if (inBlockComment) {
                const int end = line.indexOf(QLatin1String("*/"), i);
                if (end < 0) {
                    emitSpan(html, cComment, line.mid(i), true);
                    i = n;
                } else {
                    emitSpan(html, cComment, line.mid(i, end - i + 2), true);
                    i = end + 2;
                    inBlockComment = false;
                }
                continue;
            }

            if (line.mid(i, 2) == QLatin1String("//") || (usesHashComment && line.at(i) == '#')) {
                emitSpan(html, cComment, line.mid(i), true);
                break;
            }
            if (line.mid(i, 2) == QLatin1String("/*")) {
                const int end = line.indexOf(QLatin1String("*/"), i + 2);
                if (end < 0) {
                    emitSpan(html, cComment, line.mid(i), true);
                    inBlockComment = true;
                    break;
                }
                emitSpan(html, cComment, line.mid(i, end - i + 2), true);
                i = end + 2;
                continue;
            }

            const QChar ch = line.at(i);
            if (ch == '"' || ch == '\'' || ch == '`') {
                const QChar quote = ch;
                int j = i + 1;
                while (j < n) {
                    if (line.at(j) == '\\' && j + 1 < n) {
                        j += 2;
                        continue;
                    }
                    if (line.at(j) == quote) {
                        ++j;
                        break;
                    }
                    ++j;
                }
                emitSpan(html, cString, line.mid(i, j - i));
                i = j;
                continue;
            }

            if (ch.isDigit()) {
                int j = i + 1;
                while (j < n && (line.at(j).isLetterOrNumber() || line.at(j) == '.' || line.at(j) == '_'))
                    ++j;
                emitSpan(html, cNumber, line.mid(i, j - i));
                i = j;
                continue;
            }

            if (ch.isLetter() || ch == '_') {
                int j = i + 1;
                while (j < n && (line.at(j).isLetterOrNumber() || line.at(j) == '_'))
                    ++j;
                const QString word = line.mid(i, j - i);
                if (keywords.contains(word))
                    emitSpan(html, cKeyword, word, false, true);
                else if (types.contains(word))
                    emitSpan(html, cType, word);
                else
                    html += word.toHtmlEscaped();
                i = j;
                continue;
            }

            html += QString(ch).toHtmlEscaped();
            ++i;
        }
    }

    html += QStringLiteral("</pre>");
    return html;
}

QString renderMarkdownToHtml(const QString &md, bool isDark)
{
    const QString textColor   = isDark ? QStringLiteral("#e4e4e7") : QStringLiteral("#1e293b");
    const QString mutedColor  = isDark ? QStringLiteral("#a1a1aa") : QStringLiteral("#475569");
    const QString accentColor = isDark ? QStringLiteral("#60a5fa") : QStringLiteral("#2563eb");
    const QString codeBg      = isDark ? QStringLiteral("#18181b") : QStringLiteral("#f1f5f9");
    const QString borderCol   = isDark ? QStringLiteral("#3f3f46") : QStringLiteral("#cbd5e1");

    auto formatInline = [&](const QString &src) -> QString {
        QString s = src.toHtmlEscaped();
        static const QRegularExpression codeRe(QStringLiteral("`([^`]+)`"));
        s.replace(codeRe, QStringLiteral("<code style=\"background:%1; padding:1px 4px; font-family:monospace;\">\\1</code>").arg(codeBg));
        static const QRegularExpression linkRe(QStringLiteral("\\[([^\\]]+)\\]\\(([^)]+)\\)"));
        s.replace(linkRe, QStringLiteral("<a href=\"\\2\" style=\"color:%1;\">\\1</a>").arg(accentColor));
        static const QRegularExpression boldRe(QStringLiteral("\\*\\*([^*]+)\\*\\*"));
        s.replace(boldRe, QStringLiteral("<b>\\1</b>"));
        static const QRegularExpression italicRe(QStringLiteral("(?<!\\*)\\*([^*]+)\\*(?!\\*)"));
        s.replace(italicRe, QStringLiteral("<i>\\1</i>"));
        return s;
    };

    QString html = QStringLiteral("<div style=\"color:%1; font-size:13px; line-height:1.5;\">").arg(textColor);
    const QStringList lines = md.split('\n');
    bool inCode = false;
    bool inList = false;
    QString codeLang;
    QStringList codeBuf;

    auto flushList = [&]() {
        if (inList) {
            html += QStringLiteral("</ul>");
            inList = false;
        }
    };

    for (const QString &rawLine : lines) {
        const QString trimmed = rawLine.trimmed();
        if (trimmed.startsWith(QLatin1String("```"))) {
            flushList();
            if (!inCode) {
                inCode = true;
                codeLang = trimmed.mid(3).trimmed();
                codeBuf.clear();
            } else {
                const QString highlighted = highlightCodeToHtml(codeBuf.join('\n'), codeLang, isDark);
                html += QStringLiteral("<div style=\"background:%1; border:1px solid %2; padding:8px; margin:6px 0;\">%3</div>")
                            .arg(codeBg, borderCol, highlighted);
                inCode = false;
                codeLang.clear();
            }
            continue;
        }
        if (inCode) {
            codeBuf.append(rawLine);
            continue;
        }

        if (trimmed.isEmpty()) {
            flushList();
            html += QStringLiteral("<div style=\"height:6px;\"></div>");
            continue;
        }
        if (trimmed == QLatin1String("---") || trimmed == QLatin1String("***")) {
            flushList();
            html += QStringLiteral("<hr style=\"border:none; border-top:1px solid %1;\"/>").arg(borderCol);
            continue;
        }
        int headingLevel = 0;
        while (headingLevel < 6 && headingLevel < trimmed.size() && trimmed.at(headingLevel) == '#')
            ++headingLevel;
        if (headingLevel > 0 && headingLevel < trimmed.size() && trimmed.at(headingLevel) == ' ') {
            flushList();
            const int px = std::max(13, 23 - headingLevel * 2);
            html += QStringLiteral("<h%1 style=\"color:%2; font-size:%3px; margin:8px 0 4px 0;\">%4</h%1>")
                        .arg(headingLevel)
                        .arg(accentColor)
                        .arg(px)
                        .arg(formatInline(trimmed.mid(headingLevel + 1)));
            continue;
        }
        if (trimmed.startsWith(QLatin1String("> "))) {
            flushList();
            html += QStringLiteral("<blockquote style=\"margin:4px 0; padding:4px 10px; border-left:3px solid %1; color:%2;\">%3</blockquote>")
                        .arg(accentColor, mutedColor, formatInline(trimmed.mid(2)));
            continue;
        }
        if (trimmed.startsWith(QLatin1String("- ")) || trimmed.startsWith(QLatin1String("* "))) {
            if (!inList) {
                html += QStringLiteral("<ul style=\"margin:4px 0 4px 18px;\">");
                inList = true;
            }
            html += QStringLiteral("<li>%1</li>").arg(formatInline(trimmed.mid(2)));
            continue;
        }
        static const QRegularExpression olRe(QStringLiteral("^\\d+\\.\\s+(.*)$"));
        const QRegularExpressionMatch olMatch = olRe.match(trimmed);
        if (olMatch.hasMatch()) {
            if (!inList) {
                html += QStringLiteral("<ul style=\"margin:4px 0 4px 18px;\">");
                inList = true;
            }
            html += QStringLiteral("<li>%1</li>").arg(formatInline(olMatch.captured(1)));
            continue;
        }

        flushList();
        html += QStringLiteral("<p style=\"margin:3px 0;\">%1</p>").arg(formatInline(rawLine));
    }

    if (inCode) {
        html += QStringLiteral("<div style=\"background:%1; border:1px solid %2; padding:8px; margin:6px 0;\">%3</div>")
                    .arg(codeBg, borderCol, highlightCodeToHtml(codeBuf.join('\n'), codeLang, isDark));
    }
    flushList();
    html += QStringLiteral("</div>");
    return html;
}

QVariantMap parseExifMetadata(const QString &filePath)
{
    QVariantMap exif;
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return exif;

    const QByteArray head = file.read(256 * 1024);
    if (head.size() < 12)
        return exif;

    QByteArray tiff;
    const auto u8 = [&](int pos) -> quint8 { return static_cast<quint8>(head.at(pos)); };
    if (u8(0) == 0xFF && u8(1) == 0xD8) {
        int pos = 2;
        while (pos + 4 <= head.size()) {
            if (u8(pos) != 0xFF)
                break;
            while (pos < head.size() && u8(pos) == 0xFF)
                ++pos;
            if (pos >= head.size())
                break;
            const quint8 marker = u8(pos++);
            if (marker == 0xD9 || marker == 0xDA)
                break;
            if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7))
                continue;
            if (pos + 2 > head.size())
                break;
            const quint16 segLen = qFromBigEndian<quint16>(reinterpret_cast<const uchar *>(head.constData() + pos));
            if (segLen < 2 || pos + segLen > head.size())
                break;
            if (marker == 0xE1 && segLen >= 8 && head.mid(pos + 2, 6) == QByteArray("Exif\0\0", 6)) {
                tiff = head.mid(pos + 8, segLen - 8);
                break;
            }
            pos += segLen;
        }
    } else if ((head.startsWith(QByteArray("II*\0", 4))) || head.startsWith(QByteArray("MM\0*", 4))) {
        tiff = head;
    }

    if (tiff.size() < 8)
        return exif;

    const bool littleEndian = (tiff.at(0) == 'I' && tiff.at(1) == 'I');
    const bool bigEndian = (tiff.at(0) == 'M' && tiff.at(1) == 'M');
    if (!littleEndian && !bigEndian)
        return exif;

    auto readU16 = [&](int off) -> quint16 {
        if (off < 0 || off + 2 > tiff.size()) return 0;
        const uchar *p = reinterpret_cast<const uchar *>(tiff.constData() + off);
        return littleEndian ? qFromLittleEndian<quint16>(p) : qFromBigEndian<quint16>(p);
    };
    auto readU32 = [&](int off) -> quint32 {
        if (off < 0 || off + 4 > tiff.size()) return 0;
        const uchar *p = reinterpret_cast<const uchar *>(tiff.constData() + off);
        return littleEndian ? qFromLittleEndian<quint32>(p) : qFromBigEndian<quint32>(p);
    };

    if (readU16(2) != 42)
        return exif;

    const quint32 ifd0Offset = readU32(4);

    auto readValueOffset = [&](int entryOff, quint16 type, quint32 count) -> int {
        const qint64 typeSize = (type == 1 || type == 2 || type == 7) ? 1
                                : (type == 3) ? 2
                                : (type == 4 || type == 9) ? 4
                                : (type == 5 || type == 10) ? 8 : 1;
        const qint64 totalBytes = static_cast<qint64>(count) * typeSize;
        if (totalBytes <= 4)
            return entryOff + 8;
        const quint32 ptr = readU32(entryOff + 8);
        if (ptr >= static_cast<quint32>(tiff.size()) || ptr + totalBytes > static_cast<quint32>(tiff.size()))
            return -1;
        return static_cast<int>(ptr);
    };

    auto readAscii = [&](int dataOff, quint32 count) -> QString {
        if (dataOff < 0 || dataOff + static_cast<int>(count) > tiff.size() || count == 0)
            return {};
        QByteArray raw = tiff.mid(dataOff, static_cast<qsizetype>(count));
        const int nul = raw.indexOf('\0');
        if (nul >= 0)
            raw.truncate(nul);
        return QString::fromUtf8(raw).trimmed();
    };

    auto readRational = [&](int dataOff, int idx, quint32 *numOut, quint32 *denOut) -> double {
        const int off = dataOff + idx * 8;
        if (off < 0 || off + 8 > tiff.size())
            return 0.0;
        const quint32 num = readU32(off);
        const quint32 den = readU32(off + 4);
        if (numOut) *numOut = num;
        if (denOut) *denOut = den;
        return (den != 0) ? static_cast<double>(num) / static_cast<double>(den) : 0.0;
    };

    auto readShortOrLong = [&](int dataOff, quint16 type) -> quint32 {
        return (type == 3) ? readU16(dataOff) : readU32(dataOff);
    };

    quint32 exifSubIfd = 0;
    quint32 gpsIfd = 0;

    auto scanIfd = [&](quint32 ifdOffset, auto &&onTag) {
        if (ifdOffset < 8 || static_cast<int>(ifdOffset) + 2 > tiff.size())
            return;
        const quint16 entries = readU16(static_cast<int>(ifdOffset));
        for (quint16 i = 0; i < entries; ++i) {
            const int entryOff = static_cast<int>(ifdOffset) + 2 + i * 12;
            if (entryOff + 12 > tiff.size())
                break;
            const quint16 tag = readU16(entryOff);
            const quint16 type = readU16(entryOff + 2);
            const quint32 count = readU32(entryOff + 4);
            const int dataOff = readValueOffset(entryOff, type, count);
            if (dataOff >= 0)
                onTag(tag, type, count, dataOff);
        }
    };

    scanIfd(ifd0Offset, [&](quint16 tag, quint16 type, quint32 count, int dataOff) {
        if (tag == 0x010F && type == 2)
            exif[QStringLiteral("cameraMake")] = readAscii(dataOff, count);
        else if (tag == 0x0110 && type == 2)
            exif[QStringLiteral("cameraModel")] = readAscii(dataOff, count);
        else if (tag == 0x0112)
            exif[QStringLiteral("orientation")] = static_cast<int>(readShortOrLong(dataOff, type));
        else if (tag == 0x0132 && type == 2 && !exif.contains(QStringLiteral("dateTaken")))
            exif[QStringLiteral("dateTaken")] = readAscii(dataOff, count);
        else if (tag == 0x8769)
            exifSubIfd = readShortOrLong(dataOff, type);
        else if (tag == 0x8825)
            gpsIfd = readShortOrLong(dataOff, type);
    });

    if (exifSubIfd > 0) {
        scanIfd(exifSubIfd, [&](quint16 tag, quint16 type, quint32 count, int dataOff) {
            if (tag == 0x9003 && type == 2) {
                exif[QStringLiteral("dateTaken")] = readAscii(dataOff, count);
            } else if (tag == 0x829A && count >= 1) {
                quint32 num = 0, den = 0;
                const double val = readRational(dataOff, 0, &num, &den);
                if (val > 0.0) {
                    exif[QStringLiteral("exposure")] = (val < 1.0 && num > 0)
                        ? QStringLiteral("1/%1s").arg(qRound(static_cast<double>(den) / static_cast<double>(num)))
                        : QStringLiteral("%1s").arg(QString::number(val, 'g', 3));
                }
            } else if (tag == 0x829D && count >= 1) {
                const double fnum = readRational(dataOff, 0, nullptr, nullptr);
                if (fnum > 0.0)
                    exif[QStringLiteral("aperture")] = QStringLiteral("f/%1").arg(QString::number(fnum, 'f', 1));
            } else if (tag == 0x8827 && count >= 1) {
                exif[QStringLiteral("iso")] = static_cast<int>(readShortOrLong(dataOff, type));
            } else if (tag == 0x920A && count >= 1) {
                const double fl = readRational(dataOff, 0, nullptr, nullptr);
                if (fl > 0.0)
                    exif[QStringLiteral("focalLength")] = QStringLiteral("%1 mm").arg(QString::number(fl, 'g', 4));
            } else if (tag == 0xA002) {
                exif[QStringLiteral("pixelWidth")] = static_cast<int>(readShortOrLong(dataOff, type));
            } else if (tag == 0xA003) {
                exif[QStringLiteral("pixelHeight")] = static_cast<int>(readShortOrLong(dataOff, type));
            }
        });
    }

    if (gpsIfd > 0) {
        QString latRef, lonRef;
        double latDeg = 0.0, lonDeg = 0.0;
        bool hasLat = false, hasLon = false;
        scanIfd(gpsIfd, [&](quint16 tag, quint16 type, quint32 count, int dataOff) {
            if (tag == 0x0001 && type == 2) {
                latRef = readAscii(dataOff, count);
            } else if (tag == 0x0002 && count >= 3) {
                latDeg = readRational(dataOff, 0, nullptr, nullptr)
                         + readRational(dataOff, 1, nullptr, nullptr) / 60.0
                         + readRational(dataOff, 2, nullptr, nullptr) / 3600.0;
                hasLat = true;
            } else if (tag == 0x0003 && type == 2) {
                lonRef = readAscii(dataOff, count);
            } else if (tag == 0x0004 && count >= 3) {
                lonDeg = readRational(dataOff, 0, nullptr, nullptr)
                         + readRational(dataOff, 1, nullptr, nullptr) / 60.0
                         + readRational(dataOff, 2, nullptr, nullptr) / 3600.0;
                hasLon = true;
            }
        });
        if (hasLat && hasLon) {
            if (latRef.compare(QLatin1String("S"), Qt::CaseInsensitive) == 0) latDeg = -latDeg;
            if (lonRef.compare(QLatin1String("W"), Qt::CaseInsensitive) == 0) lonDeg = -lonDeg;
            exif[QStringLiteral("gpsLat")] = latDeg;
            exif[QStringLiteral("gpsLon")] = lonDeg;
            exif[QStringLiteral("gpsCoordinates")] = QStringLiteral("%1°, %2°")
                .arg(QString::number(latDeg, 'f', 5), QString::number(lonDeg, 'f', 5));
        }
    }

    return exif;
}

QStringList extractPdfTextBlocksNative(const QByteArray &pdfBytes)
{
    QStringList blocks;
    int pos = 0;
    while (pos < pdfBytes.size() && blocks.size() < 64) {
        const int bt = pdfBytes.indexOf("BT", pos);
        if (bt < 0)
            break;
        const int et = pdfBytes.indexOf("ET", bt + 2);
        if (et < 0)
            break;
        const QByteArray segment = pdfBytes.mid(bt + 2, et - bt - 2);
        QString blockText;
        for (int i = 0; i < segment.size(); ++i) {
            if (segment.at(i) == '(') {
                ++i;
                QByteArray lit;
                while (i < segment.size() && segment.at(i) != ')') {
                    if (segment.at(i) == '\\' && i + 1 < segment.size()) {
                        lit.append(segment.at(i + 1));
                        i += 2;
                        continue;
                    }
                    lit.append(segment.at(i));
                    ++i;
                }
                if (!lit.isEmpty()) {
                    if (!blockText.isEmpty())
                        blockText += ' ';
                    blockText += QString::fromLatin1(lit);
                }
            }
        }
        if (!blockText.trimmed().isEmpty())
            blocks.append(blockText.trimmed());
        pos = et + 2;
    }
    return blocks;
}

void populatePdfPreview(const QFileInfo &fi, int requestedPage, const QString &tempDirPath, QVariantMap &map,
                        const std::atomic<bool> *cancelFlag = nullptr)
{
    map[QStringLiteral("isPdf")] = true;
    const QString absPath = fi.absoluteFilePath();

    int pageCount = 0;
    QString pdfTitle;
    QString pdfAuthor;
    QStringList nativeBlocks;

    if (isTaskCancelled(cancelFlag))
        return;

    QFile pdfFile(absPath);
    if (pdfFile.open(QIODevice::ReadOnly)) {
        const QByteArray bytes = pdfFile.read(4 * 1024 * 1024);
        const QString latin = QString::fromLatin1(bytes);
        static const QRegularExpression pageObjRe(QStringLiteral("/Type\\s*/Page(?![A-Za-z])"));
        QRegularExpressionMatchIterator it = pageObjRe.globalMatch(latin);
        while (it.hasNext()) {
            it.next();
            ++pageCount;
        }
        static const QRegularExpression titleRe(QStringLiteral("/Title\\s*\\(([^)]*)\\)"));
        const QRegularExpressionMatch tm = titleRe.match(latin);
        if (tm.hasMatch())
            pdfTitle = tm.captured(1).trimmed();
        static const QRegularExpression authorRe(QStringLiteral("/Author\\s*\\(([^)]*)\\)"));
        const QRegularExpressionMatch am = authorRe.match(latin);
        if (am.hasMatch())
            pdfAuthor = am.captured(1).trimmed();
        nativeBlocks = extractPdfTextBlocksNative(bytes);
    }

    if (isTaskCancelled(cancelFlag))
        return;

    const QString pdfInfoBin = QStandardPaths::findExecutable(QStringLiteral("pdfinfo"));
    if (!pdfInfoBin.isEmpty()) {
        QProcess proc;
        proc.start(pdfInfoBin, {absPath});
        if (waitProcessCancelable(proc, 1200, cancelFlag) && proc.exitCode() == 0) {
            const QString infoOut = QString::fromUtf8(proc.readAllStandardOutput());
            static const QRegularExpression pagesRe(QStringLiteral("Pages:\\s+(\\d+)"));
            const QRegularExpressionMatch pm = pagesRe.match(infoOut);
            if (pm.hasMatch())
                pageCount = std::max(1, pm.captured(1).toInt());
        }
    }

    if (isTaskCancelled(cancelFlag))
        return;

    pageCount = std::max(1, pageCount);
    const int page = std::clamp(requestedPage, 1, pageCount);
    map[QStringLiteral("pdfPageCount")] = pageCount;
    map[QStringLiteral("pdfPage")] = page;
    if (!pdfTitle.isEmpty())
        map[QStringLiteral("pdfTitle")] = pdfTitle;
    if (!pdfAuthor.isEmpty())
        map[QStringLiteral("pdfAuthor")] = pdfAuthor;

    QString pageText;
    const QString pdftotextBin = QStandardPaths::findExecutable(QStringLiteral("pdftotext"));
    if (!pdftotextBin.isEmpty()) {
        QProcess proc;
        proc.start(pdftotextBin, {QStringLiteral("-f"), QString::number(page),
                                  QStringLiteral("-l"), QString::number(page), absPath, QStringLiteral("-")});
        if (waitProcessCancelable(proc, 1500, cancelFlag) && proc.exitCode() == 0)
            pageText = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    }
    if (isTaskCancelled(cancelFlag))
        return;
    if (pageText.isEmpty() && !nativeBlocks.isEmpty()) {
        const int idx = std::min(page - 1, static_cast<int>(nativeBlocks.size()) - 1);
        pageText = nativeBlocks.at(idx);
    }
    if (pageText.isEmpty())
        pageText = QObject::tr("PDF Document — Page %1 of %2").arg(page).arg(pageCount);

    map[QStringLiteral("pdfPageText")] = pageText;
    map[QStringLiteral("isText")] = true;
    map[QStringLiteral("text")] = pageText;

    const QString pdftoppmBin = QStandardPaths::findExecutable(QStringLiteral("pdftoppm"));
    if (!pdftoppmBin.isEmpty() && !tempDirPath.isEmpty()) {
        const QString prefix = QDir(tempDirPath).filePath(
            QStringLiteral("pdf_%1_p%2").arg(qHash(absPath), 0, 16).arg(page));
        QProcess proc;
        proc.start(pdftoppmBin, {QStringLiteral("-png"), QStringLiteral("-r"), QStringLiteral("110"),
                                 QStringLiteral("-f"), QString::number(page),
                                 QStringLiteral("-l"), QString::number(page),
                                 QStringLiteral("-singlefile"), absPath, prefix});
        if (waitProcessCancelable(proc, 2500, cancelFlag) && proc.exitCode() == 0) {
            const QString renderedPng = prefix + QStringLiteral(".png");
            if (QFileInfo::exists(renderedPng))
                map[QStringLiteral("pdfPageImagePath")] = QUrl::fromLocalFile(renderedPng).toString();
        }
    }
}

QVariantMap parseMediaMetadata(const QFileInfo &fi, bool isAudio, bool isVideo,
                               const std::atomic<bool> *cancelFlag = nullptr)
{
    QVariantMap info;
    const QString absPath = fi.absoluteFilePath();
    const QString ext = fi.suffix().toLower();
    info[QStringLiteral("container")] = ext.toUpper();

    // Native C++ container inspection (WAV, FLAC, MP3, MP4/MOV/M4A)
    QFile f(absPath);
    if (f.open(QIODevice::ReadOnly)) {
        const QByteArray hdr = f.read(64 * 1024);
        if (hdr.size() >= 44 && hdr.startsWith("RIFF") && hdr.mid(8, 4) == "WAVE") {
            info[QStringLiteral("codec")] = QStringLiteral("PCM WAV");
            int pos = 12;
            quint32 sampleRate = 0;
            quint16 channels = 0;
            quint32 byteRate = 0;
            quint32 dataBytes = 0;
            while (pos + 8 <= hdr.size()) {
                const QByteArray chunkId = hdr.mid(pos, 4);
                const quint32 chunkSz = qFromLittleEndian<quint32>(reinterpret_cast<const uchar *>(hdr.constData() + pos + 4));
                if (chunkId == "fmt " && pos + 8 + 16 <= hdr.size()) {
                    const uchar *p = reinterpret_cast<const uchar *>(hdr.constData() + pos + 8);
                    channels = qFromLittleEndian<quint16>(p + 2);
                    sampleRate = qFromLittleEndian<quint32>(p + 4);
                    byteRate = qFromLittleEndian<quint32>(p + 8);
                } else if (chunkId == "data") {
                    dataBytes = chunkSz;
                    break;
                }
                pos += 8 + static_cast<int>(chunkSz) + (chunkSz & 1);
            }
            if (sampleRate > 0)
                info[QStringLiteral("sampleRate")] = QStringLiteral("%1 Hz").arg(sampleRate);
            if (channels > 0)
                info[QStringLiteral("channels")] = static_cast<int>(channels);
            if (byteRate > 0) {
                info[QStringLiteral("bitrate")] = QStringLiteral("%1 kbps").arg((byteRate * 8) / 1000);
                if (dataBytes > 0) {
                    const qint64 durMs = (static_cast<qint64>(dataBytes) * 1000) / byteRate;
                    info[QStringLiteral("durationMs")] = durMs;
                    info[QStringLiteral("durationFormatted")] = formatDurationMs(durMs);
                }
            }
        } else if (hdr.size() >= 42 && hdr.startsWith("fLaC")) {
            info[QStringLiteral("codec")] = QStringLiteral("FLAC");
            const uchar *si = reinterpret_cast<const uchar *>(hdr.constData() + 8 + 10);
            const quint32 packed = (static_cast<quint32>(si[0]) << 24) | (static_cast<quint32>(si[1]) << 16)
                                   | (static_cast<quint32>(si[2]) << 8) | static_cast<quint32>(si[3]);
            const quint32 sr = (packed >> 12) & 0xFFFFF;
            const quint32 ch = ((packed >> 9) & 0x7) + 1;
            const quint64 samples = (static_cast<quint64>(packed & 0xF) << 32) | qFromBigEndian<quint32>(si + 4);
            if (sr > 0) {
                info[QStringLiteral("sampleRate")] = QStringLiteral("%1 Hz").arg(sr);
                info[QStringLiteral("channels")] = static_cast<int>(ch);
                if (samples > 0) {
                    const qint64 durMs = static_cast<qint64>((samples * 1000ULL) / sr);
                    info[QStringLiteral("durationMs")] = durMs;
                    info[QStringLiteral("durationFormatted")] = formatDurationMs(durMs);
                }
            }
        } else if (ext == QLatin1String("mp3")) {
            info[QStringLiteral("codec")] = QStringLiteral("MP3");
        } else if (ext == QLatin1String("mp4") || ext == QLatin1String("m4a") || ext == QLatin1String("mov")) {
            info[QStringLiteral("codec")] = isVideo ? QStringLiteral("H.264 / AAC") : QStringLiteral("AAC");
            const int mvhdPos = hdr.indexOf("mvhd");
            if (mvhdPos >= 4 && mvhdPos + 24 <= hdr.size()) {
                const int version = static_cast<quint8>(hdr.at(mvhdPos + 4));
                const uchar *p = reinterpret_cast<const uchar *>(hdr.constData() + mvhdPos + 4);
                quint32 timescale = 0;
                quint64 units = 0;
                if (version == 0 && mvhdPos + 24 <= hdr.size()) {
                    timescale = qFromBigEndian<quint32>(p + 12);
                    units = qFromBigEndian<quint32>(p + 16);
                } else if (version == 1 && mvhdPos + 36 <= hdr.size()) {
                    timescale = qFromBigEndian<quint32>(p + 20);
                    units = qFromBigEndian<quint64>(p + 24);
                }
                if (timescale > 0 && units > 0) {
                    const qint64 durMs = static_cast<qint64>((units * 1000ULL) / timescale);
                    info[QStringLiteral("durationMs")] = durMs;
                    info[QStringLiteral("durationFormatted")] = formatDurationMs(durMs);
                }
            }
        }
    }

    // Enrich with ffprobe when available
    const QString ffprobeBin = QStandardPaths::findExecutable(QStringLiteral("ffprobe"));
    if (!ffprobeBin.isEmpty() && !isTaskCancelled(cancelFlag)) {
        QProcess proc;
        proc.start(ffprobeBin, {QStringLiteral("-v"), QStringLiteral("quiet"),
                                QStringLiteral("-print_format"), QStringLiteral("json"),
                                QStringLiteral("-show_format"), QStringLiteral("-show_streams"), absPath});
        if (waitProcessCancelable(proc, 1500, cancelFlag) && proc.exitCode() == 0) {
            const QJsonObject root = QJsonDocument::fromJson(proc.readAllStandardOutput()).object();
            const QJsonObject fmt = root.value(QStringLiteral("format")).toObject();
            const double durSecs = fmt.value(QStringLiteral("duration")).toString().toDouble();
            if (durSecs > 0.0) {
                const qint64 durMs = static_cast<qint64>(durSecs * 1000.0);
                info[QStringLiteral("durationMs")] = durMs;
                info[QStringLiteral("durationFormatted")] = formatDurationMs(durMs);
            }
            const qint64 bitRate = fmt.value(QStringLiteral("bit_rate")).toString().toLongLong();
            if (bitRate > 0)
                info[QStringLiteral("bitrate")] = QStringLiteral("%1 kbps").arg(bitRate / 1000);
            const QJsonObject tags = fmt.value(QStringLiteral("tags")).toObject();
            const QString title = tags.value(QStringLiteral("title")).toString();
            const QString artist = tags.value(QStringLiteral("artist")).toString();
            if (!title.isEmpty()) info[QStringLiteral("title")] = title;
            if (!artist.isEmpty()) info[QStringLiteral("artist")] = artist;

            const QJsonArray streams = root.value(QStringLiteral("streams")).toArray();
            QStringList codecs;
            for (const QJsonValue &sv : streams) {
                const QJsonObject st = sv.toObject();
                const QString ctype = st.value(QStringLiteral("codec_type")).toString();
                const QString cname = st.value(QStringLiteral("codec_name")).toString().toUpper();
                if (!cname.isEmpty() && !codecs.contains(cname))
                    codecs.append(cname);
                if (ctype == QLatin1String("video")) {
                    const int w = st.value(QStringLiteral("width")).toInt();
                    const int h = st.value(QStringLiteral("height")).toInt();
                    if (w > 0 && h > 0)
                        info[QStringLiteral("resolution")] = QStringLiteral("%1 × %2").arg(w).arg(h);
                } else if (ctype == QLatin1String("audio")) {
                    const QString sr = st.value(QStringLiteral("sample_rate")).toString();
                    if (!sr.isEmpty())
                        info[QStringLiteral("sampleRate")] = QStringLiteral("%1 Hz").arg(sr);
                    const int ch = st.value(QStringLiteral("channels")).toInt();
                    if (ch > 0)
                        info[QStringLiteral("channels")] = ch;
                }
            }
            if (!codecs.isEmpty())
                info[QStringLiteral("codec")] = codecs.join(QStringLiteral(" / "));
        }
    }

    if (!info.contains(QStringLiteral("codec")) || info.value(QStringLiteral("codec")).toString().isEmpty())
        info[QStringLiteral("codec")] = ext.toUpper();
    info[QStringLiteral("mediaType")] = isAudio ? QStringLiteral("audio") : (isVideo ? QStringLiteral("video") : QStringLiteral("media"));
    return info;
}

QString expandRenameTags(const QString &tpl, const QFileInfo &fi,
                         const QString &baseName, const QString &ext,
                         int counterVal, int counterDigits,
                         bool *usedCounterOut, bool *usedExtOut)
{
    QString out = tpl;
    const QDateTime dt = fi.exists() ? fi.lastModified() : QDateTime::currentDateTime();
    const QString counterStr = QStringLiteral("%1").arg(counterVal, std::max(1, counterDigits), 10, QLatin1Char('0'));
    const QString parentName = fi.dir().dirName();

    if (out.contains(QStringLiteral("[C]"), Qt::CaseSensitive) || out.contains(QStringLiteral("[Counter]"), Qt::CaseSensitive)) {
        if (usedCounterOut)
            *usedCounterOut = true;
        out.replace(QStringLiteral("[Counter]"), counterStr);
        out.replace(QStringLiteral("[C]"), counterStr);
    }
    if (out.contains(QStringLiteral("[Ext]"), Qt::CaseSensitive) || out.contains(QStringLiteral("[E]"), Qt::CaseSensitive)) {
        if (usedExtOut)
            *usedExtOut = true;
        out.replace(QStringLiteral("[Ext]"), ext);
        out.replace(QStringLiteral("[E]"), ext);
    }

    static const QRegularExpression sliceRe(QStringLiteral("\\[N(\\d+)-(\\d+)\\]"));
    QRegularExpressionMatchIterator sliceIt = sliceRe.globalMatch(out);
    QList<QPair<QPair<qsizetype, qsizetype>, QString>> sliceRepls;
    while (sliceIt.hasNext()) {
        const QRegularExpressionMatch m = sliceIt.next();
        const int start1 = std::max(1, m.captured(1).toInt());
        const int end1 = std::max(start1, m.captured(2).toInt());
        const int start0 = start1 - 1;
        const QString sub = (start0 < baseName.size()) ? baseName.mid(start0, end1 - start0) : QString();
        sliceRepls.append({{m.capturedStart(), m.capturedLength()}, sub});
    }
    for (int i = sliceRepls.size() - 1; i >= 0; --i)
        out.replace(sliceRepls.at(i).first.first, sliceRepls.at(i).first.second, sliceRepls.at(i).second);

    out.replace(QStringLiteral("[Name]"), baseName);
    out.replace(QStringLiteral("[N]"), baseName);
    out.replace(QStringLiteral("[ParentFolder]"), parentName);
    out.replace(QStringLiteral("[Parent]"), parentName);
    out.replace(QStringLiteral("[P]"), parentName);
    out.replace(QStringLiteral("[Date]"), dt.toString(QStringLiteral("yyyy-MM-dd")));
    out.replace(QStringLiteral("[YMD]"), dt.toString(QStringLiteral("yyyy-MM-dd")));
    out.replace(QStringLiteral("[Time]"), dt.toString(QStringLiteral("HH-mm-ss")));
    out.replace(QStringLiteral("[hms]"), dt.toString(QStringLiteral("HH-mm-ss")));
    out.replace(QStringLiteral("[Year]"), dt.toString(QStringLiteral("yyyy")));
    out.replace(QStringLiteral("[Y]"), dt.toString(QStringLiteral("yyyy")));
    out.replace(QStringLiteral("[Month]"), dt.toString(QStringLiteral("MM")));
    out.replace(QStringLiteral("[M]"), dt.toString(QStringLiteral("MM")));
    out.replace(QStringLiteral("[Day]"), dt.toString(QStringLiteral("dd")));
    out.replace(QStringLiteral("[D]"), dt.toString(QStringLiteral("dd")));
    return out;
}

QString normalizeRegexReplacement(const QString &repl)
{
    QString out;
    out.reserve(repl.size());
    for (int i = 0; i < repl.size(); ++i) {
        if (repl.at(i) == '$' && i + 1 < repl.size() && repl.at(i + 1).isDigit()) {
            out += '\\';
            out += repl.at(i + 1);
            ++i;
            continue;
        }
        out += repl.at(i);
    }
    return out;
}

QString normalizeArchiveEntryPath(struct archive_entry *entry, bool *outEndsWithSlash = nullptr)
{
    const char *utf8Name = archive_entry_pathname_utf8(entry);
    QString rawName = utf8Name ? QString::fromUtf8(utf8Name)
                               : QString::fromLocal8Bit(archive_entry_pathname(entry));
    if (outEndsWithSlash)
        *outEndsWithSlash = rawName.endsWith('/') || rawName.endsWith('\\');
    rawName.replace('\\', '/');

    const QStringList rawParts = rawName.split('/', Qt::SkipEmptyParts);
    QStringList safeParts;
    for (const QString &part : rawParts) {
        if (part == QLatin1String("."))
            continue;
        if (part == QLatin1String("..")) {
            if (!safeParts.isEmpty())
                safeParts.removeLast();
            continue;
        }
        safeParts.append(part);
    }
    return safeParts.join('/');
}

bool streamArchiveToFile(struct archive *a, const QString &destPath, int perm)
{
    QFileInfo destFi(destPath);
    if (!QDir().mkpath(destFi.absolutePath()))
        return false;

    QFile out(destPath);
    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;

    const void *buff = nullptr;
    size_t size = 0;
    la_int64_t offset = 0;
    bool ok = true;

    while (true) {
        const int r = archive_read_data_block(a, &buff, &size, &offset);
        if (r == ARCHIVE_EOF)
            break;
        if (r < ARCHIVE_OK) {
            ok = false;
            break;
        }
        if (offset > out.pos()) {
            const qint64 gap = offset - out.pos();
            static const QByteArray zeros(4096, '\0');
            qint64 remaining = gap;
            while (remaining > 0) {
                const qint64 chunk = std::min<qint64>(remaining, zeros.size());
                if (out.write(zeros.constData(), chunk) != chunk) {
                    ok = false;
                    break;
                }
                remaining -= chunk;
            }
            if (!ok)
                break;
        }
        if (size > 0 && out.write(static_cast<const char *>(buff), static_cast<qint64>(size)) != static_cast<qint64>(size)) {
            ok = false;
            break;
        }
    }

    out.close();
    if (ok && perm > 0) {
        QFile::Permissions qp = QFile::ReadOwner | QFile::WriteOwner;
        if (perm & 0100) qp |= QFile::ExeOwner;
        if (perm & 0040) qp |= QFile::ReadGroup;
        if (perm & 0020) qp |= QFile::WriteGroup;
        if (perm & 0010) qp |= QFile::ExeGroup;
        if (perm & 0004) qp |= QFile::ReadOther;
        if (perm & 0002) qp |= QFile::WriteOther;
        if (perm & 0001) qp |= QFile::ExeOther;
        QFile::setPermissions(destPath, qp);
    }
    return ok;
}

bool anyPathInsideArchive(const QStringList &paths)
{
    QString arc, inner;
    for (const QString &p : paths) {
        if (PanelModel::splitArchivePath(p, &arc, &inner) && !inner.isEmpty())
            return true;
    }
    return false;
}

bool isArchiveTargetPath(const QString &targetDir)
{
    QString arc, inner;
    return PanelModel::splitArchivePath(targetDir, &arc, &inner);
}

QString findTerminalExecutable(bool fallbackXterm = true)
{
    static const QStringList candidates = {
        QStringLiteral("xdg-terminal-exec"),
        QStringLiteral("foot"),
        QStringLiteral("alacritty"),
        QStringLiteral("kitty"),
        QStringLiteral("ghostty"),
        QStringLiteral("wezterm")
    };
    for (const QString &bin : candidates) {
        const QString found = QStandardPaths::findExecutable(bin);
        if (!found.isEmpty())
            return found;
    }
    return fallbackXterm ? QStringLiteral("xterm") : QString();
}

QString envWithFallback(const char *primary, const char *fallback)
{
    const QString v = qEnvironmentVariable(primary);
    return v.isEmpty() ? qEnvironmentVariable(fallback) : v;
}

bool envIsSetWithFallback(const char *primary, const char *fallback)
{
    return qEnvironmentVariableIsSet(primary) || qEnvironmentVariableIsSet(fallback);
}

QString gvfsRootDir()
{
    const QString overrideDir = envWithFallback("TWINFORGE_GVFS_DIR", "OMAPANEL_GVFS_DIR");
    if (!overrideDir.isEmpty())
        return overrideDir;
    const QString runtimeDir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (!runtimeDir.isEmpty())
        return QDir(runtimeDir).filePath(QStringLiteral("gvfs"));
    return QStringLiteral("/run/user/%1/gvfs").arg(static_cast<unsigned long>(::getuid()));
}

QString sshfsMountsRootDir()
{
    const QString overrideDir = envWithFallback("TWINFORGE_MOUNTS_DIR", "OMAPANEL_MOUNTS_DIR");
    if (!overrideDir.isEmpty())
        return overrideDir;
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    if (cacheDir.isEmpty())
        cacheDir = QDir::homePath() + QStringLiteral("/.cache/twinforge");
    return QDir(cacheDir).filePath(QStringLiteral("mounts"));
}

QString normalizeRemoteProtocol(const QString &raw)
{
    const QString p = raw.trimmed().toLower();
    if (p == QLatin1String("gdrive") || p == QLatin1String("google-drive")
        || p == QLatin1String("google") || p == QLatin1String("google_drive"))
        return QStringLiteral("gdrive");
    if (p == QLatin1String("rclone"))
        return QStringLiteral("rclone");
    if (p == QLatin1String("ssh"))
        return QStringLiteral("sftp");
    if (p == QLatin1String("smb") || p == QLatin1String("cifs"))
        return QStringLiteral("smb");
    if (p == QLatin1String("sshfs"))
        return QStringLiteral("sshfs");
    return p.isEmpty() ? QStringLiteral("sftp") : p;
}

bool isCloudRemoteProtocol(const QString &proto)
{
    return proto == QLatin1String("gdrive") || proto == QLatin1String("rclone");
}

QString findRcloneExecutable()
{
    const QString envBin = envWithFallback("TWINFORGE_RCLONE_BIN", "OMAPANEL_RCLONE_BIN");
    if (!envBin.isEmpty()) {
        const QFileInfo fi(envBin);
        if (fi.exists() && fi.isExecutable() && !fi.isDir())
            return fi.absoluteFilePath();
    }

    const QString pathBin = QStandardPaths::findExecutable(QStringLiteral("rclone"));
    if (!pathBin.isEmpty())
        return pathBin;

    QStringList candidates = {
        QDir::homePath() + QStringLiteral("/.local/share/mise/shims/rclone"),
        QDir::homePath() + QStringLiteral("/.local/bin/rclone"),
        QStringLiteral("/usr/local/bin/rclone"),
        QStringLiteral("/usr/bin/rclone")
    };

    const QDir miseLatest(QDir::homePath() + QStringLiteral("/.local/share/mise/installs/rclone/latest"));
    if (miseLatest.exists()) {
        const QStringList subdirs = miseLatest.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const QString &sub : subdirs)
            candidates.prepend(miseLatest.filePath(sub + QStringLiteral("/rclone")));
        candidates.prepend(miseLatest.filePath(QStringLiteral("rclone")));
    }

    for (const QString &cand : candidates) {
        const QFileInfo fi(cand);
        if (fi.exists() && fi.isExecutable() && !fi.isDir())
            return fi.absoluteFilePath();
    }
    return {};
}

QStringList rcloneConfigArgs()
{
    const QString confPath = envWithFallback("TWINFORGE_RCLONE_CONF", "OMAPANEL_RCLONE_CONF");
    if (!confPath.isEmpty())
        return {QStringLiteral("--config"), confPath};
    return {};
}

QString sanitizeMountSegment(const QString &raw)
{
    QString out;
    out.reserve(raw.size());
    for (const QChar c : raw.trimmed()) {
        if (c.isLetterOrNumber() || c == QLatin1Char('_') || c == QLatin1Char('-'))
            out.append(c);
        else
            out.append(QLatin1Char('_'));
    }
    return out.isEmpty() ? QStringLiteral("remote") : out;
}

QString rcloneMountDirFor(const QString &proto, const QString &remoteName, const QString &id)
{
    const QString folderName = !id.trimmed().isEmpty()
                                   ? sanitizeMountSegment(id)
                                   : QStringLiteral("%1_%2").arg(proto, sanitizeMountSegment(remoteName));
    return QDir(sshfsMountsRootDir()).filePath(folderName);
}

QString decodeProcMountEscapes(QString s)
{
    s.replace(QStringLiteral("\\040"), QStringLiteral(" "));
    s.replace(QStringLiteral("\\011"), QStringLiteral("\t"));
    s.replace(QStringLiteral("\\012"), QStringLiteral("\n"));
    s.replace(QStringLiteral("\\134"), QStringLiteral("\\"));
    return s;
}

QString findMountedRcloneMountPoint(const QString &expectedTargetDir, const QString &remoteName)
{
    QFile procMounts(QStringLiteral("/proc/mounts"));
    if (!procMounts.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    const QString cleanExpected = expectedTargetDir.isEmpty() ? QString() : QDir::cleanPath(expectedTargetDir);
    const QString remotePrefix = remoteName + QLatin1Char(':');
    QString fallbackMatch;

    while (!procMounts.atEnd()) {
        const QString line = QString::fromUtf8(procMounts.readLine()).trimmed();
        const QStringList cols = line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (cols.size() < 3)
            continue;
        const QString dev = decodeProcMountEscapes(cols.at(0));
        const QString mnt = QDir::cleanPath(decodeProcMountEscapes(cols.at(1)));
        const QString fsType = cols.at(2);

        if (!cleanExpected.isEmpty() && mnt == cleanExpected && fsType.startsWith(QLatin1String("fuse")))
            return mnt;
        if (fallbackMatch.isEmpty() && fsType == QLatin1String("fuse.rclone")
            && dev.startsWith(remotePrefix, Qt::CaseSensitive) && QDir(mnt).exists()) {
            fallbackMatch = mnt;
        }
    }
    return fallbackMatch;
}

QString shellQuoteArg(const QString &arg)
{
    QString out = arg;
    out.replace(QLatin1Char('\''), QStringLiteral("'\\''"));
    return QLatin1Char('\'') + out + QLatin1Char('\'');
}

QStringList splitExecTokens(const QString &execStr)
{
    QStringList tokens;
    QString current;
    QChar inQuote;
    bool escape = false;
    for (int i = 0; i < execStr.size(); ++i) {
        const QChar c = execStr.at(i);
        if (escape) {
            current.append(c);
            escape = false;
            continue;
        }
        if (c == QLatin1Char('\\') && inQuote != QLatin1Char('\'')) {
            escape = true;
            continue;
        }
        if (!inQuote.isNull()) {
            if (c == inQuote)
                inQuote = QChar();
            else
                current.append(c);
            continue;
        }
        if (c == QLatin1Char('"') || c == QLatin1Char('\'')) {
            inQuote = c;
            continue;
        }
        if (c.isSpace()) {
            if (!current.isEmpty()) {
                tokens.append(current);
                current.clear();
            }
            continue;
        }
        current.append(c);
    }
    if (!current.isEmpty())
        tokens.append(current);
    return tokens;
}

QStringList xdgApplicationDirs()
{
    QStringList dirs;
    const QString overrideEnv = envWithFallback("TWINFORGE_APPS_DIR", "OMAPANEL_APPS_DIR");
    if (!overrideEnv.isEmpty()) {
        for (const QString &part : overrideEnv.split(QLatin1Char(':'), Qt::SkipEmptyParts)) {
            if (!dirs.contains(part) && QDir(part).exists())
                dirs.append(part);
        }
    }
    if (envWithFallback("TWINFORGE_APPS_ONLY_OVERRIDE", "OMAPANEL_APPS_ONLY_OVERRIDE") == QLatin1String("1"))
        return dirs;

    const QStringList stdDirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    for (const QString &d : stdDirs) {
        if (!dirs.contains(d) && QDir(d).exists())
            dirs.append(d);
    }
    static const QStringList extraDirs = {
        QStringLiteral("/usr/share/applications"),
        QStringLiteral("/usr/local/share/applications"),
        QStringLiteral("/var/lib/flatpak/exports/share/applications"),
        QDir::homePath() + QStringLiteral("/.local/share/applications"),
        QDir::homePath() + QStringLiteral("/.local/share/flatpak/exports/share/applications")
    };
    for (const QString &d : extraDirs) {
        if (!dirs.contains(d) && QDir(d).exists())
            dirs.append(d);
    }
    return dirs;
}

QString mimeAppsFilePath()
{
    const QString overridePath = envWithFallback("TWINFORGE_MIMEAPPS_FILE", "OMAPANEL_MIMEAPPS_FILE");
    if (!overridePath.isEmpty())
        return overridePath;
    return QDir::homePath() + QStringLiteral("/.config/mimeapps.list");
}

QString queryDefaultDesktopForMime(const QString &mimeType)
{
    if (mimeType.isEmpty())
        return {};

    QStringList candidateFiles;
    const QString overridePath = envWithFallback("TWINFORGE_MIMEAPPS_FILE", "OMAPANEL_MIMEAPPS_FILE");
    if (!overridePath.isEmpty()) {
        candidateFiles.append(overridePath);
    } else {
        candidateFiles.append(QDir::homePath() + QStringLiteral("/.config/mimeapps.list"));
        candidateFiles.append(QDir::homePath() + QStringLiteral("/.local/share/applications/mimeapps.list"));
        candidateFiles.append(QStringLiteral("/etc/xdg/mimeapps.list"));
    }

    for (const QString &filePath : candidateFiles) {
        QFile f(filePath);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;
        bool inDefaultSection = false;
        while (!f.atEnd()) {
            const QString line = QString::fromUtf8(f.readLine()).trimmed();
            if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
                continue;
            if (line.startsWith(QLatin1Char('[')) && line.endsWith(QLatin1Char(']'))) {
                inDefaultSection = (line == QLatin1String("[Default Applications]"));
                continue;
            }
            if (!inDefaultSection)
                continue;
            const int eq = line.indexOf(QLatin1Char('='));
            if (eq <= 0)
                continue;
            if (line.left(eq).trimmed() == mimeType) {
                const QStringList vals = line.mid(eq + 1).split(QLatin1Char(';'), Qt::SkipEmptyParts);
                if (!vals.isEmpty())
                    return vals.first().trimmed();
            }
        }
    }

    if (overridePath.isEmpty()) {
        const QString xdgMimeBin = QStandardPaths::findExecutable(QStringLiteral("xdg-mime"));
        if (!xdgMimeBin.isEmpty()) {
            QProcess proc;
            proc.start(xdgMimeBin, {QStringLiteral("query"), QStringLiteral("default"), mimeType});
            if (proc.waitForFinished(700) && proc.exitCode() == 0) {
                const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
                if (!out.isEmpty())
                    return out;
            }
        }
    }
    return {};
}

QVariantMap parseDesktopFile(const QString &desktopFilePath, bool skipExecCheck)
{
    QFile f(desktopFilePath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    bool inDesktopEntry = false;
    QString typeVal, name, genericName, comment, execStr, icon;
    QString tryExec;
    QStringList mimeTypes;
    bool terminal = false;
    bool noDisplay = false;
    bool hidden = false;

    while (!f.atEnd()) {
        const QString line = QString::fromUtf8(f.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
            continue;
        if (line.startsWith(QLatin1Char('[')) && line.endsWith(QLatin1Char(']'))) {
            if (inDesktopEntry)
                break; // Only parse main [Desktop Entry] group
            inDesktopEntry = (line == QLatin1String("[Desktop Entry]"));
            continue;
        }
        if (!inDesktopEntry)
            continue;
        const int eq = line.indexOf(QLatin1Char('='));
        if (eq <= 0)
            continue;
        const QString key = line.left(eq).trimmed();
        const QString val = line.mid(eq + 1).trimmed();

        if (key == QLatin1String("Type")) typeVal = val;
        else if (key == QLatin1String("Name")) name = val;
        else if (key == QLatin1String("GenericName")) genericName = val;
        else if (key == QLatin1String("Comment")) comment = val;
        else if (key == QLatin1String("Exec")) execStr = val;
        else if (key == QLatin1String("TryExec")) tryExec = val;
        else if (key == QLatin1String("Icon")) icon = val;
        else if (key == QLatin1String("Terminal")) terminal = (val.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0);
        else if (key == QLatin1String("NoDisplay")) noDisplay = (val.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0);
        else if (key == QLatin1String("Hidden")) hidden = (val.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0);
        else if (key == QLatin1String("MimeType")) mimeTypes = val.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    }

    if (typeVal != QLatin1String("Application") || noDisplay || hidden || name.isEmpty() || execStr.isEmpty())
        return {};

    if (!skipExecCheck) {
        if (!tryExec.isEmpty()) {
            const bool exists = QFileInfo::exists(tryExec) || !QStandardPaths::findExecutable(tryExec).isEmpty();
            if (!exists)
                return {};
        } else {
            const QStringList tokens = splitExecTokens(execStr);
            if (!tokens.isEmpty()) {
                QString bin = tokens.first();
                if (bin == QLatin1String("env") && tokens.size() > 1) {
                    for (int k = 1; k < tokens.size(); ++k) {
                        if (!tokens.at(k).contains(QLatin1Char('='))) {
                            bin = tokens.at(k);
                            break;
                        }
                    }
                }
                const bool exists = bin.startsWith(QLatin1Char('/'))
                                    ? QFileInfo::exists(bin)
                                    : !QStandardPaths::findExecutable(bin).isEmpty();
                if (!exists)
                    return {};
            }
        }
    }

    QVariantMap m;
    m[QStringLiteral("desktopId")] = QFileInfo(desktopFilePath).fileName();
    m[QStringLiteral("desktopPath")] = desktopFilePath;
    m[QStringLiteral("name")] = name;
    m[QStringLiteral("genericName")] = genericName;
    m[QStringLiteral("comment")] = comment;
    m[QStringLiteral("exec")] = execStr;
    m[QStringLiteral("icon")] = icon;
    m[QStringLiteral("terminal")] = terminal;
    m[QStringLiteral("mimeTypes")] = mimeTypes;
    m[QStringLiteral("isDefault")] = false;
    return m;
}

QVariantList collectAllDesktopApps()
{
    const QString overrideEnv = envWithFallback("TWINFORGE_APPS_DIR", "OMAPANEL_APPS_DIR");
    const bool skipExecCheck = !overrideEnv.isEmpty();
    const QStringList dirs = xdgApplicationDirs();

    QSet<QString> seenIds;
    QVariantList result;

    for (const QString &dir : dirs) {
        QDirIterator it(dir, {QStringLiteral("*.desktop")}, QDir::Files);
        while (it.hasNext()) {
            const QString filePath = it.next();
            const QString desktopId = QFileInfo(filePath).fileName();
            if (seenIds.contains(desktopId))
                continue;
            const QVariantMap parsed = parseDesktopFile(filePath, skipExecCheck);
            if (parsed.isEmpty())
                continue;
            seenIds.insert(desktopId);
            result.append(parsed);
        }
    }

    std::sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("name")).toString().compare(
                   b.toMap().value(QStringLiteral("name")).toString(), Qt::CaseInsensitive) < 0;
    });
    return result;
}

bool desktopAppSupportsMime(const QVariantMap &app, const QMimeType &mime)
{
    const QStringList supported = app.value(QStringLiteral("mimeTypes")).toStringList();
    if (supported.isEmpty())
        return false;

    const QString primary = mime.name();
    const QString superWildcard = primary.contains(QLatin1Char('/'))
                                      ? primary.left(primary.indexOf(QLatin1Char('/'))) + QStringLiteral("/*")
                                      : QString();

    for (const QString &rawPat : supported) {
        const QString pat = rawPat.trimmed();
        if (pat.isEmpty())
            continue;
        if (pat == primary || mime.aliases().contains(pat) || mime.inherits(pat))
            return true;
        if (!superWildcard.isEmpty() && pat == superWildcard)
            return true;
    }
    return false;
}

bool customActionPatternMatches(const QString &patternStr, const QFileInfo &fi, const QMimeType &mime)
{
    const QString trimmed = patternStr.trimmed();
    if (trimmed.isEmpty() || trimmed == QLatin1String("*"))
        return true;

    const QString fileName = fi.fileName();
    const bool isDir = fi.isDir();
    const QStringList tokens = trimmed.split(QRegularExpression(QStringLiteral("[;,]")), Qt::SkipEmptyParts);
    for (const QString &rawTok : tokens) {
        const QString tok = rawTok.trimmed();
        if (tok.isEmpty() || tok == QLatin1String("*"))
            return true;
        if (tok == QLatin1String("inode/directory")) {
            if (isDir)
                return true;
            continue;
        }
        if (tok.contains(QLatin1Char('/'))) {
            if (tok.endsWith(QLatin1String("/*"))) {
                const QString prefix = tok.left(tok.size() - 1);
                if (mime.name().startsWith(prefix, Qt::CaseInsensitive))
                    return true;
            } else if (mime.name().compare(tok, Qt::CaseInsensitive) == 0 || mime.inherits(tok)) {
                return true;
            }
            continue;
        }
        const QRegularExpression re = QRegularExpression::fromWildcard(tok, Qt::CaseInsensitive);
        if (re.match(fileName).hasMatch())
            return true;
    }
    return false;
}

} // namespace

Backend::Backend(const QString &bookmarksFile, QObject *parent)
    : QObject(parent),
      m_leftPanel(QDir::homePath()),
      m_rightPanel(QDir::homePath()),
      m_bookmarksFile(bookmarksFile.isEmpty() ? QDir::homePath() + "/.config/twinforge/bookmarks.json" : bookmarksFile),
      m_sessionFile(QFileInfo(m_bookmarksFile).dir().filePath("session.ini")),
      m_workspacesFile(QFileInfo(m_bookmarksFile).dir().filePath("workspaces.json"))
{
    // Migrate legacy ~/.config/omapanel/* config files once if present
    if (bookmarksFile.isEmpty()) {
        const QString legacyDir = QDir::homePath() + QStringLiteral("/.config/omapanel");
        const QString legacySession = QDir(legacyDir).filePath(QStringLiteral("session.ini"));
        const QString legacyBookmarks = QDir(legacyDir).filePath(QStringLiteral("bookmarks.json"));
        if (!QFileInfo::exists(m_sessionFile) && QFileInfo::exists(legacySession)) {
            QDir().mkpath(QFileInfo(m_sessionFile).absolutePath());
            QFile::copy(legacySession, m_sessionFile);
        }
        if (!QFileInfo::exists(m_bookmarksFile) && QFileInfo::exists(legacyBookmarks)) {
            QDir().mkpath(QFileInfo(m_bookmarksFile).absolutePath());
            QFile::copy(legacyBookmarks, m_bookmarksFile);
        }
    }
    if (QDir(QDir::homePath() + "/Downloads").exists()) {
        m_rightPanel.setPath(QDir::homePath() + "/Downloads");
    }
    loadBookmarks();
    loadWorkspaces();
    loadSession();
    ensureDefaultCustomActions();
    refreshRcloneRemotes();
    refreshDrives();

    if (m_recentDirs.isEmpty()) {
        m_loadingSession = true;
        if (!m_leftPanel.isArchiveView() && !m_leftPanel.isTrashView())
            recordRecentDirectory(m_leftPanel.path());
        if (!m_rightPanel.isArchiveView() && !m_rightPanel.isTrashView())
            recordRecentDirectory(m_rightPanel.path());
        m_loadingSession = false;
    }

    auto connectPanelSession = [this](PanelModel *panel) {
        connect(panel, &PanelModel::pathChanged, this, [this, panel] {
            if (!panel->isArchiveView() && !panel->isTrashView())
                recordRecentDirectory(panel->path());
            saveSession();
        });
        connect(panel, &PanelModel::tabsChanged, this, &Backend::saveSession);
        connect(panel, &PanelModel::sortChanged, this, &Backend::saveSession);
        connect(panel, &PanelModel::showHiddenChanged, this, &Backend::saveSession);
    };
    connectPanelSession(&m_leftPanel);
    connectPanelSession(&m_rightPanel);

    if (auto *clipboard = QGuiApplication::clipboard()) {
        connect(clipboard, &QClipboard::dataChanged, this, &Backend::refreshClipboardState);
        refreshClipboardState();
    }
}

Backend::~Backend()
{
    m_operationQueue.clear();
    m_drivesGeneration.fetch_add(1, std::memory_order_relaxed);
    if (m_drivesCancel) {
        m_drivesCancel->store(true, std::memory_order_relaxed);
        m_drivesCancel.reset();
    }
    cancelSearch();
    cancelDuplicateScan();
    cancelSyncOperation();
    cancelChecksumCalculation();
    cancelPreview();
    cancelArchiveOperation();
    cancelRemoteOperation();
    cancelGoogleDriveAuth();
    cancelCommand();
    cancelSplitOperation();
    saveSession();
    delete m_archiveTempDir;
    m_archiveTempDir = nullptr;
    if (m_fileOp) {
        m_fileOp->cancel();
        m_fileOpThread->wait();
        delete m_fileOpThread;
        delete m_fileOp;
    }
}

void Backend::setActivePanel(int index)
{
    if (index != 0 && index != 1)
        return;
    if (m_activePanel != index) {
        m_activePanel = index;
        emit activePanelChanged();
        saveSession();
    }
}

void Backend::setWindowWidth(int width)
{
    const int clamped = std::max(860, width);
    if (m_windowWidth != clamped) {
        m_windowWidth = clamped;
        emit windowSizeChanged();
        saveSession();
    }
}

void Backend::setWindowHeight(int height)
{
    const int clamped = std::max(540, height);
    if (m_windowHeight != clamped) {
        m_windowHeight = clamped;
        emit windowSizeChanged();
        saveSession();
    }
}

void Backend::setThemeMode(const QString &mode)
{
    const QString normalized = (mode.trimmed().compare(QLatin1String("light"), Qt::CaseInsensitive) == 0)
                                   ? QStringLiteral("light")
                                   : QStringLiteral("dark");
    if (m_themeMode != normalized) {
        m_themeMode = normalized;
        emit themeModeChanged();
        saveSession();
    }
}

void Backend::toggleThemeMode()
{
    setThemeMode(isDarkTheme() ? QStringLiteral("light") : QStringLiteral("dark"));
    showStatus(isDarkTheme() ? tr("Theme switched to Dark.") : tr("Theme switched to Light."));
}

PanelModel* Backend::activeModel()
{
    return (m_activePanel == 0) ? &m_leftPanel : &m_rightPanel;
}

PanelModel* Backend::targetModel()
{
    return (m_activePanel == 0) ? &m_rightPanel : &m_leftPanel;
}

void Backend::switchPanel()
{
    setActivePanel(m_activePanel == 0 ? 1 : 0);
}

void Backend::swapPanels()
{
    const QString leftPath = m_leftPanel.path();
    const QString rightPath = m_rightPanel.path();
    m_leftPanel.setPath(rightPath);
    m_rightPanel.setPath(leftPath);
    showStatus(tr("Panels swapped."));
}

void Backend::syncPanels()
{
    targetModel()->setPath(activeModel()->path());
    showStatus(tr("Target panel synced to %1").arg(activeModel()->path()));
}

void Backend::compareDirectories()
{
    m_leftPanel.selectDifferenceFrom(&m_rightPanel);
    m_rightPanel.selectDifferenceFrom(&m_leftPanel);
    const int leftDiff = m_leftPanel.selectedCount();
    const int rightDiff = m_rightPanel.selectedCount();
    showStatus(tr("Compare complete: %1 diff in left, %2 diff in right.").arg(leftDiff).arg(rightDiff));
}

void Backend::openItem(const QString &path)
{
    QString archiveFile;
    QString internalPath;
    if (PanelModel::splitArchivePath(path, &archiveFile, &internalPath)) {
        if (internalPath.isEmpty()) {
            activeModel()->setPath(archiveFile);
            showStatus(tr("Opened archive: %1").arg(QFileInfo(archiveFile).fileName()));
            return;
        }
        const QList<ArchiveEntryInfo> entries = PanelModel::readArchiveEntries(archiveFile);
        const QString childPrefix = internalPath + '/';
        for (const ArchiveEntryInfo &entry : entries) {
            if ((entry.internalPath == internalPath && entry.isDir) || entry.internalPath.startsWith(childPrefix)) {
                activeModel()->setPath(archiveFile + "/" + internalPath);
                return;
            }
        }
        const QString tempFile = extractArchiveEntryToTemp(archiveFile, internalPath);
        if (!tempFile.isEmpty()) {
            QDesktopServices::openUrl(QUrl::fromLocalFile(tempFile));
        }
        return;
    }

    QFileInfo info(path);
    if (!info.exists())
        return;

    if (info.isDir()) {
        activeModel()->cd(info.absoluteFilePath());
    } else if (isArchive(info.fileName())) {
        activeModel()->setPath(info.absoluteFilePath());
        showStatus(tr("Opened archive: %1").arg(info.fileName()));
    } else {
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    }
}

void Backend::openWithEditor(const QString &path)
{
    QString targetPath = path;
    QString arc, inner;
    if (PanelModel::splitArchivePath(path, &arc, &inner) && !inner.isEmpty()) {
        targetPath = extractArchiveEntryToTemp(arc, inner);
        if (targetPath.isEmpty())
            return;
    }

    QFileInfo info(targetPath);
    if (!info.exists())
        return;

    QString editor = qEnvironmentVariable("EDITOR");
    if (!editor.isEmpty()) {
        const QString terminal = findTerminalExecutable(false);
        if (!terminal.isEmpty()) {
            QProcess::startDetached(terminal, {"-e", editor, targetPath});
            return;
        }
    }

    QDesktopServices::openUrl(QUrl::fromLocalFile(targetPath));
}

void Backend::openInTerminal(const QString &path)
{
    QString dirPath;
    QString arc, inner;
    if (PanelModel::splitArchivePath(path, &arc, &inner)) {
        dirPath = QFileInfo(arc).absolutePath();
    } else {
        QFileInfo info(path);
        dirPath = info.isDir() ? info.absoluteFilePath() : info.absolutePath();
    }

    const QString terminal = findTerminalExecutable(true);
    QProcess::startDetached(terminal, {}, dirPath);
}

bool Backend::startFileOperation(FileOperation::Mode mode, const QStringList &sourcePaths, const QString &targetDir)
{
    if (sourcePaths.isEmpty() || targetDir.isEmpty())
        return false;

    if (!QFileInfo(targetDir).isDir()) {
        showStatus(tr("Target folder does not exist: %1").arg(targetDir));
        return false;
    }

    if (m_fileOp) {
        QueuedFileOperation q;
        q.id = ++m_nextQueueId;
        q.mode = mode;
        q.sourcePaths = sourcePaths;
        q.targetDir = targetDir;
        const QString firstName = QFileInfo(sourcePaths.first()).fileName();
        const QString targetName = QFileInfo(targetDir).fileName().isEmpty() ? targetDir : QFileInfo(targetDir).fileName();
        q.title = (mode == FileOperation::Copy ? tr("Copy") : tr("Move"))
                  + QStringLiteral(": ")
                  + (sourcePaths.size() == 1 ? firstName : tr("%1 item(s)").arg(sourcePaths.size()))
                  + QStringLiteral(" → ") + targetName;
        m_operationQueue.append(q);
        emit operationQueueChanged();
        emit busyChanged();
        showStatus(tr("Queued (%1 waiting): %2").arg(m_operationQueue.size()).arg(q.title));
        return true;
    }

    return launchFileOperation(mode, sourcePaths, targetDir);
}

bool Backend::launchFileOperation(FileOperation::Mode mode, const QStringList &sourcePaths, const QString &targetDir)
{
    m_fileOp = new FileOperation(mode, sourcePaths, targetDir);
    connect(m_fileOp, &FileOperation::pausedChanged, this, [this](bool paused) {
        if (m_isPaused != paused) {
            m_isPaused = paused;
            emit busyChanged();
        }
    });
    connect(m_fileOp, &FileOperation::progress, this, [this](qint64 done, qint64 total, const QString &name) {
        m_busyDoneBytes = done;
        m_busyTotalBytes = total;
        m_busyProgress = total > 0 ? static_cast<double>(done) / static_cast<double>(total) : 0.0;
        m_busyDetail = name;
        const qint64 elapsedMs = m_fileOp ? m_fileOp->activeElapsedMs() : 0;
        if (elapsedMs > 0 && done > 0) {
            m_busySpeedBytes = (done * 1000) / elapsedMs;
            m_busySpeed = PanelModel::formatSize(m_busySpeedBytes, false) + QStringLiteral("/s");
            if (total > done && m_busySpeedBytes > 0) {
                const qint64 remSecs = (total - done) / m_busySpeedBytes;
                m_busyEta = formatEtaSeconds(remSecs);
            } else if (total > 0 && done >= total) {
                m_busyEta = QStringLiteral("0s");
            } else {
                m_busyEta.clear();
            }
        } else {
            m_busySpeedBytes = 0;
            m_busySpeed = QStringLiteral("0 B/s");
            m_busyEta.clear();
        }
        emit busyChanged();
    });
    connect(m_fileOp, &FileOperation::conflict, this, &Backend::conflictRequested);
    connect(m_fileOp, &FileOperation::finished, this, &Backend::onFileOperationFinished, Qt::QueuedConnection);

    FileOperation *op = m_fileOp;
    m_fileOpThread = QThread::create([op] { op->run(); });

    m_isBusy = true;
    m_canCancel = true;
    m_isPaused = false;
    m_busyTitle = mode == FileOperation::Copy ? tr("Copying files...") : tr("Moving files...");
    m_busyProgress = 0.0;
    m_busyDetail.clear();
    m_busyDoneBytes = 0;
    m_busyTotalBytes = 0;
    m_busySpeedBytes = 0;
    m_busySpeed = QStringLiteral("0 B/s");
    m_busyEta.clear();
    emit busyChanged();

    m_fileOpThread->start();
    return true;
}

void Backend::onFileOperationFinished()
{
    if (!m_fileOp)
        return;

    m_fileOpThread->wait();
    const bool isCopy = m_fileOp->mode() == FileOperation::Copy;
    const bool cancelled = m_fileOp->wasCancelled();
    const int completed = m_fileOp->completedCount();
    const int skipped = m_fileOp->skippedCount();
    const int failed = m_fileOp->failedCount();
    const QStringList errors = m_fileOp->errors();
    const QList<QPair<QString, QString>> moved = m_fileOp->movedPairs();

    delete m_fileOpThread;
    delete m_fileOp;
    m_fileOpThread = nullptr;
    m_fileOp = nullptr;

    if (!isCopy && !moved.isEmpty()) {
        UndoEntry entry;
        entry.type = UndoEntry::Move;
        entry.description = moved.size() == 1
                                ? tr("Move %1").arg(QFileInfo(moved.first().second).fileName())
                                : tr("Move %1 item(s)").arg(moved.size());
        // Reverse order so nested/merged items unwind safely.
        for (int i = moved.size() - 1; i >= 0; --i)
            entry.pairs.append(UndoPair{moved.at(i).first, moved.at(i).second, {}});
        pushUndo(std::move(entry));
    }

    m_isBusy = false;
    m_canCancel = false;
    m_isPaused = false;
    m_busyDetail.clear();
    m_busySpeed.clear();
    m_busySpeedBytes = 0;
    m_busyEta.clear();
    m_busyDoneBytes = 0;
    m_busyTotalBytes = 0;
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    for (const QString &error : errors)
        qWarning("twinforge: %s", qPrintable(error));

    QString message;
    if (cancelled)
        message = isCopy ? tr("Copy cancelled.") : tr("Move cancelled.");
    else if (failed == 0 && skipped == 0)
        message = isCopy ? tr("Copy completed.") : tr("Move completed.");
    else
        message = tr("%1 done, %2 skipped, %3 failed.").arg(completed).arg(skipped).arg(failed);
    if (!errors.isEmpty())
        message += " " + errors.first();

    const bool success = !cancelled && failed == 0;
    showStatus(message);
    emit operationFinished(success, message);

    if (!m_operationQueue.isEmpty()) {
        const QueuedFileOperation nextOp = m_operationQueue.takeFirst();
        emit operationQueueChanged();
        launchFileOperation(nextOp.mode, nextOp.sourcePaths, nextOp.targetDir);
    }
}

bool Backend::copyItems(const QStringList &sourcePaths, const QString &targetDir)
{
    if (!sourcePaths.isEmpty()) {
        QString archiveFile;
        QString internalPath;
        if (PanelModel::splitArchivePath(sourcePaths.first(), &archiveFile, &internalPath) && !internalPath.isEmpty()) {
            return extractArchiveItems(archiveFile, sourcePaths, targetDir);
        }
    }
    if (isArchiveTargetPath(targetDir)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }
    return startFileOperation(FileOperation::Copy, sourcePaths, targetDir);
}

bool Backend::moveItems(const QStringList &sourcePaths, const QString &targetDir)
{
    if (anyPathInsideArchive(sourcePaths) || isArchiveTargetPath(targetDir)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }
    return startFileOperation(FileOperation::Move, sourcePaths, targetDir);
}

void Backend::cancelOperation()
{
    if (!m_fileOp)
        return;
    m_isPaused = false;
    m_fileOp->cancel();
    m_canCancel = false;
    m_busyTitle = tr("Cancelling...");
    emit busyChanged();
}

void Backend::cancelAllOperations()
{
    clearOperationQueue();
    cancelOperation();
}

void Backend::pauseOperation()
{
    if (!m_fileOp || m_isPaused)
        return;
    m_fileOp->pause();
    m_isPaused = m_fileOp->isPaused();
    emit busyChanged();
}

void Backend::resumeOperation()
{
    if (!m_fileOp || !m_isPaused)
        return;
    m_fileOp->resume();
    m_isPaused = m_fileOp->isPaused();
    emit busyChanged();
}

void Backend::togglePauseOperation()
{
    if (!m_fileOp)
        return;
    if (m_isPaused)
        resumeOperation();
    else
        pauseOperation();
}

QVariantList Backend::operationQueue() const
{
    QVariantList list;
    list.reserve(m_operationQueue.size());
    for (const QueuedFileOperation &q : m_operationQueue) {
        QVariantMap row;
        row[QStringLiteral("id")] = q.id;
        row[QStringLiteral("mode")] = (q.mode == FileOperation::Copy) ? QStringLiteral("copy") : QStringLiteral("move");
        row[QStringLiteral("title")] = q.title;
        row[QStringLiteral("targetDir")] = q.targetDir;
        row[QStringLiteral("itemCount")] = q.sourcePaths.size();
        row[QStringLiteral("firstPath")] = q.sourcePaths.isEmpty() ? QString() : q.sourcePaths.first();
        list.append(row);
    }
    return list;
}

bool Backend::removeQueuedOperation(int queueId)
{
    for (int i = 0; i < m_operationQueue.size(); ++i) {
        if (m_operationQueue.at(i).id == queueId) {
            m_operationQueue.removeAt(i);
            emit operationQueueChanged();
            emit busyChanged();
            return true;
        }
    }
    return false;
}

void Backend::clearOperationQueue()
{
    if (m_operationQueue.isEmpty())
        return;
    m_operationQueue.clear();
    emit operationQueueChanged();
    emit busyChanged();
}

void Backend::resolveConflict(int action, bool applyToAll)
{
    if (m_fileOp)
        m_fileOp->resolveConflict(action, applyToAll);
}

QString Backend::formatConflictDetails(qint64 size, const QDateTime &modified, bool isDir) const
{
    const QString sizeText = isDir ? tr("folder") : PanelModel::formatSize(size, false);
    return QString("%1  ·  %2").arg(sizeText, modified.toString("yyyy-MM-dd hh:mm:ss"));
}

bool Backend::deleteItems(const QStringList &paths, bool permanent)
{
    if (paths.isEmpty())
        return false;

    if (anyPathInsideArchive(paths)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    if (m_fileOp) {
        showStatus(tr("Another file operation is still running."));
        return false;
    }

    m_isBusy = true;
    m_busyTitle = tr("Deleting files...");
    emit busyChanged();

    bool success = true;
    QList<UndoPair> trashedPairs;

    for (const QString &path : paths) {
        QFileInfo fi(path);
        if (!itemExistsOrLink(fi))
            continue;

        bool deleted = false;
        if (!permanent) {
            QString pathInTrash;
            deleted = QFile::moveToTrash(fi.absoluteFilePath(), &pathInTrash);
            if (deleted && !pathInTrash.isEmpty()) {
                trashedPairs.append(UndoPair{pathInTrash, fi.absoluteFilePath(), trashInfoForTrashFile(pathInTrash)});
            }
        } else {
            if (fi.isDir() && !fi.isSymLink()) {
                deleted = QDir(fi.absoluteFilePath()).removeRecursively();
            } else {
                deleted = QFile::remove(fi.absoluteFilePath());
            }
        }

        if (!deleted)
            success = false;
    }

    if (!trashedPairs.isEmpty()) {
        UndoEntry entry;
        entry.type = UndoEntry::Trash;
        entry.description = trashedPairs.size() == 1
                                ? tr("Trash %1").arg(QFileInfo(trashedPairs.first().toPath).fileName())
                                : tr("Trash %1 item(s)").arg(trashedPairs.size());
        entry.pairs = trashedPairs;
        pushUndo(std::move(entry));
        emit trashChanged();
        refreshDrives();
    }

    m_isBusy = false;
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    if (!success && !permanent) {
        showStatus(tr("Could not move item(s) to Trash."));
    } else {
        showStatus(success ? tr("Delete completed.") : tr("Some files could not be deleted."));
    }
    emit operationFinished(success, success ? tr("Deleted successfully") : tr("Delete failed"));
    return success;
}

bool Backend::createDirectory(const QString &name)
{
    if (name.trimmed().isEmpty())
        return false;

    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    if (name.contains(','))
        return createDirectories(name) > 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create folder in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return false;
    }

    bool ok = current.mkpath(name.trimmed());
    if (ok) {
        activeModel()->refresh();
        showStatus(tr("Folder created: %1").arg(name.trimmed()));
    } else {
        showStatus(tr("Failed to create folder '%1' in %2 (Permission denied)").arg(name.trimmed(), current.path()));
    }
    return ok;
}

int Backend::createDirectories(const QString &namesCsv)
{
    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return 0;
    }

    const QStringList parts = namesCsv.split(',', Qt::SkipEmptyParts);
    if (parts.isEmpty())
        return 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return 0;
    }

    int createdCount = 0;
    QStringList createdNames;
    QStringList failedNames;

    for (const QString &rawPart : parts) {
        const QString name = rawPart.trimmed();
        if (name.isEmpty() || name == QLatin1String(".") || name == QLatin1String(".."))
            continue;

        if (current.mkpath(name)) {
            createdCount++;
            createdNames.append(name);
        } else {
            failedNames.append(name);
        }
    }

    if (createdCount > 0) {
        activeModel()->refresh();
        if (failedNames.isEmpty()) {
            if (createdCount == 1) {
                showStatus(tr("Folder created: %1").arg(createdNames.first()));
            } else {
                showStatus(tr("%1 folders created: %2").arg(createdCount).arg(createdNames.join(QStringLiteral(", "))));
            }
        } else {
            showStatus(tr("%1 folders created (%2 failed): %3")
                           .arg(createdCount)
                           .arg(failedNames.size())
                           .arg(createdNames.join(QStringLiteral(", "))));
        }
    } else if (!failedNames.isEmpty()) {
        showStatus(tr("Failed to create folder(s) in %1 (Permission denied): %2")
                       .arg(current.path(), failedNames.join(QStringLiteral(", "))));
    }

    return createdCount;
}

bool Backend::createNewFile(const QString &fileName)
{
    if (fileName.trimmed().isEmpty())
        return false;

    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    if (fileName.contains(','))
        return createFiles(fileName) > 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return false;
    }

    const QString fullPath = current.filePath(fileName.trimmed());
    QFileInfo fi(fullPath);
    if (!fi.dir().exists()) {
        current.mkpath(fi.dir().path());
    }

    if (QFileInfo::exists(fullPath)) {
        openWithEditor(fullPath);
        return true;
    }

    QFile f(fullPath);
    if (!f.open(QIODevice::WriteOnly)) {
        showStatus(tr("Failed to create file '%1' in %2: %3").arg(fileName, current.path(), f.errorString()));
        return false;
    }
    f.close();

    activeModel()->refresh();
    showStatus(tr("File created: %1").arg(fileName));
    openWithEditor(fullPath);
    return true;
}

int Backend::createFiles(const QString &namesCsv)
{
    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return 0;
    }

    const QStringList parts = namesCsv.split(',', Qt::SkipEmptyParts);
    if (parts.isEmpty())
        return 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return 0;
    }

    int createdCount = 0;
    QStringList createdNames;
    QStringList failedNames;
    QString firstCreatedFullPath;
    QString lastError;

    for (const QString &rawPart : parts) {
        const QString name = rawPart.trimmed();
        if (name.isEmpty() || name == QLatin1String(".") || name == QLatin1String(".."))
            continue;

        const QString fullPath = current.filePath(name);
        QFileInfo fi(fullPath);
        if (!fi.dir().exists()) {
            current.mkpath(fi.dir().path());
        }

        if (fi.exists()) {
            createdCount++;
            createdNames.append(name);
            if (firstCreatedFullPath.isEmpty())
                firstCreatedFullPath = fullPath;
            continue;
        }

        QFile f(fullPath);
        if (f.open(QIODevice::WriteOnly)) {
            f.close();
            createdCount++;
            createdNames.append(name);
            if (firstCreatedFullPath.isEmpty())
                firstCreatedFullPath = fullPath;
        } else {
            failedNames.append(name);
            lastError = f.errorString();
        }
    }

    if (createdCount > 0) {
        activeModel()->refresh();
        if (failedNames.isEmpty()) {
            if (createdCount == 1) {
                showStatus(tr("File created: %1").arg(createdNames.first()));
                openWithEditor(firstCreatedFullPath);
            } else {
                showStatus(tr("%1 files created: %2").arg(createdCount).arg(createdNames.join(QStringLiteral(", "))));
            }
        } else {
            showStatus(tr("%1 files created (%2 failed): %3")
                           .arg(createdCount)
                           .arg(failedNames.size())
                           .arg(createdNames.join(QStringLiteral(", "))));
        }
    } else if (!failedNames.isEmpty()) {
        if (!lastError.isEmpty()) {
            showStatus(tr("Failed to create file(s) in %1 (%2): %3")
                           .arg(current.path(), lastError, failedNames.join(QStringLiteral(", "))));
        } else {
            showStatus(tr("Failed to create file(s) in %1 (Permission denied): %2")
                           .arg(current.path(), failedNames.join(QStringLiteral(", "))));
        }
    }

    return createdCount;
}

QString Backend::copyNamesAsCsv(const QStringList &paths)
{
    QStringList resolvedPaths = paths;
    if (resolvedPaths.isEmpty()) {
        resolvedPaths = activeModel()->selectedPaths();
        if (resolvedPaths.isEmpty()) {
            resolvedPaths = activeModel()->allItemPaths(true);
        }
    }

    QStringList names;
    names.reserve(resolvedPaths.size());
    for (const QString &p : resolvedPaths) {
        const QString fn = QFileInfo(p).fileName();
        if (!fn.isEmpty() && fn != QLatin1String(".."))
            names.append(fn);
    }

    if (names.isEmpty()) {
        showStatus(tr("No files or folders to copy as text."));
        return {};
    }

    const QString csvText = names.join(QStringLiteral(", "));
    auto *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(csvText);
    }

    showStatus(tr("Copied %1 name(s) as text to clipboard: %2")
                   .arg(names.size())
                   .arg(csvText.length() > 60 ? csvText.left(57) + QStringLiteral("...") : csvText));
    return csvText;
}

QString Backend::copyPathsAsCsv(const QStringList &paths)
{
    QStringList resolvedPaths = paths;
    if (resolvedPaths.isEmpty()) {
        resolvedPaths = activeModel()->selectedPaths();
        if (resolvedPaths.isEmpty()) {
            resolvedPaths = activeModel()->allItemPaths(true);
        }
    }

    QStringList validPaths;
    validPaths.reserve(resolvedPaths.size());
    for (const QString &p : resolvedPaths) {
        if (!p.isEmpty() && QFileInfo(p).fileName() != QLatin1String(".."))
            validPaths.append(p);
    }

    if (validPaths.isEmpty()) {
        showStatus(tr("No files or folders to copy as text."));
        return {};
    }

    const QString csvText = validPaths.join(QStringLiteral(", "));
    auto *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(csvText);
    }

    showStatus(tr("Copied %1 path(s) as text to clipboard").arg(validPaths.size()));
    return csvText;
}

QString Backend::copyFolderContentsAsCsv(const QString &dirPath, bool fullPaths)
{
    const QString target = dirPath.isEmpty() ? activeModel()->path() : dirPath;
    QDir dir(target);
    const QFileInfoList entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot, QDir::DirsFirst | QDir::Name);

    QStringList list;
    list.reserve(entries.size());
    for (const QFileInfo &fi : entries) {
        list.append(fullPaths ? fi.absoluteFilePath() : fi.fileName());
    }

    if (list.isEmpty()) {
        showStatus(tr("Folder is empty."));
        return {};
    }

    const QString csvText = list.join(QStringLiteral(", "));
    auto *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(csvText);
    }

    showStatus(tr("Copied %1 item(s) from %2 to clipboard")
                   .arg(list.size())
                   .arg(QFileInfo(target).fileName()));
    return csvText;
}

bool Backend::copyTextToClipboard(const QString &text, const QString &statusMsg)
{
    if (text.isEmpty())
        return false;
    auto *cb = QGuiApplication::clipboard();
    if (!cb)
        return false;
    cb->setText(text);
    showStatus(statusMsg.isEmpty() ? tr("Copied to clipboard: %1").arg(text) : statusMsg);
    return true;
}

bool Backend::createSymlink(const QString &sourcePath, const QString &linkDir, const QString &linkName)
{
    QFileInfo srcFi(sourcePath);
    if (!srcFi.exists() && !srcFi.isSymLink()) {
        showStatus(tr("Source file does not exist."));
        return false;
    }

    const QString destDir = linkDir.isEmpty() ? targetModel()->path() : linkDir;
    QDir dir(destDir);
    if (!dir.exists()) {
        showStatus(tr("Destination folder does not exist."));
        return false;
    }

    const QString finalName = linkName.trimmed().isEmpty() ? srcFi.fileName() : linkName.trimmed();
    const QString destPath = dir.filePath(finalName);
    if (QFileInfo::exists(destPath) || QFileInfo(destPath).isSymLink()) {
        showStatus(tr("A file named \"%1\" already exists at destination.").arg(finalName));
        return false;
    }

    bool ok = QFile::link(srcFi.absoluteFilePath(), destPath);
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(ok ? tr("Created symlink: %1 → %2").arg(finalName, srcFi.fileName())
                  : tr("Failed to create symlink."));
    return ok;
}

bool Backend::createSymlinks(const QStringList &sourcePaths, const QString &linkDir)
{
    if (sourcePaths.isEmpty())
        return false;
    int created = 0;
    for (const QString &src : sourcePaths) {
        if (createSymlink(src, linkDir))
            ++created;
    }
    return created > 0;
}

bool Backend::renameItem(const QString &oldPath, const QString &newName)
{
    if (oldPath.isEmpty() || newName.trimmed().isEmpty())
        return false;

    if (anyPathInsideArchive({oldPath})) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    QFileInfo oldFi(oldPath);
    if (!itemExistsOrLink(oldFi))
        return false;

    const QString absOld = oldFi.absoluteFilePath();
    const QString newPath = oldFi.dir().filePath(newName.trimmed());
    if (absOld == newPath)
        return true;

    if (itemExistsOrLink(QFileInfo(newPath))) {
        showStatus(tr("An item named \"%1\" already exists.").arg(newName.trimmed()));
        return false;
    }

    bool ok = QFile::rename(absOld, newPath);
    if (ok) {
        UndoEntry entry;
        entry.type = UndoEntry::Rename;
        entry.description = tr("Rename %1 → %2").arg(oldFi.fileName(), newName.trimmed());
        entry.pairs.append(UndoPair{newPath, absOld, {}});
        pushUndo(std::move(entry));

        m_leftPanel.refresh();
        m_rightPanel.refresh();
        showStatus(tr("Renamed to: %1").arg(newName));
    } else {
        showStatus(tr("Failed to rename item."));
    }
    return ok;
}

void Backend::pushUndo(UndoEntry entry)
{
    if (entry.pairs.isEmpty())
        return;
    m_undoStack.append(std::move(entry));
    while (m_undoStack.size() > 25)
        m_undoStack.removeFirst();
    emit undoChanged();
}

bool Backend::undoLastOperation()
{
    if (m_fileOp) {
        showStatus(tr("Another file operation is still running."));
        return false;
    }
    if (m_undoStack.isEmpty()) {
        showStatus(tr("Nothing to undo."));
        return false;
    }

    const UndoEntry entry = m_undoStack.takeLast();
    emit undoChanged();

    int restored = 0;
    for (const UndoPair &pair : entry.pairs) {
        if (!itemExistsOrLink(QFileInfo(pair.fromPath)))
            continue;
        if (itemExistsOrLink(QFileInfo(pair.toPath)))
            continue;

        if (FileOperation::moveSinglePath(pair.fromPath, pair.toPath)) {
            if (!pair.trashInfoPath.isEmpty())
                QFile::remove(pair.trashInfoPath);
            ++restored;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    if (entry.type == UndoEntry::Trash && restored > 0) {
        emit trashChanged();
        refreshDrives();
    }

    const bool ok = restored == entry.pairs.size();
    if (ok) {
        showStatus(tr("Undone: %1").arg(entry.description));
    } else {
        showStatus(tr("Undo partially completed (%1/%2): %3")
                       .arg(restored)
                       .arg(entry.pairs.size())
                       .arg(entry.description));
    }
    emit operationFinished(ok, m_statusMessage);
    return ok;
}

bool Backend::setClipboardFiles(const QStringList &paths, bool cut)
{
    QList<QUrl> urls;
    QByteArray gnomePayload = cut ? QByteArray("cut") : QByteArray("copy");

    for (const QString &p : paths) {
        const QFileInfo fi(p);
        if (!itemExistsOrLink(fi))
            continue;
        const QUrl url = QUrl::fromLocalFile(fi.absoluteFilePath());
        urls.append(url);
        gnomePayload.append('\n');
        gnomePayload.append(url.toEncoded());
    }

    if (urls.isEmpty())
        return false;

    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard)
        return false;

    auto *mime = new QMimeData();
    mime->setUrls(urls);
    mime->setData(QStringLiteral("x-special/gnome-copied-files"), gnomePayload);
    mime->setData(QStringLiteral("application/x-kde-cutselection"), cut ? QByteArray("1") : QByteArray("0"));
    clipboard->setMimeData(mime);

    refreshClipboardState();
    showStatus(cut ? tr("Cut %1 item(s) to clipboard.").arg(urls.size())
                   : tr("Copied %1 item(s) to clipboard.").arg(urls.size()));
    return true;
}

bool Backend::copyToClipboard(const QStringList &paths)
{
    return setClipboardFiles(paths, false);
}

bool Backend::cutToClipboard(const QStringList &paths)
{
    return setClipboardFiles(paths, true);
}

bool Backend::parseClipboardMime(const QMimeData *mime, QStringList &outPaths, bool &outIsCut)
{
    outPaths.clear();
    outIsCut = false;
    if (!mime)
        return false;

    if (mime->hasFormat(QStringLiteral("x-special/gnome-copied-files"))) {
        const QList<QByteArray> lines = mime->data(QStringLiteral("x-special/gnome-copied-files")).split('\n');
        if (!lines.isEmpty()) {
            const QByteArray header = lines.first().trimmed();
            outIsCut = (header == "cut");
            for (int i = 1; i < lines.size(); ++i) {
                const QByteArray raw = lines.at(i).trimmed();
                if (raw.isEmpty())
                    continue;
                const QUrl url = QUrl::fromEncoded(raw);
                const QString local = url.isLocalFile() ? url.toLocalFile() : QString::fromUtf8(raw);
                if (!local.isEmpty() && itemExistsOrLink(QFileInfo(local)))
                    outPaths.append(QFileInfo(local).absoluteFilePath());
            }
            if (!outPaths.isEmpty())
                return true;
        }
    }

    if (mime->hasFormat(QStringLiteral("application/x-kde-cutselection"))) {
        outIsCut = mime->data(QStringLiteral("application/x-kde-cutselection")).trimmed() == "1";
    }

    if (mime->hasUrls()) {
        for (const QUrl &url : mime->urls()) {
            if (!url.isLocalFile())
                continue;
            const QString local = url.toLocalFile();
            if (!local.isEmpty() && itemExistsOrLink(QFileInfo(local)))
                outPaths.append(QFileInfo(local).absoluteFilePath());
        }
    }

    return !outPaths.isEmpty();
}

void Backend::refreshClipboardState()
{
    QStringList paths;
    bool isCut = false;
    if (auto *clipboard = QGuiApplication::clipboard())
        parseClipboardMime(clipboard->mimeData(), paths, isCut);

    if (paths != m_clipboardPaths || isCut != m_clipboardIsCut) {
        m_clipboardPaths = paths;
        m_clipboardIsCut = isCut;
        emit clipboardChanged();
    }
}

bool Backend::pasteFromClipboard(const QString &targetDir)
{
    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard)
        return false;

    QStringList paths;
    bool isCut = false;
    if (!parseClipboardMime(clipboard->mimeData(), paths, isCut)) {
        showStatus(tr("Clipboard does not contain any files."));
        return false;
    }

    const QString dest = targetDir.isEmpty() ? activeModel()->path() : targetDir;
    if (isArchiveTargetPath(dest)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }
    if (isCut) {
        const bool started = moveItems(paths, dest);
        if (started) {
            clipboard->clear();
            refreshClipboardState();
        }
        return started;
    }
    return copyItems(paths, dest);
}

void Backend::startDrag(const QStringList &paths)
{
    QList<QUrl> urls;
    for (const QString &p : paths) {
        const QFileInfo fi(p);
        if (itemExistsOrLink(fi))
            urls.append(QUrl::fromLocalFile(fi.absoluteFilePath()));
    }
    if (urls.isEmpty())
        return;

    auto *drag = new QDrag(this);
    auto *mime = new QMimeData();
    mime->setUrls(urls);
    drag->setMimeData(mime);

    const QString label = urls.size() == 1
                              ? QFileInfo(urls.first().toLocalFile()).fileName()
                              : tr("%1 items").arg(urls.size());
    QFont font;
    font.setPixelSize(12);
    font.setBold(true);
    const QFontMetrics fm(font);
    const int w = std::clamp(fm.horizontalAdvance(label) + 28, 80, 280);
    const int h = 28;

    QPixmap pixmap(w, h);
    pixmap.fill(Qt::transparent);
    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setBrush(QColor("#161b2a"));
    painter.setPen(QColor("#7d82d9"));
    painter.drawRoundedRect(pixmap.rect().adjusted(1, 1, -1, -1), 5, 5);
    painter.setFont(font);
    painter.setPen(QColor("#f1f5f9"));
    painter.drawText(pixmap.rect().adjusted(12, 0, -12, 0),
                     Qt::AlignVCenter | Qt::AlignLeft,
                     fm.elidedText(label, Qt::ElideMiddle, w - 24));
    painter.end();

    drag->setPixmap(pixmap);
    drag->exec(Qt::CopyAction | Qt::MoveAction, Qt::CopyAction);
}

bool Backend::handleDrop(const QVariantList &urls, const QString &targetDir, bool move)
{
    if (urls.isEmpty() || targetDir.isEmpty())
        return false;

    if (isArchiveTargetPath(targetDir)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    const QFileInfo targetInfo(targetDir);
    if (!targetInfo.isDir())
        return false;
    const QString canonicalTarget = targetInfo.canonicalFilePath().isEmpty()
                                        ? QDir::cleanPath(targetInfo.absoluteFilePath())
                                        : targetInfo.canonicalFilePath();

    QStringList paths;
    for (const QVariant &v : urls) {
        QUrl url = v.toUrl();
        if (url.isEmpty() && v.typeId() == QMetaType::QString)
            url = QUrl::fromUserInput(v.toString());
        const QString local = url.isLocalFile() ? url.toLocalFile() : v.toString();
        const QFileInfo fi(local);
        if (!local.isEmpty() && itemExistsOrLink(fi)) {
            const QString parentCanonical = QDir(fi.absolutePath()).canonicalPath();
            const QString cleanParent = parentCanonical.isEmpty()
                                            ? QDir::cleanPath(fi.absolutePath())
                                            : parentCanonical;
            // Ignore accidental self-folder drops so small drags inside one folder don't duplicate files.
            if (cleanParent == canonicalTarget || fi.absoluteFilePath() == targetInfo.absoluteFilePath())
                continue;
            paths.append(fi.absoluteFilePath());
        }
    }

    if (paths.isEmpty())
        return false;

    return move ? moveItems(paths, targetInfo.absoluteFilePath())
                : copyItems(paths, targetInfo.absoluteFilePath());
}

QString Backend::formatSymbolicPermissions(int octalMode) const
{
    QString s(9, QLatin1Char('-'));
    if (octalMode & 0400) s[0] = QLatin1Char('r');
    if (octalMode & 0200) s[1] = QLatin1Char('w');
    if (octalMode & 0100) s[2] = QLatin1Char('x');
    if (octalMode & 0040) s[3] = QLatin1Char('r');
    if (octalMode & 0020) s[4] = QLatin1Char('w');
    if (octalMode & 0010) s[5] = QLatin1Char('x');
    if (octalMode & 0004) s[6] = QLatin1Char('r');
    if (octalMode & 0002) s[7] = QLatin1Char('w');
    if (octalMode & 0001) s[8] = QLatin1Char('x');
    return s;
}

namespace {

QVariantMap computeChecksumsImpl(const QString &filePath,
                                 const std::atomic<bool> *cancelFlag = nullptr,
                                 const std::function<void(double)> &onProgress = {})
{
    QVariantMap res;
    QFileInfo fi(filePath);
    if (!fi.exists() || fi.isDir())
        return res;

    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly))
        return res;

    QCryptographicHash md5(QCryptographicHash::Md5);
    QCryptographicHash sha1(QCryptographicHash::Sha1);
    QCryptographicHash sha256(QCryptographicHash::Sha256);

    const qint64 totalBytes = fi.size();
    qint64 doneBytes = 0;
    qint64 lastReported = 0;
    char buf[65536];
    qint64 bytesRead = 0;
    while ((bytesRead = f.read(buf, sizeof(buf))) > 0) {
        if (isTaskCancelled(cancelFlag))
            return {};
        const QByteArrayView view(buf, bytesRead);
        md5.addData(view);
        sha1.addData(view);
        sha256.addData(view);
        doneBytes += bytesRead;
        if (onProgress && totalBytes > 0 && (doneBytes - lastReported >= 1024 * 1024 || doneBytes >= totalBytes)) {
            lastReported = doneBytes;
            onProgress(std::clamp(static_cast<double>(doneBytes) / static_cast<double>(totalBytes), 0.0, 1.0));
        }
    }

    if (isTaskCancelled(cancelFlag))
        return {};

    res["filePath"] = fi.absoluteFilePath();
    res["fileName"] = fi.fileName();
    res["size"] = fi.size();
    res["formattedSize"] = PanelModel::formatSize(fi.size(), false);
    res["md5"] = QString::fromLatin1(md5.result().toHex());
    res["sha1"] = QString::fromLatin1(sha1.result().toHex());
    res["sha256"] = QString::fromLatin1(sha256.result().toHex());
    return res;
}

} // namespace

QVariantMap Backend::calculateChecksums(const QString &filePath) const
{
    return computeChecksumsImpl(filePath);
}

void Backend::cancelChecksumCalculation()
{
    m_checksumGeneration.fetch_add(1, std::memory_order_relaxed);
    if (m_checksumCancel) {
        m_checksumCancel->store(true, std::memory_order_relaxed);
        m_checksumCancel.reset();
    }
    if (m_checksumRunning) {
        m_checksumRunning = false;
        emit checksumStateChanged();
    }
}

void Backend::startChecksumCalculation(const QString &filePath)
{
    cancelChecksumCalculation();
    m_checksumResult.clear();
    m_checksumProgress = 0.0;
    emit checksumResultChanged();
    emit checksumProgressChanged();

    const QFileInfo fi(filePath);
    if (!fi.exists() || fi.isDir()) {
        emit checksumFinished({});
        return;
    }

    const quint64 gen = m_checksumGeneration.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_checksumCancel = cancelFlag;
    m_checksumRunning = true;
    emit checksumStateChanged();

    const QString absPath = fi.absoluteFilePath();
    QPointer<Backend> self(this);

    auto *task = QRunnable::create([self, gen, absPath, cancelFlag]() {
        const QVariantMap res = computeChecksumsImpl(absPath, cancelFlag.get(), [self, gen](double progress) {
            QMetaObject::invokeMethod(
                self,
                [self, gen, progress]() {
                    if (!self || self->m_checksumGeneration.load(std::memory_order_relaxed) != gen)
                        return;
                    self->m_checksumProgress = progress;
                    emit self->checksumProgressChanged();
                },
                Qt::QueuedConnection);
        });

        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, res]() {
                if (!self || self->m_checksumGeneration.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_checksumRunning = false;
                self->m_checksumProgress = 1.0;
                self->m_checksumCancel.reset();
                self->m_checksumResult = res;
                emit self->checksumProgressChanged();
                emit self->checksumResultChanged();
                emit self->checksumStateChanged();
                emit self->checksumFinished(res);
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

bool Backend::verifyChecksum(const QString &filePath, const QString &expectedHash) const
{
    const QString cleanExpected = expectedHash.trimmed().toLower();
    if (cleanExpected.isEmpty())
        return false;
    const QVariantMap sums = calculateChecksums(filePath);
    if (sums.isEmpty())
        return false;
    if (cleanExpected.length() == 32)
        return sums["md5"].toString() == cleanExpected;
    if (cleanExpected.length() == 40)
        return sums["sha1"].toString() == cleanExpected;
    if (cleanExpected.length() == 64)
        return sums["sha256"].toString() == cleanExpected;
    return sums["md5"].toString() == cleanExpected
        || sums["sha1"].toString() == cleanExpected
        || sums["sha256"].toString() == cleanExpected;
}

bool Backend::saveChecksumFile(const QString &filePath, const QString &algorithm, const QString &targetFilePath) const
{
    QFileInfo fi(filePath);
    if (!fi.exists() || fi.isDir())
        return false;
    const QVariantMap sums = calculateChecksums(filePath);
    if (sums.isEmpty())
        return false;

    const QString algo = algorithm.trimmed().toLower();
    const QString hash = (algo == "md5") ? sums["md5"].toString() : sums["sha256"].toString();
    const QString ext = (algo == "md5") ? ".md5" : ".sha256";

    QString outPath = targetFilePath.trimmed();
    if (outPath.isEmpty())
        outPath = fi.dir().filePath(fi.fileName() + ext);

    QFile f(outPath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    f.write(QString("%1  %2\n").arg(hash, fi.fileName()).toUtf8());
    f.close();

    const_cast<Backend*>(this)->m_leftPanel.refresh();
    const_cast<Backend*>(this)->m_rightPanel.refresh();
    const_cast<Backend*>(this)->showStatus(tr("Checksum file saved: %1").arg(QFileInfo(outPath).fileName()));
    return true;
}

QVariantMap Backend::verifyChecksumFile(const QString &checksumFilePath) const
{
    QVariantMap result;
    QFileInfo sumFi(checksumFilePath);
    if (!sumFi.exists()) {
        result["success"] = false;
        result["message"] = tr("Checksum file not found.");
        return result;
    }
    QFile f(checksumFilePath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        result["success"] = false;
        result["message"] = tr("Could not read checksum file.");
        return result;
    }
    QDir dir = sumFi.dir();
    int total = 0;
    int matched = 0;
    int failed = 0;
    int missing = 0;
    QVariantList details;

    while (!f.atEnd()) {
        const QString line = QString::fromUtf8(f.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;
        static const QRegularExpression rx(R"(^([a-fA-F0-9]{32,64})\s+[*]?(.+)$)");
        auto match = rx.match(line);
        if (match.hasMatch()) {
            const QString hash = match.captured(1).toLower();
            const QString relName = match.captured(2).trimmed();
            const QString targetPath = dir.filePath(relName);
            ++total;
            QVariantMap item;
            item["file"] = relName;
            item["expected"] = hash;
            if (!QFile::exists(targetPath)) {
                ++missing;
                item["status"] = "missing";
            } else if (verifyChecksum(targetPath, hash)) {
                ++matched;
                item["status"] = "ok";
            } else {
                ++failed;
                item["status"] = "mismatch";
            }
            details.append(item);
        }
    }
    result["success"] = (total > 0 && failed == 0 && missing == 0);
    result["total"] = total;
    result["matched"] = matched;
    result["failed"] = failed;
    result["missing"] = missing;
    result["details"] = details;
    result["message"] = tr("Checksum verification: %1/%2 matched (%3 failed, %4 missing).")
                            .arg(matched).arg(total).arg(failed).arg(missing);
    return result;
}

QVariantMap Backend::compareFiles(const QString &path1, const QString &path2) const
{
    QVariantMap res;
    QFileInfo fi1(path1);
    QFileInfo fi2(path2);
    if (!fi1.exists() || !fi2.exists() || fi1.isDir() || fi2.isDir()) {
        res["success"] = false;
        res["message"] = tr("Both paths must be existing files.");
        return res;
    }

    res["file1"] = fi1.absoluteFilePath();
    res["file2"] = fi2.absoluteFilePath();
    res["name1"] = fi1.fileName();
    res["name2"] = fi2.fileName();
    res["size1"] = fi1.size();
    res["size2"] = fi2.size();

    QFile f1(path1);
    QFile f2(path2);
    if (!f1.open(QIODevice::ReadOnly) || !f2.open(QIODevice::ReadOnly)) {
        res["success"] = false;
        res["message"] = tr("Could not read files.");
        return res;
    }

    const QByteArray head1 = f1.peek(4096);
    const QByteArray head2 = f2.peek(4096);
    bool isBinary = false;
    for (char c : head1) { if (c == '\0') { isBinary = true; break; } }
    if (!isBinary) {
        for (char c : head2) { if (c == '\0') { isBinary = true; break; } }
    }
    res["isBinary"] = isBinary;

    if (isBinary) {
        f1.seek(0);
        f2.seek(0);
        const bool same = (fi1.size() == fi2.size()) && (f1.readAll() == f2.readAll());
        res["success"] = true;
        res["isIdentical"] = same;
        res["differences"] = same ? 0 : 1;
        res["added"] = 0;
        res["deleted"] = 0;
        res["modified"] = same ? 0 : 1;
        res["rows"] = QVariantList();
        return res;
    }

    QStringList lines1;
    while (!f1.atEnd()) {
        QString l = QString::fromUtf8(f1.readLine());
        if (l.endsWith('\n')) l.chop(1);
        if (l.endsWith('\r')) l.chop(1);
        lines1.append(l);
    }
    QStringList lines2;
    while (!f2.atEnd()) {
        QString l = QString::fromUtf8(f2.readLine());
        if (l.endsWith('\n')) l.chop(1);
        if (l.endsWith('\r')) l.chop(1);
        lines2.append(l);
    }

    const int n = lines1.size();
    const int m = lines2.size();

    if (lines1 == lines2) {
        res["success"] = true;
        res["isIdentical"] = true;
        res["differences"] = 0;
        res["added"] = 0;
        res["deleted"] = 0;
        res["modified"] = 0;
        QVariantList rows;
        for (int idx = 0; idx < n; ++idx) {
            QVariantMap row;
            row["type"] = "equal";
            row["line1"] = idx + 1;
            row["text1"] = lines1[idx];
            row["line2"] = idx + 1;
            row["text2"] = lines2[idx];
            rows.append(row);
        }
        res["rows"] = rows;
        return res;
    }

    const int maxLines = 3000;
    if (n > maxLines || m > maxLines) {
        QVariantList rows;
        int diffCount = 0;
        const int limit = std::max(n, m);
        for (int idx = 0; idx < limit; ++idx) {
            QVariantMap row;
            const QString t1 = (idx < n) ? lines1[idx] : QString();
            const QString t2 = (idx < m) ? lines2[idx] : QString();
            if (idx >= n) {
                row["type"] = "added";
                row["line1"] = 0;
                row["text1"] = "";
                row["line2"] = idx + 1;
                row["text2"] = t2;
                ++diffCount;
            } else if (idx >= m) {
                row["type"] = "deleted";
                row["line1"] = idx + 1;
                row["text1"] = t1;
                row["line2"] = 0;
                row["text2"] = "";
                ++diffCount;
            } else if (t1 == t2) {
                row["type"] = "equal";
                row["line1"] = idx + 1;
                row["text1"] = t1;
                row["line2"] = idx + 1;
                row["text2"] = t2;
            } else {
                row["type"] = "modified";
                row["line1"] = idx + 1;
                row["text1"] = t1;
                row["line2"] = idx + 1;
                row["text2"] = t2;
                ++diffCount;
            }
            rows.append(row);
        }
        res["success"] = true;
        res["isIdentical"] = false;
        res["differences"] = diffCount;
        res["rows"] = rows;
        return res;
    }

    std::vector<std::vector<int>> dp(n + 1, std::vector<int>(m + 1, 0));
    for (int r = 0; r < n; ++r) {
        for (int c = 0; c < m; ++c) {
            if (lines1[r] == lines2[c])
                dp[r + 1][c + 1] = dp[r][c] + 1;
            else
                dp[r + 1][c + 1] = std::max(dp[r + 1][c], dp[r][c + 1]);
        }
    }

    struct RawEdit { int type; int idx1; int idx2; }; // 0: equal, 1: deleted, 2: added
    QList<RawEdit> edits;
    int r = n, c = m;
    while (r > 0 || c > 0) {
        if (r > 0 && c > 0 && lines1[r - 1] == lines2[c - 1]) {
            edits.prepend({0, r - 1, c - 1});
            --r; --c;
        } else if (c > 0 && (r == 0 || dp[r][c - 1] >= dp[r - 1][c])) {
            edits.prepend({2, -1, c - 1});
            --c;
        } else if (r > 0 && (c == 0 || dp[r][c - 1] < dp[r - 1][c])) {
            edits.prepend({1, r - 1, -1});
            --r;
        }
    }

    QVariantList rows;
    int addedCount = 0;
    int deletedCount = 0;
    int modifiedCount = 0;

    int editIdx = 0;
    while (editIdx < edits.size()) {
        const auto &e = edits[editIdx];
        if (e.type == 0) {
            QVariantMap row;
            row["type"] = "equal";
            row["line1"] = e.idx1 + 1;
            row["text1"] = lines1[e.idx1];
            row["line2"] = e.idx2 + 1;
            row["text2"] = lines2[e.idx2];
            rows.append(row);
            ++editIdx;
        } else if (e.type == 1 && (editIdx + 1 < edits.size()) && edits[editIdx + 1].type == 2) {
            QVariantMap row;
            row["type"] = "modified";
            row["line1"] = e.idx1 + 1;
            row["text1"] = lines1[e.idx1];
            row["line2"] = edits[editIdx + 1].idx2 + 1;
            row["text2"] = lines2[edits[editIdx + 1].idx2];
            rows.append(row);
            ++modifiedCount;
            editIdx += 2;
        } else if (e.type == 1) {
            QVariantMap row;
            row["type"] = "deleted";
            row["line1"] = e.idx1 + 1;
            row["text1"] = lines1[e.idx1];
            row["line2"] = 0;
            row["text2"] = "";
            rows.append(row);
            ++deletedCount;
            ++editIdx;
        } else {
            QVariantMap row;
            row["type"] = "added";
            row["line1"] = 0;
            row["text1"] = "";
            row["line2"] = e.idx2 + 1;
            row["text2"] = lines2[e.idx2];
            rows.append(row);
            ++addedCount;
            ++editIdx;
        }
    }

    res["success"] = true;
    res["isIdentical"] = (addedCount == 0 && deletedCount == 0 && modifiedCount == 0);
    res["differences"] = addedCount + deletedCount + modifiedCount;
    res["added"] = addedCount;
    res["deleted"] = deletedCount;
    res["modified"] = modifiedCount;
    res["rows"] = rows;
    return res;
}

QVariantMap Backend::getItemProperties(const QString &path) const
{
    QVariantMap props;
    const QFileInfo fi(path);
    if (!itemExistsOrLink(fi)) {
        props["exists"] = false;
        return props;
    }

    struct stat st{};
    const bool hasStat = (::lstat(QFile::encodeName(fi.absoluteFilePath()).constData(), &st) == 0);
    const int mode = hasStat ? static_cast<int>(st.st_mode & 0777) : 0644;

    const bool isSymLink = fi.isSymLink();
    const bool isRealDir = fi.isDir() && !isSymLink;

    QMimeDatabase mimeDb;
    const QMimeType mime = isRealDir
                               ? mimeDb.mimeTypeForName(QStringLiteral("inode/directory"))
                               : mimeDb.mimeTypeForFile(fi.absoluteFilePath(), QMimeDatabase::MatchDefault);

    qint64 totalBytes = isSymLink ? 0 : (isRealDir ? 0 : fi.size());
    int fileCount = 0;
    int dirCount = 0;
    if (isRealDir) {
        QDirIterator it(fi.absoluteFilePath(),
                        QDir::AllEntries | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QFileInfo sub = it.fileInfo();
            if (sub.isSymLink()) {
                ++fileCount;
            } else if (sub.isDir()) {
                ++dirCount;
            } else {
                ++fileCount;
                totalBytes += sub.size();
            }
        }
    }

    const QString humanSize = PanelModel::formatSize(totalBytes, false);
    const QString exactBytes = QLocale().toString(totalBytes);

    props["exists"] = true;
    props["name"] = fi.fileName().isEmpty() ? QStringLiteral("/") : fi.fileName();
    props["path"] = fi.absoluteFilePath();
    props["parentPath"] = fi.absolutePath();
    props["isDir"] = isRealDir;
    props["isSymLink"] = isSymLink;
    props["symLinkTarget"] = isSymLink ? FileOperation::readRawSymLink(fi) : QString();
    props["mimeName"] = mime.name();
    props["mimeComment"] = mime.comment();
    props["size"] = totalBytes;
    props["formattedSize"] = QString("%1 (%2 B)").arg(humanSize, exactBytes);
    props["itemCounts"] = isRealDir ? tr("%1 files, %2 folders").arg(fileCount).arg(dirCount) : QString();
    props["owner"] = fi.owner().isEmpty() ? QString::number(fi.ownerId()) : fi.owner();
    props["group"] = fi.group().isEmpty() ? QString::number(fi.groupId()) : fi.group();
    props["created"] = fi.birthTime().isValid() ? fi.birthTime().toString("yyyy-MM-dd hh:mm:ss") : QStringLiteral("—");
    props["modified"] = fi.lastModified().isValid() ? fi.lastModified().toString("yyyy-MM-dd hh:mm:ss") : QStringLiteral("—");
    props["accessed"] = fi.lastRead().isValid() ? fi.lastRead().toString("yyyy-MM-dd hh:mm:ss") : QStringLiteral("—");
    props["mode"] = mode;
    props["octal"] = QString("0%1").arg(mode, 3, 8, QLatin1Char('0'));
    props["symbolic"] = formatSymbolicPermissions(mode);
    return props;
}

bool Backend::setItemPermissions(const QString &path, int octalMode, bool recursive)
{
    const QFileInfo fi(path);
    if (!itemExistsOrLink(fi))
        return false;

    const mode_t cleanMode = static_cast<mode_t>(octalMode & 0777);
    bool ok = true;

    if (!fi.isSymLink()) {
        if (::chmod(QFile::encodeName(fi.absoluteFilePath()).constData(), cleanMode) != 0)
            ok = false;
    }

    if (recursive && fi.isDir() && !fi.isSymLink()) {
        QDirIterator it(fi.absoluteFilePath(),
                        QDir::AllEntries | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QFileInfo sub = it.fileInfo();
            if (sub.isSymLink())
                continue;
            if (::chmod(QFile::encodeName(sub.absoluteFilePath()).constData(), cleanMode) != 0)
                ok = false;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    const QString octalStr = QString("0%1").arg(octalMode & 0777, 3, 8, QLatin1Char('0'));
    showStatus(ok ? tr("Permissions updated to %1 (%2).")
                        .arg(octalStr, formatSymbolicPermissions(octalMode & 0777))
                  : tr("Could not change permissions on some items."));
    return ok;
}

void Backend::loadSession()
{
    if (!QFileInfo::exists(m_sessionFile))
        return;

    m_loadingSession = true;
    QSettings settings(m_sessionFile, QSettings::IniFormat);

    m_windowWidth = std::max(860, settings.value("window/width", 1260).toInt());
    m_windowHeight = std::max(540, settings.value("window/height", 800).toInt());
    const int savedActive = settings.value("window/activePanel", 0).toInt();
    m_activePanel = (savedActive == 1) ? 1 : 0;
    const QString savedTheme = settings.value("window/themeMode", "dark").toString();
    m_themeMode = (savedTheme.compare(QLatin1String("light"), Qt::CaseInsensitive) == 0)
                      ? QStringLiteral("light")
                      : QStringLiteral("dark");

    auto restorePanel = [&settings](const QString &group, PanelModel &panel) {
        settings.beginGroup(group);
        panel.setShowHidden(settings.value("showHidden", false).toBool());
        const int sortField = std::clamp(settings.value("sortField", 0).toInt(), 0, 3);
        const bool sortAsc = settings.value("sortAscending", true).toBool();
        if (panel.sortField() != sortField)
            panel.setSortField(sortField);
        panel.setSortAscending(sortAsc);

        const int activeTab = settings.value("activeTab", 0).toInt();
        const QByteArray tabsStateRaw = settings.value("tabsStateJson").toByteArray();
        QVariantList savedTabsState;
        if (!tabsStateRaw.isEmpty()) {
            const QJsonArray arr = QJsonDocument::fromJson(tabsStateRaw).array();
            for (const QJsonValue &val : arr) {
                if (val.isObject())
                    savedTabsState.append(val.toObject().toVariantMap());
            }
        }
        if (!savedTabsState.isEmpty()) {
            panel.restoreTabsState(savedTabsState, activeTab);
        } else {
            QStringList savedTabs = settings.value("tabs").toStringList();
            const QString singlePath = settings.value("path").toString();
            if (savedTabs.isEmpty() && !singlePath.isEmpty())
                savedTabs.append(singlePath);
            if (!savedTabs.isEmpty())
                panel.restoreTabs(savedTabs, activeTab);
        }
        settings.endGroup();
    };

    restorePanel("leftPanel", m_leftPanel);
    restorePanel("rightPanel", m_rightPanel);

    m_recentDirs.clear();
    const QStringList savedRecent = settings.value("history/recentDirs").toStringList();
    for (const QString &rawDir : savedRecent) {
        const QFileInfo fi(rawDir);
        if (fi.isDir()) {
            const QString canon = fi.canonicalFilePath().isEmpty() ? fi.absoluteFilePath() : fi.canonicalFilePath();
            if (!m_recentDirs.contains(canon))
                m_recentDirs.append(canon);
        }
        if (m_recentDirs.size() >= 50)
            break;
    }

    m_commandHistory.clear();
    const QStringList savedCmds = settings.value("history/commandHistory").toStringList();
    for (const QString &cmd : savedCmds) {
        const QString t = cmd.trimmed();
        if (!t.isEmpty())
            m_commandHistory.append(t);
        if (m_commandHistory.size() >= 100)
            break;
    }

    m_multiRenamePresets.clear();
    const QByteArray presetsRaw = settings.value("multiRename/presetsJson").toByteArray();
    if (!presetsRaw.isEmpty()) {
        const QJsonArray arr = QJsonDocument::fromJson(presetsRaw).array();
        for (const QJsonValue &val : arr) {
            if (val.isObject())
                m_multiRenamePresets.append(val.toObject().toVariantMap());
        }
    }

    m_remoteConnections.clear();
    const QByteArray remoteRaw = settings.value("network/connectionsJson").toByteArray();
    if (!remoteRaw.isEmpty()) {
        const QJsonArray arr = QJsonDocument::fromJson(remoteRaw).array();
        for (const QJsonValue &val : arr) {
            if (val.isObject())
                m_remoteConnections.append(val.toObject().toVariantMap());
        }
    }

    m_customActions.clear();
    const QByteArray actionsRaw = settings.value("actions/customActionsJson").toByteArray();
    if (!actionsRaw.isEmpty()) {
        const QJsonArray arr = QJsonDocument::fromJson(actionsRaw).array();
        for (const QJsonValue &val : arr) {
            if (val.isObject())
                m_customActions.append(val.toObject().toVariantMap());
        }
    }

    m_loadingSession = false;
    emit recentDirectoriesChanged();
    emit commandHistoryChanged();
    emit multiRenamePresetsChanged();
    emit remoteConnectionsChanged();
    emit customActionsChanged();
}

void Backend::saveSession() const
{
    if (m_loadingSession || m_sessionFile.isEmpty())
        return;

    QDir().mkpath(QFileInfo(m_sessionFile).absolutePath());
    QSettings settings(m_sessionFile, QSettings::IniFormat);

    settings.setValue("window/width", m_windowWidth);
    settings.setValue("window/height", m_windowHeight);
    settings.setValue("window/activePanel", m_activePanel);
    settings.setValue("window/themeMode", m_themeMode);
    settings.setValue("history/recentDirs", m_recentDirs);
    settings.setValue("history/commandHistory", m_commandHistory);

    QJsonArray presetArr;
    for (const QVariant &v : std::as_const(m_multiRenamePresets))
        presetArr.append(QJsonObject::fromVariantMap(v.toMap()));
    settings.setValue("multiRename/presetsJson", QJsonDocument(presetArr).toJson(QJsonDocument::Compact));

    QJsonArray remoteArr;
    for (const QVariant &v : std::as_const(m_remoteConnections))
        remoteArr.append(QJsonObject::fromVariantMap(v.toMap()));
    settings.setValue("network/connectionsJson", QJsonDocument(remoteArr).toJson(QJsonDocument::Compact));

    QJsonArray actionsArr;
    for (const QVariant &v : std::as_const(m_customActions))
        actionsArr.append(QJsonObject::fromVariantMap(v.toMap()));
    settings.setValue("actions/customActionsJson", QJsonDocument(actionsArr).toJson(QJsonDocument::Compact));

    auto savePanel = [&settings](const QString &group, const PanelModel &panel) {
        settings.beginGroup(group);
        settings.setValue("path", panel.path());
        settings.setValue("tabs", panel.tabPaths());
        QJsonArray tabsStateArr;
        const QVariantList stateList = panel.serializeTabs();
        for (const QVariant &v : stateList)
            tabsStateArr.append(QJsonObject::fromVariantMap(v.toMap()));
        settings.setValue("tabsStateJson", QJsonDocument(tabsStateArr).toJson(QJsonDocument::Compact));
        settings.setValue("activeTab", panel.activeTab());
        settings.setValue("sortField", panel.sortField());
        settings.setValue("sortAscending", panel.sortAscending());
        settings.setValue("showHidden", panel.showHidden());
        settings.endGroup();
    };

    savePanel("leftPanel", m_leftPanel);
    savePanel("rightPanel", m_rightPanel);
    settings.sync();
}

QString Backend::computeNewName(const QFileInfo &fi, int index, const QString &findText,
                                const QString &replaceText, const QString &prefix,
                                const QString &suffix, int caseMode, bool addCounter,
                                bool useRegex, const QString &nameMask,
                                int counterStart, int counterStep, int counterDigits)
{
    QString base = fi.completeBaseName();
    QString ext = fi.suffix();
    if (base.isEmpty() && !ext.isEmpty()) {
        // Dotfile like .bashrc
        base = "." + ext;
        ext.clear();
    }

    const int counterVal = counterStart + index * counterStep;
    const int digits = std::clamp(counterDigits, 1, 10);
    bool usedCounter = false;
    bool usedExt = false;

    const QString expandedReplace = expandRenameTags(replaceText, fi, base, ext, counterVal, digits, &usedCounter, nullptr);

    if (!findText.isEmpty()) {
        if (useRegex) {
            const QRegularExpression rx(findText, QRegularExpression::CaseInsensitiveOption);
            if (rx.isValid())
                base.replace(rx, normalizeRegexReplacement(expandedReplace));
        } else {
            base.replace(findText, expandedReplace, Qt::CaseInsensitive);
        }
    }

    const QString effMask = nameMask.trimmed().isEmpty() ? QStringLiteral("[N]") : nameMask;
    const QString maskedStem = expandRenameTags(effMask, fi, base, ext, counterVal, digits, &usedCounter, &usedExt);
    const QString expPrefix = expandRenameTags(prefix, fi, base, ext, counterVal, digits, &usedCounter, nullptr);
    const QString expSuffix = expandRenameTags(suffix, fi, base, ext, counterVal, digits, &usedCounter, nullptr);

    QString result = expPrefix + maskedStem + expSuffix;

    switch (caseMode) {
    case 1: // lowercase
        result = result.toLower();
        ext = ext.toLower();
        break;
    case 2: // UPPERCASE
        result = result.toUpper();
        ext = ext.toUpper();
        break;
    case 3: // Title Case
        if (!result.isEmpty()) {
            result = result.left(1).toUpper() + result.mid(1).toLower();
        }
        ext = ext.toLower();
        break;
    default:
        break;
    }

    if (addCounter && !usedCounter) {
        result += QStringLiteral("_%1").arg(counterVal, digits, 10, QLatin1Char('0'));
    }
    if (!ext.isEmpty() && !usedExt) {
        result += "." + ext;
    }
    result.replace('/', '_');
    return result;
}

QVariantList Backend::previewMultiRename(const QStringList &paths, const QString &findText,
                                         const QString &replaceText, const QString &prefix,
                                         const QString &suffix, int caseMode, bool addCounter,
                                         bool useRegex, const QString &nameMask,
                                         int counterStart, int counterStep, int counterDigits) const
{
    QVariantList list;
    for (int i = 0; i < paths.size(); ++i) {
        QFileInfo fi(paths.at(i));
        QVariantMap entry;
        entry["oldPath"] = fi.absoluteFilePath();
        entry["oldName"] = fi.fileName();
        entry["newName"] = computeNewName(fi, i, findText, replaceText, prefix, suffix, caseMode, addCounter,
                                          useRegex, nameMask, counterStart, counterStep, counterDigits);
        list.append(entry);
    }
    return list;
}

bool Backend::executeMultiRename(const QStringList &paths, const QString &findText,
                                 const QString &replaceText, const QString &prefix,
                                 const QString &suffix, int caseMode, bool addCounter,
                                 bool useRegex, const QString &nameMask,
                                 int counterStart, int counterStep, int counterDigits)
{
    if (paths.isEmpty())
        return false;

    if (anyPathInsideArchive(paths)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    int renamedCount = 0;
    QList<UndoPair> renamedPairs;

    for (int i = 0; i < paths.size(); ++i) {
        QFileInfo fi(paths.at(i));
        if (!itemExistsOrLink(fi))
            continue;
        const QString oldAbs = fi.absoluteFilePath();
        const QString newName = computeNewName(fi, i, findText, replaceText, prefix, suffix, caseMode, addCounter,
                                               useRegex, nameMask, counterStart, counterStep, counterDigits);
        const QString newPath = fi.dir().filePath(newName);
        if (oldAbs == newPath) {
            ++renamedCount;
            continue;
        }
        if (itemExistsOrLink(QFileInfo(newPath)))
            continue;
        if (QFile::rename(oldAbs, newPath)) {
            renamedPairs.prepend(UndoPair{newPath, oldAbs, {}});
            ++renamedCount;
        }
    }

    if (!renamedPairs.isEmpty()) {
        UndoEntry entry;
        entry.type = UndoEntry::Rename;
        entry.description = tr("Multi-Rename %1 item(s)").arg(renamedPairs.size());
        entry.pairs = renamedPairs;
        pushUndo(std::move(entry));
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(tr("Multi-Rename: %1/%2 items renamed.").arg(renamedCount).arg(paths.size()));
    return renamedCount == paths.size();
}

bool Backend::saveMultiRenamePreset(const QString &name, const QVariantMap &preset)
{
    const QString cleanName = name.trimmed();
    if (cleanName.isEmpty())
        return false;

    QVariantMap entry = preset;
    entry[QStringLiteral("name")] = cleanName;

    int existingIdx = -1;
    for (int i = 0; i < m_multiRenamePresets.size(); ++i) {
        if (m_multiRenamePresets.at(i).toMap().value(QStringLiteral("name")).toString().compare(cleanName, Qt::CaseInsensitive) == 0) {
            existingIdx = i;
            break;
        }
    }
    if (existingIdx >= 0)
        m_multiRenamePresets[existingIdx] = entry;
    else
        m_multiRenamePresets.append(entry);

    emit multiRenamePresetsChanged();
    saveSession();
    showStatus(tr("Saved Multi-Rename preset: %1").arg(cleanName));
    return true;
}

QVariantMap Backend::getMultiRenamePreset(const QString &name) const
{
    const QString cleanName = name.trimmed();
    for (const QVariant &v : m_multiRenamePresets) {
        const QVariantMap map = v.toMap();
        if (map.value(QStringLiteral("name")).toString().compare(cleanName, Qt::CaseInsensitive) == 0)
            return map;
    }
    return {};
}

bool Backend::deleteMultiRenamePreset(const QString &name)
{
    const QString cleanName = name.trimmed();
    for (int i = 0; i < m_multiRenamePresets.size(); ++i) {
        if (m_multiRenamePresets.at(i).toMap().value(QStringLiteral("name")).toString().compare(cleanName, Qt::CaseInsensitive) == 0) {
            m_multiRenamePresets.removeAt(i);
            emit multiRenamePresetsChanged();
            saveSession();
            showStatus(tr("Deleted preset: %1").arg(cleanName));
            return true;
        }
    }
    return false;
}

bool Backend::isArchive(const QString &path) const
{
    return PanelModel::isArchiveFileName(path);
}

bool Backend::packArchive(const QStringList &sourcePaths, const QString &archivePath)
{
    if (sourcePaths.isEmpty() || archivePath.trimmed().isEmpty())
        return false;

    QFileInfo firstFi(sourcePaths.first());
    const QString workDir = firstFi.absolutePath();
    QStringList relativeNames;
    for (const QString &p : sourcePaths) {
        relativeNames.append(QFileInfo(p).fileName());
    }

    QString outArchive = archivePath.trimmed();
    if (QFileInfo(outArchive).isRelative()) {
        outArchive = QDir(targetModel()->path()).filePath(outArchive);
    }

    QProcess proc;
    proc.setWorkingDirectory(workDir);

    if (outArchive.endsWith(".zip", Qt::CaseInsensitive)) {
        const QString bsdtar = QStandardPaths::findExecutable("bsdtar");
        const QString zipBin = QStandardPaths::findExecutable("zip");
        if (!zipBin.isEmpty()) {
            QStringList args = {"-r", outArchive};
            args.append(relativeNames);
            proc.start(zipBin, args);
        } else if (!bsdtar.isEmpty()) {
            QStringList args = {"-a", "-cf", outArchive};
            args.append(relativeNames);
            proc.start(bsdtar, args);
        } else {
            showStatus(tr("Missing zip or bsdtar tool."));
            return false;
        }
    } else {
        // Default to tar -caf
        QStringList args = {"-caf", outArchive};
        args.append(relativeNames);
        proc.start("tar", args);
    }

    bool ok = proc.waitForFinished(30000) && proc.exitCode() == 0;
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(ok ? tr("Created archive: %1").arg(QFileInfo(outArchive).fileName())
                  : tr("Failed to create archive."));
    return ok;
}

bool Backend::extractArchive(const QString &archivePath, const QString &targetDir)
{
    QFileInfo fi(archivePath);
    if (!fi.exists() || targetDir.isEmpty())
        return false;

    QDir(targetDir).mkpath(".");
    QProcess proc;
    proc.setWorkingDirectory(targetDir);

    const QString bsdtar = QStandardPaths::findExecutable("bsdtar");
    if (!bsdtar.isEmpty()) {
        proc.start(bsdtar, {"-xf", fi.absoluteFilePath(), "-C", targetDir});
    } else if (archivePath.endsWith(".zip", Qt::CaseInsensitive)) {
        proc.start("unzip", {"-o", fi.absoluteFilePath(), "-d", targetDir});
    } else if (archivePath.endsWith(".7z", Qt::CaseInsensitive)) {
        proc.start("7z", {"x", "-y", fi.absoluteFilePath(), "-o" + targetDir});
    } else {
        proc.start("tar", {"-xf", fi.absoluteFilePath(), "-C", targetDir});
    }

    bool ok = proc.waitForFinished(30000) && proc.exitCode() == 0;
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(ok ? tr("Extracted %1 to %2").arg(fi.fileName(), targetDir)
                  : tr("Failed to extract archive."));
    return ok;
}

void Backend::cancelArchiveOperation()
{
    m_archiveOpGen.fetch_add(1, std::memory_order_relaxed);
    if (m_archiveOpCancel) {
        m_archiveOpCancel->store(true, std::memory_order_relaxed);
        m_archiveOpCancel.reset();
    }
    if (m_archiveOpRunning) {
        m_archiveOpRunning = false;
        m_archiveOpTitle.clear();
        m_archiveOpDetail.clear();
        emit archiveOpChanged();
        showStatus(tr("Archive operation cancelled."));
    }
}

void Backend::packArchiveAsync(const QStringList &sourcePaths, const QString &archivePath)
{
    if (sourcePaths.isEmpty() || archivePath.trimmed().isEmpty())
        return;

    cancelArchiveOperation();

    const QFileInfo firstFi(sourcePaths.first());
    const QString workDir = firstFi.absolutePath();
    QStringList relativeNames;
    relativeNames.reserve(sourcePaths.size());
    for (const QString &p : sourcePaths)
        relativeNames.append(QFileInfo(p).fileName());

    QString outArchive = archivePath.trimmed();
    if (QFileInfo(outArchive).isRelative())
        outArchive = QDir(targetModel()->path()).filePath(outArchive);

    QString program;
    QStringList args;
    if (outArchive.endsWith(QLatin1String(".zip"), Qt::CaseInsensitive)) {
        const QString bsdtar = QStandardPaths::findExecutable(QStringLiteral("bsdtar"));
        const QString zipBin = QStandardPaths::findExecutable(QStringLiteral("zip"));
        if (!zipBin.isEmpty()) {
            program = zipBin;
            args = {QStringLiteral("-r"), outArchive};
            args.append(relativeNames);
        } else if (!bsdtar.isEmpty()) {
            program = bsdtar;
            args = {QStringLiteral("-a"), QStringLiteral("-cf"), outArchive};
            args.append(relativeNames);
        } else {
            const QString msg = tr("Missing zip or bsdtar tool.");
            showStatus(msg);
            emit archiveOperationFinished(false, msg);
            return;
        }
    } else {
        program = QStringLiteral("tar");
        args = {QStringLiteral("-caf"), outArchive};
        args.append(relativeNames);
    }

    const quint64 gen = m_archiveOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_archiveOpCancel = cancelFlag;
    m_archiveOpRunning = true;
    m_archiveOpTitle = tr("Packing Archive");
    m_archiveOpDetail = QFileInfo(outArchive).fileName();
    emit archiveOpChanged();

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, workDir, program, args, outArchive, cancelFlag]() {
        QProcess proc;
        proc.setWorkingDirectory(workDir);
        proc.start(program, args);
        const bool finished = waitProcessCancelable(proc, 120000, cancelFlag.get());
        const bool ok = finished && proc.exitCode() == 0;
        const bool cancelled = cancelFlag->load(std::memory_order_relaxed);

        if (cancelled) {
            QFile::remove(outArchive);
            return;
        }

        QMetaObject::invokeMethod(
            self,
            [self, gen, ok, outArchive]() {
                if (!self || self->m_archiveOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_archiveOpRunning = false;
                self->m_archiveOpTitle.clear();
                self->m_archiveOpDetail.clear();
                self->m_archiveOpCancel.reset();
                emit self->archiveOpChanged();

                self->m_leftPanel.refresh();
                self->m_rightPanel.refresh();
                const QString msg = ok ? tr("Created archive: %1").arg(QFileInfo(outArchive).fileName())
                                       : tr("Failed to create archive.");
                self->showStatus(msg);
                emit self->archiveOperationFinished(ok, msg);
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

void Backend::extractArchiveAsync(const QString &archivePath, const QString &targetDir)
{
    const QFileInfo fi(archivePath);
    if (!fi.exists() || targetDir.isEmpty())
        return;

    cancelArchiveOperation();

    QString program;
    QStringList args;
    const QString absArchive = fi.absoluteFilePath();
    const QString bsdtar = QStandardPaths::findExecutable(QStringLiteral("bsdtar"));
    if (!bsdtar.isEmpty()) {
        program = bsdtar;
        args = {QStringLiteral("-xf"), absArchive, QStringLiteral("-C"), targetDir};
    } else if (archivePath.endsWith(QLatin1String(".zip"), Qt::CaseInsensitive)) {
        program = QStringLiteral("unzip");
        args = {QStringLiteral("-o"), absArchive, QStringLiteral("-d"), targetDir};
    } else if (archivePath.endsWith(QLatin1String(".7z"), Qt::CaseInsensitive)) {
        program = QStringLiteral("7z");
        args = {QStringLiteral("x"), QStringLiteral("-y"), absArchive, QStringLiteral("-o") + targetDir};
    } else {
        program = QStringLiteral("tar");
        args = {QStringLiteral("-xf"), absArchive, QStringLiteral("-C"), targetDir};
    }

    const quint64 gen = m_archiveOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_archiveOpCancel = cancelFlag;
    m_archiveOpRunning = true;
    m_archiveOpTitle = tr("Extracting Archive");
    m_archiveOpDetail = fi.fileName();
    emit archiveOpChanged();

    const QString arcName = fi.fileName();
    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, targetDir, program, args, arcName, cancelFlag]() {
        QDir(targetDir).mkpath(QStringLiteral("."));
        QProcess proc;
        proc.setWorkingDirectory(targetDir);
        proc.start(program, args);
        const bool finished = waitProcessCancelable(proc, 120000, cancelFlag.get());
        const bool ok = finished && proc.exitCode() == 0;
        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, ok, arcName, targetDir]() {
                if (!self || self->m_archiveOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_archiveOpRunning = false;
                self->m_archiveOpTitle.clear();
                self->m_archiveOpDetail.clear();
                self->m_archiveOpCancel.reset();
                emit self->archiveOpChanged();

                self->m_leftPanel.refresh();
                self->m_rightPanel.refresh();
                const QString msg = ok ? tr("Extracted %1 to %2").arg(arcName, targetDir)
                                       : tr("Failed to extract archive.");
                self->showStatus(msg);
                emit self->archiveOperationFinished(ok, msg);
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

bool Backend::extractArchiveItems(const QString &archivePath, const QStringList &sourcePaths, const QString &targetDir)
{
    QFileInfo arcFi(archivePath);
    if (!arcFi.isFile() || sourcePaths.isEmpty() || targetDir.trimmed().isEmpty())
        return false;

    const QString cleanArchive = arcFi.canonicalFilePath().isEmpty()
                                     ? arcFi.absoluteFilePath()
                                     : arcFi.canonicalFilePath();

    QDir().mkpath(targetDir);
    const QFileInfo targetFi(targetDir);
    if (!targetFi.isDir()) {
        showStatus(tr("Target folder does not exist: %1").arg(targetDir));
        return false;
    }
    const QString targetRoot = targetFi.canonicalFilePath().isEmpty()
                                   ? QDir::cleanPath(targetFi.absoluteFilePath())
                                   : targetFi.canonicalFilePath();
    const QString safePrefix = targetRoot.endsWith('/') ? targetRoot : (targetRoot + '/');

    struct ExtractTarget {
        QString internalPath;
        QString stripPrefix;
    };
    QList<ExtractTarget> targets;
    for (const QString &rawSource : sourcePaths) {
        QString selArchive;
        QString selInternal;
        if (PanelModel::splitArchivePath(rawSource, &selArchive, &selInternal)) {
            if (selArchive != cleanArchive || selInternal.isEmpty())
                continue;
        } else {
            selInternal = rawSource;
            selInternal.replace('\\', '/');
            while (selInternal.startsWith('/'))
                selInternal.remove(0, 1);
            while (selInternal.endsWith('/'))
                selInternal.chop(1);
            if (selInternal.isEmpty())
                continue;
        }
        const int lastSlash = selInternal.lastIndexOf('/');
        const QString strip = (lastSlash > 0) ? selInternal.left(lastSlash + 1) : QString();
        targets.append(ExtractTarget{selInternal, strip});
    }

    if (targets.isEmpty())
        return false;

    struct archive *a = archive_read_new();
    if (!a)
        return false;
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    const QByteArray encodedArchive = QFile::encodeName(cleanArchive);
    if (archive_read_open_filename(a, encodedArchive.constData(), 65536) != ARCHIVE_OK) {
        archive_read_free(a);
        showStatus(tr("Failed to open archive: %1").arg(arcFi.fileName()));
        return false;
    }

    int extractedCount = 0;
    struct archive_entry *entry = nullptr;
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        bool endsWithSlash = false;
        const QString entryPath = normalizeArchiveEntryPath(entry, &endsWithSlash);
        if (entryPath.isEmpty()) {
            archive_read_data_skip(a);
            continue;
        }

        const ExtractTarget *matched = nullptr;
        for (const ExtractTarget &t : targets) {
            if (entryPath == t.internalPath || entryPath.startsWith(t.internalPath + '/')) {
                matched = &t;
                break;
            }
        }
        if (!matched) {
            archive_read_data_skip(a);
            continue;
        }

        const QString relOut = entryPath.mid(matched->stripPrefix.size());
        if (relOut.isEmpty() || relOut.contains(QLatin1String(".."))) {
            archive_read_data_skip(a);
            continue;
        }

        const QString cleanDest = QDir::cleanPath(safePrefix + relOut);
        if (!cleanDest.startsWith(safePrefix)) {
            archive_read_data_skip(a);
            continue;
        }

        const auto ftype = archive_entry_filetype(entry);
        if (ftype == AE_IFDIR || endsWithSlash) {
            if (QDir().mkpath(cleanDest))
                ++extractedCount;
            archive_read_data_skip(a);
        } else if (ftype == AE_IFLNK) {
            const char *symTarget = archive_entry_symlink(entry);
            if (symTarget && *symTarget) {
                QDir().mkpath(QFileInfo(cleanDest).absolutePath());
                QFile::remove(cleanDest);
                if (QFile::link(QString::fromUtf8(symTarget), cleanDest))
                    ++extractedCount;
            }
            archive_read_data_skip(a);
        } else {
            const int perm = static_cast<int>(archive_entry_perm(entry)) & 0777;
            if (streamArchiveToFile(a, cleanDest, perm > 0 ? perm : 0644))
                ++extractedCount;
        }
    }

    archive_read_free(a);
    m_leftPanel.refresh();
    m_rightPanel.refresh();

    const bool ok = extractedCount > 0;
    const QString msg = ok
                            ? tr("Extracted %1 item(s) from %2 to %3").arg(extractedCount).arg(arcFi.fileName(), targetRoot)
                            : tr("No matching items extracted from %1.").arg(arcFi.fileName());
    showStatus(msg);
    emit operationFinished(ok, msg);
    return ok;
}

QString Backend::ensureArchiveTempDir()
{
    if (!m_archiveTempDir)
        m_archiveTempDir = new QTemporaryDir();
    return m_archiveTempDir->isValid() ? m_archiveTempDir->path() : QString();
}

QString Backend::extractArchiveEntryToTempDir(const QString &archivePath, const QString &internalPath,
                                              const QString &tempDirPath)
{
    if (archivePath.isEmpty() || internalPath.isEmpty() || tempDirPath.isEmpty())
        return {};

    const QString key = QString::fromLatin1(
        QCryptographicHash::hash((archivePath + QLatin1Char('|') + internalPath).toUtf8(), QCryptographicHash::Sha1)
            .toHex()
            .left(12));
    const QString fileName = QFileInfo(internalPath).fileName();
    if (fileName.isEmpty() || fileName == QLatin1String(".") || fileName == QLatin1String(".."))
        return {};

    const QString destPath = QDir(tempDirPath).filePath(key + QLatin1Char('/') + fileName);

    struct archive *a = archive_read_new();
    if (!a)
        return {};
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    const QByteArray encodedArchive = QFile::encodeName(archivePath);
    if (archive_read_open_filename(a, encodedArchive.constData(), 65536) != ARCHIVE_OK) {
        archive_read_free(a);
        return {};
    }

    QString outPath;
    struct archive_entry *entry = nullptr;
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        bool endsWithSlash = false;
        const QString entryPath = normalizeArchiveEntryPath(entry, &endsWithSlash);
        if (entryPath == internalPath && archive_entry_filetype(entry) != AE_IFDIR && !endsWithSlash) {
            const int perm = static_cast<int>(archive_entry_perm(entry)) & 0777;
            if (streamArchiveToFile(a, destPath, perm > 0 ? perm : 0644))
                outPath = destPath;
            break;
        }
        archive_read_data_skip(a);
    }

    archive_read_free(a);
    return outPath;
}

QString Backend::extractArchiveEntryToTemp(const QString &archivePath, const QString &internalPath)
{
    return extractArchiveEntryToTempDir(archivePath, internalPath, ensureArchiveTempDir());
}

void Backend::recordRecentDirectory(const QString &path)
{
    if (path.trimmed().isEmpty())
        return;

    QString arc, inner;
    if (PanelModel::splitArchivePath(path, &arc, &inner))
        return;

    QFileInfo fi(path);
    if (!fi.isDir())
        return;

    const QString clean = fi.canonicalFilePath().isEmpty()
                              ? QDir::cleanPath(fi.absoluteFilePath())
                              : fi.canonicalFilePath();
    if (clean.isEmpty())
        return;

    if (!m_recentDirs.isEmpty() && m_recentDirs.first() == clean)
        return;

    m_recentDirs.removeAll(clean);
    m_recentDirs.prepend(clean);
    while (m_recentDirs.size() > 50)
        m_recentDirs.removeLast();

    emit recentDirectoriesChanged();

    const QString tmpRoot = QDir::tempPath();
    if (!m_loadingSession && !clean.startsWith(tmpRoot + '/') && !m_bookmarksFile.startsWith(tmpRoot + '/')) {
        const QString zoxide = QStandardPaths::findExecutable(QStringLiteral("zoxide"));
        if (!zoxide.isEmpty())
            QProcess::startDetached(zoxide, {QStringLiteral("add"), clean});
    }
}

int Backend::fuzzyScore(const QString &pattern, const QString &candidate)
{
    const QString pat = pattern.trimmed().toLower();
    if (pat.isEmpty())
        return 0;

    const QString cand = candidate.toLower();
    if (cand.isEmpty())
        return -1;

    int score = 0;
    int patIdx = 0;
    int prevMatch = -2;
    for (int i = 0; i < cand.size() && patIdx < pat.size(); ++i) {
        if (cand.at(i) == pat.at(patIdx)) {
            int bonus = 10;
            if (i == 0) {
                bonus += 25;
            } else {
                const QChar prev = cand.at(i - 1);
                if (prev == '/' || prev == '-' || prev == '_' || prev == '.' || prev == ' ')
                    bonus += 18;
            }
            if (i == prevMatch + 1)
                bonus += 15;
            score += bonus;
            prevMatch = i;
            ++patIdx;
        }
    }

    if (patIdx < pat.size())
        return -1;

    const int exactPos = cand.indexOf(pat);
    if (exactPos == 0)
        score += 80;
    else if (exactPos > 0)
        score += 40;

    score -= std::min(50, static_cast<int>(cand.size()) / 4);
    return std::max(1, score);
}

QVariantList Backend::queryJumpDirectories(const QString &query, int maxResults) const
{
    struct Candidate {
        QString path;
        QString name;
        QString source;
        QString badge;
        int priorityBonus = 0;
        bool forceInclude = false;
    };

    QList<Candidate> candidates;
    QHash<QString, int> indexByPath;

    auto addCandidate = [&](const QString &rawPath, const QString &source, const QString &badge,
                            int priorityBonus, bool forceInclude = false) {
        QFileInfo fi(rawPath);
        if (!fi.isDir())
            return;
        const QString clean = fi.canonicalFilePath().isEmpty()
                                  ? QDir::cleanPath(fi.absoluteFilePath())
                                  : fi.canonicalFilePath();
        if (clean.isEmpty())
            return;

        if (indexByPath.contains(clean)) {
            Candidate &existing = candidates[indexByPath.value(clean)];
            if (priorityBonus > existing.priorityBonus) {
                existing.source = source;
                existing.badge = badge;
                existing.priorityBonus = priorityBonus;
            }
            if (forceInclude)
                existing.forceInclude = true;
            return;
        }

        Candidate c;
        c.path = clean;
        c.name = clean == QLatin1String("/") ? QStringLiteral("/") : QFileInfo(clean).fileName();
        if (c.name.isEmpty())
            c.name = clean;
        c.source = source;
        c.badge = badge;
        c.priorityBonus = priorityBonus;
        c.forceInclude = forceInclude;
        indexByPath.insert(clean, candidates.size());
        candidates.append(c);
    };

    const PanelModel *active = (m_activePanel == 0) ? &m_leftPanel : &m_rightPanel;
    const QString activeRealDir = active->isArchiveView()
                                      ? QFileInfo(active->archiveFilePath()).absolutePath()
                                      : active->path();
    const QString trimmed = query.trimmed();

    // 1. Direct path completion if user typed an explicit path (/..., ~/..., ./..., ../...)
    if (trimmed.startsWith('/') || trimmed.startsWith('~') || trimmed.startsWith('.')) {
        QString expanded = trimmed;
        if (expanded == QLatin1String("~"))
            expanded = QDir::homePath();
        else if (expanded.startsWith(QLatin1String("~/")))
            expanded = QDir::homePath() + expanded.mid(1);
        else if (expanded.startsWith('.'))
            expanded = QDir::cleanPath(activeRealDir + '/' + expanded);

        if (QFileInfo(expanded).isDir())
            addCandidate(expanded, QStringLiteral("path"), tr("Path"), 220, true);

        const int lastSlash = expanded.lastIndexOf('/');
        const QString parentDir = (lastSlash == 0) ? QStringLiteral("/")
                                  : (lastSlash > 0) ? expanded.left(lastSlash)
                                                    : QString();
        const QString leafPrefix = (lastSlash >= 0) ? expanded.mid(lastSlash + 1).toLower() : QString();
        if (!parentDir.isEmpty() && QFileInfo(parentDir).isDir()) {
            const QDir pDir(parentDir);
            const QFileInfoList subDirs = pDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot |
                                                                 (leafPrefix.startsWith('.') ? QDir::Hidden : QDir::Filter(0)));
            int added = 0;
            for (const QFileInfo &sd : subDirs) {
                if (leafPrefix.isEmpty() || sd.fileName().toLower().startsWith(leafPrefix) ||
                    fuzzyScore(leafPrefix, sd.fileName()) > 0) {
                    addCandidate(sd.absoluteFilePath(), QStringLiteral("path"), tr("Path"), 190, true);
                    if (++added >= 40)
                        break;
                }
            }
        }
    }

    // 2. Bookmarks
    for (const QString &b : m_bookmarks)
        addCandidate(b, QStringLiteral("bookmark"), tr("Bookmark"), 95);

    // 3. Open tabs (both panels)
    for (const QString &tp : m_leftPanel.tabPaths())
        addCandidate(tp, QStringLiteral("tab"), tr("Open Tab"), 85);
    for (const QString &tp : m_rightPanel.tabPaths())
        addCandidate(tp, QStringLiteral("tab"), tr("Open Tab"), 85);

    // 4. Recent directories (newer entries get slightly higher bonus)
    for (int i = 0; i < m_recentDirs.size(); ++i)
        addCandidate(m_recentDirs.at(i), QStringLiteral("recent"), tr("Recent"), std::max(40, 80 - i));

    // 5. Direct subdirectories of active panel (when not in archive view)
    if (!active->isArchiveView() && QFileInfo(active->path()).isDir()) {
        const QDir activeDir(active->path());
        const QFileInfoList children = activeDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
        int childCount = 0;
        for (const QFileInfo &ch : children) {
            addCandidate(ch.absoluteFilePath(), QStringLiteral("subfolder"), tr("Subfolder"), 65);
            if (++childCount >= 120)
                break;
        }
    }

    // 6. Mounted drives
    for (const QVariant &dv : m_drives) {
        const QVariantMap d = dv.toMap();
        if (d.value(QStringLiteral("isMounted")).toBool())
            addCandidate(d.value(QStringLiteral("path")).toString(), QStringLiteral("drive"), tr("Drive"), 55);
    }

    // 7. zoxide frecency database (when installed)
    const QString tmpRoot = QDir::tempPath();
    if (!m_bookmarksFile.startsWith(tmpRoot + '/')) {
        const QString zoxide = QStandardPaths::findExecutable(QStringLiteral("zoxide"));
        if (!zoxide.isEmpty()) {
            QProcess proc;
            QStringList args{QStringLiteral("query"), QStringLiteral("-l")};
            if (!trimmed.isEmpty() && !trimmed.startsWith('/') && !trimmed.startsWith('~') && !trimmed.startsWith('.')) {
                args.append(trimmed.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts));
            }
            proc.start(zoxide, args);
            if (proc.waitForFinished(500) && proc.exitCode() == 0) {
                const QString out = QString::fromUtf8(proc.readAllStandardOutput());
                const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
                int count = 0;
                for (const QString &line : lines) {
                    addCandidate(line.trimmed(), QStringLiteral("zoxide"), QStringLiteral("zoxide"),
                                 std::max(35, 78 - count));
                    if (++count >= 80)
                        break;
                }
            }
        }
    }

    struct ScoredCandidate {
        Candidate cand;
        int score = 0;
    };
    QList<ScoredCandidate> scored;
    const QString activePath = active->path();

    for (const Candidate &c : candidates) {
        int totalScore = 0;
        if (trimmed.isEmpty()) {
            totalScore = c.priorityBonus + (c.path == activePath ? -15 : 0);
        } else if (c.forceInclude) {
            const int ps = fuzzyScore(trimmed, c.path);
            totalScore = c.priorityBonus + std::max(0, ps);
        } else {
            const int nameScore = fuzzyScore(trimmed, c.name);
            const int pathScore = fuzzyScore(trimmed, c.path);
            if (nameScore < 0 && pathScore < 0)
                continue;
            totalScore = std::max(0, nameScore) * 2 + std::max(0, pathScore) + c.priorityBonus;
        }
        scored.append(ScoredCandidate{c, totalScore});
    }

    std::sort(scored.begin(), scored.end(), [](const ScoredCandidate &a, const ScoredCandidate &b) {
        if (a.score != b.score)
            return a.score > b.score;
        if (a.cand.path.size() != b.cand.path.size())
            return a.cand.path.size() < b.cand.path.size();
        return a.cand.path.compare(b.cand.path, Qt::CaseInsensitive) < 0;
    });

    const int limit = std::clamp(maxResults, 1, 200);
    QVariantList result;
    result.reserve(std::min(limit, static_cast<int>(scored.size())));
    for (int i = 0; i < scored.size() && i < limit; ++i) {
        QVariantMap row;
        row["path"] = scored.at(i).cand.path;
        row["name"] = scored.at(i).cand.name;
        row["source"] = scored.at(i).cand.source;
        row["badge"] = scored.at(i).cand.badge;
        row["score"] = scored.at(i).score;
        result.append(row);
    }
    return result;
}

QVariantList Backend::buildBaseDrivesList() const
{
    QVariantList result;
    QSet<QString> seenPaths;

    auto addDrive = [&](const QString &label, const QString &path, const QString &freeStr, bool canUnmount = false) {
        if (seenPaths.contains(path) || !QDir(path).exists())
            return;
        seenPaths.insert(path);
        QVariantMap d;
        d["label"] = label;
        d["path"] = path;
        d["free"] = freeStr;
        d["isMounted"] = true;
        d["canUnmount"] = canUnmount;
        d["isRemovable"] = canUnmount;
        d["devPath"] = QString();
        result.append(d);
    };

    const QStorageInfo homeStorage(QDir::homePath());
    addDrive("~ Home", QDir::homePath(), PanelModel::formatSize(homeStorage.bytesAvailable(), false));

    const QStorageInfo rootStorage("/");
    addDrive("/ Root", "/", PanelModel::formatSize(rootStorage.bytesAvailable(), false));

    const QString sshfsRoot = sshfsMountsRootDir();
    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady())
            continue;
        const QString rootPath = storage.rootPath();
        const QByteArray fsType = storage.fileSystemType();
        if (fsType == "tmpfs" || fsType == "devtmpfs" || fsType == "proc" || fsType == "sysfs" ||
            fsType == "cgroup2" || fsType == "overlay" || fsType == "squashfs" || fsType == "efivarfs")
            continue;
        if (rootPath == QLatin1String("/") || rootPath == QLatin1String("/home") ||
            rootPath == QLatin1String("/root") || rootPath == QLatin1String("/srv") ||
            rootPath.startsWith("/boot") || rootPath.startsWith("/run/user") ||
            (!sshfsRoot.isEmpty() && rootPath.startsWith(sshfsRoot)) ||
            rootPath.startsWith("/var") || rootPath.startsWith("/sys") || rootPath.startsWith("/dev"))
            continue;

        QString label = storage.displayName();
        if (label.isEmpty() || label == rootPath) {
            label = QFileInfo(rootPath).fileName();
            if (label.isEmpty())
                label = rootPath;
        }
        const bool canUnmount = rootPath.startsWith("/run/media") || rootPath.startsWith("/media") || rootPath.startsWith("/mnt");
        addDrive(label, rootPath, PanelModel::formatSize(storage.bytesAvailable(), false), canUnmount);
    }

    addDrive("/tmp", "/tmp", "");

    // Freedesktop Trash chip
    {
        const int count = trashCount();
        QVariantMap trashChip;
        trashChip[QStringLiteral("label")] = tr("Trash");
        trashChip[QStringLiteral("path")] = QStringLiteral("trash://");
        trashChip[QStringLiteral("free")] = count > 0 ? QString::number(count) : QString();
        trashChip[QStringLiteral("isMounted")] = true;
        trashChip[QStringLiteral("canUnmount")] = false;
        trashChip[QStringLiteral("isRemovable")] = false;
        trashChip[QStringLiteral("isTrash")] = true;
        trashChip[QStringLiteral("devPath")] = QString();
        result.append(trashChip);
    }

    // Saved remote connections (Google Drive / rclone / SFTP / SMB / SSHFS) + discovered rclone Drive remotes
    const QString gvfsRoot = gvfsRootDir();
    QSet<QString> coveredGvfsDirs;
    QSet<QString> coveredCloudKeys;
    const QVariantList remotes = remoteConnections();
    for (const QVariant &v : remotes) {
        const QVariantMap conn = v.toMap();
        const QString mountPath = conn.value(QStringLiteral("mountPath")).toString();
        const bool isMounted = conn.value(QStringLiteral("isMounted")).toBool();
        const QString uri = conn.value(QStringLiteral("uri")).toString();
        const QString protoLower = conn.value(QStringLiteral("protocol")).toString().toLower();
        const QString proto = protoLower.toUpper();
        const QString host = conn.value(QStringLiteral("host")).toString();
        QVariantMap d;
        d[QStringLiteral("label")] = conn.value(QStringLiteral("name")).toString();
        d[QStringLiteral("path")] = (isMounted && !mountPath.isEmpty()) ? mountPath : uri;
        d[QStringLiteral("free")] = proto;
        d[QStringLiteral("isMounted")] = isMounted;
        d[QStringLiteral("canUnmount")] = isMounted;
        d[QStringLiteral("isRemovable")] = false;
        d[QStringLiteral("isRemote")] = true;
        d[QStringLiteral("remoteId")] = conn.value(QStringLiteral("id")).toString();
        d[QStringLiteral("remoteUri")] = uri;
        d[QStringLiteral("protocol")] = protoLower;
        d[QStringLiteral("devPath")] = QString();
        result.append(d);

        if (isCloudRemoteProtocol(protoLower) && !host.isEmpty())
            coveredCloudKeys.insert(host);

        if (isMounted && !mountPath.isEmpty()) {
            seenPaths.insert(mountPath);
            if (!gvfsRoot.isEmpty() && mountPath.startsWith(gvfsRoot + QLatin1Char('/'))) {
                const QString rel = mountPath.mid(gvfsRoot.size() + 1);
                const QString topDir = rel.section(QLatin1Char('/'), 0, 0);
                if (!topDir.isEmpty())
                    coveredGvfsDirs.insert(QDir(gvfsRoot).filePath(topDir));
            }
        }
    }

    for (const QVariant &v : std::as_const(m_rcloneRemotes)) {
        const QVariantMap rm = v.toMap();
        const QString rName = rm.value(QStringLiteral("name")).toString();
        const bool isGdrive = rm.value(QStringLiteral("isGoogleDrive")).toBool();
        if (!isGdrive || rName.isEmpty() || coveredCloudKeys.contains(rName))
            continue;
        QVariantMap conn;
        conn[QStringLiteral("protocol")] = QStringLiteral("gdrive");
        conn[QStringLiteral("host")] = rName;
        const QString mountPath = resolveRemoteMountPath(conn);
        const bool isMounted = !mountPath.isEmpty();
        const QString uri = QStringLiteral("gdrive://") + rName;
        QVariantMap d;
        d[QStringLiteral("label")] = QStringLiteral("Google Drive (%1)").arg(rName);
        d[QStringLiteral("path")] = isMounted ? mountPath : uri;
        d[QStringLiteral("free")] = QStringLiteral("GDRIVE");
        d[QStringLiteral("isMounted")] = isMounted;
        d[QStringLiteral("canUnmount")] = isMounted;
        d[QStringLiteral("isRemovable")] = false;
        d[QStringLiteral("isRemote")] = true;
        d[QStringLiteral("remoteId")] = QString();
        d[QStringLiteral("remoteUri")] = uri;
        d[QStringLiteral("protocol")] = QStringLiteral("gdrive");
        d[QStringLiteral("devPath")] = QString();
        result.append(d);
        if (isMounted)
            seenPaths.insert(mountPath);
    }

    if (QDir(gvfsRoot).exists()) {
        const QFileInfoList gvfsEntries = QDir(gvfsRoot).entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const QFileInfo &fi : gvfsEntries) {
            const QString gvfsPath = fi.absoluteFilePath();
            if (seenPaths.contains(gvfsPath) || coveredGvfsDirs.contains(gvfsPath))
                continue;
            const QString dirName = fi.fileName();
            const QString proto = dirName.startsWith(QLatin1String("smb")) ? QStringLiteral("smb") : QStringLiteral("sftp");
            QString displayLabel = dirName;
            static const QRegularExpression hostRe(QStringLiteral("(?:host|server)=([^,]+)"));
            const QRegularExpressionMatch hm = hostRe.match(dirName);
            if (hm.hasMatch())
                displayLabel = hm.captured(1);
            QVariantMap d;
            d[QStringLiteral("label")] = displayLabel;
            d[QStringLiteral("path")] = gvfsPath;
            d[QStringLiteral("free")] = proto.toUpper();
            d[QStringLiteral("isMounted")] = true;
            d[QStringLiteral("canUnmount")] = true;
            d[QStringLiteral("isRemovable")] = false;
            d[QStringLiteral("isRemote")] = true;
            d[QStringLiteral("remoteId")] = QString();
            d[QStringLiteral("remoteUri")] = QString();
            d[QStringLiteral("protocol")] = proto;
            d[QStringLiteral("devPath")] = QString();
            result.append(d);
        }
    }

    return result;
}

void Backend::refreshDrives()
{
    m_drives = buildBaseDrivesList();
    emit drivesChanged();

    const quint64 gen = m_drivesGeneration.fetch_add(1, std::memory_order_relaxed) + 1;
    if (m_drivesCancel)
        m_drivesCancel->store(true, std::memory_order_relaxed);
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_drivesCancel = cancelFlag;

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, cancelFlag]() {
        QVariantList blockUnmounted;
        QProcess lsblkProc;
        lsblkProc.start(QStringLiteral("lsblk"),
                        {QStringLiteral("-J"), QStringLiteral("-o"),
                         QStringLiteral("NAME,PATH,RM,RO,TYPE,SIZE,MOUNTPOINT,LABEL,FSTYPE,MODEL")});
        if (waitProcessCancelable(lsblkProc, 2500, cancelFlag.get()) && lsblkProc.exitCode() == 0) {
            const QByteArray out = lsblkProc.readAllStandardOutput();
            const QJsonObject rootObj = QJsonDocument::fromJson(out).object();
            const QJsonArray blockDevices = rootObj[QStringLiteral("blockdevices")].toArray();

            std::function<void(const QJsonArray &)> parseDevices = [&](const QJsonArray &devs) {
                for (const QJsonValue &v : devs) {
                    if (cancelFlag->load(std::memory_order_relaxed))
                        return;
                    const QJsonObject dev = v.toObject();
                    const QString mountPoint = dev[QStringLiteral("mountpoint")].toString();
                    const QString devPath = dev[QStringLiteral("path")].toString();
                    const QString fstype = dev[QStringLiteral("fstype")].toString();
                    const QString size = dev[QStringLiteral("size")].toString();
                    const QString label = dev[QStringLiteral("label")].toString();
                    const bool isRm = dev[QStringLiteral("rm")].toBool();
                    const QString model = dev[QStringLiteral("model")].toString();

                    if (mountPoint.isEmpty() && !fstype.isEmpty() && fstype != QLatin1String("swap")
                        && fstype != QLatin1String("crypto_LUKS")) {
                        QString displayLabel = label.isEmpty() ? QFileInfo(devPath).fileName() : label;
                        if (!model.isEmpty())
                            displayLabel += QStringLiteral(" (") + model.trimmed() + QLatin1Char(')');
                        QVariantMap d;
                        d[QStringLiteral("label")] = displayLabel;
                        d[QStringLiteral("path")] = devPath;
                        d[QStringLiteral("free")] = size;
                        d[QStringLiteral("isMounted")] = false;
                        d[QStringLiteral("canUnmount")] = false;
                        d[QStringLiteral("isRemovable")] = isRm;
                        d[QStringLiteral("devPath")] = devPath;
                        d[QStringLiteral("fsType")] = fstype;
                        blockUnmounted.append(d);
                    }

                    if (dev.contains(QStringLiteral("children")))
                        parseDevices(dev[QStringLiteral("children")].toArray());
                }
            };
            parseDevices(blockDevices);
        }

        if (cancelFlag->load(std::memory_order_relaxed) || blockUnmounted.isEmpty())
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, blockUnmounted]() {
                if (!self || self->m_drivesGeneration.load(std::memory_order_relaxed) != gen)
                    return;
                QVariantList merged = self->buildBaseDrivesList();
                int insertPos = merged.size();
                for (int i = 0; i < merged.size(); ++i) {
                    if (merged.at(i).toMap().value(QStringLiteral("isRemote")).toBool()) {
                        insertPos = i;
                        break;
                    }
                }
                for (int i = 0; i < blockUnmounted.size(); ++i)
                    merged.insert(insertPos + i, blockUnmounted.at(i));
                self->m_drives = merged;
                emit self->drivesChanged();
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

bool Backend::mountDevice(const QString &devPath)
{
    if (devPath.trimmed().isEmpty())
        return false;

    QProcess proc;
    proc.start("udisksctl", {"mount", "-b", devPath.trimmed()});
    if (!proc.waitForFinished(10000)) {
        showStatus(tr("Mount command timed out."));
        return false;
    }

    const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();

    if (proc.exitCode() == 0) {
        static const QRegularExpression rx(R"(Mounted\s+\S+\s+at\s+(\S+))");
        auto match = rx.match(out);
        refreshDrives();
        if (match.hasMatch()) {
            const QString mountPoint = match.captured(1);
            activeModel()->setPath(mountPoint);
            showStatus(tr("Mounted at: %1").arg(mountPoint));
        } else {
            showStatus(tr("Device mounted successfully."));
        }
        return true;
    }

    showStatus(err.isEmpty() ? tr("Failed to mount %1").arg(devPath) : err);
    return false;
}

bool Backend::unmountDevice(const QString &mountOrDevPath)
{
    if (mountOrDevPath.trimmed().isEmpty())
        return false;

    QProcess proc;
    if (mountOrDevPath.startsWith("/dev/")) {
        proc.start("udisksctl", {"unmount", "-b", mountOrDevPath.trimmed()});
    } else {
        proc.start("udisksctl", {"unmount", "-p", mountOrDevPath.trimmed()});
        if (!proc.waitForFinished(3000) || proc.exitCode() != 0) {
            proc.start("udisksctl", {"unmount", "-b", mountOrDevPath.trimmed()});
        }
    }
    proc.waitForFinished(8000);

    const bool ok = (proc.exitCode() == 0);
    if (ok) {
        if (m_leftPanel.path().startsWith(mountOrDevPath))
            m_leftPanel.setPath(QDir::homePath());
        if (m_rightPanel.path().startsWith(mountOrDevPath))
            m_rightPanel.setPath(QDir::homePath());
        refreshDrives();
        showStatus(tr("Device unmounted successfully."));
    } else {
        const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
        showStatus(err.isEmpty() ? tr("Failed to unmount.") : err);
    }
    return ok;
}

void Backend::mountDeviceAsync(const QString &devPath)
{
    const QString cleanDev = devPath.trimmed();
    if (cleanDev.isEmpty())
        return;

    cancelRemoteOperation();
    const quint64 gen = m_remoteOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_remoteOpCancel = cancelFlag;
    m_remoteOpRunning = true;
    m_remoteOpDetail = tr("Mounting %1…").arg(QFileInfo(cleanDev).fileName());
    emit remoteOpChanged();

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, cleanDev, cancelFlag]() {
        QProcess proc;
        proc.start(QStringLiteral("udisksctl"), {QStringLiteral("mount"), QStringLiteral("-b"), cleanDev});
        const bool finished = waitProcessCancelable(proc, 12000, cancelFlag.get());
        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        const bool ok = finished && proc.exitCode() == 0;
        const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
        QString mountPoint;
        if (ok) {
            static const QRegularExpression rx(QStringLiteral(R"(Mounted\s+\S+\s+at\s+(\S+))"));
            const auto match = rx.match(out);
            if (match.hasMatch())
                mountPoint = match.captured(1);
        }

        QMetaObject::invokeMethod(
            self,
            [self, gen, ok, finished, mountPoint, err, cleanDev]() {
                if (!self || self->m_remoteOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_remoteOpRunning = false;
                self->m_remoteOpDetail.clear();
                self->m_remoteOpCancel.reset();
                emit self->remoteOpChanged();

                if (ok) {
                    self->refreshDrives();
                    if (!mountPoint.isEmpty())
                        self->activeModel()->setPath(mountPoint);
                    const QString msg = !mountPoint.isEmpty() ? tr("Mounted at: %1").arg(mountPoint)
                                                              : tr("Device mounted successfully.");
                    self->showStatus(msg);
                    emit self->remoteOperationFinished(true, mountPoint, msg);
                } else {
                    const QString msg = !finished ? tr("Mount command timed out.")
                                                  : (err.isEmpty() ? tr("Failed to mount %1").arg(cleanDev) : err);
                    self->showStatus(msg);
                    emit self->remoteOperationFinished(false, QString(), msg);
                }
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

void Backend::unmountDeviceAsync(const QString &mountOrDevPath)
{
    const QString target = mountOrDevPath.trimmed();
    if (target.isEmpty())
        return;

    cancelRemoteOperation();
    const quint64 gen = m_remoteOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_remoteOpCancel = cancelFlag;
    m_remoteOpRunning = true;
    m_remoteOpDetail = tr("Unmounting %1…").arg(QFileInfo(target).fileName());
    emit remoteOpChanged();

    // Move panels off the target mount before unmounting so the filesystem is not busy.
    if (m_leftPanel.path().startsWith(target))
        m_leftPanel.setPath(QDir::homePath());
    if (m_rightPanel.path().startsWith(target))
        m_rightPanel.setPath(QDir::homePath());

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, target, cancelFlag]() {
        QProcess proc;
        bool finished = false;
        if (target.startsWith(QLatin1String("/dev/"))) {
            proc.start(QStringLiteral("udisksctl"), {QStringLiteral("unmount"), QStringLiteral("-b"), target});
            finished = waitProcessCancelable(proc, 8000, cancelFlag.get());
        } else {
            proc.start(QStringLiteral("udisksctl"), {QStringLiteral("unmount"), QStringLiteral("-p"), target});
            finished = waitProcessCancelable(proc, 3000, cancelFlag.get());
            if (!cancelFlag->load(std::memory_order_relaxed) && (!finished || proc.exitCode() != 0)) {
                proc.start(QStringLiteral("udisksctl"), {QStringLiteral("unmount"), QStringLiteral("-b"), target});
                finished = waitProcessCancelable(proc, 8000, cancelFlag.get());
            }
        }
        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        const bool ok = finished && proc.exitCode() == 0;
        const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();

        QMetaObject::invokeMethod(
            self,
            [self, gen, ok, err]() {
                if (!self || self->m_remoteOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_remoteOpRunning = false;
                self->m_remoteOpDetail.clear();
                self->m_remoteOpCancel.reset();
                emit self->remoteOpChanged();

                if (ok) {
                    self->refreshDrives();
                    const QString msg = tr("Device unmounted successfully.");
                    self->showStatus(msg);
                    emit self->remoteOperationFinished(true, QString(), msg);
                } else {
                    const QString msg = err.isEmpty() ? tr("Failed to unmount.") : err;
                    self->showStatus(msg);
                    emit self->remoteOperationFinished(false, QString(), msg);
                }
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

void Backend::loadBookmarks()
{
    m_bookmarks.clear();
    QFile file(m_bookmarksFile);
    if (file.open(QIODevice::ReadOnly)) {
        const QJsonArray arr = QJsonDocument::fromJson(file.readAll()).array();
        for (const QJsonValue &v : arr) {
            if (v.isString() && !v.toString().isEmpty())
                m_bookmarks.append(v.toString());
        }
    }
    if (m_bookmarks.isEmpty()) {
        m_bookmarks.append(QDir::homePath());
        if (QDir(QDir::homePath() + "/Downloads").exists())
            m_bookmarks.append(QDir::homePath() + "/Downloads");
        if (QDir(QDir::homePath() + "/Projects").exists())
            m_bookmarks.append(QDir::homePath() + "/Projects");
    }
    emit bookmarksChanged();
}

void Backend::saveBookmarks() const
{
    QFileInfo fi(m_bookmarksFile);
    QDir().mkpath(fi.absolutePath());
    QFile file(m_bookmarksFile);
    if (file.open(QIODevice::WriteOnly)) {
        QJsonArray arr;
        for (const QString &b : m_bookmarks)
            arr.append(b);
        file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    }
}

void Backend::toggleBookmark(const QString &path)
{
    if (path.isEmpty())
        return;

    if (m_bookmarks.contains(path)) {
        m_bookmarks.removeAll(path);
        showStatus(tr("Removed bookmark: %1").arg(path));
    } else {
        m_bookmarks.append(path);
        showStatus(tr("Added bookmark: %1").arg(path));
    }
    saveBookmarks();
    emit bookmarksChanged();
}

bool Backend::isBookmarked(const QString &path) const
{
    return m_bookmarks.contains(path);
}

QVariantMap Backend::runCommand(const QString &command)
{
    QVariantMap res;
    const QString trimmed = command.trimmed();
    if (trimmed.isEmpty())
        return res;

    recordCommandHistory(trimmed);

    QString cdMsg;
    int cdCode = 0;
    if (tryHandleBuiltinCd(trimmed, &cdMsg, &cdCode)) {
        res["exitCode"] = cdCode;
        res["output"] = cdMsg;
        showStatus(cdMsg);
        return res;
    }

    QProcess proc;
    const QString workDir = activeFilesystemPath();
    proc.setWorkingDirectory(workDir);
    proc.setProcessChannelMode(QProcess::MergedChannels);
    proc.start("/bin/sh", {"-c", trimmed});
    proc.waitForFinished(10000);

    const QString output = QString::fromUtf8(proc.readAll()).trimmed();
    const int code = proc.exitCode();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    res["exitCode"] = code;
    res["output"] = output;

    if (!output.isEmpty()) {
        QString firstLine = output.section('\n', 0, 0);
        showStatus(QString("[%1] %2").arg(code).arg(firstLine));
    } else {
        showStatus(tr("Command finished (exit %1): %2").arg(code).arg(trimmed));
    }
    return res;
}

QVariantMap Backend::buildPreviewData(const QString &path, int pdfPage, bool dark, const QString &tempDirPath,
                                      const std::atomic<bool> *cancelFlag)
{
    QVariantMap map;
    if (isTaskCancelled(cancelFlag))
        return map;

    QString archiveFile;
    QString internalPath;
    if (PanelModel::splitArchivePath(path, &archiveFile, &internalPath) && !internalPath.isEmpty()) {
        struct archive *a = archive_read_new();
        if (!a) {
            map["exists"] = false;
            return map;
        }
        archive_read_support_filter_all(a);
        archive_read_support_format_all(a);

        const QByteArray encodedArchive = QFile::encodeName(archiveFile);
        if (archive_read_open_filename(a, encodedArchive.constData(), 65536) != ARCHIVE_OK) {
            archive_read_free(a);
            map["exists"] = false;
            return map;
        }

        const QString childPrefix = internalPath + '/';
        bool matchedDir = false;
        QString dirModified;
        int subDirs = 0;
        int files = 0;
        qint64 directBytes = 0;
        QStringList sampleNames;
        QSet<QString> seenChildren;

        struct archive_entry *entry = nullptr;
        while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
            if (isTaskCancelled(cancelFlag)) {
                archive_read_free(a);
                return {};
            }
            bool endsWithSlash = false;
            const QString entryPath = normalizeArchiveEntryPath(entry, &endsWithSlash);
            if (entryPath.isEmpty()) {
                archive_read_data_skip(a);
                continue;
            }

            const bool entryIsDir = (archive_entry_filetype(entry) == AE_IFDIR) || endsWithSlash;
            const qint64 entrySize = std::max<qint64>(0, static_cast<qint64>(archive_entry_size(entry)));
            const QString modifiedStr = archive_entry_mtime_is_set(entry)
                                            ? QDateTime::fromSecsSinceEpoch(archive_entry_mtime(entry))
                                                  .toString("yyyy-MM-dd hh:mm:ss")
                                            : QString();

            if (entryPath == internalPath && !entryIsDir) {
                const QFileInfo entryFi(internalPath);
                const QString ext = entryFi.suffix().toLower();
                map["exists"] = true;
                map["name"] = entryFi.fileName();
                map["path"] = archiveFile + "/" + internalPath;
                map["isDir"] = false;
                map["size"] = entrySize;
                map["formattedSize"] = PanelModel::formatSize(entrySize, false);
                map["modified"] = modifiedStr;

                if (isImageExtension(ext)) {
                    archive_read_free(a);
                    const QString tempImg = extractArchiveEntryToTempDir(archiveFile, internalPath, tempDirPath);
                    if (!tempImg.isEmpty()) {
                        map["isImage"] = true;
                        map["imagePath"] = QUrl::fromLocalFile(tempImg).toString();
                        QImageReader reader(tempImg);
                        const QSize sz = reader.size();
                        if (sz.isValid())
                            map["imageDimensions"] = QString("%1 × %2 px").arg(sz.width()).arg(sz.height());
                        const QString fmt = QString::fromLatin1(reader.format()).toUpper();
                        map["imageFormat"] = fmt.isEmpty() ? ext.toUpper() : fmt;
                    }
                    return map;
                }

                constexpr qint64 kMaxPreviewBytes = 128 * 1024;
                QByteArray chunk;
                char buf[8192];
                bool truncated = false;
                while (chunk.size() <= kMaxPreviewBytes) {
                    const la_ssize_t n = archive_read_data(a, buf, sizeof(buf));
                    if (n <= 0)
                        break;
                    chunk.append(buf, static_cast<qsizetype>(n));
                    if (chunk.size() > kMaxPreviewBytes) {
                        chunk.truncate(kMaxPreviewBytes);
                        truncated = true;
                        break;
                    }
                }
                archive_read_free(a);

                const bool isBinary = chunk.contains('\0');
                map["isImage"] = false;
                map["isBinary"] = isBinary;
                map["isText"] = true;
                if (!isBinary) {
                    const QString text = QString::fromUtf8(chunk);
                    map["text"] = text;
                    map["truncated"] = truncated;
                    const QString lang = syntaxLanguageForFile(entryFi.fileName(), ext);
                    if (ext == QLatin1String("md") || ext == QLatin1String("markdown") || ext == QLatin1String("mdx")) {
                        map["isMarkdown"] = true;
                        map["isCode"] = true;
                        map["syntaxLanguage"] = QStringLiteral("Markdown");
                        map["renderedHtml"] = renderMarkdownToHtml(text, dark);
                        map["highlightedHtml"] = highlightCodeToHtml(text, ext, dark);
                    } else if (!lang.isEmpty()) {
                        map["isCode"] = true;
                        map["syntaxLanguage"] = lang;
                        map["highlightedHtml"] = highlightCodeToHtml(text, ext, dark);
                    }
                } else {
                    map["text"] = formatHexDumpText(chunk, map["formattedSize"].toString(), entrySize);
                }
                return map;
            }

            if (entryPath == internalPath && entryIsDir) {
                matchedDir = true;
                dirModified = modifiedStr;
            } else if (entryPath.startsWith(childPrefix)) {
                matchedDir = true;
                const QString rel = entryPath.mid(childPrefix.size());
                const int slash = rel.indexOf('/');
                const QString childName = (slash >= 0) ? rel.left(slash) : rel;
                const bool childIsDir = (slash >= 0) || entryIsDir;
                if (!childName.isEmpty() && !seenChildren.contains(childName)) {
                    seenChildren.insert(childName);
                    if (childIsDir)
                        ++subDirs;
                    else {
                        ++files;
                        directBytes += entrySize;
                    }
                    if (sampleNames.size() < 25)
                        sampleNames.append((childIsDir ? "📁 " : "🗎 ") + childName);
                }
            }
            archive_read_data_skip(a);
        }

        archive_read_free(a);
        if (matchedDir) {
            map["exists"] = true;
            map["name"] = QFileInfo(internalPath).fileName();
            map["path"] = archiveFile + "/" + internalPath;
            map["isDir"] = true;
            map["size"] = 0;
            map["formattedSize"] = PanelModel::formatSize(0, true);
            map["modified"] = dirModified;
            map["isText"] = true;
            map["text"] = QObject::tr("Archive Folder: %1\nPath: %2\n\nContents: %3 folder(s), %4 file(s)\nDirect files size: %5\n\nItems:\n%6")
                              .arg(map["name"].toString(),
                                   map["path"].toString())
                              .arg(subDirs)
                              .arg(files)
                              .arg(PanelModel::formatSize(directBytes, false),
                                   sampleNames.isEmpty() ? QObject::tr("(empty directory)") : sampleNames.join("\n"));
            return map;
        }

        map["exists"] = false;
        return map;
    }

    QFileInfo fi(path);
    if (!fi.exists()) {
        map["exists"] = false;
        return map;
    }

    map["exists"] = true;
    map["name"] = fi.fileName();
    map["path"] = fi.absoluteFilePath();
    map["isDir"] = fi.isDir();
    map["size"] = fi.size();
    map["formattedSize"] = PanelModel::formatSize(fi.size(), fi.isDir());
    map["modified"] = fi.lastModified().toString("yyyy-MM-dd hh:mm:ss");

    if (fi.isDir()) {
        QDir dir(fi.absoluteFilePath());
        const QFileInfoList list = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
        int subDirs = 0;
        int files = 0;
        qint64 directBytes = 0;
        QStringList sampleNames;
        for (const QFileInfo &entry : list) {
            if (isTaskCancelled(cancelFlag))
                return {};
            if (entry.isDir())
                ++subDirs;
            else {
                ++files;
                directBytes += entry.size();
            }
            if (sampleNames.size() < 25)
                sampleNames.append((entry.isDir() ? "📁 " : "🗎 ") + entry.fileName());
        }
        map["isText"] = true;
        map["text"] = QObject::tr("Directory: %1\nPath: %2\nModified: %3\n\nContents: %4 folder(s), %5 file(s)\nDirect files size: %6\n\nItems:\n%7")
                          .arg(fi.fileName(),
                               fi.absoluteFilePath(),
                               map["modified"].toString())
                          .arg(subDirs)
                          .arg(files)
                          .arg(PanelModel::formatSize(directBytes, false),
                               sampleNames.isEmpty() ? QObject::tr("(empty directory)") : sampleNames.join("\n"));
        return map;
    }

    const QString ext = fi.suffix().toLower();
    bool isImage = isImageExtension(ext);
    map["isImage"] = isImage;

    if (isImage) {
        map["imagePath"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
        QImageReader reader(fi.absoluteFilePath());
        const QSize sz = reader.size();
        if (sz.isValid()) {
            map["imageDimensions"] = QString("%1 × %2 px").arg(sz.width()).arg(sz.height());
        }
        const QString fmt = QString::fromLatin1(reader.format()).toUpper();
        map["imageFormat"] = fmt.isEmpty() ? ext.toUpper() : fmt;
        const QVariantMap exif = parseExifMetadata(fi.absoluteFilePath());
        if (!exif.isEmpty()) {
            map["hasExif"] = true;
            map["exif"] = exif;
            QStringList summaryParts;
            const QString cam = (exif.value("cameraMake").toString() + " " + exif.value("cameraModel").toString()).trimmed();
            if (!cam.isEmpty()) summaryParts.append(cam);
            if (!exif.value("aperture").toString().isEmpty()) summaryParts.append(exif.value("aperture").toString());
            if (!exif.value("exposure").toString().isEmpty()) summaryParts.append(exif.value("exposure").toString());
            if (exif.value("iso").toInt() > 0) summaryParts.append(QStringLiteral("ISO %1").arg(exif.value("iso").toInt()));
            if (!exif.value("focalLength").toString().isEmpty()) summaryParts.append(exif.value("focalLength").toString());
            if (!exif.value("gpsCoordinates").toString().isEmpty()) summaryParts.append(QStringLiteral("GPS ") + exif.value("gpsCoordinates").toString());
            map["exifSummary"] = summaryParts.join(QStringLiteral(" • "));
        } else {
            map["hasExif"] = false;
        }
        return map;
    }

    if (ext == QLatin1String("pdf")) {
        populatePdfPreview(fi, pdfPage, tempDirPath, map, cancelFlag);
        return map;
    }

    if (isFontExtension(ext)) {
        map["isFont"] = true;
        map["fontUrl"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
        map["fontFormat"] = ext.toUpper();
        map["fontPangram"] = QStringLiteral("The quick brown fox jumps over the lazy dog — 0123456789");
        map["isText"] = true;
        return map;
    }

    const bool audioFile = isAudioExtension(ext);
    const bool videoFile = isVideoExtension(ext);
    if (audioFile || videoFile) {
        const QVariantMap info = parseMediaMetadata(fi, audioFile, videoFile, cancelFlag);
        if (isTaskCancelled(cancelFlag))
            return {};
        map["isMedia"] = true;
        map["isAudio"] = audioFile;
        map["isVideo"] = videoFile;
        map["mediaUrl"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
        map["mediaInfo"] = info;
        map["mediaDuration"] = info.value("durationFormatted").toString();
        map["mediaDurationMs"] = info.value("durationMs").toLongLong();
        map["mediaCodec"] = info.value("codec").toString();
        map["mediaBitrate"] = info.value("bitrate").toString();
        map["mediaSampleRate"] = info.value("sampleRate").toString();
        map["mediaChannels"] = info.value("channels").toInt();
        map["mediaResolution"] = info.value("resolution").toString();
        QStringList lines;
        lines << QObject::tr("Media: %1 (%2)").arg(fi.fileName(), audioFile ? QObject::tr("Audio") : QObject::tr("Video"));
        lines << QObject::tr("Codec: %1").arg(info.value("codec").toString());
        if (!info.value("durationFormatted").toString().isEmpty())
            lines << QObject::tr("Duration: %1").arg(info.value("durationFormatted").toString());
        if (!info.value("resolution").toString().isEmpty())
            lines << QObject::tr("Resolution: %1").arg(info.value("resolution").toString());
        if (!info.value("bitrate").toString().isEmpty())
            lines << QObject::tr("Bitrate: %1").arg(info.value("bitrate").toString());
        if (!info.value("sampleRate").toString().isEmpty())
            lines << QObject::tr("Sample Rate: %1").arg(info.value("sampleRate").toString());
        if (info.value("channels").toInt() > 0)
            lines << QObject::tr("Channels: %1").arg(info.value("channels").toInt());
        map["isText"] = true;
        map["text"] = lines.join('\n');
        return map;
    }

    if (PanelModel::isArchiveFileName(path)) {
        QProcess proc;
        const QString bsdtar = QStandardPaths::findExecutable("bsdtar");
        if (!bsdtar.isEmpty()) {
            proc.start(bsdtar, {"-tvf", fi.absoluteFilePath()});
        } else if (ext == "zip") {
            proc.start("unzip", {"-l", fi.absoluteFilePath()});
        } else {
            proc.start("tar", {"-tvf", fi.absoluteFilePath()});
        }
        if (waitProcessCancelable(proc, 3000, cancelFlag) && proc.exitCode() == 0) {
            map["isText"] = true;
            map["text"] = QObject::tr("Archive: %1 (%2)\n\n").arg(fi.fileName(), map["formattedSize"].toString()) +
                          QString::fromUtf8(proc.readAllStandardOutput());
            return map;
        }
        if (isTaskCancelled(cancelFlag))
            return {};
    }

    QFile file(path);
    if (file.open(QIODevice::ReadOnly)) {
        QByteArray chunk = file.read(128 * 1024);
        const bool isBinary = chunk.contains('\0');
        map["isBinary"] = isBinary;
        if (!isBinary) {
            const QString text = QString::fromUtf8(chunk);
            map["isText"] = true;
            map["text"] = text;
            map["truncated"] = (file.size() > chunk.size());
            const QString lang = syntaxLanguageForFile(fi.fileName(), ext);
            if (ext == QLatin1String("md") || ext == QLatin1String("markdown") || ext == QLatin1String("mdx")) {
                map["isMarkdown"] = true;
                map["isCode"] = true;
                map["syntaxLanguage"] = QStringLiteral("Markdown");
                map["renderedHtml"] = renderMarkdownToHtml(text, dark);
                map["highlightedHtml"] = highlightCodeToHtml(text, ext, dark);
            } else if (!lang.isEmpty()) {
                map["isCode"] = true;
                map["syntaxLanguage"] = lang;
                map["highlightedHtml"] = highlightCodeToHtml(text, ext, dark);
            }
        } else {
            map["isText"] = true;
            map["text"] = formatHexDumpText(chunk, map["formattedSize"].toString(), fi.size());
        }
    }

    return map;
}

void Backend::finalizeFontPreviewOnMainThread(QVariantMap &map) const
{
    if (!map.value(QStringLiteral("isFont")).toBool())
        return;

    const QString absPath = map.value(QStringLiteral("path")).toString();
    const QFileInfo fi(absPath);
    const QString ext = fi.suffix().toLower();
    static QHash<QString, int> s_loadedFonts;
    int fontId = s_loadedFonts.value(absPath, -2);
    if (fontId == -2) {
        fontId = QFontDatabase::addApplicationFont(absPath);
        s_loadedFonts.insert(absPath, fontId);
    }
    QString family = fi.completeBaseName();
    QStringList styles;
    if (fontId >= 0) {
        const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) {
            family = families.first();
            styles = QFontDatabase::styles(family);
        }
    }
    map[QStringLiteral("fontFamily")] = family;
    map[QStringLiteral("fontStyles")] = styles.join(QStringLiteral(", "));
    map[QStringLiteral("text")] = tr("Font: %1 (%2)\nFamily: %3\nStyles: %4\n\n%5")
                                      .arg(fi.fileName(), ext.toUpper(), family,
                                           styles.isEmpty() ? tr("Regular") : styles.join(QStringLiteral(", ")),
                                           map.value(QStringLiteral("fontPangram")).toString());
}

QVariantMap Backend::getPreview(const QString &path, int pdfPage)
{
    QVariantMap map = buildPreviewData(path, pdfPage, isDarkTheme(), ensureArchiveTempDir(), nullptr);
    finalizeFontPreviewOnMainThread(map);
    return map;
}

void Backend::cancelPreview(const QString &target)
{
    const bool cancelModal = target.isEmpty() || target == QLatin1String("modal");
    const bool cancelQuick = target.isEmpty() || target == QLatin1String("quickview");
    bool changed = false;

    if (cancelModal) {
        m_modalPreviewGen.fetch_add(1, std::memory_order_relaxed);
        if (m_modalPreviewCancel) {
            m_modalPreviewCancel->store(true, std::memory_order_relaxed);
            m_modalPreviewCancel.reset();
        }
        if (m_previewLoading) {
            m_previewLoading = false;
            changed = true;
        }
    }
    if (cancelQuick) {
        m_quickViewPreviewGen.fetch_add(1, std::memory_order_relaxed);
        if (m_quickViewPreviewCancel) {
            m_quickViewPreviewCancel->store(true, std::memory_order_relaxed);
            m_quickViewPreviewCancel.reset();
        }
        if (m_quickViewLoading) {
            m_quickViewLoading = false;
            changed = true;
        }
    }
    if (changed)
        emit previewLoadingChanged();
}

void Backend::requestPreview(const QString &path, int pdfPage, const QString &target)
{
    const QString normTarget = (target == QLatin1String("quickview"))
                                   ? QStringLiteral("quickview")
                                   : QStringLiteral("modal");
    cancelPreview(normTarget);

    if (path.isEmpty()) {
        emit previewReady(normTarget, {});
        return;
    }

    const bool isQuick = (normTarget == QLatin1String("quickview"));
    const quint64 gen = isQuick
                            ? (m_quickViewPreviewGen.fetch_add(1, std::memory_order_relaxed) + 1)
                            : (m_modalPreviewGen.fetch_add(1, std::memory_order_relaxed) + 1);
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    if (isQuick) {
        m_quickViewPreviewCancel = cancelFlag;
        m_quickViewLoading = true;
    } else {
        m_modalPreviewCancel = cancelFlag;
        m_previewLoading = true;
    }
    emit previewLoadingChanged();

    const bool dark = isDarkTheme();
    const QString tempDirPath = ensureArchiveTempDir();
    QPointer<Backend> self(this);

    auto *task = QRunnable::create([self, gen, normTarget, isQuick, path, pdfPage, dark, tempDirPath, cancelFlag]() {
        QVariantMap map = Backend::buildPreviewData(path, pdfPage, dark, tempDirPath, cancelFlag.get());
        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, normTarget, isQuick, map]() mutable {
                if (!self)
                    return;
                const quint64 curGen = isQuick
                                           ? self->m_quickViewPreviewGen.load(std::memory_order_relaxed)
                                           : self->m_modalPreviewGen.load(std::memory_order_relaxed);
                if (curGen != gen)
                    return;

                self->finalizeFontPreviewOnMainThread(map);
                if (isQuick) {
                    self->m_quickViewLoading = false;
                    self->m_quickViewPreviewCancel.reset();
                } else {
                    self->m_previewLoading = false;
                    self->m_modalPreviewCancel.reset();
                }
                emit self->previewLoadingChanged();
                emit self->previewReady(normTarget, map);
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

QStringList Backend::searchFiles(const QString &rootPath, const QString &query, int maxResults)
{
    QStringList results;
    if (rootPath.isEmpty() || query.trimmed().isEmpty())
        return results;

    const QString needle = query.trimmed().toLower();
    QDirIterator it(rootPath, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden,
                    QDirIterator::Subdirectories);

    while (it.hasNext() && results.size() < maxResults) {
        it.next();
        if (it.fileName().toLower().contains(needle)) {
            results.append(it.filePath());
        }
    }

    return results;
}

QVariantList Backend::runAdvancedSearchSync(const QString &rootPath, const QVariantMap &options)
{
    const SearchSpec spec = parseSearchOptions(options);
    return runSearchImpl(rootPath, spec, nullptr, [](int, const QVariantList &) {});
}

void Backend::cancelSearch()
{
    if (!m_searchThread && !m_searchRunning)
        return;

    m_searchCancelRequested.store(true, std::memory_order_relaxed);
    ++m_searchGeneration;

    if (m_searchThread) {
        m_searchThread->wait();
        delete m_searchThread;
        m_searchThread = nullptr;
    }

    if (m_searchRunning) {
        m_searchRunning = false;
        emit searchStateChanged();
        showStatus(tr("Search cancelled."));
    }
}

void Backend::startAdvancedSearch(const QString &rootPath, const QVariantMap &options)
{
    cancelSearch();

    const QFileInfo rootFi(rootPath);
    if (!rootFi.exists() || !rootFi.isDir()) {
        showStatus(tr("Search folder does not exist: %1").arg(rootPath));
        return;
    }

    const QString cleanRoot = rootFi.absoluteFilePath();
    const SearchSpec spec = parseSearchOptions(options);

    m_searchCancelRequested.store(false, std::memory_order_relaxed);
    const quint64 gen = ++m_searchGeneration;
    m_searchRunning = true;
    m_searchScannedCount = 0;
    m_searchResultItems.clear();
    emit searchResultsChanged();
    emit searchProgressChanged();
    emit searchStateChanged();

    QThread *worker = QThread::create([this, gen, cleanRoot, spec]() {
        int totalScanned = 0;
        runSearchImpl(cleanRoot, spec, &m_searchCancelRequested,
                      [this, gen](int scanned, const QVariantList &batch) {
                          QMetaObject::invokeMethod(this, [this, gen, scanned, batch]() {
                              if (gen != m_searchGeneration)
                                  return;
                              m_searchScannedCount = scanned;
                              emit searchProgressChanged();
                              if (!batch.isEmpty()) {
                                  m_searchResultItems.append(batch);
                                  emit searchResultsChanged();
                              }
                          }, Qt::QueuedConnection);
                      },
                      &totalScanned);

        const bool cancelled = m_searchCancelRequested.load(std::memory_order_relaxed);
        QMetaObject::invokeMethod(this, [this, gen, totalScanned, cancelled]() {
            if (gen != m_searchGeneration)
                return;
            m_searchScannedCount = totalScanned;
            m_searchRunning = false;
            if (m_searchThread) {
                m_searchThread->wait();
                delete m_searchThread;
                m_searchThread = nullptr;
            }
            emit searchProgressChanged();
            emit searchStateChanged();
            showStatus(cancelled
                           ? tr("Search stopped (%1 results found).").arg(m_searchResultItems.size())
                           : tr("Search finished: %1 result(s) across %2 item(s).")
                                 .arg(m_searchResultItems.size())
                                 .arg(totalScanned));
        }, Qt::QueuedConnection);
    });

    m_searchThread = worker;
    worker->start();
}

void Backend::feedPathsToPanel(const QStringList &paths, const QString &title, bool newTab)
{
    PanelModel *panel = activeModel();
    const QString basePath = panel->isArchiveView() ? QFileInfo(panel->archiveFilePath()).absolutePath() : panel->path();
    const QString cleanTitle = title.trimmed().isEmpty() ? tr("Search Results") : title.trimmed();
    if (newTab)
        panel->addTab(basePath);
    panel->feedItems(paths, cleanTitle, basePath);
    showStatus(tr("Fed %1 item(s) to panel \"%2\".").arg(paths.size()).arg(cleanTitle));
}

namespace {

QHash<QString, QFileInfo> collectFilesRecursiveCancelable(const QString &rootPath, bool includeHidden,
                                                          const std::atomic<bool> *cancelFlag,
                                                          const std::function<void(int, const QString &)> &onScanned = {})
{
    QHash<QString, QFileInfo> files;
    const QDir rootDir(rootPath);
    if (!rootDir.exists())
        return files;

    QDir::Filters filters = QDir::Files | QDir::NoDotAndDotDot | QDir::System;
    if (includeHidden)
        filters |= QDir::Hidden;

    QDirIterator it(rootPath, filters, QDirIterator::Subdirectories);
    int count = 0;
    while (it.hasNext()) {
        if (isTaskCancelled(cancelFlag))
            return {};
        it.next();
        const QFileInfo fi = it.fileInfo();
        if (fi.isSymLink())
            continue;
        const QString rel = rootDir.relativeFilePath(fi.absoluteFilePath());
        if (rel.isEmpty())
            continue;
        if (!includeHidden) {
            const QStringList parts = rel.split(QLatin1Char('/'), Qt::SkipEmptyParts);
            bool hasHiddenDir = false;
            for (const QString &part : parts) {
                if (part.startsWith(QLatin1Char('.'))) {
                    hasHiddenDir = true;
                    break;
                }
            }
            if (hasHiddenDir)
                continue;
        }
        files.insert(rel, fi);
        if (onScanned && (++count % 250 == 0))
            onScanned(count, fi.fileName());
    }
    if (onScanned)
        onScanned(count, QString());
    return files;
}

QVariantList compareDirectoriesImpl(const QString &leftRoot, const QString &rightRoot,
                                    const QString &compareMode, bool includeHidden,
                                    const std::atomic<bool> *cancelFlag = nullptr,
                                    const std::function<void(double, const QString &)> &onProgress = {})
{
    QVariantList out;
    if (leftRoot.isEmpty() || rightRoot.isEmpty() || isTaskCancelled(cancelFlag))
        return out;

    const QDir leftDir(leftRoot);
    const QDir rightDir(rightRoot);
    if (!leftDir.exists() || !rightDir.exists())
        return out;

    if (onProgress)
        onProgress(0.05, QObject::tr("Scanning left folder…"));
    const QHash<QString, QFileInfo> leftMap = collectFilesRecursiveCancelable(leftRoot, includeHidden, cancelFlag);
    if (isTaskCancelled(cancelFlag))
        return {};

    if (onProgress)
        onProgress(0.25, QObject::tr("Scanning right folder…"));
    const QHash<QString, QFileInfo> rightMap = collectFilesRecursiveCancelable(rightRoot, includeHidden, cancelFlag);
    if (isTaskCancelled(cancelFlag))
        return {};

    QSet<QString> keySet;
    for (auto it = leftMap.constBegin(); it != leftMap.constEnd(); ++it)
        keySet.insert(it.key());
    for (auto it = rightMap.constBegin(); it != rightMap.constEnd(); ++it)
        keySet.insert(it.key());

    QStringList sortedKeys = keySet.values();
    std::sort(sortedKeys.begin(), sortedKeys.end(), [](const QString &a, const QString &b) {
        return QString::localeAwareCompare(a.toLower(), b.toLower()) < 0;
    });

    const QString mode = compareMode.trimmed().toLower();
    out.reserve(sortedKeys.size());
    const int totalKeys = std::max(1, static_cast<int>(sortedKeys.size()));
    int idx = 0;

    for (const QString &rel : std::as_const(sortedKeys)) {
        if (isTaskCancelled(cancelFlag))
            return {};
        ++idx;
        if (onProgress && (idx == 1 || idx % 40 == 0 || idx == totalKeys || mode == QLatin1String("sha256"))) {
            const double p = 0.3 + 0.7 * (static_cast<double>(idx) / static_cast<double>(totalKeys));
            onProgress(p, rel);
        }

        const bool inL = leftMap.contains(rel);
        const bool inR = rightMap.contains(rel);
        const QFileInfo lFi = leftMap.value(rel);
        const QFileInfo rFi = rightMap.value(rel);

        QString status;
        QString action;

        if (inL && !inR) {
            status = QStringLiteral("left_only");
            action = QStringLiteral("copy_to_right");
        } else if (!inL && inR) {
            status = QStringLiteral("right_only");
            action = QStringLiteral("copy_to_left");
        } else {
            const qint64 lSz = lFi.size();
            const qint64 rSz = rFi.size();
            const QDateTime lTm = lFi.lastModified();
            const QDateTime rTm = rFi.lastModified();
            const qint64 deltaSecs = lTm.secsTo(rTm);

            if (mode == QLatin1String("size")) {
                if (lSz == rSz) {
                    status = QStringLiteral("equal");
                    action = QStringLiteral("skip");
                } else {
                    status = QStringLiteral("different");
                    action = (deltaSecs < -2) ? QStringLiteral("copy_to_right")
                                              : ((deltaSecs > 2) ? QStringLiteral("copy_to_left") : QStringLiteral("skip"));
                }
            } else if (mode == QLatin1String("sha256")) {
                bool contentSame = (lSz == rSz);
                if (contentSame)
                    contentSame = (computeFileSha256Hex(lFi.absoluteFilePath()) == computeFileSha256Hex(rFi.absoluteFilePath()));

                if (contentSame) {
                    status = QStringLiteral("equal");
                    action = QStringLiteral("skip");
                } else if (deltaSecs < -2) {
                    status = QStringLiteral("left_newer");
                    action = QStringLiteral("copy_to_right");
                } else if (deltaSecs > 2) {
                    status = QStringLiteral("right_newer");
                    action = QStringLiteral("copy_to_left");
                } else {
                    status = QStringLiteral("different");
                    action = QStringLiteral("skip");
                }
            } else {
                if (lSz == rSz && qAbs(deltaSecs) <= 2) {
                    status = QStringLiteral("equal");
                    action = QStringLiteral("skip");
                } else if (deltaSecs < -2) {
                    status = QStringLiteral("left_newer");
                    action = QStringLiteral("copy_to_right");
                } else if (deltaSecs > 2) {
                    status = QStringLiteral("right_newer");
                    action = QStringLiteral("copy_to_left");
                } else {
                    status = QStringLiteral("different");
                    action = QStringLiteral("skip");
                }
            }
        }

        QVariantMap row;
        row[QStringLiteral("relPath")] = rel;
        row[QStringLiteral("leftPath")] = inL ? lFi.absoluteFilePath() : leftDir.filePath(rel);
        row[QStringLiteral("rightPath")] = inR ? rFi.absoluteFilePath() : rightDir.filePath(rel);
        row[QStringLiteral("leftExists")] = inL;
        row[QStringLiteral("rightExists")] = inR;
        row[QStringLiteral("leftSize")] = inL ? lFi.size() : qint64(-1);
        row[QStringLiteral("rightSize")] = inR ? rFi.size() : qint64(-1);
        row[QStringLiteral("leftFormattedSize")] = inL ? PanelModel::formatSize(lFi.size(), false) : QString();
        row[QStringLiteral("rightFormattedSize")] = inR ? PanelModel::formatSize(rFi.size(), false) : QString();
        row[QStringLiteral("leftModified")] = inL ? lFi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm")) : QString();
        row[QStringLiteral("rightModified")] = inR ? rFi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm")) : QString();
        row[QStringLiteral("status")] = status;
        row[QStringLiteral("action")] = action;
        out.append(row);
    }

    return out;
}

QVariantMap executeDirectorySyncImpl(const QString &leftRoot, const QString &rightRoot,
                                     const QVariantList &syncItems,
                                     const std::atomic<bool> *cancelFlag = nullptr,
                                     const std::function<void(double, const QString &)> &onProgress = {})
{
    int copiedToRight = 0;
    int copiedToLeft = 0;
    int failed = 0;

    const QDir leftDir(leftRoot);
    const QDir rightDir(rightRoot);

    int totalWork = 0;
    for (const QVariant &v : syncItems) {
        const QString action = v.toMap().value(QStringLiteral("action")).toString();
        if (action == QLatin1String("copy_to_right") || action == QLatin1String("copy_to_left"))
            ++totalWork;
    }
    int doneWork = 0;

    for (const QVariant &v : syncItems) {
        if (isTaskCancelled(cancelFlag))
            break;

        const QVariantMap item = v.toMap();
        const QString action = item.value(QStringLiteral("action")).toString();
        if (action != QLatin1String("copy_to_right") && action != QLatin1String("copy_to_left"))
            continue;

        const QString relPath = item.value(QStringLiteral("relPath")).toString();
        ++doneWork;
        if (onProgress && totalWork > 0) {
            onProgress(static_cast<double>(doneWork - 1) / static_cast<double>(totalWork), relPath);
        }

        if (relPath.isEmpty() || QDir::isAbsolutePath(relPath) || relPath.contains(QLatin1String(".."))) {
            ++failed;
            continue;
        }

        const bool toRight = (action == QLatin1String("copy_to_right"));
        const QString srcPath = toRight ? leftDir.filePath(relPath) : rightDir.filePath(relPath);
        const QString dstPath = toRight ? rightDir.filePath(relPath) : leftDir.filePath(relPath);

        const QFileInfo srcFi(srcPath);
        if (!srcFi.exists() || !srcFi.isFile()) {
            ++failed;
            continue;
        }

        if (!QDir().mkpath(QFileInfo(dstPath).absolutePath())) {
            ++failed;
            continue;
        }

        const QString tmpDst = dstPath + QStringLiteral(".twinforge_sync_tmp");
        QFile::remove(tmpDst);
        if (!QFile::copy(srcPath, tmpDst)) {
            QFile::remove(tmpDst);
            ++failed;
            continue;
        }

        if (QFileInfo::exists(dstPath) && !QFile::remove(dstPath)) {
            QFile::remove(tmpDst);
            ++failed;
            continue;
        }

        if (!QFile::rename(tmpDst, dstPath)) {
            QFile::remove(tmpDst);
            ++failed;
            continue;
        }

        const QDateTime srcMtime = srcFi.lastModified();
        if (srcMtime.isValid()) {
            QFile dstFile(dstPath);
            if (dstFile.open(QIODevice::ReadWrite)) {
                dstFile.setFileTime(srcMtime, QFileDevice::FileModificationTime);
                dstFile.close();
            }
        }

        if (toRight)
            ++copiedToRight;
        else
            ++copiedToLeft;
    }

    QVariantMap summary;
    summary[QStringLiteral("copiedToRight")] = copiedToRight;
    summary[QStringLiteral("copiedToLeft")] = copiedToLeft;
    summary[QStringLiteral("failed")] = failed;
    summary[QStringLiteral("totalApplied")] = copiedToRight + copiedToLeft;
    summary[QStringLiteral("cancelled")] = isTaskCancelled(cancelFlag);
    return summary;
}

QVariantList findDuplicateFilesImpl(const QString &rootPath, const QString &secondaryRootPath,
                                    qint64 minSizeBytes, bool includeHidden,
                                    const std::atomic<bool> *cancelFlag = nullptr,
                                    const std::function<void(int, const QString &)> &onProgress = {})
{
    QVariantList result;
    const qint64 minSz = std::max<qint64>(1, minSizeBytes);

    QStringList scanRoots;
    if (!rootPath.isEmpty() && QFileInfo(rootPath).isDir())
        scanRoots.append(rootPath);
    if (!secondaryRootPath.isEmpty() && QFileInfo(secondaryRootPath).isDir())
        scanRoots.append(secondaryRootPath);
    if (scanRoots.isEmpty())
        return result;

    QHash<qint64, QList<QFileInfo>> bySize;
    QSet<QString> visitedCanonical;
    int scannedTotal = 0;

    for (const QString &root : std::as_const(scanRoots)) {
        if (isTaskCancelled(cancelFlag))
            return {};
        const QHash<QString, QFileInfo> files = collectFilesRecursiveCancelable(
            root, includeHidden, cancelFlag,
            [&](int c, const QString &name) {
                if (onProgress)
                    onProgress(scannedTotal + c, name.isEmpty() ? QObject::tr("Scanning files…") : name);
            });
        if (isTaskCancelled(cancelFlag))
            return {};
        scannedTotal += files.size();
        for (auto it = files.constBegin(); it != files.constEnd(); ++it) {
            const QFileInfo &fi = it.value();
            if (fi.size() < minSz)
                continue;
            QString canon = fi.canonicalFilePath();
            if (canon.isEmpty())
                canon = fi.absoluteFilePath();
            if (visitedCanonical.contains(canon))
                continue;
            visitedCanonical.insert(canon);
            bySize[fi.size()].append(fi);
        }
    }

    if (onProgress)
        onProgress(scannedTotal, QObject::tr("Hashing duplicate candidates…"));

    struct DupGroup {
        qint64 size = 0;
        QString hash;
        QList<QFileInfo> files;
    };
    QList<DupGroup> groups;
    int hashedCount = 0;

    for (auto sizeIt = bySize.constBegin(); sizeIt != bySize.constEnd(); ++sizeIt) {
        if (isTaskCancelled(cancelFlag))
            return {};
        const qint64 sz = sizeIt.key();
        const QList<QFileInfo> &candidates = sizeIt.value();
        if (candidates.size() < 2)
            continue;

        QList<QFileInfo> filtered = candidates;
        if (sz > 128 * 1024) {
            QHash<QString, QList<QFileInfo>> preBuckets;
            for (const QFileInfo &fi : candidates) {
                if (isTaskCancelled(cancelFlag))
                    return {};
                const QString pre = computeFileSha256Hex(fi.absoluteFilePath(), true);
                if (!pre.isEmpty())
                    preBuckets[pre].append(fi);
            }
            filtered.clear();
            for (auto pbIt = preBuckets.constBegin(); pbIt != preBuckets.constEnd(); ++pbIt) {
                if (pbIt.value().size() >= 2)
                    filtered.append(pbIt.value());
            }
        }

        if (filtered.size() < 2)
            continue;

        QHash<QString, QList<QFileInfo>> fullBuckets;
        for (const QFileInfo &fi : filtered) {
            if (isTaskCancelled(cancelFlag))
                return {};
            if (onProgress && (++hashedCount % 8 == 1))
                onProgress(scannedTotal, QObject::tr("SHA-256: %1").arg(fi.fileName()));
            const QString sha = computeFileSha256Hex(fi.absoluteFilePath(), false);
            if (!sha.isEmpty())
                fullBuckets[sha].append(fi);
        }

        for (auto fbIt = fullBuckets.constBegin(); fbIt != fullBuckets.constEnd(); ++fbIt) {
            if (fbIt.value().size() < 2)
                continue;
            QList<QFileInfo> sortedFiles = fbIt.value();
            std::sort(sortedFiles.begin(), sortedFiles.end(), [](const QFileInfo &a, const QFileInfo &b) {
                if (a.lastModified() != b.lastModified())
                    return a.lastModified() > b.lastModified();
                return a.absoluteFilePath() < b.absoluteFilePath();
            });
            groups.append(DupGroup{sz, fbIt.key(), sortedFiles});
        }
    }

    std::sort(groups.begin(), groups.end(), [](const DupGroup &a, const DupGroup &b) {
        const qint64 wasteA = a.size * (a.files.size() - 1);
        const qint64 wasteB = b.size * (b.files.size() - 1);
        if (wasteA != wasteB)
            return wasteA > wasteB;
        if (a.size != b.size)
            return a.size > b.size;
        return a.hash < b.hash;
    });

    for (int g = 0; g < groups.size(); ++g) {
        const DupGroup &grp = groups.at(g);
        const int count = grp.files.size();
        for (int i = 0; i < count; ++i) {
            const QFileInfo &fi = grp.files.at(i);
            const bool isFirst = (i == 0);
            QVariantMap row;
            row[QStringLiteral("groupIndex")] = g;
            row[QStringLiteral("hash")] = grp.hash;
            row[QStringLiteral("path")] = fi.absoluteFilePath();
            row[QStringLiteral("name")] = fi.fileName();
            row[QStringLiteral("dirPath")] = fi.absolutePath();
            row[QStringLiteral("size")] = grp.size;
            row[QStringLiteral("formattedSize")] = PanelModel::formatSize(grp.size, false);
            row[QStringLiteral("modified")] = fi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm"));
            row[QStringLiteral("modifiedSecs")] = fi.lastModified().toSecsSinceEpoch();
            row[QStringLiteral("isFirstInGroup")] = isFirst;
            row[QStringLiteral("groupCount")] = count;
            row[QStringLiteral("wastedBytes")] = isFirst ? qint64(0) : grp.size;
            row[QStringLiteral("selected")] = !isFirst;
            result.append(row);
        }
    }

    return result;
}

} // namespace

QVariantList Backend::compareDirectoriesRecursive(const QString &leftRoot, const QString &rightRoot,
                                                  const QString &compareMode, bool includeHidden)
{
    return compareDirectoriesImpl(leftRoot, rightRoot, compareMode, includeHidden);
}

QVariantMap Backend::executeDirectorySync(const QString &leftRoot, const QString &rightRoot, const QVariantList &syncItems)
{
    const QVariantMap summary = executeDirectorySyncImpl(leftRoot, rightRoot, syncItems);
    m_leftPanel.refresh();
    m_rightPanel.refresh();

    showStatus(tr("Synchronized %1 file(s): %2 → right, %3 ← left (%4 failed).")
                   .arg(summary.value(QStringLiteral("totalApplied")).toInt())
                   .arg(summary.value(QStringLiteral("copiedToRight")).toInt())
                   .arg(summary.value(QStringLiteral("copiedToLeft")).toInt())
                   .arg(summary.value(QStringLiteral("failed")).toInt()));
    return summary;
}

void Backend::cancelSyncOperation()
{
    m_syncGeneration.fetch_add(1, std::memory_order_relaxed);
    if (m_syncCancel) {
        m_syncCancel->store(true, std::memory_order_relaxed);
        m_syncCancel.reset();
    }
    if (m_syncRunning) {
        m_syncRunning = false;
        m_syncDetail.clear();
        emit syncProgressChanged();
        emit syncStateChanged();
    }
}

void Backend::startDirectoryCompare(const QString &leftRoot, const QString &rightRoot,
                                    const QString &compareMode, bool includeHidden)
{
    cancelSyncOperation();
    m_syncCompareResults.clear();
    m_syncProgress = 0.0;
    m_syncDetail = tr("Comparing directories…");
    emit syncCompareResultsChanged();
    emit syncProgressChanged();

    const quint64 gen = m_syncGeneration.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_syncCancel = cancelFlag;
    m_syncRunning = true;
    emit syncStateChanged();

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, leftRoot, rightRoot, compareMode, includeHidden, cancelFlag]() {
        const QVariantList results = compareDirectoriesImpl(
            leftRoot, rightRoot, compareMode, includeHidden, cancelFlag.get(),
            [self, gen](double progress, const QString &detail) {
                QMetaObject::invokeMethod(
                    self,
                    [self, gen, progress, detail]() {
                        if (!self || self->m_syncGeneration.load(std::memory_order_relaxed) != gen)
                            return;
                        self->m_syncProgress = progress;
                        self->m_syncDetail = detail;
                        emit self->syncProgressChanged();
                    },
                    Qt::QueuedConnection);
            });

        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, results]() {
                if (!self || self->m_syncGeneration.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_syncRunning = false;
                self->m_syncProgress = 1.0;
                self->m_syncDetail.clear();
                self->m_syncCancel.reset();
                self->m_syncCompareResults = results;
                emit self->syncProgressChanged();
                emit self->syncCompareResultsChanged();
                emit self->syncStateChanged();
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

void Backend::startDirectorySync(const QString &leftRoot, const QString &rightRoot, const QVariantList &syncItems)
{
    cancelSyncOperation();
    m_syncProgress = 0.0;
    m_syncDetail = tr("Synchronizing files…");
    emit syncProgressChanged();

    const quint64 gen = m_syncGeneration.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_syncCancel = cancelFlag;
    m_syncRunning = true;
    emit syncStateChanged();

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, leftRoot, rightRoot, syncItems, cancelFlag]() {
        const QVariantMap summary = executeDirectorySyncImpl(
            leftRoot, rightRoot, syncItems, cancelFlag.get(),
            [self, gen](double progress, const QString &detail) {
                QMetaObject::invokeMethod(
                    self,
                    [self, gen, progress, detail]() {
                        if (!self || self->m_syncGeneration.load(std::memory_order_relaxed) != gen)
                            return;
                        self->m_syncProgress = progress;
                        self->m_syncDetail = detail;
                        emit self->syncProgressChanged();
                    },
                    Qt::QueuedConnection);
            });

        QMetaObject::invokeMethod(
            self,
            [self, gen, summary]() {
                if (!self || self->m_syncGeneration.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_syncRunning = false;
                self->m_syncProgress = 1.0;
                self->m_syncDetail.clear();
                self->m_syncCancel.reset();
                self->m_leftPanel.refresh();
                self->m_rightPanel.refresh();
                self->showStatus(tr("Synchronized %1 file(s): %2 → right, %3 ← left (%4 failed).")
                                     .arg(summary.value(QStringLiteral("totalApplied")).toInt())
                                     .arg(summary.value(QStringLiteral("copiedToRight")).toInt())
                                     .arg(summary.value(QStringLiteral("copiedToLeft")).toInt())
                                     .arg(summary.value(QStringLiteral("failed")).toInt()));
                emit self->syncProgressChanged();
                emit self->syncStateChanged();
                emit self->directorySyncFinished(summary);
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

QVariantList Backend::findDuplicateFiles(const QString &rootPath, const QString &secondaryRootPath,
                                         qint64 minSizeBytes, bool includeHidden)
{
    return findDuplicateFilesImpl(rootPath, secondaryRootPath, minSizeBytes, includeHidden);
}

void Backend::cancelDuplicateScan()
{
    m_dupGeneration.fetch_add(1, std::memory_order_relaxed);
    if (m_dupCancel) {
        m_dupCancel->store(true, std::memory_order_relaxed);
        m_dupCancel.reset();
    }
    if (m_duplicateScanRunning) {
        m_duplicateScanRunning = false;
        m_duplicateScanDetail.clear();
        emit duplicateScanProgressChanged();
        emit duplicateScanStateChanged();
    }
}

void Backend::startDuplicateScan(const QString &rootPath, const QString &secondaryRootPath,
                                 qint64 minSizeBytes, bool includeHidden)
{
    cancelDuplicateScan();
    m_duplicateResults.clear();
    m_duplicateScanScannedCount = 0;
    m_duplicateScanDetail = tr("Scanning files…");
    emit duplicateResultsChanged();
    emit duplicateScanProgressChanged();

    const quint64 gen = m_dupGeneration.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_dupCancel = cancelFlag;
    m_duplicateScanRunning = true;
    emit duplicateScanStateChanged();

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, rootPath, secondaryRootPath, minSizeBytes, includeHidden, cancelFlag]() {
        const QVariantList results = findDuplicateFilesImpl(
            rootPath, secondaryRootPath, minSizeBytes, includeHidden, cancelFlag.get(),
            [self, gen](int scanned, const QString &detail) {
                QMetaObject::invokeMethod(
                    self,
                    [self, gen, scanned, detail]() {
                        if (!self || self->m_dupGeneration.load(std::memory_order_relaxed) != gen)
                            return;
                        self->m_duplicateScanScannedCount = scanned;
                        self->m_duplicateScanDetail = detail;
                        emit self->duplicateScanProgressChanged();
                    },
                    Qt::QueuedConnection);
            });

        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, results]() {
                if (!self || self->m_dupGeneration.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_duplicateScanRunning = false;
                self->m_duplicateScanDetail.clear();
                self->m_dupCancel.reset();
                self->m_duplicateResults = results;
                emit self->duplicateScanProgressChanged();
                emit self->duplicateResultsChanged();
                emit self->duplicateScanStateChanged();
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

QString Backend::buildRemoteUri(const QVariantMap &connection) const
{
    const QString proto = normalizeRemoteProtocol(connection.value(QStringLiteral("protocol")).toString());
    const QString host = connection.value(QStringLiteral("host")).toString().trimmed();
    if (host.isEmpty())
        return connection.value(QStringLiteral("uri")).toString().trimmed();

    QString remotePath = connection.value(QStringLiteral("remotePath")).toString().trimmed();
    if (!remotePath.isEmpty() && !remotePath.startsWith(QLatin1Char('/')))
        remotePath.prepend(QLatin1Char('/'));

    if (isCloudRemoteProtocol(proto))
        return proto + QStringLiteral("://") + host + remotePath;

    const QString user = connection.value(QStringLiteral("user")).toString().trimmed();
    const QString domain = connection.value(QStringLiteral("domain")).toString().trimmed();
    const int port = connection.value(QStringLiteral("port")).toInt();

    QString authority;
    if (proto == QLatin1String("smb") && !domain.isEmpty() && !user.isEmpty())
        authority += domain + QLatin1Char(';') + user + QLatin1Char('@');
    else if (!user.isEmpty())
        authority += user + QLatin1Char('@');

    authority += host;
    if (port > 0 && ((proto == QLatin1String("smb") && port != 445)
                     || (proto != QLatin1String("smb") && port != 22))) {
        authority += QLatin1Char(':') + QString::number(port);
    }

    return proto + QStringLiteral("://") + authority + remotePath;
}

QVariantMap Backend::parseRemoteUri(const QString &uri) const
{
    QVariantMap out;
    QString raw = uri.trimmed();
    const int schemeIdx = raw.indexOf(QStringLiteral("://"));
    if (schemeIdx <= 0)
        return out;

    const QString proto = normalizeRemoteProtocol(raw.left(schemeIdx));
    const QString rest = raw.mid(schemeIdx + 3);

    int pathIdx = rest.indexOf(QLatin1Char('/'));
    if (proto == QLatin1String("sshfs")) {
        const int colonSlash = rest.indexOf(QStringLiteral(":/"));
        if (colonSlash >= 0 && (pathIdx < 0 || colonSlash < pathIdx)) {
            const QString authHost = rest.left(colonSlash);
            const QString rPath = rest.mid(colonSlash + 1);
            raw = proto + QStringLiteral("://") + authHost + rPath;
            pathIdx = rest.indexOf(QLatin1Char('/'));
        }
    }

    QString authHost;
    QString remotePath;
    if (proto == QLatin1String("sshfs")) {
        const int colonSlash = rest.indexOf(QStringLiteral(":/"));
        if (colonSlash >= 0) {
            authHost = rest.left(colonSlash);
            remotePath = rest.mid(colonSlash + 1);
        }
    }
    if (authHost.isEmpty()) {
        if (pathIdx >= 0) {
            authHost = rest.left(pathIdx);
            remotePath = rest.mid(pathIdx);
        } else {
            authHost = rest;
        }
    }

    if (isCloudRemoteProtocol(proto)) {
        QString remoteName = authHost.trimmed();
        if (remoteName.endsWith(QLatin1Char(':')))
            remoteName.chop(1);
        if (remoteName.isEmpty() && proto == QLatin1String("gdrive"))
            remoteName = QStringLiteral("gdrive");

        out[QStringLiteral("protocol")] = proto;
        out[QStringLiteral("host")] = remoteName;
        out[QStringLiteral("port")] = 0;
        out[QStringLiteral("user")] = QString();
        out[QStringLiteral("domain")] = QString();
        out[QStringLiteral("remotePath")] = remotePath;
        out[QStringLiteral("uri")] = buildRemoteUri(out);
        if (!remoteName.isEmpty()) {
            QString defaultName = (proto == QLatin1String("gdrive"))
                                      ? QStringLiteral("Google Drive (%1)").arg(remoteName)
                                      : QStringLiteral("rclone (%1)").arg(remoteName);
            if (!remotePath.isEmpty() && remotePath != QLatin1String("/"))
                defaultName += remotePath;
            out[QStringLiteral("name")] = defaultName;
        }
        return out;
    }

    QString userPart;
    QString hostPort = authHost;
    const int atIdx = authHost.lastIndexOf(QLatin1Char('@'));
    if (atIdx >= 0) {
        userPart = authHost.left(atIdx);
        hostPort = authHost.mid(atIdx + 1);
    }

    QString domain;
    QString user = userPart;
    if (proto == QLatin1String("smb")) {
        const int semi = userPart.indexOf(QLatin1Char(';'));
        if (semi >= 0) {
            domain = userPart.left(semi);
            user = userPart.mid(semi + 1);
        }
    }

    QString host = hostPort;
    int port = (proto == QLatin1String("smb")) ? 445 : 22;
    if (hostPort.startsWith(QLatin1Char('['))) {
        const int closeBracket = hostPort.indexOf(QLatin1Char(']'));
        if (closeBracket > 0) {
            host = hostPort.left(closeBracket + 1);
            if (closeBracket + 1 < hostPort.size() && hostPort.at(closeBracket + 1) == QLatin1Char(':')) {
                const int p = hostPort.mid(closeBracket + 2).toInt();
                if (p > 0) port = p;
            }
        }
    } else {
        const int colon = hostPort.lastIndexOf(QLatin1Char(':'));
        if (colon > 0) {
            bool ok = false;
            const int p = hostPort.mid(colon + 1).toInt(&ok);
            if (ok && p > 0) {
                host = hostPort.left(colon);
                port = p;
            }
        }
    }

    out[QStringLiteral("protocol")] = proto;
    out[QStringLiteral("host")] = host;
    out[QStringLiteral("port")] = port;
    out[QStringLiteral("user")] = user;
    out[QStringLiteral("domain")] = domain;
    out[QStringLiteral("remotePath")] = remotePath;
    out[QStringLiteral("uri")] = buildRemoteUri(out);
    if (!host.isEmpty()) {
        QString defaultName = user.isEmpty() ? host : (user + QLatin1Char('@') + host);
        if (proto == QLatin1String("smb") && !remotePath.isEmpty())
            defaultName += remotePath;
        out[QStringLiteral("name")] = defaultName;
    }
    return out;
}

QString Backend::resolveRemoteMountPath(const QVariantMap &connection) const
{
    const QString explicitMount = connection.value(QStringLiteral("localMountPath")).toString().trimmed();
    if (!explicitMount.isEmpty() && QDir(explicitMount).exists())
        return explicitMount;

    QVariantMap conn = connection;
    if (conn.value(QStringLiteral("host")).toString().isEmpty()
        && !conn.value(QStringLiteral("uri")).toString().isEmpty()) {
        const QVariantMap parsed = parseRemoteUri(conn.value(QStringLiteral("uri")).toString());
        for (auto it = parsed.constBegin(); it != parsed.constEnd(); ++it) {
            if (!conn.contains(it.key()) || conn.value(it.key()).toString().isEmpty())
                conn[it.key()] = it.value();
        }
    }

    const QString proto = normalizeRemoteProtocol(conn.value(QStringLiteral("protocol")).toString());
    const QString host = conn.value(QStringLiteral("host")).toString().trimmed();
    const QString user = conn.value(QStringLiteral("user")).toString().trimmed();
    const QString id = conn.value(QStringLiteral("id")).toString().trimmed();
    QString remotePath = conn.value(QStringLiteral("remotePath")).toString().trimmed();
    if (!remotePath.isEmpty() && !remotePath.startsWith(QLatin1Char('/')))
        remotePath.prepend(QLatin1Char('/'));

    if (isCloudRemoteProtocol(proto)) {
        if (host.isEmpty())
            return {};
        const QString expectedDir = rcloneMountDirFor(proto, host, id);
        const QString altDir = rcloneMountDirFor(proto, host, QString());

        QString baseMount = findMountedRcloneMountPoint(expectedDir, host);
        if (baseMount.isEmpty() && altDir != expectedDir)
            baseMount = findMountedRcloneMountPoint(altDir, host);

        if (baseMount.isEmpty() && (envIsSetWithFallback("TWINFORGE_MOUNTS_DIR", "OMAPANEL_MOUNTS_DIR")
                                    || envIsSetWithFallback("TWINFORGE_RCLONE_BIN", "OMAPANEL_RCLONE_BIN"))) {
            const QStringList candidates = (altDir != expectedDir)
                                               ? QStringList{expectedDir, altDir}
                                               : QStringList{expectedDir};
            for (const QString &cand : candidates) {
                const QDir d(cand);
                if (d.exists() && !d.entryList(QDir::AllEntries | QDir::NoDotAndDotDot).isEmpty()) {
                    baseMount = cand;
                    break;
                }
            }
        }

        if (baseMount.isEmpty())
            return {};

        if (!remotePath.isEmpty() && remotePath != QLatin1String("/")) {
            QString rel = remotePath;
            while (rel.startsWith(QLatin1Char('/')))
                rel.remove(0, 1);
            const QString sub = QDir(baseMount).filePath(rel);
            if (QDir(sub).exists())
                return QDir::cleanPath(sub);
        }
        return baseMount;
    }

    if (proto == QLatin1String("sshfs")) {
        const QString root = sshfsMountsRootDir();
        QStringList candidates;
        if (!id.isEmpty())
            candidates.append(QDir(root).filePath(id));
        if (!host.isEmpty())
            candidates.append(QDir(root).filePath(host));
        for (const QString &cand : candidates) {
            const QDir d(cand);
            if (d.exists() && !d.entryList(QDir::AllEntries | QDir::NoDotAndDotDot).isEmpty())
                return cand;
        }
    }

    if (host.isEmpty())
        return {};

    const QString gvfsRoot = gvfsRootDir();
    const QDir gdir(gvfsRoot);
    if (!gdir.exists())
        return {};

    auto parseGvfsAttrs = [](const QString &dirName) -> QMap<QString, QString> {
        QMap<QString, QString> attrs;
        const int colon = dirName.indexOf(QLatin1Char(':'));
        if (colon < 0)
            return attrs;
        attrs[QStringLiteral("_scheme")] = dirName.left(colon);
        for (const QString &part : dirName.mid(colon + 1).split(QLatin1Char(','), Qt::SkipEmptyParts)) {
            const int eq = part.indexOf(QLatin1Char('='));
            if (eq > 0)
                attrs[part.left(eq).toLower()] = part.mid(eq + 1);
        }
        return attrs;
    };

    const QFileInfoList entries = gdir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &fi : entries) {
        const QMap<QString, QString> attrs = parseGvfsAttrs(fi.fileName());
        const QString scheme = attrs.value(QStringLiteral("_scheme"));
        if (proto == QLatin1String("smb")) {
            if (!scheme.startsWith(QLatin1String("smb")))
                continue;
            const QString srv = attrs.value(QStringLiteral("server"));
            if (srv.compare(host, Qt::CaseInsensitive) != 0)
                continue;
            QString cleanRel = remotePath;
            while (cleanRel.startsWith(QLatin1Char('/')))
                cleanRel.remove(0, 1);
            const QString share = cleanRel.section(QLatin1Char('/'), 0, 0);
            const QString sub = cleanRel.section(QLatin1Char('/'), 1);
            const QString gShare = attrs.value(QStringLiteral("share"));
            if (!share.isEmpty() && !gShare.isEmpty() && gShare.compare(share, Qt::CaseInsensitive) != 0)
                continue;
            if (!sub.isEmpty()) {
                const QString fullSub = QDir(fi.absoluteFilePath()).filePath(sub);
                if (QDir(fullSub).exists())
                    return QDir::cleanPath(fullSub);
            }
            return fi.absoluteFilePath();
        } else {
            if (scheme != QLatin1String("sftp") && scheme != QLatin1String("ssh"))
                continue;
            const QString gHost = attrs.value(QStringLiteral("host"));
            if (gHost.compare(host, Qt::CaseInsensitive) != 0)
                continue;
            const QString gUser = attrs.value(QStringLiteral("user"));
            if (!user.isEmpty() && !gUser.isEmpty() && gUser != user)
                continue;
            if (!remotePath.isEmpty() && remotePath != QLatin1String("/")) {
                QString rel = remotePath;
                while (rel.startsWith(QLatin1Char('/')))
                    rel.remove(0, 1);
                const QString fullSub = QDir(fi.absoluteFilePath()).filePath(rel);
                if (QDir(fullSub).exists())
                    return QDir::cleanPath(fullSub);
            }
            return fi.absoluteFilePath();
        }
    }

    return {};
}

bool Backend::rcloneAvailable() const
{
    return !findRcloneExecutable().isEmpty()
           || envIsSetWithFallback("TWINFORGE_RCLONE_REMOTES", "OMAPANEL_RCLONE_REMOTES");
}

void Backend::refreshRcloneRemotes()
{
    QVariantList parsedList;
    const QString overrideRemotes = envWithFallback("TWINFORGE_RCLONE_REMOTES", "OMAPANEL_RCLONE_REMOTES");
    if (!overrideRemotes.isEmpty()) {
        for (const QString &entry : overrideRemotes.split(QLatin1Char(';'), Qt::SkipEmptyParts)) {
            const int sep = entry.indexOf(QLatin1Char(':'));
            const QString name = (sep >= 0 ? entry.left(sep) : entry).trimmed();
            const QString type = (sep >= 0 ? entry.mid(sep + 1) : QStringLiteral("drive")).trimmed().toLower();
            if (name.isEmpty())
                continue;
            const bool isGdrive = (type == QLatin1String("drive"));
            const QString proto = isGdrive ? QStringLiteral("gdrive") : QStringLiteral("rclone");
            QVariantMap conn;
            conn[QStringLiteral("protocol")] = proto;
            conn[QStringLiteral("host")] = name;
            const QString mountPath = resolveRemoteMountPath(conn);
            QVariantMap row;
            row[QStringLiteral("name")] = name;
            row[QStringLiteral("type")] = type;
            row[QStringLiteral("isGoogleDrive")] = isGdrive;
            row[QStringLiteral("protocol")] = proto;
            row[QStringLiteral("label")] = isGdrive
                                               ? QStringLiteral("Google Drive (%1)").arg(name)
                                               : QStringLiteral("%1 (%2)").arg(name, type);
            row[QStringLiteral("uri")] = proto + QStringLiteral("://") + name;
            row[QStringLiteral("mountPath")] = mountPath;
            row[QStringLiteral("isMounted")] = !mountPath.isEmpty();
            parsedList.append(row);
        }
    } else {
        const QString rcloneBin = findRcloneExecutable();
        if (!rcloneBin.isEmpty()) {
            QProcess proc;
            QStringList args = {QStringLiteral("listremotes"), QStringLiteral("--long")};
            args << rcloneConfigArgs();
            proc.start(rcloneBin, args);
            if (proc.waitForFinished(4000) && proc.exitCode() == 0) {
                const QString out = QString::fromUtf8(proc.readAllStandardOutput());
                for (const QString &rawLine : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
                    const QString line = rawLine.trimmed();
                    const int colon = line.indexOf(QLatin1Char(':'));
                    if (colon <= 0)
                        continue;
                    const QString name = line.left(colon).trimmed();
                    const QString type = line.mid(colon + 1).trimmed().section(QLatin1Char(' '), 0, 0).toLower();
                    const bool isGdrive = (type == QLatin1String("drive"));
                    const QString proto = isGdrive ? QStringLiteral("gdrive") : QStringLiteral("rclone");
                    QVariantMap conn;
                    conn[QStringLiteral("protocol")] = proto;
                    conn[QStringLiteral("host")] = name;
                    const QString mountPath = resolveRemoteMountPath(conn);
                    QVariantMap row;
                    row[QStringLiteral("name")] = name;
                    row[QStringLiteral("type")] = type;
                    row[QStringLiteral("isGoogleDrive")] = isGdrive;
                    row[QStringLiteral("protocol")] = proto;
                    row[QStringLiteral("label")] = isGdrive
                                                       ? QStringLiteral("Google Drive (%1)").arg(name)
                                                       : QStringLiteral("%1 (%2)").arg(name, type);
                    row[QStringLiteral("uri")] = proto + QStringLiteral("://") + name;
                    row[QStringLiteral("mountPath")] = mountPath;
                    row[QStringLiteral("isMounted")] = !mountPath.isEmpty();
                    parsedList.append(row);
                }
            }
        }
    }

    m_rcloneRemotes = parsedList;
    emit rcloneRemotesChanged();
}

void Backend::startGoogleDriveAuth(const QString &remoteName, const QString &clientId, const QString &clientSecret)
{
    if (m_gdriveAuthRunning) {
        showStatus(tr("Google Drive authorization is already running."));
        return;
    }

    const QString rcloneBin = findRcloneExecutable();
    if (rcloneBin.isEmpty()) {
        const QString msg = tr("rclone executable not found. Install rclone to connect Google Drive.");
        m_gdriveAuthStatus = msg;
        emit gdriveAuthChanged();
        emit gdriveAuthFinished(false, QString(), msg);
        showStatus(msg);
        return;
    }

    const QString cleanName = sanitizeMountSegment(remoteName.trimmed().isEmpty() ? QStringLiteral("gdrive") : remoteName);
    m_gdriveAuthName = cleanName;
    m_gdriveAuthClientId = clientId.trimmed();
    m_gdriveAuthClientSecret = clientSecret.trimmed();
    m_gdriveAuthStep = 0;
    m_gdriveAuthRunning = true;
    m_gdriveAuthUrl.clear();
    m_gdriveAuthStatus = tr("Opening browser for Google Drive authorization (%1)...").arg(cleanName);
    emit gdriveAuthChanged();

    auto launchAuthStep = std::make_shared<std::function<void(const QStringList &)>>();
    *launchAuthStep = [this, rcloneBin, cleanName, launchAuthStep](const QStringList &args) {
        auto *proc = new QProcess(this);
        m_gdriveAuthProc = proc;

        auto extractAuthUrl = [this, cleanName](const QString &chunk) {
            static const QRegularExpression urlRe(QStringLiteral("(https?://[^\\s\"'<>]+)"));
            QRegularExpressionMatchIterator it = urlRe.globalMatch(chunk);
            while (it.hasNext()) {
                const QString u = it.next().captured(1);
                if (u.contains(QStringLiteral("127.0.0.1")) || u.contains(QStringLiteral("accounts.google.com"))) {
                    if (m_gdriveAuthUrl != u) {
                        m_gdriveAuthUrl = u;
                        m_gdriveAuthStatus = tr("Complete Google sign-in in browser (%1)...").arg(cleanName);
                        emit gdriveAuthChanged();
                    }
                    break;
                }
            }
        };

        connect(proc, &QProcess::readyReadStandardError, this, [proc, extractAuthUrl] {
            const QString errText = QString::fromUtf8(proc->readAllStandardError());
            extractAuthUrl(errText);
        });

        connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
                [this, proc, cleanName, launchAuthStep](int exitCode, QProcess::ExitStatus exitStatus) {
            const QByteArray stdOut = proc->readAllStandardOutput().trimmed();
            const QString stdErr = QString::fromUtf8(proc->readAllStandardError()).trimmed();
            if (m_gdriveAuthProc == proc)
                m_gdriveAuthProc = nullptr;
            proc->deleteLater();

            if (!m_gdriveAuthRunning) {
                return;
            }

            if (exitStatus != QProcess::NormalExit || exitCode != 0) {
                m_gdriveAuthRunning = false;
                m_gdriveAuthUrl.clear();
                m_gdriveAuthStatus = stdErr.isEmpty() ? tr("Google Drive authorization failed.") : stdErr;
                emit gdriveAuthChanged();
                emit gdriveAuthFinished(false, cleanName, m_gdriveAuthStatus);
                showStatus(m_gdriveAuthStatus);
                return;
            }

            const QJsonDocument doc = QJsonDocument::fromJson(stdOut);
            if (doc.isObject()) {
                const QJsonObject obj = doc.object();
                const QString state = obj.value(QStringLiteral("State")).toString().trimmed();
                const QString errField = obj.value(QStringLiteral("Error")).toString().trimmed();
                if (!errField.isEmpty()) {
                    m_gdriveAuthRunning = false;
                    m_gdriveAuthUrl.clear();
                    m_gdriveAuthStatus = errField;
                    emit gdriveAuthChanged();
                    emit gdriveAuthFinished(false, cleanName, errField);
                    showStatus(errField);
                    return;
                }
                if (!state.isEmpty() && m_gdriveAuthStep < 4) {
                    ++m_gdriveAuthStep;
                    QString answer = obj.value(QStringLiteral("Option")).toObject().value(QStringLiteral("DefaultStr")).toString();
                    if (state == QLatin1String("client_id_warning"))
                        answer = QStringLiteral("true");
                    else if (state == QLatin1String("teamdrive_ok"))
                        answer = QStringLiteral("false");
                    else if (answer.isEmpty())
                        answer = QStringLiteral("false");

                    QStringList contArgs = {QStringLiteral("config"), QStringLiteral("update"), cleanName,
                                            QStringLiteral("--non-interactive"), QStringLiteral("--continue"),
                                            QStringLiteral("--state"), state, QStringLiteral("--result"), answer};
                    contArgs << rcloneConfigArgs();
                    (*launchAuthStep)(contArgs);
                    return;
                }
            }

            m_gdriveAuthRunning = false;
            m_gdriveAuthUrl.clear();
            m_gdriveAuthStatus = tr("Google Drive '%1' authorized.").arg(cleanName);

            QVariantMap conn;
            conn[QStringLiteral("protocol")] = QStringLiteral("gdrive");
            conn[QStringLiteral("host")] = cleanName;
            conn[QStringLiteral("name")] = QStringLiteral("Google Drive (%1)").arg(cleanName);
            conn[QStringLiteral("remotePath")] = QStringLiteral("/");
            conn[QStringLiteral("uri")] = QStringLiteral("gdrive://") + cleanName + QLatin1Char('/');
            saveRemoteConnection(conn);

            refreshRcloneRemotes();
            refreshDrives();
            emit gdriveAuthChanged();
            emit gdriveAuthFinished(true, cleanName, m_gdriveAuthStatus);
            showStatus(m_gdriveAuthStatus);
        });

        proc->start(rcloneBin, args);
    };

    QStringList initialArgs = {QStringLiteral("config"), QStringLiteral("create"), cleanName, QStringLiteral("drive"),
                               QStringLiteral("scope=drive"), QStringLiteral("config_is_local=true"),
                               QStringLiteral("--non-interactive")};
    if (!m_gdriveAuthClientId.isEmpty() && !m_gdriveAuthClientSecret.isEmpty()) {
        initialArgs << (QStringLiteral("client_id=") + m_gdriveAuthClientId)
                    << (QStringLiteral("client_secret=") + m_gdriveAuthClientSecret);
    } else {
        initialArgs << QStringLiteral("config_shared_client_id=true");
    }
    initialArgs << rcloneConfigArgs();
    (*launchAuthStep)(initialArgs);
}

void Backend::cancelGoogleDriveAuth()
{
    if (!m_gdriveAuthRunning && !m_gdriveAuthProc)
        return;

    m_gdriveAuthRunning = false;
    m_gdriveAuthUrl.clear();
    m_gdriveAuthStatus = tr("Google Drive authorization cancelled.");
    if (m_gdriveAuthProc) {
        QProcess *proc = m_gdriveAuthProc;
        m_gdriveAuthProc = nullptr;
        proc->kill();
        proc->waitForFinished(1500);
        proc->deleteLater();
    }
    emit gdriveAuthChanged();
}

QVariantList Backend::remoteConnections() const
{
    QVariantList enriched;
    for (const QVariant &v : m_remoteConnections) {
        QVariantMap m = v.toMap();
        m[QStringLiteral("protocol")] = normalizeRemoteProtocol(m.value(QStringLiteral("protocol")).toString());
        m[QStringLiteral("uri")] = buildRemoteUri(m);
        const QString mountPath = resolveRemoteMountPath(m);
        m[QStringLiteral("mountPath")] = mountPath;
        m[QStringLiteral("isMounted")] = !mountPath.isEmpty();
        enriched.append(m);
    }
    return enriched;
}

bool Backend::saveRemoteConnection(const QVariantMap &connection)
{
    QVariantMap conn = connection;
    const QString rawUri = conn.value(QStringLiteral("uri")).toString().trimmed();
    if (!rawUri.isEmpty()) {
        const QVariantMap parsed = parseRemoteUri(rawUri);
        for (auto it = parsed.constBegin(); it != parsed.constEnd(); ++it) {
            if (conn.value(it.key()).toString().trimmed().isEmpty())
                conn[it.key()] = it.value();
        }
    }

    const QString proto = normalizeRemoteProtocol(conn.value(QStringLiteral("protocol")).toString());
    QString host = conn.value(QStringLiteral("host")).toString().trimmed();
    if (host.endsWith(QLatin1Char(':')) && isCloudRemoteProtocol(proto))
        host.chop(1);
    if (host.isEmpty()) {
        showStatus(isCloudRemoteProtocol(proto) ? tr("Remote name cannot be empty.") : tr("Remote host cannot be empty."));
        return false;
    }

    conn[QStringLiteral("protocol")] = proto;
    conn[QStringLiteral("host")] = host;
    const int port = conn.value(QStringLiteral("port")).toInt();
    conn[QStringLiteral("port")] = isCloudRemoteProtocol(proto)
                                       ? 0
                                       : ((port > 0) ? port : ((proto == QLatin1String("smb")) ? 445 : 22));
    const QString uri = buildRemoteUri(conn);
    conn[QStringLiteral("uri")] = uri;

    QString name = conn.value(QStringLiteral("name")).toString().trimmed();
    if (name.isEmpty()) {
        if (proto == QLatin1String("gdrive")) {
            name = QStringLiteral("Google Drive (%1)").arg(host);
        } else if (proto == QLatin1String("rclone")) {
            name = QStringLiteral("rclone (%1)").arg(host);
        } else {
            const QString user = conn.value(QStringLiteral("user")).toString().trimmed();
            name = user.isEmpty() ? host : (user + QLatin1Char('@') + host);
        }
        const QString rp = conn.value(QStringLiteral("remotePath")).toString().trimmed();
        if ((proto == QLatin1String("smb") || isCloudRemoteProtocol(proto))
            && !rp.isEmpty() && rp != QLatin1String("/")) {
            name += (rp.startsWith(QLatin1Char('/')) ? rp : QLatin1Char('/') + rp);
        }
        conn[QStringLiteral("name")] = name;
    }

    QString id = conn.value(QStringLiteral("id")).toString().trimmed();
    if (id.isEmpty()) {
        id = QStringLiteral("remote_%1_%2").arg(proto, QString::number(qHash(name + uri), 16));
        conn[QStringLiteral("id")] = id;
    }

    bool replaced = false;
    for (int i = 0; i < m_remoteConnections.size(); ++i) {
        const QVariantMap existing = m_remoteConnections.at(i).toMap();
        if ((!id.isEmpty() && existing.value(QStringLiteral("id")).toString() == id)
            || existing.value(QStringLiteral("name")).toString().compare(name, Qt::CaseInsensitive) == 0) {
            m_remoteConnections[i] = conn;
            replaced = true;
            break;
        }
    }
    if (!replaced)
        m_remoteConnections.append(conn);

    saveSession();
    refreshDrives();
    emit remoteConnectionsChanged();
    showStatus(tr("Saved remote connection: %1").arg(name));
    return true;
}

bool Backend::deleteRemoteConnection(const QString &idOrName)
{
    const QString target = idOrName.trimmed();
    if (target.isEmpty())
        return false;

    for (int i = 0; i < m_remoteConnections.size(); ++i) {
        const QVariantMap existing = m_remoteConnections.at(i).toMap();
        if (existing.value(QStringLiteral("id")).toString() == target
            || existing.value(QStringLiteral("name")).toString() == target) {
            const QString removedName = existing.value(QStringLiteral("name")).toString();
            m_remoteConnections.removeAt(i);
            saveSession();
            refreshDrives();
            emit remoteConnectionsChanged();
            showStatus(tr("Deleted remote connection: %1").arg(removedName));
            return true;
        }
    }
    return false;
}

QString Backend::connectRemote(const QString &idOrUri)
{
    const QString key = idOrUri.trimmed();
    if (key.isEmpty())
        return {};

    QVariantMap conn;
    for (const QVariant &v : std::as_const(m_remoteConnections)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toString() == key
            || m.value(QStringLiteral("name")).toString() == key
            || buildRemoteUri(m) == key) {
            conn = m;
            break;
        }
    }
    if (conn.isEmpty())
        conn = parseRemoteUri(key);

    if (conn.isEmpty()) {
        showStatus(tr("Invalid remote connection URI: %1").arg(key));
        return {};
    }

    QString mountPath = resolveRemoteMountPath(conn);
    if (!mountPath.isEmpty()) {
        activeModel()->setPath(mountPath);
        refreshRcloneRemotes();
        refreshDrives();
        emit remoteConnectionsChanged();
        showStatus(tr("Connected to remote: %1").arg(mountPath));
        return mountPath;
    }

    const QString proto = normalizeRemoteProtocol(conn.value(QStringLiteral("protocol")).toString());
    if (isCloudRemoteProtocol(proto)) {
        const QString rcloneBin = findRcloneExecutable();
        if (rcloneBin.isEmpty()) {
            showStatus(tr("rclone executable not found. Install rclone to connect Google Drive."));
            return {};
        }

        const QString id = conn.value(QStringLiteral("id")).toString().trimmed();
        const QString remoteName = conn.value(QStringLiteral("host")).toString().trimmed();
        const QString rPath = conn.value(QStringLiteral("remotePath")).toString().trimmed();
        if (remoteName.isEmpty()) {
            showStatus(tr("Remote name cannot be empty."));
            return {};
        }

        const QString targetDir = rcloneMountDirFor(proto, remoteName, id);
        QDir().mkpath(targetDir);

        QString cleanRel = rPath;
        while (cleanRel.startsWith(QLatin1Char('/')))
            cleanRel.remove(0, 1);
        const QString spec = remoteName + QLatin1Char(':') + cleanRel;

        QStringList args = {
            QStringLiteral("mount"), spec, targetDir,
            QStringLiteral("--vfs-cache-mode"), QStringLiteral("writes"),
            QStringLiteral("--dir-cache-time"), QStringLiteral("30s"),
            QStringLiteral("--daemon"),
            QStringLiteral("--daemon-wait"), QStringLiteral("10s")
        };
        args << rcloneConfigArgs();

        QProcess proc;
        proc.start(rcloneBin, args);
        if (!proc.waitForFinished(15000) || proc.exitCode() != 0) {
            const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
            showStatus(err.isEmpty() ? tr("rclone mount failed for %1.").arg(spec) : err);
            return {};
        }
        mountPath = targetDir;
    } else if (proto == QLatin1String("sshfs")) {
        const QString sshfsBin = QStandardPaths::findExecutable(QStringLiteral("sshfs"));
        if (sshfsBin.isEmpty()) {
            showStatus(tr("sshfs executable not found. Install sshfs or use sftp:// with GVFS."));
            return {};
        }
        const QString id = conn.value(QStringLiteral("id")).toString().trimmed();
        const QString host = conn.value(QStringLiteral("host")).toString().trimmed();
        const QString user = conn.value(QStringLiteral("user")).toString().trimmed();
        const int port = conn.value(QStringLiteral("port")).toInt();
        const QString rPath = conn.value(QStringLiteral("remotePath")).toString().trimmed();
        const QString keyFile = conn.value(QStringLiteral("domain")).toString().trimmed();

        const QString targetDir = QDir(sshfsMountsRootDir()).filePath(id.isEmpty() ? host : id);
        QDir().mkpath(targetDir);

        QString spec = user.isEmpty() ? host : (user + QLatin1Char('@') + host);
        spec += QLatin1Char(':') + (rPath.isEmpty() ? QStringLiteral("/") : rPath);

        QStringList args = {spec, targetDir, QStringLiteral("-o"), QStringLiteral("reconnect,ServerAliveInterval=15")};
        if (port > 0 && port != 22)
            args << QStringLiteral("-p") << QString::number(port);
        if (!keyFile.isEmpty() && QFileInfo::exists(keyFile))
            args << QStringLiteral("-o") << (QStringLiteral("IdentityFile=") + keyFile);

        QProcess proc;
        proc.start(sshfsBin, args);
        if (!proc.waitForFinished(12000) || proc.exitCode() != 0) {
            const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
            showStatus(err.isEmpty() ? tr("sshfs mount failed.") : err);
            return {};
        }
        mountPath = targetDir;
    } else {
        const QString gioBin = QStandardPaths::findExecutable(QStringLiteral("gio"));
        if (gioBin.isEmpty()) {
            showStatus(tr("gio (GVFS) executable not found."));
            return {};
        }
        const QString uri = buildRemoteUri(conn);
        QProcess proc;
        proc.start(gioBin, {QStringLiteral("mount"), uri});
        if (!proc.waitForFinished(12000)) {
            showStatus(tr("Remote mount timed out (authentication may be required in desktop keyring)."));
            return {};
        }
        const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
        mountPath = resolveRemoteMountPath(conn);
        if (mountPath.isEmpty()) {
            showStatus(err.isEmpty() ? tr("Failed to mount %1").arg(uri) : err);
            return {};
        }
    }

    activeModel()->setPath(mountPath);
    refreshRcloneRemotes();
    refreshDrives();
    emit remoteConnectionsChanged();
    showStatus(tr("Connected to remote: %1").arg(mountPath));
    return mountPath;
}

bool Backend::disconnectRemote(const QString &idOrMountPath)
{
    const QString target = idOrMountPath.trimmed();
    if (target.isEmpty())
        return false;

    QString mountPath;
    for (const QVariant &v : std::as_const(m_remoteConnections)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toString() == target
            || m.value(QStringLiteral("name")).toString() == target
            || m.value(QStringLiteral("uri")).toString() == target) {
            mountPath = resolveRemoteMountPath(m);
            break;
        }
    }
    if (mountPath.isEmpty()) {
        for (const QVariant &v : std::as_const(m_rcloneRemotes)) {
            const QVariantMap rm = v.toMap();
            if (rm.value(QStringLiteral("name")).toString() == target
                || rm.value(QStringLiteral("uri")).toString() == target
                || rm.value(QStringLiteral("label")).toString() == target) {
                QVariantMap conn;
                conn[QStringLiteral("protocol")] = rm.value(QStringLiteral("protocol")).toString();
                conn[QStringLiteral("host")] = rm.value(QStringLiteral("name")).toString();
                mountPath = resolveRemoteMountPath(conn);
                break;
            }
        }
    }
    if (mountPath.isEmpty() && target.startsWith(QLatin1Char('/')))
        mountPath = target;

    if (mountPath.isEmpty())
        return false;

    const QString gvfsRoot = gvfsRootDir();
    QString topMount = mountPath;
    if (!gvfsRoot.isEmpty() && mountPath.startsWith(gvfsRoot + QLatin1Char('/'))) {
        const QString rel = mountPath.mid(gvfsRoot.size() + 1);
        const QString topDir = rel.section(QLatin1Char('/'), 0, 0);
        if (!topDir.isEmpty())
            topMount = QDir(gvfsRoot).filePath(topDir);
    }

    if (m_leftPanel.path().startsWith(topMount))
        m_leftPanel.setPath(QDir::homePath());
    if (m_rightPanel.path().startsWith(topMount))
        m_rightPanel.setPath(QDir::homePath());

    bool ok = false;
    if (!gvfsRoot.isEmpty() && topMount.startsWith(gvfsRoot + QLatin1Char('/'))) {
        const QString gioBin = QStandardPaths::findExecutable(QStringLiteral("gio"));
        if (!gioBin.isEmpty()) {
            QProcess proc;
            proc.start(gioBin, {QStringLiteral("mount"), QStringLiteral("-u"), topMount});
            if (proc.waitForFinished(8000) && proc.exitCode() == 0)
                ok = true;
        }
        if (!ok && envIsSetWithFallback("TWINFORGE_GVFS_DIR", "OMAPANEL_GVFS_DIR"))
            ok = QDir(topMount).removeRecursively();
    } else {
        const QString fm3 = QStandardPaths::findExecutable(QStringLiteral("fusermount3"));
        const QString fm = fm3.isEmpty() ? QStandardPaths::findExecutable(QStringLiteral("fusermount")) : fm3;
        if (!fm.isEmpty()) {
            QProcess proc;
            proc.start(fm, {QStringLiteral("-u"), topMount});
            if (proc.waitForFinished(8000) && proc.exitCode() == 0)
                ok = true;
        }
        if (!ok) {
            QProcess proc;
            proc.start(QStringLiteral("umount"), {topMount});
            if (proc.waitForFinished(8000) && proc.exitCode() == 0)
                ok = true;
        }
        const QString mountsRoot = sshfsMountsRootDir();
        if (!ok && (envIsSetWithFallback("TWINFORGE_MOUNTS_DIR", "OMAPANEL_MOUNTS_DIR"))
            && topMount.startsWith(mountsRoot + QLatin1Char('/'))) {
            ok = QDir(topMount).removeRecursively();
        }
        if (ok && topMount.startsWith(mountsRoot + QLatin1Char('/')) && QDir(topMount).exists()) {
            QDir().rmdir(topMount);
        }
    }

    refreshRcloneRemotes();
    refreshDrives();
    emit remoteConnectionsChanged();
    showStatus(ok ? tr("Disconnected remote mount.") : tr("Failed to disconnect remote mount."));
    return ok;
}

void Backend::cancelRemoteOperation()
{
    m_remoteOpGen.fetch_add(1, std::memory_order_relaxed);
    if (m_remoteOpCancel) {
        m_remoteOpCancel->store(true, std::memory_order_relaxed);
        m_remoteOpCancel.reset();
    }
    if (m_remoteOpRunning) {
        m_remoteOpRunning = false;
        m_remoteOpDetail.clear();
        emit remoteOpChanged();
        showStatus(tr("Remote operation cancelled."));
    }
}

void Backend::connectRemoteAsync(const QString &idOrUri)
{
    const QString key = idOrUri.trimmed();
    if (key.isEmpty())
        return;

    QVariantMap conn;
    for (const QVariant &v : std::as_const(m_remoteConnections)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toString() == key
            || m.value(QStringLiteral("name")).toString() == key
            || buildRemoteUri(m) == key) {
            conn = m;
            break;
        }
    }
    if (conn.isEmpty())
        conn = parseRemoteUri(key);

    if (conn.isEmpty()) {
        const QString msg = tr("Invalid remote connection URI: %1").arg(key);
        showStatus(msg);
        emit remoteOperationFinished(false, QString(), msg);
        return;
    }

    // Fast path: already mounted locally.
    const QString existingMount = resolveRemoteMountPath(conn);
    if (!existingMount.isEmpty()) {
        activeModel()->setPath(existingMount);
        refreshRcloneRemotes();
        refreshDrives();
        emit remoteConnectionsChanged();
        const QString msg = tr("Connected to remote: %1").arg(existingMount);
        showStatus(msg);
        emit remoteOperationFinished(true, existingMount, msg);
        return;
    }

    cancelRemoteOperation();
    const quint64 gen = m_remoteOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_remoteOpCancel = cancelFlag;
    m_remoteOpRunning = true;

    const QString proto = normalizeRemoteProtocol(conn.value(QStringLiteral("protocol")).toString());
    const QString displayName = conn.value(QStringLiteral("name")).toString().isEmpty()
                                    ? conn.value(QStringLiteral("host")).toString()
                                    : conn.value(QStringLiteral("name")).toString();
    m_remoteOpDetail = tr("Connecting %1 (%2)…").arg(displayName, proto.toUpper());
    emit remoteOpChanged();

    const QString uri = buildRemoteUri(conn);
    const QString rcloneBin = isCloudRemoteProtocol(proto) ? findRcloneExecutable() : QString();
    const QStringList rcloneCfg = isCloudRemoteProtocol(proto) ? rcloneConfigArgs() : QStringList();
    const QString sshfsRoot = sshfsMountsRootDir();

    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, conn, proto, uri, rcloneBin, rcloneCfg, sshfsRoot, cancelFlag]() {
        QString mountPath;
        QString errorMsg;

        if (isCloudRemoteProtocol(proto)) {
            if (rcloneBin.isEmpty()) {
                errorMsg = QObject::tr("rclone executable not found. Install rclone to connect Google Drive.");
            } else {
                const QString id = conn.value(QStringLiteral("id")).toString().trimmed();
                const QString remoteName = conn.value(QStringLiteral("host")).toString().trimmed();
                const QString rPath = conn.value(QStringLiteral("remotePath")).toString().trimmed();
                if (remoteName.isEmpty()) {
                    errorMsg = QObject::tr("Remote name cannot be empty.");
                } else {
                    const QString targetDir = rcloneMountDirFor(proto, remoteName, id);
                    QDir().mkpath(targetDir);
                    QString cleanRel = rPath;
                    while (cleanRel.startsWith(QLatin1Char('/')))
                        cleanRel.remove(0, 1);
                    const QString spec = remoteName + QLatin1Char(':') + cleanRel;
                    QStringList args = {
                        QStringLiteral("mount"), spec, targetDir,
                        QStringLiteral("--vfs-cache-mode"), QStringLiteral("writes"),
                        QStringLiteral("--dir-cache-time"), QStringLiteral("30s"),
                        QStringLiteral("--daemon"),
                        QStringLiteral("--daemon-wait"), QStringLiteral("10s")
                    };
                    args << rcloneCfg;

                    QProcess proc;
                    proc.start(rcloneBin, args);
                    if (!waitProcessCancelable(proc, 15000, cancelFlag.get()) || proc.exitCode() != 0) {
                        const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
                        errorMsg = err.isEmpty() ? QObject::tr("rclone mount failed for %1.").arg(spec) : err;
                    } else {
                        mountPath = targetDir;
                    }
                }
            }
        } else if (proto == QLatin1String("sshfs")) {
            const QString sshfsBin = QStandardPaths::findExecutable(QStringLiteral("sshfs"));
            if (sshfsBin.isEmpty()) {
                errorMsg = QObject::tr("sshfs executable not found. Install sshfs or use sftp:// with GVFS.");
            } else {
                const QString id = conn.value(QStringLiteral("id")).toString().trimmed();
                const QString host = conn.value(QStringLiteral("host")).toString().trimmed();
                const QString user = conn.value(QStringLiteral("user")).toString().trimmed();
                const int port = conn.value(QStringLiteral("port")).toInt();
                const QString rPath = conn.value(QStringLiteral("remotePath")).toString().trimmed();
                const QString keyFile = conn.value(QStringLiteral("domain")).toString().trimmed();

                const QString targetDir = QDir(sshfsRoot).filePath(id.isEmpty() ? host : id);
                QDir().mkpath(targetDir);
                QString spec = user.isEmpty() ? host : (user + QLatin1Char('@') + host);
                spec += QLatin1Char(':') + (rPath.isEmpty() ? QStringLiteral("/") : rPath);

                QStringList args = {spec, targetDir, QStringLiteral("-o"), QStringLiteral("reconnect,ServerAliveInterval=15")};
                if (port > 0 && port != 22)
                    args << QStringLiteral("-p") << QString::number(port);
                if (!keyFile.isEmpty() && QFileInfo::exists(keyFile))
                    args << QStringLiteral("-o") << (QStringLiteral("IdentityFile=") + keyFile);

                QProcess proc;
                proc.start(sshfsBin, args);
                if (!waitProcessCancelable(proc, 12000, cancelFlag.get()) || proc.exitCode() != 0) {
                    const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
                    errorMsg = err.isEmpty() ? QObject::tr("sshfs mount failed.") : err;
                } else {
                    mountPath = targetDir;
                }
            }
        } else {
            const QString gioBin = QStandardPaths::findExecutable(QStringLiteral("gio"));
            if (gioBin.isEmpty()) {
                errorMsg = QObject::tr("gio (GVFS) executable not found.");
            } else {
                QProcess proc;
                proc.start(gioBin, {QStringLiteral("mount"), uri});
                if (!waitProcessCancelable(proc, 12000, cancelFlag.get())) {
                    errorMsg = QObject::tr("Remote mount timed out (authentication may be required in desktop keyring).");
                } else {
                    errorMsg = QString::fromUtf8(proc.readAllStandardError()).trimmed();
                }
            }
        }

        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, conn, uri, mountPath, errorMsg]() mutable {
                if (!self || self->m_remoteOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_remoteOpRunning = false;
                self->m_remoteOpDetail.clear();
                self->m_remoteOpCancel.reset();
                emit self->remoteOpChanged();

                if (mountPath.isEmpty() && errorMsg.isEmpty())
                    mountPath = self->resolveRemoteMountPath(conn);
                else if (mountPath.isEmpty()) {
                    const QString resolved = self->resolveRemoteMountPath(conn);
                    if (!resolved.isEmpty())
                        mountPath = resolved;
                }

                if (!mountPath.isEmpty()) {
                    self->activeModel()->setPath(mountPath);
                    self->refreshRcloneRemotes();
                    self->refreshDrives();
                    emit self->remoteConnectionsChanged();
                    const QString msg = tr("Connected to remote: %1").arg(mountPath);
                    self->showStatus(msg);
                    emit self->remoteOperationFinished(true, mountPath, msg);
                } else {
                    const QString msg = errorMsg.isEmpty() ? tr("Failed to mount %1").arg(uri) : errorMsg;
                    self->showStatus(msg);
                    emit self->remoteOperationFinished(false, QString(), msg);
                }
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

void Backend::disconnectRemoteAsync(const QString &idOrMountPath)
{
    const QString target = idOrMountPath.trimmed();
    if (target.isEmpty())
        return;

    QString mountPath;
    for (const QVariant &v : std::as_const(m_remoteConnections)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toString() == target
            || m.value(QStringLiteral("name")).toString() == target
            || m.value(QStringLiteral("uri")).toString() == target) {
            mountPath = resolveRemoteMountPath(m);
            break;
        }
    }
    if (mountPath.isEmpty()) {
        for (const QVariant &v : std::as_const(m_rcloneRemotes)) {
            const QVariantMap rm = v.toMap();
            if (rm.value(QStringLiteral("name")).toString() == target
                || rm.value(QStringLiteral("uri")).toString() == target
                || rm.value(QStringLiteral("label")).toString() == target) {
                QVariantMap conn;
                conn[QStringLiteral("protocol")] = rm.value(QStringLiteral("protocol")).toString();
                conn[QStringLiteral("host")] = rm.value(QStringLiteral("name")).toString();
                mountPath = resolveRemoteMountPath(conn);
                break;
            }
        }
    }
    if (mountPath.isEmpty() && target.startsWith(QLatin1Char('/')))
        mountPath = target;

    if (mountPath.isEmpty())
        return;

    const QString gvfsRoot = gvfsRootDir();
    QString topMount = mountPath;
    if (!gvfsRoot.isEmpty() && mountPath.startsWith(gvfsRoot + QLatin1Char('/'))) {
        const QString rel = mountPath.mid(gvfsRoot.size() + 1);
        const QString topDir = rel.section(QLatin1Char('/'), 0, 0);
        if (!topDir.isEmpty())
            topMount = QDir(gvfsRoot).filePath(topDir);
    }

    if (m_leftPanel.path().startsWith(topMount))
        m_leftPanel.setPath(QDir::homePath());
    if (m_rightPanel.path().startsWith(topMount))
        m_rightPanel.setPath(QDir::homePath());

    cancelRemoteOperation();
    const quint64 gen = m_remoteOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancelFlag = std::make_shared<std::atomic<bool>>(false);
    m_remoteOpCancel = cancelFlag;
    m_remoteOpRunning = true;
    m_remoteOpDetail = tr("Disconnecting %1…").arg(QFileInfo(topMount).fileName());
    emit remoteOpChanged();

    const QString mountsRoot = sshfsMountsRootDir();
    QPointer<Backend> self(this);
    auto *task = QRunnable::create([self, gen, gvfsRoot, mountsRoot, topMount, cancelFlag]() {
        bool ok = false;
        if (!gvfsRoot.isEmpty() && topMount.startsWith(gvfsRoot + QLatin1Char('/'))) {
            const QString gioBin = QStandardPaths::findExecutable(QStringLiteral("gio"));
            if (!gioBin.isEmpty()) {
                QProcess proc;
                proc.start(gioBin, {QStringLiteral("mount"), QStringLiteral("-u"), topMount});
                if (waitProcessCancelable(proc, 8000, cancelFlag.get()) && proc.exitCode() == 0)
                    ok = true;
            }
            if (!ok && envIsSetWithFallback("TWINFORGE_GVFS_DIR", "OMAPANEL_GVFS_DIR"))
                ok = QDir(topMount).removeRecursively();
        } else {
            const QString fm3 = QStandardPaths::findExecutable(QStringLiteral("fusermount3"));
            const QString fm = fm3.isEmpty() ? QStandardPaths::findExecutable(QStringLiteral("fusermount")) : fm3;
            if (!fm.isEmpty()) {
                QProcess proc;
                proc.start(fm, {QStringLiteral("-u"), topMount});
                if (waitProcessCancelable(proc, 8000, cancelFlag.get()) && proc.exitCode() == 0)
                    ok = true;
            }
            if (!ok && !cancelFlag->load(std::memory_order_relaxed)) {
                QProcess proc;
                proc.start(QStringLiteral("umount"), {topMount});
                if (waitProcessCancelable(proc, 8000, cancelFlag.get()) && proc.exitCode() == 0)
                    ok = true;
            }
            if (!ok && (envIsSetWithFallback("TWINFORGE_MOUNTS_DIR", "OMAPANEL_MOUNTS_DIR"))
                && topMount.startsWith(mountsRoot + QLatin1Char('/'))) {
                ok = QDir(topMount).removeRecursively();
            }
            if (ok && topMount.startsWith(mountsRoot + QLatin1Char('/')) && QDir(topMount).exists()) {
                QDir().rmdir(topMount);
            }
        }

        if (cancelFlag->load(std::memory_order_relaxed))
            return;

        QMetaObject::invokeMethod(
            self,
            [self, gen, ok]() {
                if (!self || self->m_remoteOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_remoteOpRunning = false;
                self->m_remoteOpDetail.clear();
                self->m_remoteOpCancel.reset();
                emit self->remoteOpChanged();

                self->refreshRcloneRemotes();
                self->refreshDrives();
                emit self->remoteConnectionsChanged();
                const QString msg = ok ? tr("Disconnected remote mount.") : tr("Failed to disconnect remote mount.");
                self->showStatus(msg);
                emit self->remoteOperationFinished(ok, QString(), msg);
            },
            Qt::QueuedConnection);
    });
    task->setAutoDelete(true);
    QThreadPool::globalInstance()->start(task);
}

QVariantMap Backend::getFileMimeInfo(const QString &path) const
{
    QVariantMap out;
    if (path.isEmpty())
        return out;

    QMimeDatabase db;
    QString arc, inner;
    QMimeType mime;
    if (PanelModel::splitArchivePath(path, &arc, &inner) && !inner.isEmpty())
        mime = db.mimeTypeForFile(QFileInfo(inner).fileName(), QMimeDatabase::MatchExtension);
    else
        mime = db.mimeTypeForFile(path);

    const QString mimeName = mime.isValid() ? mime.name() : QStringLiteral("application/octet-stream");
    out[QStringLiteral("mimeType")] = mimeName;
    out[QStringLiteral("comment")] = mime.comment();
    out[QStringLiteral("defaultApp")] = queryDefaultDesktopForMime(mimeName);
    out[QStringLiteral("isDir")] = QFileInfo(path).isDir();
    return out;
}

QVariantList Backend::getApplicationsForFile(const QString &path) const
{
    if (path.isEmpty())
        return {};

    QMimeDatabase db;
    QString arc, inner;
    QMimeType mime;
    if (PanelModel::splitArchivePath(path, &arc, &inner) && !inner.isEmpty())
        mime = db.mimeTypeForFile(QFileInfo(inner).fileName(), QMimeDatabase::MatchExtension);
    else
        mime = db.mimeTypeForFile(path);

    if (!mime.isValid())
        return {};

    const QString defaultId = queryDefaultDesktopForMime(mime.name());
    const QVariantList allApps = collectAllDesktopApps();

    QVariantList matched;
    for (const QVariant &v : allApps) {
        QVariantMap app = v.toMap();
        if (!desktopAppSupportsMime(app, mime))
            continue;
        app[QStringLiteral("isDefault")] = (!defaultId.isEmpty() && app.value(QStringLiteral("desktopId")).toString() == defaultId);
        matched.append(app);
    }

    std::sort(matched.begin(), matched.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap ma = a.toMap();
        const QVariantMap mb = b.toMap();
        const bool defA = ma.value(QStringLiteral("isDefault")).toBool();
        const bool defB = mb.value(QStringLiteral("isDefault")).toBool();
        if (defA != defB)
            return defA > defB;
        return ma.value(QStringLiteral("name")).toString().compare(
                   mb.value(QStringLiteral("name")).toString(), Qt::CaseInsensitive) < 0;
    });

    return matched;
}

QVariantList Backend::getAllInstalledApplications() const
{
    return collectAllDesktopApps();
}

bool Backend::setDefaultApplicationForMime(const QString &mimeType, const QString &desktopId)
{
    const QString mt = mimeType.trimmed();
    const QString id = desktopId.trimmed();
    if (mt.isEmpty() || id.isEmpty())
        return false;

    const QString filePath = mimeAppsFilePath();
    QDir().mkpath(QFileInfo(filePath).absolutePath());

    QStringList lines;
    QFile inFile(filePath);
    if (inFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!inFile.atEnd())
            lines.append(QString::fromUtf8(inFile.readLine()).trimmed());
        inFile.close();
    }

    int sectionIdx = -1;
    int nextSectionIdx = lines.size();
    int existingKeyIdx = -1;

    for (int i = 0; i < lines.size(); ++i) {
        const QString &l = lines.at(i);
        if (l.startsWith(QLatin1Char('[')) && l.endsWith(QLatin1Char(']'))) {
            if (l == QLatin1String("[Default Applications]")) {
                sectionIdx = i;
            } else if (sectionIdx >= 0 && nextSectionIdx == lines.size()) {
                nextSectionIdx = i;
            }
            continue;
        }
        if (sectionIdx >= 0 && i < nextSectionIdx) {
            const int eq = l.indexOf(QLatin1Char('='));
            if (eq > 0 && l.left(eq).trimmed() == mt)
                existingKeyIdx = i;
        }
    }

    const QString entryLine = mt + QLatin1Char('=') + id;
    if (existingKeyIdx >= 0) {
        lines[existingKeyIdx] = entryLine;
    } else if (sectionIdx >= 0) {
        lines.insert(sectionIdx + 1, entryLine);
    } else {
        if (!lines.isEmpty() && !lines.last().isEmpty())
            lines.append(QString());
        lines.append(QStringLiteral("[Default Applications]"));
        lines.append(entryLine);
    }

    QFile outFile(filePath);
    if (!outFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return false;
    for (const QString &l : std::as_const(lines)) {
        outFile.write(l.toUtf8());
        outFile.write("\n");
    }
    outFile.close();

    if (!envIsSetWithFallback("TWINFORGE_MIMEAPPS_FILE", "OMAPANEL_MIMEAPPS_FILE")) {
        const QString xdgMimeBin = QStandardPaths::findExecutable(QStringLiteral("xdg-mime"));
        if (!xdgMimeBin.isEmpty())
            QProcess::startDetached(xdgMimeBin, {QStringLiteral("default"), id, mt});
    }

    showStatus(tr("Set %1 as default for %2").arg(id, mt));
    return true;
}

bool Backend::openWithApplication(const QStringList &paths, const QString &desktopIdOrExec, bool setAsDefault)
{
    if (paths.isEmpty() || desktopIdOrExec.trimmed().isEmpty())
        return false;

    QStringList resolvedPaths;
    for (const QString &p : paths) {
        QString arc, inner;
        if (PanelModel::splitArchivePath(p, &arc, &inner) && !inner.isEmpty()) {
            const QString extracted = extractArchiveEntryToTemp(arc, inner);
            if (!extracted.isEmpty())
                resolvedPaths.append(extracted);
        } else {
            resolvedPaths.append(p);
        }
    }
    if (resolvedPaths.isEmpty())
        return false;

    QVariantMap matchedApp;
    const QVariantList allApps = collectAllDesktopApps();
    for (const QVariant &v : allApps) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("desktopId")).toString() == desktopIdOrExec
            || m.value(QStringLiteral("desktopPath")).toString() == desktopIdOrExec) {
            matchedApp = m;
            break;
        }
    }

    if (setAsDefault && !matchedApp.isEmpty()) {
        const QString mimeType = getFileMimeInfo(resolvedPaths.first()).value(QStringLiteral("mimeType")).toString();
        setDefaultApplicationForMime(mimeType, matchedApp.value(QStringLiteral("desktopId")).toString());
    }

    const QString execTemplate = matchedApp.isEmpty()
                                     ? desktopIdOrExec.trimmed()
                                     : matchedApp.value(QStringLiteral("exec")).toString();
    const bool inTerminal = matchedApp.value(QStringLiteral("terminal")).toBool();
    const QString appName = matchedApp.isEmpty() ? execTemplate : matchedApp.value(QStringLiteral("name")).toString();

    const QStringList rawTokens = splitExecTokens(execTemplate);
    if (rawTokens.isEmpty())
        return false;

    QStringList finalArgs;
    bool insertedPath = false;
    for (const QString &tok : rawTokens) {
        if (tok == QLatin1String("%f")) {
            finalArgs.append(resolvedPaths.first());
            insertedPath = true;
        } else if (tok == QLatin1String("%F")) {
            finalArgs.append(resolvedPaths);
            insertedPath = true;
        } else if (tok == QLatin1String("%u")) {
            finalArgs.append(QUrl::fromLocalFile(resolvedPaths.first()).toString());
            insertedPath = true;
        } else if (tok == QLatin1String("%U")) {
            for (const QString &rp : std::as_const(resolvedPaths))
                finalArgs.append(QUrl::fromLocalFile(rp).toString());
            insertedPath = true;
        } else if (tok == QLatin1String("%i") || tok == QLatin1String("%c") || tok == QLatin1String("%k")
                   || tok == QLatin1String("%d") || tok == QLatin1String("%D") || tok == QLatin1String("%n")
                   || tok == QLatin1String("%N") || tok == QLatin1String("%v") || tok == QLatin1String("%m")) {
            continue;
        } else {
            finalArgs.append(tok);
        }
    }
    if (!insertedPath)
        finalArgs.append(resolvedPaths);

    if (finalArgs.isEmpty())
        return false;

    const QString program = finalArgs.takeFirst();
    bool started = false;
    if (inTerminal) {
        const QString terminal = findTerminalExecutable(true);
        QStringList termArgs = {QStringLiteral("-e"), program};
        termArgs.append(finalArgs);
        started = QProcess::startDetached(terminal, termArgs, activeModel()->path());
    } else {
        started = QProcess::startDetached(program, finalArgs, activeModel()->path());
    }

    if (started)
        showStatus(tr("Opened with %1").arg(appName));
    else
        showStatus(tr("Failed to launch %1").arg(appName));
    return started;
}

void Backend::ensureDefaultCustomActions()
{
    if (!m_customActions.isEmpty())
        return;
    if (!m_sessionFile.isEmpty() && QFileInfo::exists(m_sessionFile)) {
        QSettings settings(m_sessionFile, QSettings::IniFormat);
        if (settings.contains("actions/customActionsJson"))
            return;
    }

    auto makeAct = [](const QString &id, const QString &name, const QString &cmd,
                      const QString &pattern, bool inTerm, bool showOut) {
        QVariantMap m;
        m[QStringLiteral("id")] = id;
        m[QStringLiteral("name")] = name;
        m[QStringLiteral("command")] = cmd;
        m[QStringLiteral("pattern")] = pattern;
        m[QStringLiteral("runInTerminal")] = inTerm;
        m[QStringLiteral("showOutput")] = showOut;
        return m;
    };

    m_customActions = {
        makeAct(QStringLiteral("default_file_info"), tr("File Type & Encoding (file -b)"),
                QStringLiteral("file -b %f"), QStringLiteral("*"), false, true),
        makeAct(QStringLiteral("default_du_sh"), tr("Disk Usage Summary (du -sh)"),
                QStringLiteral("du -sh %F"), QStringLiteral("*"), false, true),
        makeAct(QStringLiteral("default_chmod_x"), tr("Make Executable (chmod +x)"),
                QStringLiteral("chmod +x %F"), QStringLiteral("*.sh;*.py;*.pl;*.AppImage"), false, false)
    };
    emit customActionsChanged();
}

QVariantList Backend::getCustomActionsForFile(const QString &path) const
{
    if (path.isEmpty())
        return m_customActions;

    const QFileInfo fi(path);
    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile(path);

    QVariantList result;
    for (const QVariant &v : m_customActions) {
        const QVariantMap act = v.toMap();
        if (customActionPatternMatches(act.value(QStringLiteral("pattern")).toString(), fi, mime))
            result.append(act);
    }
    return result;
}

bool Backend::saveCustomAction(const QVariantMap &action)
{
    const QString name = action.value(QStringLiteral("name")).toString().trimmed();
    const QString cmd = action.value(QStringLiteral("command")).toString().trimmed();
    if (name.isEmpty() || cmd.isEmpty()) {
        showStatus(tr("Custom action name and command are required."));
        return false;
    }

    QVariantMap act = action;
    act[QStringLiteral("name")] = name;
    act[QStringLiteral("command")] = cmd;
    QString pattern = act.value(QStringLiteral("pattern")).toString().trimmed();
    act[QStringLiteral("pattern")] = pattern.isEmpty() ? QStringLiteral("*") : pattern;
    act[QStringLiteral("runInTerminal")] = act.value(QStringLiteral("runInTerminal")).toBool();
    act[QStringLiteral("showOutput")] = act.value(QStringLiteral("showOutput")).toBool();

    QString id = act.value(QStringLiteral("id")).toString().trimmed();
    if (id.isEmpty()) {
        id = QStringLiteral("act_%1").arg(QString::number(qHash(name + cmd + QDateTime::currentDateTimeUtc().toString()), 16));
        act[QStringLiteral("id")] = id;
    }

    bool replaced = false;
    for (int i = 0; i < m_customActions.size(); ++i) {
        const QVariantMap existing = m_customActions.at(i).toMap();
        if (existing.value(QStringLiteral("id")).toString() == id
            || existing.value(QStringLiteral("name")).toString().compare(name, Qt::CaseInsensitive) == 0) {
            m_customActions[i] = act;
            replaced = true;
            break;
        }
    }
    if (!replaced)
        m_customActions.append(act);

    saveSession();
    emit customActionsChanged();
    showStatus(tr("Saved custom action: %1").arg(name));
    return true;
}

bool Backend::deleteCustomAction(const QString &idOrName)
{
    const QString key = idOrName.trimmed();
    if (key.isEmpty())
        return false;

    for (int i = 0; i < m_customActions.size(); ++i) {
        const QVariantMap existing = m_customActions.at(i).toMap();
        if (existing.value(QStringLiteral("id")).toString() == key
            || existing.value(QStringLiteral("name")).toString() == key) {
            const QString removedName = existing.value(QStringLiteral("name")).toString();
            m_customActions.removeAt(i);
            saveSession();
            emit customActionsChanged();
            showStatus(tr("Deleted custom action: %1").arg(removedName));
            return true;
        }
    }
    return false;
}

QString Backend::expandCustomActionCommand(const QString &commandTemplate, const QStringList &paths) const
{
    if (commandTemplate.trimmed().isEmpty())
        return {};

    QStringList quotedList;
    for (const QString &p : paths)
        quotedList.append(shellQuoteArg(p));

    const QString firstPath = paths.isEmpty() ? QString() : paths.first();
    const QFileInfo firstFi(firstPath);
    const QString qFirst = paths.isEmpty() ? QString() : shellQuoteArg(firstPath);
    const QString qAll = quotedList.join(QLatin1Char(' '));
    const QString qDir = paths.isEmpty() ? shellQuoteArg(m_activePanel == 0 ? m_leftPanel.path() : m_rightPanel.path())
                                         : shellQuoteArg(firstFi.isDir() ? firstFi.absoluteFilePath() : firstFi.absolutePath());
    const QString qName = paths.isEmpty() ? QString() : shellQuoteArg(firstFi.fileName());
    const QString qBase = paths.isEmpty() ? QString() : shellQuoteArg(firstFi.completeBaseName());
    const QString qExt = paths.isEmpty() ? QString() : shellQuoteArg(firstFi.suffix());

    QString out;
    out.reserve(commandTemplate.size() + qAll.size());
    bool usedFileToken = false;

    for (int i = 0; i < commandTemplate.size(); ++i) {
        if (commandTemplate.at(i) == QLatin1Char('%') && i + 1 < commandTemplate.size()) {
            const QChar code = commandTemplate.at(i + 1);
            if (code == QLatin1Char('F')) { out += qAll; usedFileToken = true; ++i; continue; }
            if (code == QLatin1Char('f')) { out += qFirst; usedFileToken = true; ++i; continue; }
            if (code == QLatin1Char('d')) { out += qDir; ++i; continue; }
            if (code == QLatin1Char('n')) { out += qName; usedFileToken = true; ++i; continue; }
            if (code == QLatin1Char('b')) { out += qBase; usedFileToken = true; ++i; continue; }
            if (code == QLatin1Char('e')) { out += qExt; ++i; continue; }
        }
        out.append(commandTemplate.at(i));
    }

    if (!usedFileToken && !qAll.isEmpty())
        out += QLatin1Char(' ') + qAll;

    return out;
}

QVariantMap Backend::executeCustomAction(const QString &idOrName, const QStringList &paths)
{
    QVariantMap res;
    res[QStringLiteral("ok")] = false;
    res[QStringLiteral("exitCode")] = -1;
    res[QStringLiteral("output")] = QString();
    res[QStringLiteral("showOutput")] = false;

    QVariantMap act;
    for (const QVariant &v : std::as_const(m_customActions)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toString() == idOrName
            || m.value(QStringLiteral("name")).toString() == idOrName) {
            act = m;
            break;
        }
    }

    const QString cmdTemplate = act.isEmpty() ? idOrName : act.value(QStringLiteral("command")).toString();
    const QString actionName = act.isEmpty() ? cmdTemplate : act.value(QStringLiteral("name")).toString();
    const bool inTerm = act.value(QStringLiteral("runInTerminal")).toBool();
    const bool showOut = act.value(QStringLiteral("showOutput")).toBool();

    QStringList resolvedPaths;
    for (const QString &p : paths) {
        QString arc, inner;
        if (PanelModel::splitArchivePath(p, &arc, &inner) && !inner.isEmpty()) {
            const QString extracted = extractArchiveEntryToTemp(arc, inner);
            if (!extracted.isEmpty())
                resolvedPaths.append(extracted);
        } else {
            resolvedPaths.append(p);
        }
    }

    const QString expanded = expandCustomActionCommand(cmdTemplate, resolvedPaths);
    res[QStringLiteral("command")] = expanded;
    res[QStringLiteral("showOutput")] = showOut;

    if (expanded.isEmpty())
        return res;

    QString workDir = activeModel()->path();
    if (!QDir(workDir).exists())
        workDir = QDir::homePath();

    if (inTerm) {
        const QString terminal = findTerminalExecutable(true);
        const bool started = QProcess::startDetached(terminal, {QStringLiteral("-e"), QStringLiteral("/bin/sh"), QStringLiteral("-c"), expanded}, workDir);
        res[QStringLiteral("ok")] = started;
        res[QStringLiteral("exitCode")] = started ? 0 : -1;
        res[QStringLiteral("showOutput")] = false;
        showStatus(started ? tr("Executed in terminal: %1").arg(actionName) : tr("Failed to launch terminal action: %1").arg(actionName));
        return res;
    }

    QProcess proc;
    proc.setWorkingDirectory(workDir);
    proc.setProcessChannelMode(QProcess::MergedChannels);
    proc.start(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), expanded});
    proc.waitForFinished(15000);

    const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    const bool ok = (proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0);
    res[QStringLiteral("ok")] = ok;
    res[QStringLiteral("exitCode")] = proc.exitCode();
    res[QStringLiteral("output")] = out;

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    showStatus(ok ? tr("Action completed: %1").arg(actionName)
                  : tr("Action failed (%1): %2").arg(proc.exitCode()).arg(actionName));
    return res;
}

void Backend::showStatus(const QString &message)
{
    m_statusMessage = message;
    emit statusMessageChanged();
}

QString Backend::activeFilesystemPath() const
{
    const PanelModel *panel = (m_activePanel == 0) ? &m_leftPanel : &m_rightPanel;
    if (panel->isTrashView())
        return QDir::homePath();
    if (panel->isArchiveView())
        return QFileInfo(panel->archiveFilePath()).absolutePath();
    return panel->path();
}

void Backend::applyNavigationRequest(const QString &leftPath, const QString &rightPath,
                                     const QString &selectPath, bool newTab)
{
    auto openOnPanel = [newTab](PanelModel &panel, const QString &rawPath) {
        if (rawPath.trimmed().isEmpty())
            return;
        if (PanelModel::isTrashUri(rawPath)) {
            if (newTab)
                panel.addTab(QStringLiteral("trash://"));
            else
                panel.setPath(QStringLiteral("trash://"));
            return;
        }
        const QString clean = QDir::cleanPath(rawPath);
        if (!QFileInfo::exists(clean))
            return;
        if (newTab)
            panel.addTab(clean);
        else
            panel.setPath(clean);
    };

    int focusPanelIdx = m_activePanel;
    if (!leftPath.isEmpty() && !rightPath.isEmpty()) {
        openOnPanel(m_leftPanel, leftPath);
        openOnPanel(m_rightPanel, rightPath);
        focusPanelIdx = 0;
        if (!selectPath.isEmpty() && QDir::cleanPath(selectPath).startsWith(QDir::cleanPath(rightPath) + QLatin1Char('/')))
            focusPanelIdx = 1;
        setActivePanel(focusPanelIdx);
    } else if (!leftPath.isEmpty()) {
        PanelModel *panel = activeModel();
        openOnPanel(*panel, leftPath);
        focusPanelIdx = m_activePanel;
    } else if (!rightPath.isEmpty()) {
        openOnPanel(m_rightPanel, rightPath);
        focusPanelIdx = 1;
        setActivePanel(1);
    }

    if (!selectPath.isEmpty()) {
        const QFileInfo selFi(selectPath);
        PanelModel *panel = (focusPanelIdx == 0) ? &m_leftPanel : &m_rightPanel;
        if (leftPath.isEmpty() && rightPath.isEmpty() && selFi.exists()) {
            openOnPanel(*panel, selFi.absolutePath());
        }
        if (selFi.fileName().startsWith(QLatin1Char('.')) && !panel->showHidden()) {
            panel->setShowHidden(true);
        }
        emit focusAndSelectRequested(focusPanelIdx, selFi.absoluteFilePath());
    }

    emit windowActivateRequested();
}

bool Backend::moveTabToOppositePanel(int panelIndex, int tabIndex)
{
    PanelModel *src = (panelIndex == 0) ? &m_leftPanel : &m_rightPanel;
    PanelModel *dst = (panelIndex == 0) ? &m_rightPanel : &m_leftPanel;
    const QVariantList srcTabs = src->tabs();
    const int idx = (tabIndex < 0) ? src->activeTab() : tabIndex;
    if (idx < 0 || idx >= srcTabs.size())
        return false;

    const QVariantMap tabInfo = srcTabs.at(idx).toMap();
    const QString targetPath = tabInfo.value(QStringLiteral("path")).toString();
    const int lockMode = tabInfo.value(QStringLiteral("lockMode"), 0).toInt();
    if (targetPath.isEmpty())
        return false;

    dst->addTab(targetPath);
    if (lockMode != PanelModel::TabUnlocked)
        dst->setTabLockMode(dst->activeTab(), lockMode);

    if (lockMode == PanelModel::TabUnlocked && src->tabCount() > 1)
        src->closeTab(idx);

    saveSession();
    showStatus(tr("Moved tab to opposite panel."));
    return true;
}

void Backend::loadWorkspaces()
{
    m_workspaces.clear();
    if (m_workspacesFile.isEmpty())
        return;

    QFile file(m_workspacesFile);
    if (!file.open(QIODevice::ReadOnly))
        return;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isArray())
        return;

    const QJsonArray arr = doc.array();
    for (const QJsonValue &val : arr) {
        if (!val.isObject())
            continue;
        QVariantMap ws = val.toObject().toVariantMap();
        if (ws.value(QStringLiteral("name")).toString().trimmed().isEmpty())
            continue;
        if (ws.value(QStringLiteral("id")).toString().trimmed().isEmpty())
            ws[QStringLiteral("id")] = QUuid::createUuid().toString(QUuid::WithoutBraces);
        m_workspaces.append(ws);
    }
    emit workspacesChanged();
}

void Backend::saveWorkspaces() const
{
    if (m_workspacesFile.isEmpty())
        return;

    QDir().mkpath(QFileInfo(m_workspacesFile).absolutePath());
    QJsonArray arr;
    for (const QVariant &v : std::as_const(m_workspaces))
        arr.append(QJsonObject::fromVariantMap(v.toMap()));

    QFile file(m_workspacesFile);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    }
}

bool Backend::saveWorkspace(const QString &name)
{
    const QString cleanName = name.trimmed();
    if (cleanName.isEmpty())
        return false;

    QVariantMap ws;
    QString existingId;
    int existingIdx = -1;
    for (int i = 0; i < m_workspaces.size(); ++i) {
        const QVariantMap cur = m_workspaces.at(i).toMap();
        if (cur.value(QStringLiteral("name")).toString().compare(cleanName, Qt::CaseInsensitive) == 0) {
            existingIdx = i;
            existingId = cur.value(QStringLiteral("id")).toString();
            break;
        }
    }

    ws[QStringLiteral("id")] = existingId.isEmpty() ? QUuid::createUuid().toString(QUuid::WithoutBraces) : existingId;
    ws[QStringLiteral("name")] = cleanName;
    ws[QStringLiteral("leftTabs")] = m_leftPanel.serializeTabs();
    ws[QStringLiteral("leftActiveTab")] = m_leftPanel.activeTab();
    ws[QStringLiteral("leftSortField")] = m_leftPanel.sortField();
    ws[QStringLiteral("leftSortAscending")] = m_leftPanel.sortAscending();
    ws[QStringLiteral("leftShowHidden")] = m_leftPanel.showHidden();
    ws[QStringLiteral("rightTabs")] = m_rightPanel.serializeTabs();
    ws[QStringLiteral("rightActiveTab")] = m_rightPanel.activeTab();
    ws[QStringLiteral("rightSortField")] = m_rightPanel.sortField();
    ws[QStringLiteral("rightSortAscending")] = m_rightPanel.sortAscending();
    ws[QStringLiteral("rightShowHidden")] = m_rightPanel.showHidden();
    ws[QStringLiteral("activePanel")] = m_activePanel;
    ws[QStringLiteral("savedAt")] = QDateTime::currentDateTime().toString(Qt::ISODate);

    if (existingIdx >= 0)
        m_workspaces[existingIdx] = ws;
    else
        m_workspaces.append(ws);

    m_activeWorkspaceName = cleanName;
    saveWorkspaces();
    emit workspacesChanged();
    showStatus(tr("Saved workspace: %1").arg(cleanName));
    return true;
}

bool Backend::loadWorkspace(const QString &nameOrId)
{
    const QString key = nameOrId.trimmed();
    if (key.isEmpty())
        return false;

    QVariantMap found;
    for (const QVariant &v : std::as_const(m_workspaces)) {
        const QVariantMap ws = v.toMap();
        if (ws.value(QStringLiteral("id")).toString() == key ||
            ws.value(QStringLiteral("name")).toString().compare(key, Qt::CaseInsensitive) == 0) {
            found = ws;
            break;
        }
    }
    if (found.isEmpty())
        return false;

    m_loadingSession = true;

    const QVariantList leftTabs = found.value(QStringLiteral("leftTabs")).toList();
    const int leftActive = found.value(QStringLiteral("leftActiveTab"), 0).toInt();
    m_leftPanel.setShowHidden(found.value(QStringLiteral("leftShowHidden"), false).toBool());
    const int leftSortField = std::clamp(found.value(QStringLiteral("leftSortField"), 0).toInt(), 0, 3);
    if (m_leftPanel.sortField() != leftSortField)
        m_leftPanel.setSortField(leftSortField);
    m_leftPanel.setSortAscending(found.value(QStringLiteral("leftSortAscending"), true).toBool());
    if (!leftTabs.isEmpty())
        m_leftPanel.restoreTabsState(leftTabs, leftActive);

    const QVariantList rightTabs = found.value(QStringLiteral("rightTabs")).toList();
    const int rightActive = found.value(QStringLiteral("rightActiveTab"), 0).toInt();
    m_rightPanel.setShowHidden(found.value(QStringLiteral("rightShowHidden"), false).toBool());
    const int rightSortField = std::clamp(found.value(QStringLiteral("rightSortField"), 0).toInt(), 0, 3);
    if (m_rightPanel.sortField() != rightSortField)
        m_rightPanel.setSortField(rightSortField);
    m_rightPanel.setSortAscending(found.value(QStringLiteral("rightSortAscending"), true).toBool());
    if (!rightTabs.isEmpty())
        m_rightPanel.restoreTabsState(rightTabs, rightActive);

    const int targetPanel = (found.value(QStringLiteral("activePanel"), 0).toInt() == 1) ? 1 : 0;
    if (m_activePanel != targetPanel) {
        m_activePanel = targetPanel;
        emit activePanelChanged();
    }

    m_activeWorkspaceName = found.value(QStringLiteral("name")).toString();
    m_loadingSession = false;
    saveSession();
    emit workspacesChanged();
    showStatus(tr("Loaded workspace: %1").arg(m_activeWorkspaceName));
    return true;
}

bool Backend::deleteWorkspace(const QString &nameOrId)
{
    const QString key = nameOrId.trimmed();
    if (key.isEmpty())
        return false;

    for (int i = 0; i < m_workspaces.size(); ++i) {
        const QVariantMap ws = m_workspaces.at(i).toMap();
        if (ws.value(QStringLiteral("id")).toString() == key ||
            ws.value(QStringLiteral("name")).toString().compare(key, Qt::CaseInsensitive) == 0) {
            const QString removedName = ws.value(QStringLiteral("name")).toString();
            m_workspaces.removeAt(i);
            if (m_activeWorkspaceName.compare(removedName, Qt::CaseInsensitive) == 0)
                m_activeWorkspaceName.clear();
            saveWorkspaces();
            emit workspacesChanged();
            showStatus(tr("Deleted workspace: %1").arg(removedName));
            return true;
        }
    }
    return false;
}

int Backend::trashCount() const
{
    const QDir filesDir(QDir(PanelModel::trashRootDir()).filePath(QStringLiteral("files")));
    if (!filesDir.exists())
        return 0;
    return filesDir.entryList(QDir::Files | QDir::Dirs | QDir::Hidden | QDir::NoDotAndDotDot | QDir::System).size();
}

void Backend::openTrash()
{
    activeModel()->setPath(QStringLiteral("trash://"));
    emit trashChanged();
}

int Backend::restoreFromTrash(const QStringList &trashFilePaths)
{
    if (trashFilePaths.isEmpty())
        return 0;

    const QDir trashRoot(PanelModel::trashRootDir());
    const QString filesDirAbs = QDir::cleanPath(QDir(trashRoot.filePath(QStringLiteral("files"))).absolutePath());
    const QString filesPrefix = filesDirAbs + QLatin1Char('/');
    const QDir infoDir(trashRoot.filePath(QStringLiteral("info")));

    int restored = 0;
    for (const QString &rawPath : trashFilePaths) {
        const QString cleanPath = QDir::cleanPath(rawPath);
        if (!cleanPath.startsWith(filesPrefix))
            continue;
        const QFileInfo srcFi(cleanPath);
        if (!itemExistsOrLink(srcFi))
            continue;

        const QString baseName = srcFi.fileName();
        const QString infoPath = infoDir.filePath(baseName + QStringLiteral(".trashinfo"));

        QString originalPath;
        QFile infoFile(infoPath);
        if (infoFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            while (!infoFile.atEnd()) {
                const QByteArray rawLine = infoFile.readLine().trimmed();
                if (rawLine.startsWith("Path=")) {
                    QString decoded = QUrl::fromPercentEncoding(rawLine.mid(5));
                    if (!decoded.isEmpty() && !QDir::isAbsolutePath(decoded))
                        decoded = QDir(QDir::homePath()).filePath(decoded);
                    originalPath = QDir::cleanPath(decoded);
                    break;
                }
            }
        }
        if (originalPath.isEmpty())
            originalPath = QDir(QDir::homePath()).filePath(baseName);

        const QFileInfo targetFi(originalPath);
        QDir().mkpath(targetFi.absolutePath());

        // Safe collision handling: never silently overwrite an existing file on restore
        QString finalTarget = originalPath;
        if (itemExistsOrLink(QFileInfo(finalTarget))) {
            const QString parentDir = targetFi.absolutePath();
            const QString fileBase = srcFi.isDir() ? targetFi.fileName() : targetFi.completeBaseName();
            const QString ext = srcFi.isDir() ? QString() : targetFi.suffix();
            for (int n = 1; n < 10000; ++n) {
                const QString tag = (n == 1) ? QStringLiteral(" (restored)")
                                             : QStringLiteral(" (restored %1)").arg(n);
                const QString candidate = ext.isEmpty()
                                              ? QDir(parentDir).filePath(fileBase + tag)
                                              : QDir(parentDir).filePath(fileBase + tag + QLatin1Char('.') + ext);
                if (!itemExistsOrLink(QFileInfo(candidate))) {
                    finalTarget = candidate;
                    break;
                }
            }
        }

        if (FileOperation::moveSinglePath(cleanPath, finalTarget)) {
            if (QFileInfo::exists(infoPath))
                QFile::remove(infoPath);
            ++restored;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    emit trashChanged();
    refreshDrives();

    if (restored > 0)
        showStatus(tr("Restored %1 item(s) from Trash.").arg(restored));
    else
        showStatus(tr("Could not restore selected item(s) from Trash."));
    return restored;
}

int Backend::deleteFromTrashPermanently(const QStringList &trashFilePaths)
{
    if (trashFilePaths.isEmpty())
        return 0;

    const QDir trashRoot(PanelModel::trashRootDir());
    const QString filesDirAbs = QDir::cleanPath(QDir(trashRoot.filePath(QStringLiteral("files"))).absolutePath());
    const QString filesPrefix = filesDirAbs + QLatin1Char('/');
    const QDir infoDir(trashRoot.filePath(QStringLiteral("info")));

    int deleted = 0;
    for (const QString &rawPath : trashFilePaths) {
        const QString cleanPath = QDir::cleanPath(rawPath);
        if (!cleanPath.startsWith(filesPrefix))
            continue;
        const QFileInfo fi(cleanPath);
        if (!itemExistsOrLink(fi))
            continue;

        bool ok = false;
        if (fi.isDir() && !fi.isSymLink())
            ok = QDir(cleanPath).removeRecursively();
        else
            ok = QFile::remove(cleanPath);

        if (ok) {
            const QString infoPath = infoDir.filePath(fi.fileName() + QStringLiteral(".trashinfo"));
            if (QFileInfo::exists(infoPath))
                QFile::remove(infoPath);
            ++deleted;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    emit trashChanged();
    refreshDrives();

    if (deleted > 0)
        showStatus(tr("Permanently deleted %1 item(s) from Trash.").arg(deleted));
    else
        showStatus(tr("Could not permanently delete item(s) from Trash."));
    return deleted;
}

int Backend::emptyTrash()
{
    const QDir trashRoot(PanelModel::trashRootDir());
    const QDir filesDir(trashRoot.filePath(QStringLiteral("files")));
    const QDir infoDir(trashRoot.filePath(QStringLiteral("info")));

    int removed = 0;
    if (filesDir.exists()) {
        const QFileInfoList entries = filesDir.entryInfoList(
            QDir::Files | QDir::Dirs | QDir::Hidden | QDir::NoDotAndDotDot | QDir::System);
        for (const QFileInfo &fi : entries) {
            bool ok = false;
            if (fi.isDir() && !fi.isSymLink())
                ok = QDir(fi.absoluteFilePath()).removeRecursively();
            else
                ok = QFile::remove(fi.absoluteFilePath());
            if (ok)
                ++removed;
        }
    }
    if (infoDir.exists()) {
        const QFileInfoList infoEntries = infoDir.entryInfoList(
            QDir::Files | QDir::Hidden | QDir::NoDotAndDotDot | QDir::System);
        for (const QFileInfo &fi : infoEntries)
            QFile::remove(fi.absoluteFilePath());
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    emit trashChanged();
    refreshDrives();

    showStatus(removed > 0 ? tr("Trash emptied (%1 item(s) removed).").arg(removed)
                           : tr("Trash is already empty."));
    return removed;
}

void Backend::recordCommandHistory(const QString &command)
{
    const QString trimmed = command.trimmed();
    if (trimmed.isEmpty())
        return;

    m_commandHistory.removeAll(trimmed);
    m_commandHistory.append(trimmed);
    while (m_commandHistory.size() > 100)
        m_commandHistory.removeFirst();

    emit commandHistoryChanged();
    saveSession();
}

void Backend::clearCommandHistory()
{
    if (m_commandHistory.isEmpty())
        return;
    m_commandHistory.clear();
    emit commandHistoryChanged();
    saveSession();
}

void Backend::clearCommandOutput()
{
    if (m_commandOutput.isEmpty())
        return;
    m_commandOutput.clear();
    emit commandOutputChanged();
}

QString Backend::shellQuote(const QString &text) const
{
    if (text.isEmpty())
        return QStringLiteral("''");
    static const QRegularExpression safeRe(QStringLiteral("^[A-Za-z0-9_./:@%+=,-]+$"));
    if (safeRe.match(text).hasMatch())
        return text;
    QString quoted = text;
    quoted.replace(QLatin1Char('\''), QStringLiteral("'\\''"));
    return QLatin1Char('\'') + quoted + QLatin1Char('\'');
}

bool Backend::tryHandleBuiltinCd(const QString &command, QString *outMessage, int *outExitCode)
{
    const QString trimmed = command.trimmed();
    if (trimmed != QLatin1String("cd") && !trimmed.startsWith(QLatin1String("cd ")))
        return false;
    // Let compound shell commands (e.g. "cd foo && make") run in /bin/sh
    if (trimmed.contains(QLatin1String("&&")) || trimmed.contains(QLatin1String("||"))
        || trimmed.contains(QLatin1Char(';')) || trimmed.contains(QLatin1Char('|'))) {
        return false;
    }

    QString arg = trimmed.mid(2).trimmed();
    if ((arg.startsWith(QLatin1Char('"')) && arg.endsWith(QLatin1Char('"')) && arg.size() >= 2)
        || (arg.startsWith(QLatin1Char('\'')) && arg.endsWith(QLatin1Char('\'')) && arg.size() >= 2)) {
        arg = arg.mid(1, arg.size() - 2);
    }

    PanelModel *panel = activeModel();
    if (arg.isEmpty() || arg == QLatin1String("~")) {
        panel->setPath(QDir::homePath());
        if (outMessage) *outMessage = tr("Changed directory to %1").arg(panel->path());
        if (outExitCode) *outExitCode = 0;
        return true;
    }
    if (arg == QLatin1String("-")) {
        if (panel->canGoBack()) {
            panel->goBack();
            if (outMessage) *outMessage = tr("Changed directory to %1").arg(panel->path());
            if (outExitCode) *outExitCode = 0;
        } else {
            if (outMessage) *outMessage = tr("cd: no previous directory in history");
            if (outExitCode) *outExitCode = 1;
        }
        return true;
    }
    if (arg == QLatin1String("..")) {
        panel->cdUp();
        if (outMessage) *outMessage = tr("Changed directory to %1").arg(panel->path());
        if (outExitCode) *outExitCode = 0;
        return true;
    }
    if (PanelModel::isTrashUri(arg)) {
        panel->setPath(QStringLiteral("trash://"));
        if (outMessage) *outMessage = tr("Opened Trash");
        if (outExitCode) *outExitCode = 0;
        return true;
    }

    QString target = arg;
    if (target.startsWith(QLatin1String("~/")))
        target = QDir::homePath() + target.mid(1);
    else if (!QDir::isAbsolutePath(target))
        target = QDir(activeFilesystemPath()).filePath(target);
    target = QDir::cleanPath(target);

    if (QFileInfo(target).isDir()) {
        panel->setPath(target);
        if (outMessage) *outMessage = tr("Changed directory to %1").arg(panel->path());
        if (outExitCode) *outExitCode = 0;
        return true;
    }

    if (outMessage) *outMessage = tr("cd: directory not found: %1").arg(arg);
    if (outExitCode) *outExitCode = 1;
    return true;
}

void Backend::runCommandAsync(const QString &command)
{
    const QString trimmed = command.trimmed();
    if (trimmed.isEmpty())
        return;

    if (m_commandRunning) {
        showStatus(tr("A command is already running. Cancel it first."));
        return;
    }

    recordCommandHistory(trimmed);

    const QString workDir = activeFilesystemPath();
    auto appendOutput = [this](const QString &chunk) {
        if (chunk.isEmpty())
            return;
        m_commandOutput.append(chunk);
        constexpr int kMaxOutputChars = 512 * 1024;
        if (m_commandOutput.size() > kMaxOutputChars) {
            m_commandOutput = m_commandOutput.right(kMaxOutputChars);
        }
        emit commandOutputChanged();
    };

    if (!m_commandOutput.isEmpty() && !m_commandOutput.endsWith(QLatin1Char('\n')))
        appendOutput(QStringLiteral("\n"));
    appendOutput(QStringLiteral("%1 ❯ %2\n").arg(workDir, trimmed));

    QString cdMsg;
    int cdCode = 0;
    if (tryHandleBuiltinCd(trimmed, &cdMsg, &cdCode)) {
        if (cdCode != 0)
            appendOutput(cdMsg + QLatin1Char('\n'));
        m_commandLastExitCode = cdCode;
        emit commandStateChanged();
        showStatus(cdMsg);
        emit commandFinished(cdCode == 0, cdCode);
        return;
    }

    auto *proc = new QProcess(this);
    m_cmdProc = proc;
    m_commandRunning = true;
    m_commandRunningText = trimmed;
    emit commandStateChanged();
    showStatus(tr("Running: %1").arg(trimmed));

    proc->setWorkingDirectory(workDir);
    proc->setProcessChannelMode(QProcess::MergedChannels);

    connect(proc, &QProcess::readyReadStandardOutput, this, [this, proc, appendOutput]() {
        if (m_cmdProc != proc)
            return;
        appendOutput(QString::fromUtf8(proc->readAllStandardOutput()));
    });

    connect(proc, &QProcess::errorOccurred, this, [this, proc, appendOutput](QProcess::ProcessError err) {
        if (m_cmdProc != proc)
            return;
        if (err == QProcess::FailedToStart) {
            appendOutput(tr("Failed to start shell command.\n"));
            m_cmdProc = nullptr;
            m_commandRunning = false;
            m_commandRunningText.clear();
            m_commandLastExitCode = 127;
            emit commandStateChanged();
            showStatus(tr("Failed to start shell command."));
            emit commandFinished(false, 127);
            proc->deleteLater();
        }
    });

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc, trimmed, appendOutput](int exitCode, QProcess::ExitStatus status) {
                if (m_cmdProc != proc) {
                    proc->deleteLater();
                    return;
                }
                const QString tail = QString::fromUtf8(proc->readAllStandardOutput());
                if (!tail.isEmpty())
                    appendOutput(tail);

                m_cmdProc = nullptr;
                m_commandRunning = false;
                m_commandRunningText.clear();
                m_commandLastExitCode = (status == QProcess::NormalExit) ? exitCode : -1;
                emit commandStateChanged();

                m_leftPanel.refresh();
                m_rightPanel.refresh();

                const bool ok = (status == QProcess::NormalExit && exitCode == 0);
                if (!ok) {
                    appendOutput(tr("[exit %1]\n").arg(m_commandLastExitCode));
                }
                showStatus(ok ? tr("Command finished: %1").arg(trimmed)
                              : tr("Command failed (exit %1): %2").arg(m_commandLastExitCode).arg(trimmed));
                emit commandFinished(ok, m_commandLastExitCode);
                proc->deleteLater();
            });

    proc->start(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), trimmed});
}

void Backend::cancelCommand()
{
    if (!m_cmdProc)
        return;
    QProcess *proc = m_cmdProc;
    m_cmdProc = nullptr;
    m_commandRunning = false;
    m_commandRunningText.clear();
    m_commandLastExitCode = 130;

    proc->disconnect(this);
    if (proc->state() != QProcess::NotRunning) {
        proc->terminate();
        if (!proc->waitForFinished(400)) {
            proc->kill();
            proc->waitForFinished(400);
        }
    }
    proc->deleteLater();

    m_commandOutput.append(tr("[Cancelled]\n"));
    emit commandOutputChanged();
    emit commandStateChanged();
    showStatus(tr("Command cancelled."));
    emit commandFinished(false, 130);
}

static bool parseSplitBaseInfo(const QString &inputPath, QString &outDir, QString &outBaseName,
                               QString &outCrcPath, QStringList &outParts,
                               QString &outOriginalName, qint64 &outExpectedSize, QString &outExpectedSha256)
{
    const QFileInfo fi(inputPath);
    if (!fi.exists() || !fi.isFile())
        return false;

    outDir = fi.absolutePath();
    const QString fileName = fi.fileName();
    outExpectedSize = -1;
    outExpectedSha256.clear();
    outOriginalName.clear();
    outParts.clear();

    static const QRegularExpression partRe(QStringLiteral("^(.+)\\.(\\d{3,4})$"));
    if (fileName.endsWith(QLatin1String(".crc"), Qt::CaseInsensitive)) {
        outBaseName = fileName.left(fileName.size() - 4);
        outCrcPath = fi.absoluteFilePath();
    } else {
        const QRegularExpressionMatch m = partRe.match(fileName);
        if (!m.hasMatch())
            return false;
        outBaseName = m.captured(1);
        const QString candidateCrc = QDir(outDir).filePath(outBaseName + QStringLiteral(".crc"));
        if (QFileInfo::exists(candidateCrc))
            outCrcPath = candidateCrc;
    }

    if (!outCrcPath.isEmpty()) {
        QFile crcFile(outCrcPath);
        if (crcFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            while (!crcFile.atEnd()) {
                const QString line = QString::fromUtf8(crcFile.readLine()).trimmed();
                if (line.startsWith(QLatin1String("filename="), Qt::CaseInsensitive))
                    outOriginalName = QFileInfo(line.mid(9).trimmed()).fileName();
                else if (line.startsWith(QLatin1String("size="), Qt::CaseInsensitive))
                    outExpectedSize = line.mid(5).trimmed().toLongLong();
                else if (line.startsWith(QLatin1String("sha256="), Qt::CaseInsensitive))
                    outExpectedSha256 = line.mid(7).trimmed().toLower();
            }
        }
    }

    if (outOriginalName.isEmpty())
        outOriginalName = outBaseName;

    // Collect sequential parts (.001, .002, ... or 4-digit .0001)
    int width = 3;
    if (!QFileInfo::exists(QDir(outDir).filePath(QStringLiteral("%1.001").arg(outBaseName)))
        && QFileInfo::exists(QDir(outDir).filePath(QStringLiteral("%1.0001").arg(outBaseName)))) {
        width = 4;
    }
    for (int idx = 1; idx < 10000; ++idx) {
        const QString suffix = QString::number(idx).rightJustified(width, QLatin1Char('0'));
        const QString partPath = QDir(outDir).filePath(outBaseName + QLatin1Char('.') + suffix);
        if (!QFileInfo::exists(partPath))
            break;
        outParts.append(partPath);
    }
    return !outParts.isEmpty();
}

QVariantMap Backend::inspectSplitSource(const QString &path) const
{
    QVariantMap info;
    const QFileInfo fi(path);
    if (!fi.exists() || !fi.isFile()) {
        info[QStringLiteral("valid")] = false;
        return info;
    }

    QString dir, baseName, crcPath, origName, expectedSha;
    QStringList parts;
    qint64 expectedSize = -1;
    if (parseSplitBaseInfo(path, dir, baseName, crcPath, parts, origName, expectedSize, expectedSha)) {
        qint64 totalBytes = 0;
        for (const QString &p : parts)
            totalBytes += QFileInfo(p).size();
        info[QStringLiteral("valid")] = true;
        info[QStringLiteral("mode")] = QStringLiteral("combine");
        info[QStringLiteral("fileName")] = origName;
        info[QStringLiteral("partCount")] = parts.size();
        info[QStringLiteral("totalBytes")] = totalBytes;
        info[QStringLiteral("formattedSize")] = PanelModel::formatSize(totalBytes, false);
        info[QStringLiteral("hasCrc")] = !crcPath.isEmpty();
        info[QStringLiteral("firstPartPath")] = parts.first();
        return info;
    }

    info[QStringLiteral("valid")] = true;
    info[QStringLiteral("mode")] = QStringLiteral("split");
    info[QStringLiteral("fileName")] = fi.fileName();
    info[QStringLiteral("partCount")] = 0;
    info[QStringLiteral("totalBytes")] = fi.size();
    info[QStringLiteral("formattedSize")] = PanelModel::formatSize(fi.size(), false);
    info[QStringLiteral("hasCrc")] = false;
    return info;
}

QVariantMap Backend::splitFileImpl(const QString &sourcePath, const QString &targetDir,
                                   qint64 partSizeBytes, bool writeCrc,
                                   const std::atomic<bool> *cancelFlag,
                                   const std::function<void(double, const QString &)> &progressCb)
{
    QVariantMap res;
    res[QStringLiteral("mode")] = QStringLiteral("split");
    res[QStringLiteral("success")] = false;
    res[QStringLiteral("cancelled")] = false;

    const QFileInfo srcFi(sourcePath);
    if (!srcFi.exists() || !srcFi.isFile()) {
        res[QStringLiteral("message")] = tr("Source file does not exist.");
        return res;
    }
    if (partSizeBytes <= 0) {
        res[QStringLiteral("message")] = tr("Part size must be greater than zero.");
        return res;
    }

    const QString outDirPath = targetDir.trimmed().isEmpty() ? srcFi.absolutePath() : QDir::cleanPath(targetDir.trimmed());
    if (!QDir().mkpath(outDirPath)) {
        res[QStringLiteral("message")] = tr("Could not create destination directory.");
        return res;
    }

    QFile srcFile(srcFi.absoluteFilePath());
    if (!srcFile.open(QIODevice::ReadOnly)) {
        res[QStringLiteral("message")] = tr("Could not open source file for reading.");
        return res;
    }

    const qint64 totalBytes = srcFi.size();
    const qint64 estimatedParts = std::max<qint64>(1, (totalBytes + partSizeBytes - 1) / partSizeBytes);
    const int numWidth = (estimatedParts >= 1000) ? 4 : 3;

    QCryptographicHash sha256(QCryptographicHash::Sha256);
    QStringList createdFiles;
    qint64 bytesReadTotal = 0;
    int partIndex = 0;

    QByteArray buffer;
    buffer.resize(256 * 1024);

    auto cleanup = [&]() {
        for (const QString &f : createdFiles)
            QFile::remove(f);
    };

    do {
        if (cancelFlag && cancelFlag->load(std::memory_order_relaxed)) {
            cleanup();
            res[QStringLiteral("cancelled")] = true;
            res[QStringLiteral("message")] = tr("Split operation cancelled.");
            return res;
        }

        ++partIndex;
        const QString suffix = QString::number(partIndex).rightJustified(numWidth, QLatin1Char('0'));
        const QString partPath = QDir(outDirPath).filePath(srcFi.fileName() + QLatin1Char('.') + suffix);

        QFile partFile(partPath);
        if (!partFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            cleanup();
            res[QStringLiteral("message")] = tr("Could not write part file: %1").arg(QFileInfo(partPath).fileName());
            return res;
        }
        createdFiles.append(partPath);

        qint64 writtenThisPart = 0;
        while (writtenThisPart < partSizeBytes) {
            if (cancelFlag && cancelFlag->load(std::memory_order_relaxed)) {
                partFile.close();
                cleanup();
                res[QStringLiteral("cancelled")] = true;
                res[QStringLiteral("message")] = tr("Split operation cancelled.");
                return res;
            }
            const qint64 toRead = std::min<qint64>(buffer.size(), partSizeBytes - writtenThisPart);
            const qint64 n = srcFile.read(buffer.data(), toRead);
            if (n < 0) {
                partFile.close();
                cleanup();
                res[QStringLiteral("message")] = tr("Error reading source file.");
                return res;
            }
            if (n == 0)
                break;

            if (partFile.write(buffer.constData(), n) != n) {
                partFile.close();
                cleanup();
                res[QStringLiteral("message")] = tr("Error writing part file.");
                return res;
            }
            sha256.addData(QByteArrayView(buffer.constData(), n));
            writtenThisPart += n;
            bytesReadTotal += n;

            if (progressCb && totalBytes > 0) {
                progressCb(std::clamp(double(bytesReadTotal) / double(totalBytes), 0.0, 1.0),
                           tr("Writing part %1 of %2…").arg(partIndex).arg(estimatedParts));
            }
        }
        partFile.close();
    } while (!srcFile.atEnd());

    const QString shaHex = QString::fromLatin1(sha256.result().toHex());
    QString crcPath;
    if (writeCrc) {
        crcPath = QDir(outDirPath).filePath(srcFi.fileName() + QStringLiteral(".crc"));
        QFile crcFile(crcPath);
        if (crcFile.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
            const QByteArray manifest =
                QStringLiteral("filename=%1\nsize=%2\nparts=%3\nsha256=%4\n")
                    .arg(srcFi.fileName())
                    .arg(totalBytes)
                    .arg(partIndex)
                    .arg(shaHex)
                    .toUtf8();
            crcFile.write(manifest);
        }
    }

    res[QStringLiteral("success")] = true;
    res[QStringLiteral("partCount")] = partIndex;
    res[QStringLiteral("parts")] = createdFiles;
    res[QStringLiteral("crcPath")] = crcPath;
    res[QStringLiteral("totalBytes")] = totalBytes;
    res[QStringLiteral("sha256")] = shaHex;
    res[QStringLiteral("message")] = tr("Split %1 into %2 part(s).").arg(srcFi.fileName()).arg(partIndex);
    return res;
}

QVariantMap Backend::combineFilesImpl(const QString &firstPartOrCrcPath, const QString &targetDir,
                                      const std::atomic<bool> *cancelFlag,
                                      const std::function<void(double, const QString &)> &progressCb)
{
    QVariantMap res;
    res[QStringLiteral("mode")] = QStringLiteral("combine");
    res[QStringLiteral("success")] = false;
    res[QStringLiteral("cancelled")] = false;

    QString srcDir, baseName, crcPath, origName, expectedSha;
    QStringList parts;
    qint64 expectedSize = -1;
    if (!parseSplitBaseInfo(firstPartOrCrcPath, srcDir, baseName, crcPath, parts, origName, expectedSize, expectedSha)) {
        res[QStringLiteral("message")] = tr("Select a .001 part or .crc manifest to combine.");
        return res;
    }

    const QString outDirPath = targetDir.trimmed().isEmpty() ? srcDir : QDir::cleanPath(targetDir.trimmed());
    if (!QDir().mkpath(outDirPath)) {
        res[QStringLiteral("message")] = tr("Could not create destination directory.");
        return res;
    }

    qint64 totalBytes = 0;
    for (const QString &p : parts)
        totalBytes += QFileInfo(p).size();

    const QString outPath = QDir(outDirPath).filePath(origName);
    QFile outFile(outPath);
    if (!outFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        res[QStringLiteral("message")] = tr("Could not open output file for writing: %1").arg(origName);
        return res;
    }

    QCryptographicHash sha256(QCryptographicHash::Sha256);
    QByteArray buffer;
    buffer.resize(256 * 1024);
    qint64 bytesWritten = 0;

    for (int i = 0; i < parts.size(); ++i) {
        if (cancelFlag && cancelFlag->load(std::memory_order_relaxed)) {
            outFile.close();
            QFile::remove(outPath);
            res[QStringLiteral("cancelled")] = true;
            res[QStringLiteral("message")] = tr("Combine operation cancelled.");
            return res;
        }

        QFile partFile(parts.at(i));
        if (!partFile.open(QIODevice::ReadOnly)) {
            outFile.close();
            QFile::remove(outPath);
            res[QStringLiteral("message")] = tr("Could not read part file: %1").arg(QFileInfo(parts.at(i)).fileName());
            return res;
        }

        while (!partFile.atEnd()) {
            if (cancelFlag && cancelFlag->load(std::memory_order_relaxed)) {
                partFile.close();
                outFile.close();
                QFile::remove(outPath);
                res[QStringLiteral("cancelled")] = true;
                res[QStringLiteral("message")] = tr("Combine operation cancelled.");
                return res;
            }
            const qint64 n = partFile.read(buffer.data(), buffer.size());
            if (n < 0) {
                partFile.close();
                outFile.close();
                QFile::remove(outPath);
                res[QStringLiteral("message")] = tr("Error reading part file.");
                return res;
            }
            if (n == 0)
                break;
            if (outFile.write(buffer.constData(), n) != n) {
                partFile.close();
                outFile.close();
                QFile::remove(outPath);
                res[QStringLiteral("message")] = tr("Error writing combined file.");
                return res;
            }
            sha256.addData(QByteArrayView(buffer.constData(), n));
            bytesWritten += n;
            if (progressCb && totalBytes > 0) {
                progressCb(std::clamp(double(bytesWritten) / double(totalBytes), 0.0, 1.0),
                           tr("Combining part %1 of %2…").arg(i + 1).arg(parts.size()));
            }
        }
    }
    outFile.close();

    const QString actualSha = QString::fromLatin1(sha256.result().toHex());
    bool hasCrc = !crcPath.isEmpty();
    bool verified = true;
    if (hasCrc) {
        if (expectedSize >= 0 && bytesWritten != expectedSize)
            verified = false;
        if (!expectedSha.isEmpty() && actualSha != expectedSha)
            verified = false;
    }

    res[QStringLiteral("success")] = verified;
    res[QStringLiteral("outputPath")] = outPath;
    res[QStringLiteral("partCount")] = parts.size();
    res[QStringLiteral("totalBytes")] = bytesWritten;
    res[QStringLiteral("sha256")] = actualSha;
    res[QStringLiteral("hasCrc")] = hasCrc;
    res[QStringLiteral("verified")] = verified;
    if (hasCrc) {
        res[QStringLiteral("message")] = verified
            ? tr("Combined %1 part(s) into %2 (SHA-256 verified).").arg(parts.size()).arg(origName)
            : tr("Combined %1, but SHA-256 / size checksum verification FAILED!").arg(origName);
    } else {
        res[QStringLiteral("message")] = tr("Combined %1 part(s) into %2.").arg(parts.size()).arg(origName);
    }
    return res;
}

QVariantMap Backend::splitFile(const QString &sourcePath, const QString &targetDir,
                               qint64 partSizeBytes, bool writeCrc)
{
    const QVariantMap res = splitFileImpl(sourcePath, targetDir, partSizeBytes, writeCrc);
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(res.value(QStringLiteral("message")).toString());
    return res;
}

QVariantMap Backend::combineFiles(const QString &firstPartOrCrcPath, const QString &targetDir)
{
    const QVariantMap res = combineFilesImpl(firstPartOrCrcPath, targetDir);
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(res.value(QStringLiteral("message")).toString());
    return res;
}

void Backend::startSplitFile(const QString &sourcePath, const QString &targetDir,
                             qint64 partSizeBytes, bool writeCrc)
{
    cancelSplitOperation();
    const quint64 gen = m_splitOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancel = std::make_shared<std::atomic<bool>>(false);
    m_splitOpCancel = cancel;
    m_splitOpRunning = true;
    m_splitOpProgress = 0.0;
    m_splitOpDetail = tr("Splitting %1…").arg(QFileInfo(sourcePath).fileName());
    emit splitOpChanged();

    QPointer<Backend> self(this);
    QThreadPool::globalInstance()->start([self, gen, cancel, sourcePath, targetDir, partSizeBytes, writeCrc]() {
        auto lastEmit = std::make_shared<QElapsedTimer>();
        lastEmit->start();
        auto progressCb = [self, gen, lastEmit](double prog, const QString &detail) {
            if (lastEmit->elapsed() < 60 && prog < 1.0)
                return;
            lastEmit->restart();
            QMetaObject::invokeMethod(self, [self, gen, prog, detail]() {
                if (!self || self->m_splitOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_splitOpProgress = prog;
                self->m_splitOpDetail = detail;
                emit self->splitOpChanged();
            }, Qt::QueuedConnection);
        };

        const QVariantMap res = splitFileImpl(sourcePath, targetDir, partSizeBytes, writeCrc, cancel.get(), progressCb);
        QMetaObject::invokeMethod(self, [self, gen, res]() {
            if (!self || self->m_splitOpGen.load(std::memory_order_relaxed) != gen)
                return;
            self->m_splitOpRunning = false;
            self->m_splitOpProgress = res.value(QStringLiteral("success")).toBool() ? 1.0 : 0.0;
            self->m_splitOpDetail = res.value(QStringLiteral("message")).toString();
            self->m_splitOpCancel.reset();
            emit self->splitOpChanged();
            self->m_leftPanel.refresh();
            self->m_rightPanel.refresh();
            self->showStatus(self->m_splitOpDetail);
            emit self->splitOperationFinished(res);
        }, Qt::QueuedConnection);
    });
}

void Backend::startCombineFiles(const QString &firstPartOrCrcPath, const QString &targetDir)
{
    cancelSplitOperation();
    const quint64 gen = m_splitOpGen.fetch_add(1, std::memory_order_relaxed) + 1;
    auto cancel = std::make_shared<std::atomic<bool>>(false);
    m_splitOpCancel = cancel;
    m_splitOpRunning = true;
    m_splitOpProgress = 0.0;
    m_splitOpDetail = tr("Combining %1…").arg(QFileInfo(firstPartOrCrcPath).fileName());
    emit splitOpChanged();

    QPointer<Backend> self(this);
    QThreadPool::globalInstance()->start([self, gen, cancel, firstPartOrCrcPath, targetDir]() {
        auto lastEmit = std::make_shared<QElapsedTimer>();
        lastEmit->start();
        auto progressCb = [self, gen, lastEmit](double prog, const QString &detail) {
            if (lastEmit->elapsed() < 60 && prog < 1.0)
                return;
            lastEmit->restart();
            QMetaObject::invokeMethod(self, [self, gen, prog, detail]() {
                if (!self || self->m_splitOpGen.load(std::memory_order_relaxed) != gen)
                    return;
                self->m_splitOpProgress = prog;
                self->m_splitOpDetail = detail;
                emit self->splitOpChanged();
            }, Qt::QueuedConnection);
        };

        const QVariantMap res = combineFilesImpl(firstPartOrCrcPath, targetDir, cancel.get(), progressCb);
        QMetaObject::invokeMethod(self, [self, gen, res]() {
            if (!self || self->m_splitOpGen.load(std::memory_order_relaxed) != gen)
                return;
            self->m_splitOpRunning = false;
            self->m_splitOpProgress = res.value(QStringLiteral("success")).toBool() ? 1.0 : 0.0;
            self->m_splitOpDetail = res.value(QStringLiteral("message")).toString();
            self->m_splitOpCancel.reset();
            emit self->splitOpChanged();
            self->m_leftPanel.refresh();
            self->m_rightPanel.refresh();
            self->showStatus(self->m_splitOpDetail);
            emit self->splitOperationFinished(res);
        }, Qt::QueuedConnection);
    });
}

void Backend::cancelSplitOperation()
{
    m_splitOpGen.fetch_add(1, std::memory_order_relaxed);
    if (m_splitOpCancel) {
        m_splitOpCancel->store(true, std::memory_order_relaxed);
        m_splitOpCancel.reset();
    }
    if (m_splitOpRunning) {
        m_splitOpRunning = false;
        m_splitOpDetail = tr("Operation cancelled.");
        emit splitOpChanged();
    }
}

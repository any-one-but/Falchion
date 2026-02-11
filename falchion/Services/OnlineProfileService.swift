import Foundation

actor OnlineProfileService {
    private let session: URLSession
    private let responsePreviewLimit = 18_000

    private let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "webp", "tiff", "tif", "bmp", "avif"]
    private let videoExtensions: Set<String> = ["mp4", "m4v", "mov", "wmv", "flv", "avi", "webm", "mkv"]

    private let deviantArtReservedRouteHeads: Set<String> = [
        "about", "art", "core", "daily-deviations", "dailydeviations", "deviations", "dreamup", "help", "join", "messages", "notifications", "settings", "shop", "submit", "watch"
    ]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func parseProfileURL(_ rawURL: String) throws -> OnlineProfileDescriptor {
        var raw = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            throw FileOperationError.invalidName
        }

        if raw.range(of: #"^[A-Za-z][A-Za-z0-9+.-]*:"#, options: .regularExpression) == nil {
            raw = "https://" + raw
        }

        guard let url = URL(string: raw), let host = url.host?.lowercased() else {
            throw FileOperationError.invalidName
        }

        if host == "reddit.com" || host.hasSuffix(".reddit.com") {
            let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
            if parts.count >= 2 {
                let head = parts[0].lowercased()
                if head == "user" || head == "u" {
                    let userID = decodePathPart(parts[1])
                    guard !userID.isEmpty else {
                        throw FileOperationError.invalidName
                    }

                    let origin = "https://www.reddit.com"
                    return OnlineProfileDescriptor(
                        service: .reddit,
                        userID: userID,
                        origin: origin,
                        sourceURL: "\(origin)/user/\(userID)",
                        profileKey: "reddit::\(userID)",
                        dataRoot: "\(origin)/data"
                    )
                }
            }

            throw FileOperationError.invalidName
        }

        if host == "deviantart.com" || host.hasSuffix(".deviantart.com") {
            var userID = ""
            if host.hasSuffix(".deviantart.com") && host != "www.deviantart.com" && host != "deviantart.com" && host != "backend.deviantart.com" {
                let subdomain = String(host.dropLast(".deviantart.com".count))
                if !subdomain.contains(".") {
                    userID = decodePathPart(subdomain)
                }
            }

            if userID.isEmpty, let queryValue = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "q" })?.value {
                let lowered = queryValue.lowercased()
                if lowered.hasPrefix("gallery:"), queryValue.count > 8 {
                    userID = String(queryValue.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            if userID.isEmpty && host != "backend.deviantart.com" {
                let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
                if let first = parts.first {
                    let candidate = decodePathPart(first).replacingOccurrences(of: "^@+", with: "", options: .regularExpression)
                    if !candidate.isEmpty && !deviantArtReservedRouteHeads.contains(candidate.lowercased()) {
                        userID = candidate
                    }
                }
            }

            guard !userID.isEmpty else {
                throw FileOperationError.invalidName
            }

            let origin = "https://www.deviantart.com"
            return OnlineProfileDescriptor(
                service: .deviantart,
                userID: userID,
                origin: origin,
                sourceURL: "\(origin)/\(userID)",
                profileKey: "deviantart::\(userID)",
                dataRoot: "\(origin)/data"
            )
        }

        let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard parts.count >= 3, parts[1].lowercased() == "user" else {
            throw FileOperationError.invalidName
        }

        let service = decodePathPart(parts[0]).lowercased()
        let userID = decodePathPart(parts[2])
        guard !service.isEmpty, !userID.isEmpty else {
            throw FileOperationError.invalidName
        }

        let origin = url.scheme.map { "\($0)://\(host)" } ?? "https://\(host)"
        return OnlineProfileDescriptor(
            service: .custom,
            userID: userID,
            origin: origin,
            sourceURL: "\(origin)/\(service)/user/\(userID)",
            profileKey: "\(service)::\(userID)",
            dataRoot: "\(origin)/data"
        )
    }

    func fetchPosts(for profile: OnlineProfileDescriptor, loadMode: OnlineLoadMode) async -> OnlineFetchResult {
        switch profile.service {
        case .reddit:
            return await fetchRedditPosts(profile: profile, loadMode: loadMode)
        case .deviantart:
            return await fetchDeviantArtPosts(profile: profile, loadMode: loadMode)
        case .custom:
            return await fetchCustomPosts(profile: profile, loadMode: loadMode)
        }
    }

    func importPosts(
        profile: OnlineProfileDescriptor,
        posts: [OnlinePost],
        mode: OnlineImportMode,
        into rootURL: URL,
        conflictPolicy: FileConflictPolicy
    ) async throws -> OnlineImportResult {
        let serviceSegment = sanitizeFolderComponent(profile.service.rawValue)
        let userSegment = sanitizeFolderComponent(profile.userID)

        let basePath: String
        switch mode {
        case .profile:
            basePath = ["Online Imports", serviceSegment, userSegment].joined(separator: "/")
        case .posts:
            basePath = ["Online Imports", serviceSegment, "posts", userSegment].joined(separator: "/")
        }

        let baseURL = rootURL.appendingPathComponent(basePath, isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        let sortedPosts = posts.sorted { lhs, rhs in
            let left = lhs.publishedAt ?? .distantPast
            let right = rhs.publishedAt ?? .distantPast
            if left != right {
                return left > right
            }
            return lhs.id.localizedCaseInsensitiveCompare(rhs.id) == .orderedAscending
        }

        var importedFiles = 0
        var importedPostCount = 0

        for (index, post) in sortedPosts.enumerated() {
            guard !post.media.isEmpty else {
                continue
            }

            let globalIndex = sortedPosts.count - index
            let postFolder = formattedPostFolderName(post: post, userID: profile.userID, globalIndex: globalIndex)
            let postURL = baseURL.appendingPathComponent(postFolder, isDirectory: true)
            try FileManager.default.createDirectory(at: postURL, withIntermediateDirectories: true)

            var importedForPost = 0
            for (mediaIndex, media) in post.media.enumerated() {
                guard let sourceURL = URL(string: media.url) else {
                    continue
                }

                let ext = inferExtension(from: sourceURL, isVideo: media.isVideo)
                let fileName = formattedFileName(post: post, userID: profile.userID, globalIndex: globalIndex, localIndex: mediaIndex + 1, ext: ext)
                let requestedURL = postURL.appendingPathComponent(fileName, isDirectory: false)
                let destinationURL = try resolveDestinationURL(requestedURL, policy: conflictPolicy)

                guard let (data, response) = try? await requestData(url: sourceURL, headers: ["User-Agent": "Mozilla/5.0 (compatible; Falchion/1.0)"]) else {
                    continue
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200...299).contains(statusCode), !data.isEmpty else {
                    continue
                }

                do {
                    try data.write(to: destinationURL, options: [.atomic])
                    importedFiles += 1
                    importedForPost += 1
                } catch {
                    continue
                }
            }

            if importedForPost > 0 {
                importedPostCount += 1
            }
        }

        return OnlineImportResult(importedFiles: importedFiles, importedPosts: importedPostCount, baseRelativePath: basePath)
    }

    private func fetchRedditPosts(profile: OnlineProfileDescriptor, loadMode: OnlineLoadMode) async -> OnlineFetchResult {
        let maxPages = loadMode == .preload ? 8 : 2
        let pageSize = 100
        var after: String?
        var posts: [OnlinePost] = []
        var responses: [OnlineResponseLogEntry] = []

        for page in 1...maxPages {
            var components = URLComponents(string: "\(normalizedOrigin(profile.origin))/user/\(profile.userID)/submitted.json")
            components?.queryItems = [
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "raw_json", value: "1")
            ]
            if let after {
                components?.queryItems?.append(URLQueryItem(name: "after", value: after))
            }

            guard let pageURL = components?.url else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "invalid_url")
            }

            let result = await fetchURL(pageURL, source: "reddit", page: page, headers: ["User-Agent": "Mozilla/5.0 (compatible; Falchion/1.0)"])
            responses.append(result.log)

            guard result.log.statusCode == 200 else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "http_\(result.log.statusCode)")
            }

            guard let payload = result.json as? [String: Any],
                  let data = payload["data"] as? [String: Any],
                  let children = data["children"] as? [[String: Any]] else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "invalid_json")
            }

            if children.isEmpty {
                break
            }

            for child in children {
                guard let postData = child["data"] as? [String: Any] else {
                    continue
                }

                let id = String(describing: postData["id"] ?? "reddit_\(page)_\(posts.count + 1)")
                let title = stringValue(postData["title"], fallback: "untitled")
                let user = stringValue(postData["author"], fallback: profile.userID)
                let publishedAt = (postData["created_utc"] as? Double).map { Date(timeIntervalSince1970: $0) }
                let media = collectRedditMedia(postData: postData, baseOrigin: profile.origin)
                if media.isEmpty {
                    continue
                }

                posts.append(OnlinePost(id: id, title: title, user: user, publishedAt: publishedAt, media: media))
            }

            if let next = data["after"] as? String, !next.isEmpty {
                after = next
            } else {
                break
            }

            if loadMode == .preload {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }

        return OnlineFetchResult(posts: dedupePosts(posts), responses: responses, errorCode: nil)
    }

    private func fetchDeviantArtPosts(profile: OnlineProfileDescriptor, loadMode: OnlineLoadMode) async -> OnlineFetchResult {
        let maxPages = loadMode == .preload ? 4 : 1
        let userEscaped = profile.userID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? profile.userID
        var pageURLString = "https://backend.deviantart.com/rss.xml?q=gallery:\(userEscaped)&type=deviation"

        var posts: [OnlinePost] = []
        var responses: [OnlineResponseLogEntry] = []

        for page in 1...maxPages {
            guard let pageURL = URL(string: pageURLString) else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "invalid_url")
            }

            let result = await fetchURL(pageURL, source: "deviantart", page: page, headers: ["User-Agent": "Mozilla/5.0 (compatible; Falchion/1.0)"])
            responses.append(result.log)

            guard result.log.statusCode == 200 else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "http_\(result.log.statusCode)")
            }

            guard let responseText = result.text else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "invalid_xml")
            }

            let parsed = parseDeviantArtRSS(responseText: responseText, defaultUser: profile.userID)
            posts.append(contentsOf: parsed.posts)

            guard let next = parsed.nextURL, !next.isEmpty else {
                break
            }

            pageURLString = next
            if loadMode == .preload {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }

        return OnlineFetchResult(posts: dedupePosts(posts), responses: responses, errorCode: nil)
    }

    private func fetchCustomPosts(profile: OnlineProfileDescriptor, loadMode: OnlineLoadMode) async -> OnlineFetchResult {
        let maxPages = loadMode == .preload ? 5 : 1
        let pageSize = 50
        var posts: [OnlinePost] = []
        var responses: [OnlineResponseLogEntry] = []

        let serviceID: String
        if let service = profile.profileKey.split(separator: "::").first {
            serviceID = String(service)
        } else {
            serviceID = "custom"
        }

        for page in 1...maxPages {
            let offset = (page - 1) * pageSize
            let endpoint = "\(normalizedOrigin(profile.origin))/api/v1/\(serviceID)/user/\(profile.userID)/posts?o=\(offset)"
            guard let pageURL = URL(string: endpoint) else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "invalid_url")
            }

            let result = await fetchURL(pageURL, source: "custom", page: page, headers: ["Accept": "application/json"])
            responses.append(result.log)

            guard result.log.statusCode == 200 else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "http_\(result.log.statusCode)")
            }

            guard let payload = result.json else {
                return OnlineFetchResult(posts: posts, responses: responses, errorCode: "invalid_json")
            }

            let rows: [[String: Any]]
            if let direct = payload as? [[String: Any]] {
                rows = direct
            } else if let object = payload as? [String: Any], let resultRows = object["results"] as? [[String: Any]] {
                rows = resultRows
            } else if let object = payload as? [String: Any], let postRows = object["posts"] as? [[String: Any]] {
                rows = postRows
            } else {
                rows = []
            }

            if rows.isEmpty {
                break
            }

            for (index, row) in rows.enumerated() {
                let id = stringValue(row["id"], fallback: "custom_\(page)_\(index + 1)")
                let title = stringValue(row["title"], fallback: "untitled")
                let user = stringValue(row["user"], fallback: profile.userID)
                let publishedAt = parseDateCandidate(row["published"] ?? row["created"] ?? row["created_at"])
                let media = collectCustomMedia(row: row, baseOrigin: profile.origin)
                if media.isEmpty {
                    continue
                }

                posts.append(OnlinePost(id: id, title: title, user: user, publishedAt: publishedAt, media: media))
            }

            if rows.count < pageSize {
                break
            }

            if loadMode == .preload {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        return OnlineFetchResult(posts: dedupePosts(posts), responses: responses, errorCode: nil)
    }

    private func fetchURL(_ url: URL, source: String, page: Int, headers: [String: String]) async -> (json: Any?, text: String?, log: OnlineResponseLogEntry) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await requestData(url: url, headers: headers)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseText = String(data: data, encoding: .utf8) ?? ""
            let trimmed = String(responseText.prefix(responsePreviewLimit))

            if let json = try? JSONSerialization.jsonObject(with: data) {
                let log = OnlineResponseLogEntry(
                    source: source,
                    url: url.absoluteString,
                    page: page,
                    statusCode: status,
                    parseOK: true,
                    error: "",
                    responsePreview: trimmed,
                    responseBytes: data.count,
                    truncated: responseText.count > responsePreviewLimit
                )
                return (json: json, text: responseText, log: log)
            }

            let log = OnlineResponseLogEntry(
                source: source,
                url: url.absoluteString,
                page: page,
                statusCode: status,
                parseOK: false,
                error: "invalid_json",
                responsePreview: trimmed,
                responseBytes: data.count,
                truncated: responseText.count > responsePreviewLimit
            )
            return (json: nil, text: responseText, log: log)
        } catch {
            let log = OnlineResponseLogEntry(
                source: source,
                url: url.absoluteString,
                page: page,
                statusCode: 0,
                parseOK: false,
                error: "network_error",
                responsePreview: "",
                responseBytes: 0,
                truncated: false
            )
            return (json: nil, text: nil, log: log)
        }
    }

    private func requestData(url: URL, headers: [String: String]) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await session.data(for: request)
    }

    private func parseDeviantArtRSS(responseText: String, defaultUser: String) -> (posts: [OnlinePost], nextURL: String?) {
        let itemPattern = "<item\\b[^>]*>([\\s\\S]*?)</item>"
        let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.caseInsensitive])
        let source = responseText as NSString
        let itemMatches = itemRegex?.matches(in: responseText, options: [], range: NSRange(location: 0, length: source.length)) ?? []

        var posts: [OnlinePost] = []

        for (index, match) in itemMatches.enumerated() {
            guard match.numberOfRanges > 1 else {
                continue
            }

            let block = source.substring(with: match.range(at: 1))
            let id = extractRSSValue("guid", in: block) ?? extractRSSValue("link", in: block) ?? "deviantart_\(index + 1)"
            let title = decodeHTML(extractRSSValue("title", in: block) ?? "untitled")
            let user = decodeHTML(extractRSSValue("dc:creator", in: block) ?? defaultUser)
            let publishedAt = parseDateCandidate(extractRSSValue("pubDate", in: block))

            var mediaURLs: [String] = []
            mediaURLs.append(contentsOf: extractAttributeURLs(pattern: "<(?:media:content|content|enclosure)\\b[^>]*\\burl=\"([^\"]+)\"", in: block))
            mediaURLs.append(contentsOf: extractAttributeURLs(pattern: "<img\\b[^>]*\\bsrc=\"([^\"]+)\"", in: block))

            if let link = extractRSSValue("link", in: block), urlLooksLikeMedia(link) {
                mediaURLs.append(link)
            }

            let media = dedupeMediaURLs(mediaURLs, baseOrigin: "https://www.deviantart.com")
            if media.isEmpty {
                continue
            }

            posts.append(OnlinePost(id: id, title: title, user: user, publishedAt: publishedAt, media: media))
        }

        let nextURL = extractNextRSSURL(responseText)
        return (posts, nextURL)
    }

    private func collectRedditMedia(postData: [String: Any], baseOrigin: String) -> [OnlinePostMedia] {
        var urls: [String] = []

        func add(_ raw: Any?) {
            guard let raw = raw else {
                return
            }
            if let value = raw as? String {
                urls.append(value)
            }
        }

        if let secureMedia = postData["secure_media"] as? [String: Any],
           let redditVideo = secureMedia["reddit_video"] as? [String: Any] {
            add(redditVideo["fallback_url"])
        }

        if let media = postData["media"] as? [String: Any],
           let redditVideo = media["reddit_video"] as? [String: Any] {
            add(redditVideo["fallback_url"])
        }

        if let preview = postData["preview"] as? [String: Any],
           let redditVideoPreview = preview["reddit_video_preview"] as? [String: Any] {
            add(redditVideoPreview["fallback_url"])
        }

        add(postData["url_overridden_by_dest"])
        add(postData["url"])

        if let preview = postData["preview"] as? [String: Any],
           let images = preview["images"] as? [[String: Any]] {
            for image in images {
                if let source = image["source"] as? [String: Any] {
                    add(source["url"])
                }

                if let resolutions = image["resolutions"] as? [[String: Any]] {
                    for resolution in resolutions {
                        add(resolution["url"])
                    }
                }
            }
        }

        if let galleryData = postData["gallery_data"] as? [String: Any],
           let items = galleryData["items"] as? [[String: Any]],
           let metadata = postData["media_metadata"] as? [String: Any] {
            for item in items {
                guard let mediaID = item["media_id"] as? String,
                      let mediaEntry = metadata[mediaID] as? [String: Any] else {
                    continue
                }

                if let source = mediaEntry["s"] as? [String: Any] {
                    add(source["u"])
                }

                if let previews = mediaEntry["p"] as? [[String: Any]] {
                    for preview in previews {
                        add(preview["u"])
                    }
                }
            }
        }

        return dedupeMediaURLs(urls, baseOrigin: baseOrigin)
    }

    private func collectCustomMedia(row: [String: Any], baseOrigin: String) -> [OnlinePostMedia] {
        var urls: [String] = []

        func addURL(_ raw: Any?) {
            guard let raw = raw else {
                return
            }

            if let value = raw as? String {
                urls.append(value)
                return
            }

            if let object = raw as? [String: Any] {
                if let url = object["url"] as? String {
                    urls.append(url)
                }
                if let path = object["path"] as? String {
                    urls.append(path)
                }
            }
        }

        if let pgFiles = row["pgFiles"] as? [[String: Any]] {
            for file in pgFiles {
                addURL(file)
            }
        }

        addURL(row["file"])

        if let attachments = row["attachments"] as? [Any] {
            for attachment in attachments {
                addURL(attachment)
            }
        }

        return dedupeMediaURLs(urls, baseOrigin: baseOrigin)
    }

    private func dedupeMediaURLs(_ rawURLs: [String], baseOrigin: String) -> [OnlinePostMedia] {
        var seen: Set<String> = []
        var out: [OnlinePostMedia] = []

        for raw in rawURLs {
            guard let normalized = normalizeAbsoluteURL(raw, baseOrigin: baseOrigin) else {
                continue
            }

            var candidate = normalized
            if candidate.lowercased().contains(".gifv") {
                candidate = candidate.replacingOccurrences(of: ".gifv", with: ".mp4", options: [.caseInsensitive])
            }

            guard urlLooksLikeMedia(candidate) else {
                continue
            }

            let dedupeKey = normalizeURLForDedupe(candidate)
            if seen.contains(dedupeKey) {
                continue
            }
            seen.insert(dedupeKey)

            out.append(OnlinePostMedia(url: candidate, isVideo: looksVideo(candidate)))
        }

        return out
    }

    private func dedupePosts(_ posts: [OnlinePost]) -> [OnlinePost] {
        var seen: Set<String> = []
        var out: [OnlinePost] = []

        for post in posts {
            let key = post.id.lowercased()
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            out.append(post)
        }

        return out
    }

    private func resolveDestinationURL(_ requestedURL: URL, policy: FileConflictPolicy) throws -> URL {
        let manager = FileManager.default
        guard manager.fileExists(atPath: requestedURL.path) else {
            return requestedURL
        }

        switch policy {
        case .abort:
            throw FileOperationError.conflict(requestedURL.lastPathComponent)
        case .replace:
            try manager.removeItem(at: requestedURL)
            return requestedURL
        case .keepBoth:
            return uniqueDestinationURL(for: requestedURL)
        }
    }

    private func uniqueDestinationURL(for originalURL: URL) -> URL {
        let manager = FileManager.default
        let directory = originalURL.deletingLastPathComponent()
        let name = originalURL.deletingPathExtension().lastPathComponent
        let ext = originalURL.pathExtension

        var idx = 1
        while true {
            let suffix = idx == 1 ? " copy" : " copy \(idx)"
            let candidateName: String
            if ext.isEmpty {
                candidateName = "\(name)\(suffix)"
            } else {
                candidateName = "\(name)\(suffix).\(ext)"
            }

            let candidate = directory.appendingPathComponent(candidateName, isDirectory: false)
            if !manager.fileExists(atPath: candidate.path) {
                return candidate
            }

            idx += 1
        }
    }

    private func formattedPostFolderName(post: OnlinePost, userID: String, globalIndex: Int) -> String {
        let dateSegment = dateSegmentFromPost(post)
        let userSegment = sanitizeNameComponent(userID, limit: 40)
        let titleSegment = sanitizeNameComponent(post.title, limit: 40)
        let indexSegment = String(format: "%06d", globalIndex)
        return "\(dateSegment)-\(userSegment)-\(indexSegment) - \(titleSegment)"
    }

    private func formattedFileName(post: OnlinePost, userID: String, globalIndex: Int, localIndex: Int, ext: String) -> String {
        let dateSegment = dateSegmentFromPost(post)
        let userSegment = sanitizeNameComponent(userID, limit: 40)
        let titleSegment = sanitizeNameComponent(post.title, limit: 40)
        let indexSegment = String(format: "%06d", globalIndex)
        let localSegment = String(format: "%06d", localIndex)
        return "\(dateSegment)-\(userSegment)-\(indexSegment) - \(titleSegment)_\(localSegment).\(ext)"
    }

    private func dateSegmentFromPost(_ post: OnlinePost) -> String {
        guard let date = post.publishedAt else {
            return "000000"
        }

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0) ?? .gmt, from: date)
        let year = (components.year ?? 0) % 100
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%02d%02d%02d", year, month, day)
    }

    private func inferExtension(from url: URL, isVideo: Bool) -> String {
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) || videoExtensions.contains(ext) {
            return ext
        }

        return isVideo ? "mp4" : "jpg"
    }

    private func sanitizeFolderComponent(_ value: String) -> String {
        sanitizeNameComponent(value, limit: 64).replacingOccurrences(of: " ", with: "_")
    }

    private func sanitizeNameComponent(_ value: String, limit: Int) -> String {
        var out = value.precomposedStringWithCanonicalMapping
        out = out.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: "[\\\\/:*?\"<>|]+", with: "", options: .regularExpression)
        out = out.replacingOccurrences(of: "[\\u0000-\\u001F\\u007F]", with: "", options: .regularExpression)
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)

        if out.isEmpty {
            return "untitled"
        }

        if out.count > limit {
            out = String(out.prefix(limit))
        }

        return out
    }

    private func normalizeAbsoluteURL(_ raw: String, baseOrigin: String) -> String? {
        let decoded = decodeHTML(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !decoded.isEmpty else {
            return nil
        }

        var candidate = decoded
        if candidate.hasPrefix("//") {
            candidate = "https:" + candidate
        }

        if let direct = URL(string: candidate), direct.scheme != nil {
            return direct.absoluteString
        }

        if let relative = URL(string: candidate, relativeTo: URL(string: baseOrigin))?.absoluteURL {
            return relative.absoluteString
        }

        return nil
    }

    private func normalizeURLForDedupe(_ url: String) -> String {
        guard let parsed = URL(string: url) else {
            return url.lowercased()
        }

        let path = parsed.path.lowercased()
        if let range = path.range(of: "/data/") {
            return String(path[range.lowerBound...])
        }

        return (path + "?" + (parsed.query ?? "")).lowercased()
    }

    private func looksVideo(_ rawURL: String) -> Bool {
        let lower = rawURL.lowercased().split(separator: "?").first.map(String.init) ?? rawURL.lowercased()
        if lower.hasSuffix(".gifv") {
            return true
        }

        let ext = URL(string: lower)?.pathExtension.lowercased() ?? ""
        return videoExtensions.contains(ext)
    }

    private func urlLooksLikeMedia(_ rawURL: String) -> Bool {
        let lower = rawURL.lowercased().split(separator: "?").first.map(String.init) ?? rawURL.lowercased()
        let ext = URL(string: lower)?.pathExtension.lowercased() ?? ""
        if imageExtensions.contains(ext) || videoExtensions.contains(ext) {
            return true
        }

        return lower.hasSuffix(".gifv")
    }

    private func extractRSSValue(_ tagName: String, in block: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: tagName)
        let pattern = "<\(escaped)\\b[^>]*>([\\s\\S]*?)</\(escaped)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let nsBlock = block as NSString
        let range = NSRange(location: 0, length: nsBlock.length)
        guard let match = regex.firstMatch(in: block, options: [], range: range), match.numberOfRanges > 1 else {
            return nil
        }

        return nsBlock.substring(with: match.range(at: 1))
    }

    private func extractAttributeURLs(pattern: String, in block: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let nsBlock = block as NSString
        let range = NSRange(location: 0, length: nsBlock.length)
        let matches = regex.matches(in: block, options: [], range: range)
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else {
                return nil
            }
            return nsBlock.substring(with: match.range(at: 1))
        }
    }

    private func extractNextRSSURL(_ responseText: String) -> String? {
        let pattern = "<atom:link\\b[^>]*\\brel=\"next\"[^>]*\\bhref=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let nsText = responseText as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: responseText, options: [], range: range), match.numberOfRanges > 1 else {
            return nil
        }

        return nsText.substring(with: match.range(at: 1))
    }

    private func parseDateCandidate(_ value: Any?) -> Date? {
        if let number = value as? Double {
            let seconds = number > 1_000_000_000_000 ? number / 1000 : number
            return Date(timeIntervalSince1970: seconds)
        }

        if let number = value as? Int {
            let doubleValue = Double(number)
            let seconds = doubleValue > 1_000_000_000_000 ? doubleValue / 1000 : doubleValue
            return Date(timeIntervalSince1970: seconds)
        }

        guard let raw = value as? String, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) {
            return date
        }

        let rfc = DateFormatter()
        rfc.locale = Locale(identifier: "en_US_POSIX")
        rfc.timeZone = TimeZone(secondsFromGMT: 0)
        rfc.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = rfc.date(from: raw) {
            return date
        }

        let plain = DateFormatter()
        plain.locale = Locale(identifier: "en_US_POSIX")
        plain.timeZone = TimeZone(secondsFromGMT: 0)
        plain.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return plain.date(from: raw)
    }

    private func stringValue(_ value: Any?, fallback: String) -> String {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return decodeHTML(trimmed)
            }
        }

        return fallback
    }

    private func normalizedOrigin(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }

    private func decodePathPart(_ raw: String) -> String {
        raw.removingPercentEncoding?.trimmingCharacters(in: .whitespacesAndNewlines) ?? raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeHTML(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#x2F;", with: "/")
    }
}

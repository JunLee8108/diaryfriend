//
//  ImageCache.swift
//  DiaryFriend
//
//  성능 최적화 및 디버깅 기능이 포함된 이미지 캐시 시스템
//

import UIKit
import SwiftUI
import CryptoKit

// MARK: - Image Cache Actor
@globalActor
actor ImageCacheActor {
    static let shared = ImageCacheActor()
}

// MARK: - Main Image Cache
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    
    // 디버깅 플래그
    static var debugMode = true
    
    // MARK: - Properties
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let downloader: ImageDownloader
    private let prefetcher: ImagePrefetcher
    private let stats = CacheStats()
    
    // 진행 중인 다운로드 추적 (중복 요청 방지)
    private let downloadTasks = TaskManager<String, UIImage?>()
    
    // MARK: - Initialization
    private init() {
        // 메모리 캐시 설정
        memoryCache.totalCostLimit = 50_000_000 // 50MB
        memoryCache.countLimit = 100
        
        // 컴포넌트 초기화
        self.diskCache = DiskCache()
        self.downloader = ImageDownloader()
        self.prefetcher = ImagePrefetcher()
        
        // 메모리 경고 처리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        if Self.debugMode {
            Logger.debug("🚀 ImageCache initialized with 50MB memory limit")
        }
    }
    
    // MARK: - Public Methods
    
    /// 이미지 가져오기 (캐시 우선, 없으면 다운로드)
    func image(for urlString: String) async -> UIImage? {
        let cacheKey = NSString(string: urlString)
        
        // 1. 메모리 캐시 체크 (가장 빠름)
        if let cached = memoryCache.object(forKey: cacheKey) {
            if Self.debugMode {
                Logger.debug("🎯 [Cache Hit - Memory] \(urlString.suffix(50))")
                await stats.recordMemoryHit()
            }
            return cached
        }
        
        // 2. 진행 중인 다운로드가 있으면 대기
        if let existingTask = await downloadTasks.getTask(for: urlString) {
            if Self.debugMode {
                Logger.debug("⏳ [Waiting for existing download] \(urlString.suffix(50))")
                await stats.recordWaitingDownload()
            }
            return await existingTask.value
        }
        
        // 3. 새로운 다운로드 태스크 시작
        let task = Task<UIImage?, Never> {
            await loadImage(urlString: urlString, cacheKey: cacheKey)
        }
        
        await downloadTasks.setTask(task, for: urlString)
        let image = await task.value
        await downloadTasks.removeTask(for: urlString)
        
        return image
    }
    
    /// 이미지 프리페치 (백그라운드에서 미리 로드)
    func prefetch(urls: [String]) {
        if Self.debugMode && !urls.isEmpty {
            Logger.debug("📦 [Prefetch] Starting prefetch for \(urls.count) images")
        }
        
        Task {
            await prefetcher.prefetch(urls: urls, using: self)
        }
    }
    
    /// 특정 URL의 캐시 제거
    func removeImage(for urlString: String) async {
        let cacheKey = NSString(string: urlString)
        memoryCache.removeObject(forKey: cacheKey)
        await diskCache.removeImage(for: urlString)
        
        if Self.debugMode {
            Logger.debug("🗑 [Cache Remove] \(urlString.suffix(50))")
        }
    }
    
    /// 전체 캐시 클리어
    func clearCache() async {
        memoryCache.removeAllObjects()
        await diskCache.clearAll()
        
        if Self.debugMode {
            Logger.debug("🧹 ImageCache: 모든 이미지 데이터 (메모리 + 디스크) 초기화 완료")
            await stats.reset()
        }
    }
    
    /// 메모리 캐시만 클리어 (테스트용)
    func clearMemoryCache() async {
        await MainActor.run {
            memoryCache.removeAllObjects()
        }
        
        if Self.debugMode {
            Logger.debug("🧹 [Memory Clear] Memory cache cleared")
        }
    }
    
    /// 캐시 크기 가져오기
    func cacheSize() async -> Int64 {
        await diskCache.totalSize()
    }
    
    /// 캐시 통계 출력
    func printStats() async {
        await stats.printReport()
    }
    
    /// 캐시 통계 리셋
    func resetStats() async {
        await stats.reset()
        if Self.debugMode {
            print("📊 [Stats Reset] Statistics have been reset")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadImage(urlString: String, cacheKey: NSString) async -> UIImage? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 2. 디스크 캐시 체크 (비동기)
        if let diskImage = await diskCache.image(for: urlString) {
            let loadTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            if Self.debugMode {
                Logger.debug("💾 [Cache Hit - Disk] \(urlString.suffix(50)) (\(String(format: "%.1f", loadTime))ms)")
                await stats.recordDiskHit(loadTime: loadTime)
            }
            
            // 메모리 캐시에 저장
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // 3. 네트워크 다운로드
        if Self.debugMode {
            Logger.debug("🌐 [Network Download] Starting: \(urlString.suffix(50))")
        }
        
        guard let downloadedImage = await downloader.download(urlString: urlString) else {
            if Self.debugMode {
                Logger.debug("❌ [Download Failed] \(urlString.suffix(50))")
                await stats.recordFailure()
            }
            return nil
        }
        
        let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        if Self.debugMode {
            Logger.debug("✅ [Download Success] \(urlString.suffix(50)) (\(String(format: "%.1f", totalTime))ms)")
            await stats.recordNetworkDownload(loadTime: totalTime)
        }
        
        // 캐시에 저장
        memoryCache.setObject(downloadedImage, forKey: cacheKey)
        
        // 디스크 저장 (백그라운드, 화재망각)
        Task.detached { [weak diskCache] in
            await diskCache?.store(downloadedImage, for: urlString)
        }
        
        return downloadedImage
    }
    
    @objc private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
        if Self.debugMode {
            Logger.debug("⚠️ [Memory Warning] Cache cleared due to memory pressure")
        }
    }
}

// MARK: - Disk Cache
private actor DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectoryURL: URL
    private let ioQueue = DispatchQueue(label: "com.diaryfriend.diskcache", attributes: .concurrent)
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheURL = paths[0].appendingPathComponent("ImageCache")
        
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
        
        self.cacheDirectoryURL = cacheURL
        
        // 오래된 캐시 정리 (30일)
        Task {
            await cleanExpiredCache()
        }
    }
    
    func image(for urlString: String) async -> UIImage? {
        let fileName = urlString.toSafeFileName()
        let fileURL = cacheDirectoryURL.appendingPathComponent(fileName)
        
        return await withCheckedContinuation { continuation in
            ioQueue.async {
                guard let data = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    func store(_ image: UIImage, for urlString: String) async {
        let fileName = urlString.toSafeFileName()
        let fileURL = cacheDirectoryURL.appendingPathComponent(fileName)
        
        await withCheckedContinuation { continuation in
            ioQueue.async(flags: .barrier) {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    try? data.write(to: fileURL, options: .atomic)
                }
                continuation.resume()
            }
        }
    }
    
    func removeImage(for urlString: String) async {
        let fileName = urlString.toSafeFileName()
        let fileURL = cacheDirectoryURL.appendingPathComponent(fileName)
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearAll() async {
        try? fileManager.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: nil)
            .forEach { try? fileManager.removeItem(at: $0) }
    }
    
    func totalSize() async -> Int64 {
        let contents = (try? fileManager.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        
        return contents.reduce(0) { total, fileURL in
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
    
    private func cleanExpiredCache() async {
        let expirationDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30일
        var removedCount = 0
        
        let contents = (try? fileManager.contentsOfDirectory(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []
        
        for fileURL in contents {
            if let modificationDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
               modificationDate < expirationDate {
                try? fileManager.removeItem(at: fileURL)
                removedCount += 1
            }
        }
        
        if ImageCache.debugMode && removedCount > 0 {
            Logger.debug("🧹 [Cache Clean] Removed \(removedCount) expired cache files")
        }
    }
}

// MARK: - Image Downloader
private actor ImageDownloader {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 5
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.urlCache = URLCache(
            memoryCapacity: 10_000_000,  // 10MB
            diskCapacity: 50_000_000,     // 50MB
            diskPath: "image_url_cache"
        )
        
        self.session = URLSession(configuration: config)
    }
    
    func download(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // 응답 검증
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            // 이미지 생성 및 최적화
            guard let image = UIImage(data: data) else { return nil }
            
            // 큰 이미지는 리사이징
            if image.size.width > 1024 || image.size.height > 1024 {
                return await image.resized(toMaxDimension: 1024)
            }
            
            return image
        } catch {
            if ImageCache.debugMode {
                Logger.debug("🔥 Download error: \(error.localizedDescription)")
            }
            return nil
        }
    }
}

// MARK: - Image Prefetcher
private actor ImagePrefetcher {
    private var prefetchTasks: Set<String> = []
    
    func prefetch(urls: [String], using cache: ImageCache) async {
        // 이미 프리페칭 중인 URL 제외
        let urlsToFetch = urls.filter { !prefetchTasks.contains($0) }
        
        guard !urlsToFetch.isEmpty else { return }
        
        // 프리페칭 시작
        urlsToFetch.forEach { prefetchTasks.insert($0) }
        
        await withTaskGroup(of: Void.self) { group in
            for url in urlsToFetch.prefix(10) { // 최대 10개씩 동시 처리
                group.addTask { [weak self] in
                    _ = await cache.image(for: url)
                    await self?.removePrefetchTask(url)
                }
            }
        }
        
        if ImageCache.debugMode {
            Logger.debug("📦 [Prefetch Complete] \(urlsToFetch.count) images prefetched")
        }
    }
    
    private func removePrefetchTask(_ url: String) {
        prefetchTasks.remove(url)
    }
}

// MARK: - Task Manager (중복 요청 방지)
private actor TaskManager<Key: Hashable, Value> {
    private var tasks: [Key: Task<Value, Never>] = [:]
    
    func getTask(for key: Key) -> Task<Value, Never>? {
        return tasks[key]
    }
    
    func setTask(_ task: Task<Value, Never>, for key: Key) {
        tasks[key] = task
    }
    
    func removeTask(for key: Key) {
        tasks[key] = nil
    }
}

// MARK: - Cache Statistics
private actor CacheStats {
    private var memoryHits = 0
    private var diskHits = 0
    private var networkDownloads = 0
    private var failures = 0
    private var waitingDownloads = 0
    private var totalMemoryTime: Double = 0
    private var totalDiskTime: Double = 0
    private var totalNetworkTime: Double = 0
    private var startTime = Date()
    
    func recordMemoryHit() {
        memoryHits += 1
    }
    
    func recordDiskHit(loadTime: Double) {
        diskHits += 1
        totalDiskTime += loadTime
    }
    
    func recordNetworkDownload(loadTime: Double) {
        networkDownloads += 1
        totalNetworkTime += loadTime
    }
    
    func recordFailure() {
        failures += 1
    }
    
    func recordWaitingDownload() {
        waitingDownloads += 1
    }
    
    func printReport() {
        let total = memoryHits + diskHits + networkDownloads
        guard total > 0 else {
            print("📊 No cache operations recorded yet")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let hitRate = percentage(memoryHits + diskHits, of: total)
        
        print("""
        
        ╔════════════════════════════════════════╗
        ║       📊 CACHE STATISTICS REPORT       ║
        ╠════════════════════════════════════════╣
        ║ ⏱  Duration: \(String(format: "%6.1f", duration))s                ║
        ╠════════════════════════════════════════╣
        ║ 🎯 Memory Hits:    \(String(format: "%4d", memoryHits)) (\(String(format: "%3d", percentage(memoryHits, of: total)))%)        ║
        ║ 💾 Disk Hits:      \(String(format: "%4d", diskHits)) (\(String(format: "%3d", percentage(diskHits, of: total)))%)        ║
        ║ 🌐 Network:        \(String(format: "%4d", networkDownloads)) (\(String(format: "%3d", percentage(networkDownloads, of: total)))%)        ║
        ║ ⏳ Wait for DL:    \(String(format: "%4d", waitingDownloads))                ║
        ║ ❌ Failures:       \(String(format: "%4d", failures))                ║
        ╠════════════════════════════════════════╣
        ║ 📈 Cache Hit Rate:  \(String(format: "%3d", hitRate))%               ║
        ║ 🔢 Total Ops:      \(String(format: "%4d", total))                ║
        ╠════════════════════════════════════════╣
        ║ ⚡ Avg Load Times:                     ║
        ║   Memory:     < 0.1ms                  ║
        ║   Disk:       \(avgTime(totalDiskTime, count: diskHits))             ║
        ║   Network:    \(avgTime(totalNetworkTime, count: networkDownloads))             ║
        ╚════════════════════════════════════════╝
        
        """)
    }
    
    func reset() {
        memoryHits = 0
        diskHits = 0
        networkDownloads = 0
        failures = 0
        waitingDownloads = 0
        totalMemoryTime = 0
        totalDiskTime = 0
        totalNetworkTime = 0
        startTime = Date()
    }
    
    private func percentage(_ value: Int, of total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(value) / Double(total)) * 100)
    }
    
    private func avgTime(_ total: Double, count: Int) -> String {
        guard count > 0 else { return "N/A     " }
        let avg = total / Double(count)
        return String(format: "%6.1fms", avg)
    }
}

// MARK: - String Extension
private extension String {
    func toSafeFileName() -> String {
        // SHA256 해시 사용 (더 안전하고 일관된 파일명)
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        return "\(hashString).jpg"
    }
}

// MARK: - UIImage Extension
private extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) async -> UIImage {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let ratio = min(maxDimension / self.size.width, maxDimension / self.size.height)
                
                guard ratio < 1 else {
                    continuation.resume(returning: self)
                    return
                }
                
                let newSize = CGSize(
                    width: self.size.width * ratio,
                    height: self.size.height * ratio
                )
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                self.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
                UIGraphicsEndImageContext()
                
                continuation.resume(returning: resizedImage)
            }
        }
    }
}

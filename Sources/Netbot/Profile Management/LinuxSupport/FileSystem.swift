//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.OperationQueue
  import struct Foundation.URLResourceKey
  import Synchronization

  struct NSFileVersion {}

  protocol NSFilePresenter {

    var presentedItemURL: URL? { get }

    var presentedItemOperationQueue: OperationQueue { get }

    var primaryPresentedItemURL: URL? { get }

    func relinquishPresentedItem(
      toReader reader: @escaping @Sendable ((@Sendable () -> Void)?) -> Void)

    func relinquishPresentedItem(
      toWriter writer: @escaping @Sendable ((@Sendable () -> Void)?) -> Void)

    func savePresentedItemChanges(completionHandler: @escaping @Sendable ((any Error)?) -> Void)

    func savePresentedItemChanges() async throws

    func accommodatePresentedItemDeletion(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void)

    func accommodatePresentedItemDeletion() async throws

    func accommodatePresentedItemEviction(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void)

    func accommodatePresentedItemEviction() async throws

    func presentedItemDidMove(to newURL: URL)

    func presentedItemDidChange()

    func presentedItemDidChangeUbiquityAttributes(_ attributes: Set<URLResourceKey>)

    var observedPresentedItemUbiquityAttributes: Set<URLResourceKey> { get }

    func presentedItemDidGain(_ version: NSFileVersion)

    func presentedItemDidLose(_ version: NSFileVersion)

    func presentedItemDidResolveConflict(_ version: NSFileVersion)

    func accommodatePresentedSubitemDeletion(
      at url: URL, completionHandler: @escaping @Sendable ((any Error)?) -> Void)

    func accommodatePresentedSubitemDeletion(at url: URL) async throws

    func presentedSubitemDidAppear(at url: URL)

    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL)

    func presentedSubitemDidChange(at url: URL)

    func presentedSubitem(at url: URL, didGain version: NSFileVersion)

    func presentedSubitem(at url: URL, didLose version: NSFileVersion)

    func presentedSubitem(at url: URL, didResolve version: NSFileVersion)
  }

  extension NSFilePresenter {

    var primaryPresentedItemURL: URL? { nil }

    func relinquishPresentedItem(
      toReader reader: @escaping @Sendable ((@Sendable () -> Void)?) -> Void
    ) {
      reader(nil)
    }

    func relinquishPresentedItem(
      toWriter writer: @escaping @Sendable ((@Sendable () -> Void)?) -> Void
    ) {
      writer(nil)
    }

    func savePresentedItemChanges(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    func savePresentedItemChanges() async throws {}

    func accommodatePresentedItemDeletion(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    func accommodatePresentedItemDeletion() async throws {}

    func accommodatePresentedItemEviction(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    func accommodatePresentedItemEviction() async throws {}

    func presentedItemDidMove(to newURL: URL) {}

    func presentedItemDidChange() {}

    func presentedItemDidChangeUbiquityAttributes(_ attributes: Set<URLResourceKey>) {}

    var observedPresentedItemUbiquityAttributes: Set<URLResourceKey> { [] }

    func presentedItemDidGain(_ version: NSFileVersion) {}

    func presentedItemDidLose(_ version: NSFileVersion) {}

    func presentedItemDidResolveConflict(_ version: NSFileVersion) {}

    func accommodatePresentedSubitemDeletion(
      at url: URL, completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    func accommodatePresentedSubitemDeletion(at url: URL) async throws {}

    func presentedSubitemDidAppear(at url: URL) {}

    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {}

    func presentedSubitemDidChange(at url: URL) {}

    func presentedSubitem(at url: URL, didGain version: NSFileVersion) {}

    func presentedSubitem(at url: URL, didLose version: NSFileVersion) {}

    func presentedSubitem(at url: URL, didResolve version: NSFileVersion) {}
  }

  extension NSFileCoordinator {

    struct ReadingOptions: OptionSet, Sendable {

      var rawValue: UInt

      static var withoutChanges: NSFileCoordinator.ReadingOptions { .init(rawValue: 0) }

      static var resolvesSymbolicLink: NSFileCoordinator.ReadingOptions {
        .init(rawValue: 0)
      }

      static var immediatelyAvailableMetadataOnly: NSFileCoordinator.ReadingOptions {
        .init(rawValue: 0)
      }

      static var forUploading: NSFileCoordinator.ReadingOptions { .init(rawValue: 0) }
    }

    struct WritingOptions: OptionSet, Sendable {

      var rawValue: UInt

      static var forDeleting: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      static var forMoving: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      static var forMerging: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      static var forReplacing: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      static var contentIndependentMetadataOnly: NSFileCoordinator.WritingOptions {
        .init(rawValue: 0)
      }
    }
  }

  class NSFileAccessIntent: @unchecked Sendable {

    class func readingIntent(with url: URL, options: NSFileCoordinator.ReadingOptions = [])
      -> NSFileAccessIntent
    {
      NSFileAccessIntent(url: url)
    }

    class func writingIntent(with url: URL, options: NSFileCoordinator.WritingOptions = [])
      -> NSFileAccessIntent
    {
      NSFileAccessIntent(url: url)
    }

    var url: URL { _url.withLock { $0 } }
    private let _url: Synchronization.Mutex<URL>
    init(url: URL) {
      self._url = .init(url)
    }
  }

  class NSFileCoordinator {

    class func addFilePresenter(_ filePresenter: any NSFilePresenter) {}

    class func removeFilePresenter(_ filePresenter: any NSFilePresenter) {}

    class var filePresenters: [any NSFilePresenter] { [] }

    init(filePresenter filePresenterOrNil: (any NSFilePresenter)?) {}

    var purposeIdentifier: String = ""

    func coordinate(
      with intents: [NSFileAccessIntent], queue: OperationQueue,
      byAccessor accessor: @escaping @Sendable ((any Error)?) -> Void
    ) {
      accessor(nil)
    }

    func coordinate(
      readingItemAt url: URL, options: NSFileCoordinator.ReadingOptions = [],
      error outError: NSErrorPointer, byAccessor reader: (URL) -> Void
    ) {
      reader(url)
    }

    func coordinate(
      writingItemAt url: URL, options: NSFileCoordinator.WritingOptions = [],
      error outError: NSErrorPointer, byAccessor writer: (URL) -> Void
    ) {
      writer(url)
    }

    func coordinate(
      readingItemAt readingURL: URL, options readingOptions: NSFileCoordinator.ReadingOptions = [],
      writingItemAt writingURL: URL, options writingOptions: NSFileCoordinator.WritingOptions = [],
      error outError: NSErrorPointer, byAccessor readerWriter: (URL, URL) -> Void
    ) {
      readerWriter(readingURL, writingURL)
    }

    func coordinate(
      writingItemAt url1: URL, options options1: NSFileCoordinator.WritingOptions = [],
      writingItemAt url2: URL, options options2: NSFileCoordinator.WritingOptions = [],
      error outError: NSErrorPointer, byAccessor writer: (URL, URL) -> Void
    ) {
      writer(url1, url2)
    }

    func prepare(
      forReadingItemsAt readingURLs: [URL],
      options readingOptions: NSFileCoordinator.ReadingOptions = [],
      writingItemsAt writingURLs: [URL],
      options writingOptions: NSFileCoordinator.WritingOptions = [], error outError: NSErrorPointer,
      byAccessor batchAccessor: (@escaping @Sendable () -> Void) -> Void
    ) {
      batchAccessor({})
    }

    func item(at oldURL: URL, willMoveTo newURL: URL) {}

    func item(at oldURL: URL, didMoveTo newURL: URL) {}

    func item(at url: URL, didChangeUbiquityAttributes attributes: Set<URLResourceKey>) {}

    func cancel() {}
  }

  @available(*, unavailable)
  extension NSFileCoordinator: @unchecked Sendable {
  }

  //typealias NSErrorPointer = AutoreleasingUnsafeMutablePointer<NSError?>?
  struct NSErrorPointer {}

//  extension URLResourceKey: @retroactive Hashable {
//
//    public static func == (lhs: URLResourceKey, rhs: URLResourceKey) -> Bool {
//      true
//    }
//
//    public func hash(into hasher: inout Hasher) {
//
//    }
//  }
#endif

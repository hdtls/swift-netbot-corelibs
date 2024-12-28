//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
  private import Synchronization

  public struct NSFileVersion {}

  public protocol NSFilePresenter {

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

    public var primaryPresentedItemURL: URL? { nil }

    public func relinquishPresentedItem(
      toReader reader: @escaping @Sendable ((@Sendable () -> Void)?) -> Void
    ) {
      reader(nil)
    }

    public func relinquishPresentedItem(
      toWriter writer: @escaping @Sendable ((@Sendable () -> Void)?) -> Void
    ) {
      writer(nil)
    }

    public func savePresentedItemChanges(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    public func savePresentedItemChanges() async throws {}

    public func accommodatePresentedItemDeletion(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    public func accommodatePresentedItemDeletion() async throws {}

    public func accommodatePresentedItemEviction(
      completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    public func accommodatePresentedItemEviction() async throws {}

    public func presentedItemDidMove(to newURL: URL) {}

    public func presentedItemDidChange() {}

    public func presentedItemDidChangeUbiquityAttributes(_ attributes: Set<URLResourceKey>) {}

    public var observedPresentedItemUbiquityAttributes: Set<URLResourceKey> { [] }

    public func presentedItemDidGain(_ version: NSFileVersion) {}

    public func presentedItemDidLose(_ version: NSFileVersion) {}

    public func presentedItemDidResolveConflict(_ version: NSFileVersion) {}

    public func accommodatePresentedSubitemDeletion(
      at url: URL, completionHandler: @escaping @Sendable ((any Error)?) -> Void
    ) {
      completionHandler(nil)
    }

    public func accommodatePresentedSubitemDeletion(at url: URL) async throws {}

    public func presentedSubitemDidAppear(at url: URL) {}

    public func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {}

    public func presentedSubitemDidChange(at url: URL) {}

    public func presentedSubitem(at url: URL, didGain version: NSFileVersion) {}

    public func presentedSubitem(at url: URL, didLose version: NSFileVersion) {}

    public func presentedSubitem(at url: URL, didResolve version: NSFileVersion) {}
  }

  extension NSFileCoordinator {

    public struct ReadingOptions: OptionSet, Sendable {

      public var rawValue: UInt
      public init(rawValue: UInt) {
        self.rawValue = rawValue
      }

      public static var withoutChanges: NSFileCoordinator.ReadingOptions { .init(rawValue: 0) }

      public static var resolvesSymbolicLink: NSFileCoordinator.ReadingOptions {
        .init(rawValue: 0)
      }

      public static var immediatelyAvailableMetadataOnly: NSFileCoordinator.ReadingOptions {
        .init(rawValue: 0)
      }

      public static var forUploading: NSFileCoordinator.ReadingOptions { .init(rawValue: 0) }
    }

    public struct WritingOptions: OptionSet, Sendable {

      public var rawValue: UInt
      public init(rawValue: UInt) {
        self.rawValue = rawValue
      }

      public static var forDeleting: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      public static var forMoving: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      public static var forMerging: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      public static var forReplacing: NSFileCoordinator.WritingOptions { .init(rawValue: 0) }

      public static var contentIndependentMetadataOnly: NSFileCoordinator.WritingOptions {
        .init(rawValue: 0)
      }
    }
  }

  open class NSFileAccessIntent: @unchecked Sendable {

    open class func readingIntent(with url: URL, options: NSFileCoordinator.ReadingOptions = [])
      -> NSFileAccessIntent
    {
      NSFileAccessIntent(url: url)
    }

    open class func writingIntent(with url: URL, options: NSFileCoordinator.WritingOptions = [])
      -> NSFileAccessIntent
    {
      NSFileAccessIntent(url: url)
    }

    open var url: URL { _url.withLock { $0 } }
    private let _url: Mutex<URL>
    init(url: URL) {
      self._url = .init(url)
    }
  }

  open class NSFileCoordinator {

    open class func addFilePresenter(_ filePresenter: any NSFilePresenter) {}

    open class func removeFilePresenter(_ filePresenter: any NSFilePresenter) {}

    open class var filePresenters: [any NSFilePresenter] { [] }

    public init(filePresenter filePresenterOrNil: (any NSFilePresenter)?) {}

    open var purposeIdentifier: String = ""

    open func coordinate(
      with intents: [NSFileAccessIntent], queue: OperationQueue,
      byAccessor accessor: @escaping @Sendable ((any Error)?) -> Void
    ) {
      accessor(nil)
    }

    open func coordinate(
      readingItemAt url: URL, options: NSFileCoordinator.ReadingOptions = [],
      error outError: NSErrorPointer, byAccessor reader: (URL) -> Void
    ) {
      reader(url)
    }

    open func coordinate(
      writingItemAt url: URL, options: NSFileCoordinator.WritingOptions = [],
      error outError: NSErrorPointer, byAccessor writer: (URL) -> Void
    ) {
      writer(url)
    }

    open func coordinate(
      readingItemAt readingURL: URL, options readingOptions: NSFileCoordinator.ReadingOptions = [],
      writingItemAt writingURL: URL, options writingOptions: NSFileCoordinator.WritingOptions = [],
      error outError: NSErrorPointer, byAccessor readerWriter: (URL, URL) -> Void
    ) {
      readerWriter(readingURL, writingURL)
    }

    open func coordinate(
      writingItemAt url1: URL, options options1: NSFileCoordinator.WritingOptions = [],
      writingItemAt url2: URL, options options2: NSFileCoordinator.WritingOptions = [],
      error outError: NSErrorPointer, byAccessor writer: (URL, URL) -> Void
    ) {
      writer(url1, url2)
    }

    open func prepare(
      forReadingItemsAt readingURLs: [URL],
      options readingOptions: NSFileCoordinator.ReadingOptions = [],
      writingItemsAt writingURLs: [URL],
      options writingOptions: NSFileCoordinator.WritingOptions = [], error outError: NSErrorPointer,
      byAccessor batchAccessor: (@escaping @Sendable () -> Void) -> Void
    ) {
      batchAccessor({})
    }

    open func item(at oldURL: URL, willMoveTo newURL: URL) {}

    open func item(at oldURL: URL, didMoveTo newURL: URL) {}

    open func item(at url: URL, didChangeUbiquityAttributes attributes: Set<URLResourceKey>) {}

    open func cancel() {}
  }

  @available(*, unavailable)
  extension NSFileCoordinator: @unchecked Sendable {
  }

  //public typealias NSErrorPointer = AutoreleasingUnsafeMutablePointer<NSError?>?
  public struct NSErrorPointer {}

  extension URLResourceKey: @retroactive Hashable {

    public static func == (lhs: URLResourceKey, rhs: URLResourceKey) -> Bool {
      true
    }

    public func hash(into hasher: inout Hasher) {

    }
  }
#endif

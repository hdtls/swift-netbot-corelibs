//
// See LICENSE.txt for license information
//

import NIOCore

extension ByteBuffer {

  public typealias Index = Int

  @usableFromInline internal func _precondition(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = String(),
    file: StaticString = #file, line: UInt = #line
  ) {
    if !condition() {
      fatalError(message(), file: file, line: line)
    }
  }

  public typealias Element = UInt8

  /// The number of elements in the buffer.
  @inlinable public var count: Int { readableBytes }

  @inlinable public var isEmpty: Bool { readableBytes == 0 }

  /// The position of the first element in a nonempty buffer.
  ///
  /// For an instance of `ByteBuffer`, `startIndex` is always zero. If the buffer
  /// is empty, `startIndex` is equal to `endIndex`.
  @inlinable public var startIndex: Index { 0 }

  /// The buffer's "past the end" position---that is, the position one greater
  /// than the last valid subscript argument.
  ///
  /// When you need a range that includes the last element of an array, use the
  /// half-open range operator (`..<`) with `endIndex`. The `..<` operator
  /// creates a range that doesn't include the upper bound, so it's always
  /// safe to use with `endIndex`.
  @inlinable public var endIndex: Index { readableBytes }

  /// Returns the position immediately after the given index.
  @inlinable public func index(after i: Index) -> Index {
    i + 1
  }

  /// Returns the position immediately before the given index.
  @inlinable public func index(before i: Int) -> Int {
    return i - 1
  }

  /// Returns an index that is the specified distance from the given index.
  @inlinable
  public func index(_ i: Int, offsetBy distance: Int) -> Int {
    return i + distance
  }

  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If `end` is equal to
  ///     `start`, the result is zero.
  /// - Returns: The distance between `start` and `end`.
  @inlinable
  public func distance(from start: Int, to end: Int) -> Int {
    return end - start
  }

  /// Returns a subsequence, up to the specified maximum length, containing
  /// the initial elements of the collection.
  ///
  /// If the maximum length exceeds the number of elements in the collection,
  /// the result contains all the elements in the collection.
  @inlinable public func prefix(_ maxLength: Int) -> ByteBuffer {
    self[..<Swift.min(count, maxLength)]
  }

  /// Returns a subsequence from the start of the collection up to, but not
  /// including, the specified position.
  ///
  /// The resulting subsequence *does not include* the element at the position
  /// `end`.
  @inlinable public func prefix(upTo end: Index) -> ByteBuffer {
    self[..<end]
  }

  /// Returns a subsequence from the start of the collection through the
  /// specified position.
  ///
  /// The resulting subsequence *includes* the element at the position
  /// specified by the `through` parameter.
  @inlinable public func prefix(through position: Index) -> ByteBuffer {
    self[...position]
  }

  /// Returns a subsequence from the specified position to the end of the
  /// collection.
  @inlinable public func suffix(from start: Index) -> ByteBuffer {
    self[start...]
  }

  /// Accesses the element at the specified position.
  @inlinable public subscript(index: Index) -> Element {
    get {
      _precondition(index < endIndex, "ByteBuffer index is out of range")
      _precondition(index >= startIndex, "Negative ByteBuffer index is out of range")
      return getInteger(at: readerIndex + index)!
    }
    set {
      _precondition(index < endIndex, "ByteBuffer index is out of range")
      _precondition(index >= startIndex, "Negative ByteBuffer index is out of range")
      setInteger(newValue, at: readerIndex + index)
    }
  }

  /// Accesses a contiguous subrange of the buffer's elements.
  @inlinable public subscript(bounds: Range<Index>) -> ByteBuffer {
    get {
      _precondition(bounds.upperBound <= endIndex, "ByteBuffer index is out of range")
      _precondition(bounds.lowerBound >= startIndex, "Negative ByteBuffer index is out of range")
      return getSlice(
        at: readerIndex + bounds.lowerBound,
        length: bounds.upperBound - bounds.lowerBound
      )!
    }
    set(rhs) {
      _precondition(bounds.upperBound <= endIndex, "ByteBuffer index is out of range")
      _precondition(bounds.lowerBound >= startIndex, "Negative ByteBuffer index is out of range")
      replaceSubrange(bounds, with: rhs)
    }
  }

  @inlinable public subscript(bounds: ClosedRange<Index>) -> ByteBuffer {
    get {
      self[bounds.lowerBound..<index(after: bounds.upperBound)]
    }
    set(rhs) {
      self[bounds.lowerBound..<index(after: bounds.upperBound)] = rhs
    }
  }

  @inlinable public subscript(bounds: PartialRangeFrom<Index>) -> ByteBuffer {
    get {
      self[bounds.lowerBound..<endIndex]
    }
    set(rhs) {
      self[bounds.lowerBound..<endIndex] = rhs
    }
  }

  @inlinable public subscript(bounds: PartialRangeUpTo<Index>) -> ByteBuffer {
    get {
      self[startIndex..<bounds.upperBound]
    }
    set(rhs) {
      self[startIndex..<bounds.upperBound] = rhs
    }
  }

  @inlinable public subscript(bounds: PartialRangeThrough<Index>) -> ByteBuffer {
    get {
      self[startIndex..<index(after: bounds.upperBound)]
    }
    set(rhs) {
      self[startIndex..<index(after: bounds.upperBound)] = rhs
    }
  }

  /// Accesses a contiguous subrange of the buffer's elements.
  @inlinable public subscript(bounds: Range<Index>) -> [UInt8] {
    get {
      _precondition(bounds.upperBound <= endIndex, "ByteBuffer index is out of range")
      _precondition(bounds.lowerBound >= startIndex, "Negative ByteBuffer index is out of range")
      return getBytes(
        at: readerIndex + bounds.lowerBound,
        length: bounds.upperBound - bounds.lowerBound
      )!
    }
    set(rhs) {
      _precondition(bounds.upperBound <= endIndex, "ByteBuffer index is out of range")
      _precondition(bounds.lowerBound >= startIndex, "Negative ByteBuffer index is out of range")
      replaceSubrange(bounds, with: rhs)
    }
  }

  @inlinable public subscript(bounds: ClosedRange<Index>) -> [UInt8] {
    get {
      self[bounds.lowerBound..<index(after: bounds.upperBound)]
    }
    set(rhs) {
      self[bounds.lowerBound..<index(after: bounds.upperBound)] = rhs
    }
  }

  @inlinable public subscript(bounds: PartialRangeFrom<Index>) -> [UInt8] {
    get {
      self[bounds.lowerBound..<endIndex]
    }
    set(rhs) {
      self[bounds.lowerBound..<endIndex] = rhs
    }
  }

  @inlinable public subscript(bounds: PartialRangeUpTo<Index>) -> [UInt8] {
    get {
      self[startIndex..<bounds.upperBound]
    }
    set(rhs) {
      self[startIndex..<bounds.upperBound] = rhs
    }
  }

  @inlinable public subscript(bounds: PartialRangeThrough<Index>) -> [UInt8] {
    get {
      self[startIndex..<index(after: bounds.upperBound)]
    }
    set(rhs) {
      self[startIndex..<index(after: bounds.upperBound)] = rhs
    }
  }

  /// Adds a new element at the end of the buffer.
  ///
  /// Use this method to append a single element to the end of a mutable buffer.
  @inlinable public mutating func append(_ newElement: __owned Element) {
    writeInteger(newElement)
  }

  /// Adds the elements of a sequence to the end of the buffer.
  ///
  /// Use this method to append the elements of a sequence to the end of this
  /// buffer.
  @inlinable public mutating func append<S>(contentsOf newElements: __owned S)
  where S: Sequence, Element == S.Element {
    writeBytes(newElements)
  }

  /// Adds the elements of a buffer to the end of the buffer.
  ///
  /// Use this method to append the elements of a buffer to the end of this
  /// buffer.
  @inlinable public mutating func append(contentsOf newElements: __owned ByteBuffer) {
    writeImmutableBuffer(newElements)
  }

  /// Inserts a new element at the specified position.
  ///
  /// The new element is inserted before the element currently at the specified
  /// index. If you pass the buffer's `endIndex` property as the `index`
  /// parameter, the new element is appended to the buffer.
  @inlinable public mutating func insert(_ newElement: __owned Element, at i: Index) {
    replaceSubrange(i..<i, with: CollectionOfOne(newElement))
  }

  @inlinable public mutating func insert<C>(contentsOf newElements: C, at i: Index)
  where C: Collection, Element == C.Element {
    replaceSubrange(i..<i, with: newElements)
  }

  @inlinable public mutating func insert(contentsOf newElements: __owned ByteBuffer, at i: Index) {
    replaceSubrange(i..<i, with: newElements)
  }

  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved up to
  /// close the gap.
  @discardableResult
  @inlinable public mutating func remove(at index: Index) -> Element {
    _precondition(index < endIndex, "ByteBuffer index is out of range")
    _precondition(index >= startIndex, "Negative ByteBuffer index is out of range")

    let result = self[index]
    guard index < endIndex - 1 else {
      moveWriterIndex(to: index)
      return result
    }

    let rhs: ByteBuffer = self[index.advanced(by: 1)...]
    moveWriterIndex(to: index)
    writeImmutableBuffer(rhs)
    return result
  }

  /// Removes the elements in the specified subrange from the collection.
  @inlinable public mutating func removeSubrange(_ bounds: Range<Index>) {
    _precondition(bounds.lowerBound >= startIndex, "ByteBuffer replace: subrange start is negative")
    _precondition(
      bounds.upperBound <= endIndex, "ByteBuffer replace: subrange extends past the end")

    guard bounds.lowerBound != endIndex else {
      return
    }

    let rhs: ByteBuffer = self[bounds.upperBound...]
    moveWriterIndex(to: bounds.lowerBound)
    writeImmutableBuffer(rhs)
  }

  @inlinable public mutating func removeSubrange(_ bounds: ClosedRange<Index>) {
    removeSubrange(bounds.lowerBound..<index(after: bounds.upperBound))
  }

  @inlinable public mutating func removeSubrange(_ bounds: PartialRangeFrom<Index>) {
    removeSubrange(bounds.lowerBound..<endIndex)
  }

  @inlinable public mutating func removeSubrange(_ bounds: PartialRangeUpTo<Index>) {
    removeSubrange(startIndex..<bounds.upperBound)
  }

  @inlinable public mutating func removeSubrange(_ bounds: PartialRangeThrough<Index>) {
    removeSubrange(startIndex..<index(after: bounds.upperBound))
  }

  /// Removes all elements from the buffer.
  ///
  /// - Important: `keepCapacity` is not used.
  @inlinable
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self.clear(minimumCapacity: capacity)
  }

  /// Replaces a range of elements with the elements in the specified
  /// collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the buffer and inserting the new elements at the same location. The
  /// number of new elements need not match the number of elements being
  /// removed.
  @inlinable public mutating func replaceSubrange<C>(
    _ bounds: Range<Index>, with newElements: __owned C
  ) where C: Collection, Element == C.Element {
    guard !newElements.isEmpty else {
      removeSubrange(bounds)
      return
    }

    _precondition(bounds.lowerBound >= startIndex, "ByteBuffer replace: subrange start is negative")
    _precondition(
      bounds.upperBound <= endIndex, "ByteBuffer replace: subrange extends past the end")

    guard bounds.lowerBound != endIndex else {
      append(contentsOf: newElements)
      return
    }

    let lhs: ByteBuffer = self[bounds.upperBound...]
    moveWriterIndex(to: bounds.lowerBound)
    writeBytes(newElements)
    writeImmutableBuffer(lhs)
  }

  @inlinable public mutating func replaceSubrange<C>(
    _ bounds: ClosedRange<Index>, with newElements: __owned C
  ) where C: Collection, Element == C.Element {
    replaceSubrange(bounds.lowerBound..<index(after: bounds.upperBound), with: newElements)
  }

  @inlinable public mutating func replaceSubrange<C>(
    _ bounds: PartialRangeFrom<Index>, with newElements: __owned C
  ) where C: Collection, Element == C.Element {
    replaceSubrange(bounds.lowerBound..<endIndex, with: newElements)
  }

  @inlinable public mutating func replaceSubrange<C>(
    _ bounds: PartialRangeUpTo<Index>, with newElements: __owned C
  ) where C: Collection, Element == C.Element {
    replaceSubrange(startIndex..<bounds.upperBound, with: newElements)
  }

  @inlinable public mutating func replaceSubrange<C>(
    _ bounds: PartialRangeThrough<Index>, with newElements: __owned C
  ) where C: Collection, Element == C.Element {
    replaceSubrange(startIndex..<index(after: bounds.upperBound), with: newElements)
  }

  /// Replaces a range of elements with the elements in the specified
  /// buffer.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the buffer and inserting the new elements at the same location. The
  /// number of new elements need not match the number of elements being
  /// removed.
  @inlinable public mutating func replaceSubrange(
    _ bounds: Range<Index>, with newElements: __owned ByteBuffer
  ) {
    guard !newElements.isEmpty else {
      removeSubrange(bounds)
      return
    }

    _precondition(bounds.lowerBound >= startIndex, "ByteBuffer replace: subrange start is negative")
    _precondition(
      bounds.upperBound <= endIndex, "ByteBuffer replace: subrange extends past the end")

    guard bounds.lowerBound != endIndex else {
      append(contentsOf: newElements)
      return
    }

    if bounds.lowerBound == startIndex && bounds.upperBound == endIndex {
      self = newElements
      return
    }

    let lhs: ByteBuffer = self[bounds.upperBound...]
    moveWriterIndex(to: bounds.lowerBound)
    writeImmutableBuffer(newElements)
    writeImmutableBuffer(lhs)
  }

  @inlinable public mutating func replaceSubrange(
    _ bounds: ClosedRange<Index>, with newElements: __owned ByteBuffer
  ) {
    replaceSubrange(bounds.lowerBound..<index(after: bounds.upperBound), with: newElements)
  }

  @inlinable public mutating func replaceSubrange(
    _ bounds: PartialRangeFrom<Index>, with newElements: __owned ByteBuffer
  ) {
    replaceSubrange(bounds.lowerBound..<endIndex, with: newElements)
  }

  @inlinable public mutating func replaceSubrange(
    _ bounds: PartialRangeUpTo<Index>, with newElements: __owned ByteBuffer
  ) {
    replaceSubrange(startIndex..<bounds.upperBound, with: newElements)
  }

  @inlinable public mutating func replaceSubrange(
    _ bounds: PartialRangeThrough<Index>, with newElements: __owned ByteBuffer
  ) {
    replaceSubrange(startIndex..<index(after: bounds.upperBound), with: newElements)
  }
}

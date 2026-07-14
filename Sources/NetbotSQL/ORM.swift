// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if !canImport(SwiftData) || !SWTNE_REQUIRES_SQL
  #if canImport(Darwin) || swift(>=6.3)
    import Observation
  #endif

  #if canImport(Darwin)
    import Foundation
  #else
    @available(SwiftStdlib 6.0, *)
    open class ValueTransformer {
      public init?() {}

      open class func transformedValueClass() -> AnyClass {
        fatalError("Subclass must override this method to make it works")
      }

      open class func allowsReverseTransformation() -> Bool {
        true
      }

      open func transformedValue(_ value: Any?) -> Any? {
        fatalError("Subclass must override this method to make it works")
      }

      open func reverseTransformedValue(_ value: Any?) -> Any? {
        fatalError("Subclass must override this method to make it works")
      }
    }
  #endif

  #if canImport(Darwin) || swift(>=6.3)
    @available(SwiftStdlib 6.0, *)
    public protocol PersistentModel: AnyObject, Observable, Hashable, Identifiable, SendableMetatype
    {
    }
  #else
    @available(SwiftStdlib 6.0, *)
    public protocol PersistentModel: AnyObject, Hashable, Identifiable, SendableMetatype {
    }
  #endif

  @available(SwiftStdlib 6.0, *)
  extension PersistentModel {

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    public var id: ObjectIdentifier {
      ObjectIdentifier(self)
    }
  }

  @available(SwiftStdlib 6.0, *)
  final public class Schema: Codable, Hashable {

    final public let version: Schema.Version

    public init() {
      version = Version(1, 0, 0)
    }

    public init(version: Version = Version(1, 0, 0)) {
      self.version = version
    }

    public convenience init(versionedSchema: any VersionedSchema.Type) {
      self.init(version: versionedSchema.versionIdentifier)
    }

    public static func == (lhs: Schema, rhs: Schema) -> Bool {
      lhs.version == rhs.version
    }

    final public func hash(into hasher: inout Hasher) {
      hasher.combine(version)
    }

    public struct Version: Codable, Comparable, CustomStringConvertible, Hashable {

      /// The major version according to the semantic versioning standard.
      public let major: Int

      /// The minor version according to the semantic versioning standard.
      public let minor: Int

      /// The patch version according to the semantic versioning standard.
      public let patch: Int

      /// Initializes a version struct with the provided components of a semantic version.
      ///
      /// - Parameters:
      ///   - major: The major version number.
      ///   - minor: The minor version number.
      ///   - patch: The patch version number.
      ///
      /// - Precondition: `major >= 0 && minor >= 0 && patch >= 0`.
      public init(_ major: Int, _ minor: Int, _ patch: Int) {
        precondition(major >= 0 && minor >= 0 && patch >= 0)
        self.major = major
        self.minor = minor
        self.patch = patch
      }

      /// Returns a Boolean value indicating whether the value of the first
      /// argument is less than that of the second argument.
      ///
      /// The precedence is determined according to rules described in the [Semantic Versioning 2.0.0](https://semver.org) standard, paragraph 11.
      ///
      /// - Parameters:
      ///   - lhs: A value to compare.
      ///   - rhs: Another value to compare.
      public static func < (lhs: Schema.Version, rhs: Schema.Version) -> Bool {
        false
      }

      /// A textual description of the version object.
      public var description: String { "\(major).\(minor).\(patch)" }
    }

  }

  @available(SwiftStdlib 6.0, *)
  extension Schema {

    /// An object that describes the configuration and behavior of a specific property of a model class.
    final public class Attribute {
      public struct Option {
        /// Ensures the property's value is unique across all models of the same type.
        public static var unique: Schema.Attribute.Option { .init() }

        /// Transforms the property's value between an in-memory form and a persisted form.
        public static func transformable(by transformerType: ValueTransformer.Type)
          -> Schema.Attribute.Option
        {
          .init()
        }

        public static func transformable(by transformerName: String) -> Schema.Attribute.Option {
          .init()
        }

        /// Stores the property's value as binary data adjacent to the model storage.
        public static var externalStorage: Schema.Attribute.Option { .init() }
      }
    }

    final public class Relationship {
      public struct Option: Codable, Hashable {

        /// Ensures the property's value is unique across all models of the same type.
        public static var unique: Schema.Relationship.Option { .init() }
      }

      public enum DeleteRule: String, Codable {

        /// A rule that doesn't make changes to any related models.
        ///
        /// Ensure that you take the appropriate action on any related models when using this delete rule,
        /// such as deleting them or nullifying their references to the deleted model. Otherwise, your data will
        /// be in an inconsistent state and may reference models that don't exist.
        case noAction

        /// A rule that nullifies the related model's reference to the deleted model.
        case nullify

        /// A rule that deletes any related models.
        case cascade

        /// A rule that prevents the deletion of a model because it contains one or more references to other
        /// models.
        case deny
      }
    }

    final public class Index<T> {
      public enum Types<P> {

        case binary([PartialKeyPath<P>])

        case rtree([PartialKeyPath<P>])
      }
    }
  }

  /// An interface for describing a specific version of a schema, including the models it contains.
  @available(SwiftStdlib 6.0, *)
  public protocol VersionedSchema: SendableMetatype {

    /// The models to include in this version of the schema.
    static var models: [any PersistentModel.Type] { get }

    /// The textual description of the migration’s version or purpose.
    static var versionIdentifier: Schema.Version { get }
  }

  @available(SwiftStdlib 6.0, *)
  @attached(peer)
  public macro Attribute(
    _ options: Schema.Attribute.Option..., originalName: String? = nil,
    hashModifier: String? = nil
  ) = #externalMacro(module: "NetbotSQLMacros", type: "AttributePropertyMacro")

  #if canImport(Darwin) || swift(>=6.3)
    @available(SwiftStdlib 6.0, *)
    @attached(
      member,
      conformances: Observable, PersistentModel, Sendable,
      names: named(_$observationRegistrar), named(access), named(withMutation),
      named(shouldNotifyObservers)
    )
    @attached(memberAttribute)
    @attached(extension, conformances: Observable, PersistentModel, Sendable)
    public macro Model() = #externalMacro(module: "NetbotSQLMacros", type: "PersistentModelMacro")
  #else
    @available(SwiftStdlib 6.0, *)
    @attached(extension, conformances: PersistentModel, Sendable)
    public macro Model() = #externalMacro(module: "NetbotSQLMacros", type: "PersistentModelMacro")
  #endif

  @available(SwiftStdlib 6.0, *)
  @attached(peer)
  public macro Relationship(
    _ options: Schema.Relationship.Option...,
    deleteRule: Schema.Relationship.DeleteRule = .nullify,
    minimumModelCount: Int? = 0, maximumModelCount: Int? = 0, originalName: String? = nil,
    inverse: AnyKeyPath? = nil, hashModifier: String? = nil
  ) = #externalMacro(module: "NetbotSQLMacros", type: "RelationshipPropertyMacro")

  @available(SwiftStdlib 6.0, *)
  @freestanding(declaration)
  public macro Index<T>(_ indices: Schema.Index<T>.Types<T>...) =
    #externalMacro(module: "NetbotSQLMacros", type: "IndexMacro")

  @available(SwiftStdlib 6.0, *)
  @freestanding(declaration)
  public macro Index<T>(_ indices: [PartialKeyPath<T>]...) =
    #externalMacro(module: "NetbotSQLMacros", type: "IndexMacro")

  @available(SwiftStdlib 6.0, *)
  @freestanding(declaration)
  public macro Unique<T>(_ constraints: [PartialKeyPath<T>]...) =
    #externalMacro(module: "NetbotSQLMacros", type: "UniqueConstraintsMacro")
#endif

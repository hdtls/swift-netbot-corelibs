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

  public class Schema {}

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

  @attached(peer) public macro Attribute(
    _ options: Schema.Attribute.Option..., originalName: String? = nil,
    hashModifier: String? = nil
  ) = #externalMacro(module: "NetbotSQLMacros", type: "AttributePropertyMacro")

  #if swift(>=6.3)
    @attached(
      member, conformances: Observable, Sendable, names: named(_$observationRegistrar),
      named(access),
      named(withMutation), named(shouldNotifyObservers))
    @attached(memberAttribute)
    @attached(extension, conformances: Observable, Sendable)
    public macro Model() = #externalMacro(module: "NetbotSQLMacros", type: "PersistentModelMacro")
  #else
    @attached(extension, conformances: Sendable)
    public macro Model() = #externalMacro(module: "NetbotSQLMacros", type: "PersistentModelMacro")
  #endif

  @attached(peer) public macro Relationship(
    _ options: Schema.Relationship.Option...,
    deleteRule: Schema.Relationship.DeleteRule = .nullify,
    minimumModelCount: Int? = 0, maximumModelCount: Int? = 0, originalName: String? = nil,
    inverse: AnyKeyPath? = nil, hashModifier: String? = nil
  ) = #externalMacro(module: "NetbotSQLMacros", type: "RelationshipPropertyMacro")

  @freestanding(declaration) public macro Index<T>(_ indices: Schema.Index<T>.Types<T>...) =
    #externalMacro(module: "NetbotSQLMacros", type: "IndexMacro")

  @freestanding(declaration) public macro Index<T>(_ indices: [PartialKeyPath<T>]...) =
    #externalMacro(module: "NetbotSQLMacros", type: "IndexMacro")

  @freestanding(declaration) public macro Unique<T>(_ constraints: [PartialKeyPath<T>]...) =
    #externalMacro(module: "NetbotSQLMacros", type: "UniqueConstraintsMacro")
#endif

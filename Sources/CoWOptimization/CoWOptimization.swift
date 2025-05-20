//
// See LICENSE.txt for license information
//

/// Defines and implements copy on write.
///
/// This macro adds copy on write support to a custom type. For example, the following code
/// applies the `_cowOptimization` macro to the type `Car` making it copy on write:
///
///     @_cowOptimization
///     struct Car {
///        var name: String = ""
///        var needsRepairs: Bool = false
///     }
@attached(
  member, names: named(_storage), named(copyStorageIfNotUniquelyReferenced), named(_Storage))
@attached(memberAttribute)
public macro _cowOptimization() =
  #externalMacro(module: "CoWOptimizationMacros", type: "CoWOptimizationMacro")

@attached(accessor, names: named(get), named(_modify))
public macro _cowOptimizationTracked() =
  #externalMacro(module: "CoWOptimizationMacros", type: "CoWOptimizationTrackedMacro")

@attached(peer)
public macro _cowOptimizationIgnored() =
  #externalMacro(module: "CoWOptimizationMacros", type: "CoWOptimizationIgnoredMacro")

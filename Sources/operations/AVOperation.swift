/// A protocol that defines an asynchronous operation on an audiovisual asset.
///
/// Conforming types to `AVOperation` are responsible for performing operations that may include editing, processing, or analyzing audiovisual content. The result of the operation is an optional `AVComposeContext` which encapsulates the changes made to the asset.
///
/// - Throws: An error if the operation cannot be completed.
/// - Returns: An optional `AVComposeContext` object representing the result of the operation.
protocol AVOperation {
  func run() async throws -> AVComposeContext?
}
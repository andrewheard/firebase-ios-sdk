// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FirebaseAppCheckInterop
import FirebaseAuthInterop
import FirebaseCore
import Foundation

// Avoids exposing internal FirebaseCore APIs to Swift users.
@_implementationOnly import FirebaseCoreExtension

/// The Vertex AI for Firebase SDK provides access to Gemini models directly from your app.
@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public class VertexAI {
  // MARK: - Public APIs

  /// The default `VertexAI` instance.
  ///
  /// - Parameter location: The region identifier, defaulting to `us-central1`; see [Vertex AI
  /// regions
  ///   ](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations#available-regions)
  ///   for a list of supported regions.
  /// - Returns: An instance of `VertexAI`, configured with the default `FirebaseApp`.
  public static func vertexAI(location: String = "us-central1") -> VertexAI {
    guard let app = FirebaseApp.app() else {
      fatalError("No instance of the default Firebase app was found.")
    }

    return vertexAI(app: app, location: location)
  }

  /// Creates an instance of `VertexAI` configured with a custom `FirebaseApp`.
  ///
  ///  - Parameters:
  ///   - app: The custom `FirebaseApp` used for initialization.
  ///   - location: The region identifier, defaulting to `us-central1`; see
  ///     [Vertex AI locations]
  ///     (https://firebase.google.com/docs/vertex-ai/locations?platform=ios#available-locations)
  ///     for a list of supported locations.
  /// - Returns: A `VertexAI` instance, configured with the custom `FirebaseApp`.
  public static func vertexAI(app: FirebaseApp, location: String = "us-central1") -> VertexAI {
    os_unfair_lock_lock(&instancesLock)

    // Unlock before the function returns.
    defer { os_unfair_lock_unlock(&instancesLock) }

    let instanceKey = "\(app.name):\(location)"
    if let instance = instances[instanceKey] {
      return instance
    }
    let newInstance = VertexAI(app: app, location: location)
    instances[instanceKey] = newInstance
    return newInstance
  }

  /// Initializes a generative model with the given parameters.
  ///
  /// - Note: Refer to [Gemini models](https://firebase.google.com/docs/vertex-ai/gemini-models) for
  /// guidance on choosing an appropriate model for your use case.
  ///
  /// - Parameters:
  ///   - modelName: The name of the model to use, for example `"gemini-1.5-flash"`; see
  ///     [available model names
  ///     ](https://firebase.google.com/docs/vertex-ai/gemini-models#available-model-names) for a
  ///     list of supported model names.
  ///   - generationConfig: The content generation parameters your model should use.
  ///   - safetySettings: A value describing what types of harmful content your model should allow.
  ///   - tools: A list of ``Tool`` objects that the model may use to generate the next response.
  ///   - toolConfig: Tool configuration for any `Tool` specified in the request.
  ///   - systemInstruction: Instructions that direct the model to behave a certain way; currently
  ///     only text content is supported.
  ///   - requestOptions: Configuration parameters for sending requests to the backend.
  public func generativeModel(modelName: String,
                              generationConfig: GenerationConfig? = nil,
                              safetySettings: [SafetySetting]? = nil,
                              tools: [Tool]? = nil,
                              toolConfig: ToolConfig? = nil,
                              systemInstruction: ModelContent? = nil,
                              requestOptions: RequestOptions = RequestOptions())
    -> GenerativeModel {
    return GenerativeModel(
      name: modelResourceName(modelName: modelName),
      firebaseInfo: firebaseInfo,
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      tools: tools,
      toolConfig: toolConfig,
      systemInstruction: systemInstruction,
      requestOptions: requestOptions
    )
  }

  /// **[Public Preview]** Initializes an ``ImagenModel`` with the given parameters.
  ///
  /// > Warning: For Vertex AI in Firebase, image generation using Imagen 3 models is in Public
  /// Preview, which means that the feature is not subject to any SLA or deprecation policy and
  /// could change in backwards-incompatible ways.
  ///
  /// > Important: Only Imagen 3 models (named `imagen-3.0-*`) are supported.
  ///
  /// - Parameters:
  ///   - modelName: The name of the Imagen 3 model to use, for example `"imagen-3.0-generate-002"`;
  ///     see [model
  ///     versions](https://cloud.google.com/vertex-ai/generative-ai/docs/image/model-versioning)
  ///     for a list of supported Imagen 3 models.
  ///   - generationConfig: Configuration options for generating images with Imagen.
  ///   - safetySettings: Settings describing what types of potentially harmful content your model
  ///     should allow.
  ///   - requestOptions: Configuration parameters for sending requests to the backend.
  public func imagenModel(modelName: String, generationConfig: ImagenGenerationConfig? = nil,
                          safetySettings: ImagenSafetySettings? = nil,
                          requestOptions: RequestOptions = RequestOptions()) -> ImagenModel {
    return ImagenModel(
      name: modelResourceName(modelName: modelName),
      firebaseInfo: firebaseInfo,
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      requestOptions: requestOptions
    )
  }

  /// Class to enable VertexAI to register via the Objective-C based Firebase component system
  /// to include VertexAI in the userAgent.
  @objc(FIRVertexAIComponent) class FirebaseVertexAIComponent: NSObject {}

  // MARK: - Private

  /// Firebase data relevant to Vertex AI.
  let firebaseInfo: FirebaseInfo

  #if compiler(>=6)
    /// A map of active  `VertexAI` instances keyed by the `FirebaseApp` name and the `location`, in
    /// the format `appName:location`.
    private nonisolated(unsafe) static var instances: [String: VertexAI] = [:]

    /// Lock to manage access to the `instances` array to avoid race conditions.
    private nonisolated(unsafe) static var instancesLock: os_unfair_lock = .init()
  #else
    /// A map of active  `VertexAI` instances keyed by the `FirebaseApp` name and the `location`, in
    /// the format `appName:location`.
    private static var instances: [String: VertexAI] = [:]

    /// Lock to manage access to the `instances` array to avoid race conditions.
    private static var instancesLock: os_unfair_lock = .init()
  #endif

  let location: String

  init(app: FirebaseApp, location: String) {
    guard let projectID = app.options.projectID else {
      fatalError("The Firebase app named \"\(app.name)\" has no project ID in its configuration.")
    }
    guard let apiKey = app.options.apiKey else {
      fatalError("The Firebase app named \"\(app.name)\" has no API key in its configuration.")
    }
    firebaseInfo = FirebaseInfo(
      appCheck: ComponentType<AppCheckInterop>.instance(
        for: AppCheckInterop.self,
        in: app.container
      ),
      auth: ComponentType<AuthInterop>.instance(for: AuthInterop.self, in: app.container),
      projectID: projectID,
      apiKey: apiKey,
      googleAppID: app.options.googleAppID,
      firebaseApp: app
    )
    self.location = location
  }

  func modelResourceName(modelName: String) -> String {
    guard !modelName.isEmpty && modelName
      .allSatisfy({ !$0.isWhitespace && !$0.isNewline && $0 != "/" }) else {
      fatalError("""
      Invalid model name "\(modelName)" specified; see \
      https://firebase.google.com/docs/vertex-ai/gemini-model#available-models for a list of \
      available models.
      """)
    }
    guard !location.isEmpty && location
      .allSatisfy({ !$0.isWhitespace && !$0.isNewline && $0 != "/" }) else {
      fatalError("""
      Invalid location "\(location)" specified; see \
      https://firebase.google.com/docs/vertex-ai/locations?platform=ios#available-locations \
      for a list of available locations.
      """)
    }

    let projectID = firebaseInfo.projectID
    return "projects/\(projectID)/locations/\(location)/publishers/google/models/\(modelName)"
  }
}

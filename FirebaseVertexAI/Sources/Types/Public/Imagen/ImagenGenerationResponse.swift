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

import Foundation

/// A response from a request to generate images with Imagen.
///
/// The type placeholder `T` is an image type of either ``ImagenInlineImage`` or ``ImagenGCSImage``.
///
/// This type is returned from:
///   - ``ImagenModel/generateImages(prompt:)`` where `T` is ``ImagenInlineImage``
///   - ``ImagenModel/generateImages(prompt:gcsURI:)`` where `T` is ``ImagenGCSImage``
@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public struct ImagenGenerationResponse<T> {
  /// The images generated by Imagen; see ``ImagenInlineImage`` and ``ImagenGCSImage``.
  ///
  /// > Important: The number of images generated may be fewer than the number requested if one or
  ///   more were filtered out; see ``filteredReason``.
  public let images: [T]

  /// The reason, if any, that generated images were filtered out.
  ///
  /// This property will only be populated if fewer images were generated than were requested,
  /// otherwise it will be `nil`. Images may be filtered out due to the ``ImagenSafetyFilterLevel``,
  /// the ``ImagenPersonFilterLevel``, or filtering included in the model. The filter levels may be
  /// adjusted in your ``ImagenSafetySettings``. See the [Responsible AI and usage guidelines for
  /// Imagen](https://cloud.google.com/vertex-ai/generative-ai/docs/image/responsible-ai-imagen)
  /// for more details.
  public let filteredReason: String?
}

// MARK: - Codable Conformances

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension ImagenGenerationResponse: Decodable where T: Decodable {
  enum CodingKeys: CodingKey {
    case predictions
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    var predictionsContainer = try container.nestedUnkeyedContainer(forKey: .predictions)

    var images = [T]()
    var filteredReasons = [String]()
    while !predictionsContainer.isAtEnd {
      if let image = try? predictionsContainer.decode(T.self) {
        images.append(image)
      } else if let filteredReason = try? predictionsContainer.decode(RAIFilteredReason.self) {
        filteredReasons.append(filteredReason.raiFilteredReason)
      } else if let _ = try? predictionsContainer.decode(JSONObject.self) {
        // TODO(#14221): Log unsupported prediction type message with the decoded `JSONObject`.
      } else {
        // This should never be thrown since JSONObject accepts any valid JSON.
        throw DecodingError.dataCorruptedError(
          in: predictionsContainer,
          debugDescription: "Failed to decode Prediction."
        )
      }
    }

    self.images = images
    let filteredReason = filteredReasons.joined(separator: "\n")
    if filteredReason.isEmpty {
      self.filteredReason = nil
    } else {
      self.filteredReason = filteredReason
    }
    // TODO(#14221): Throw `ImagenImagesBlockedError` with `filteredReason` if `images` is empty.
  }
}

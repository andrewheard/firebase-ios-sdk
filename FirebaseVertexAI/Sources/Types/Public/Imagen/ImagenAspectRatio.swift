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

/// An aspect ratio for images generated by Imagen.
///
/// To specify an aspect ratio for generated images, set ``ImagenGenerationConfig/aspectRatio`` in
/// your ``ImagenGenerationConfig``. See the [Cloud
/// documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/image/generate-images#aspect-ratio)
/// for more details and examples of the supported aspect ratios.
@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public struct ImagenAspectRatio: Sendable {
  /// Square (1:1) aspect ratio.
  ///
  /// Common uses for this aspect ratio include social media posts.
  public static let square1x1 = ImagenAspectRatio(kind: .square1x1)

  /// Portrait widescreen (9:16) aspect ratio.
  ///
  /// This is the ``landscape16x9`` aspect ratio rotated 90 degrees. This a relatively new aspect
  /// ratio that has been popularized by short form video apps (for example, YouTube shorts). Use
  /// this for tall objects with strong vertical orientations such as buildings, trees, waterfalls,
  /// or other similar objects.
  public static let portrait9x16 = ImagenAspectRatio(kind: .portrait9x16)

  /// Widescreen (16:9) aspect ratio.
  ///
  /// This ratio has replaced ``landscape4x3`` as the most common aspect ratio for TVs, monitors,
  /// and mobile phone screens (landscape). Use this aspect ratio when you want to capture more of
  /// the background (for example, scenic landscapes).
  public static let landscape16x9 = ImagenAspectRatio(kind: .landscape16x9)

  /// Portrait full screen (3:4) aspect ratio.
  ///
  /// This is the ``landscape4x3`` aspect ratio rotated 90 degrees. This lets to capture more of
  /// the scene vertically compared to the ``square1x1`` aspect ratio.
  public static let portrait3x4 = ImagenAspectRatio(kind: .portrait3x4)

  /// Fullscreen (4:3) aspect ratio.
  ///
  /// This aspect ratio is commonly used in media or film. It is also the dimensions of most old
  /// (non-widescreen) TVs and medium format cameras. It captures more of the scene horizontally
  /// (compared to ``square1x1``), making it a preferred aspect ratio for photography.
  public static let landscape4x3 = ImagenAspectRatio(kind: .landscape4x3)

  let rawValue: String
}

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension ImagenAspectRatio: ProtoEnum {
  enum Kind: String {
    case square1x1 = "1:1"
    case portrait9x16 = "9:16"
    case landscape16x9 = "16:9"
    case portrait3x4 = "3:4"
    case landscape4x3 = "4:3"
  }
}

# Source

Local copy of the `flutter_image_gallery_saver` plugin used by Nady,
revision `21bcb58c7b4480748d41198655019ed6c1dc75b1`, version 0.0.2.
Upstream: https://github.com/knottx/flutter_image_gallery_saver

The MIT license is preserved in LICENSE. Only runtime source is included.
Android gallery saving is the acceptance target; iOS is not part of this delivery's device acceptance.

Local Android changes: request legacy storage permission only below API 29,
and perform file copying and image decoding on a background executor.

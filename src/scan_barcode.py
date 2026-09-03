"""Print the first QR or barcode payload found in an image.

Usage: python3 scan_barcode.py IMAGE

Exit codes: 0 payload printed, 1 nothing found, 2 bad usage or unreadable
image, 3 OpenCV missing.
"""
import sys

try:
    import cv2
except ImportError:
    sys.exit(3)

# Below this, a QR code is unlikely to have enough pixels per module to decode.
MIN_PIXELS = 600
UPSCALE = 3


def scan(path):
    """Return the first payload found in the image at path, else None."""
    image = cv2.imread(path)
    if image is None:
        return None

    height, width = image.shape[:2]
    if max(height, width) < MIN_PIXELS:
        image = cv2.resize(
            image, None, fx=UPSCALE, fy=UPSCALE, interpolation=cv2.INTER_CUBIC
        )

    found, payloads, _, _ = cv2.QRCodeDetector().detectAndDecodeMulti(image)
    decoded = [text for text in payloads if text] if found else []

    if not decoded:
        try:
            detector = cv2.barcode.BarcodeDetector()
        except AttributeError:
            return None  # OpenCV built without the barcode module.
        found, payloads, _, _ = detector.detectAndDecodeWithType(image)
        decoded = [text for text in payloads if text] if found else []

    return decoded[0] if decoded else None


def main(argv):
    if len(argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    payload = scan(argv[1])
    if payload is None:
        return 1

    print(payload)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

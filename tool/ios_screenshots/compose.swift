// App Store用のスクリーンショットを合成する(iOSリリース手順「スクリーンショット」)。
// 使い方: swift tool/ios_screenshots/compose.swift <Play用の合成画像> <iPhoneのスクリーンショット> <出力.jpg> <見出しの高さ>
// Play用の画像(1080x1920)の見出し(上)と線路の飾り(下)を残し、真ん中をiPhoneの画面と枠に差し替えて、
// 1206x2622(アルファなしのJPEG)にする。見出しの高さは、Play用の画像のスマホの枠の上端より少し上(画像ごとに違う)。
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func load(_ p: String) -> CGImage {
  let s = CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil)!
  return CGImageSourceCreateImageAtIndex(s, 0, nil)!
}
let play = load(CommandLine.arguments[1])
let shot = load(CommandLine.arguments[2])
let out = CommandLine.arguments[3]
// Play用の画像で、スマホの枠より上(見出し)の高さ。画像ごとに少し違う
let cropH = Double(CommandLine.arguments[4])!

let W = 1206.0, H = 2622.0
let scale = W / Double(play.width)          // 1080 -> 1206
let headerSrcH = 461.0, footerSrcY = 1825.0  // 枠を置く位置は、7枚でそろえる
let headerH = headerSrcH * scale
let footerH = (Double(play.height) - footerSrcY) * scale

let ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// CoreGraphicsは左下が原点。上からの座標で描けるよう反転する。
ctx.translateBy(x: 0, y: H); ctx.scaleBy(x: 1, y: -1)
func drawImage(_ img: CGImage, _ r: CGRect) {
  ctx.saveGState(); ctx.translateBy(x: r.minX, y: r.maxY); ctx.scaleBy(x: 1, y: -1)
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: r.width, height: r.height)); ctx.restoreGState()
}
func rgb(_ hex: UInt32) -> CGColor {
  CGColor(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}

ctx.setFillColor(rgb(0xF6F0DF)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

// iPhoneの枠と画面
let border = 24.0, gapTop = 26.0, gapBottom = 34.0
let outerH = H - headerH - footerH - gapTop - gapBottom
let innerH = outerH - border * 2
let innerW = innerH * Double(shot.width) / Double(shot.height)
let outerW = innerW + border * 2
let outer = CGRect(x: (W - outerW) / 2, y: headerH + gapTop, width: outerW, height: outerH)
let inner = outer.insetBy(dx: border, dy: border)
// 影
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: CGColor(red: 0.08, green: 0.19, blue: 0.14, alpha: 0.28))
ctx.addPath(CGPath(roundedRect: outer, cornerWidth: 118, cornerHeight: 118, transform: nil))
ctx.setFillColor(rgb(0x143124)); ctx.fillPath(); ctx.restoreGState()
// 枠のふち(少し明るい緑)
ctx.addPath(CGPath(roundedRect: outer.insetBy(dx: 2, dy: 2), cornerWidth: 116, cornerHeight: 116, transform: nil))
ctx.setStrokeColor(rgb(0x2F4A3A)); ctx.setLineWidth(4); ctx.strokePath()
// 画面(角を丸めて切り抜く)
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: inner, cornerWidth: 96, cornerHeight: 96, transform: nil)); ctx.clip()
drawImage(shot, inner)
ctx.restoreGState()

// 見出し(上)と線路の飾り(下)は、Play用の画像から切り出す
drawImage(play.cropping(to: CGRect(x: 0, y: 0, width: Double(play.width), height: cropH))!,
          CGRect(x: 0, y: 0, width: W, height: cropH * scale))
drawImage(play.cropping(to: CGRect(x: 0, y: footerSrcY, width: Double(play.width), height: Double(play.height) - footerSrcY))!,
          CGRect(x: 0, y: H - footerH, width: W, height: footerH))

let img = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
CGImageDestinationFinalize(dest)

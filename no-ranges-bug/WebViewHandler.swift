import Foundation
import MobileCoreServices
import WebKit

class WebViewHander: NSObject, WKURLSchemeHandler {

  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {

    if var startPath = Bundle.main.path(forResource: "www", ofType: nil) {
        let url = urlSchemeTask.request.url!
        let stringToLoad = url.path

        if stringToLoad.isEmpty || url.pathExtension.isEmpty {
            startPath.append("/index.html")
        } else {
            startPath.append(stringToLoad)
        }
        
        
        let localUrl = URL.init(string: url.absoluteString)!
        let fileUrl = URL.init(fileURLWithPath: startPath)
        
        print("Received headers \(String(describing: urlSchemeTask.request.allHTTPHeaderFields))")

        do {
          let fileHandle = try FileHandle(forReadingFrom: fileUrl)
          let mimeType = mimeTypeForExtension(pathExtension: url.pathExtension)
          let optionalRangeHeader = urlSchemeTask.request.value(forHTTPHeaderField: "Range")
          var headers =  [
            "Content-Type": mimeType,
          ]
          let data: Data
          var statusCode = 200
          if optionalRangeHeader != nil && isMediaExtension(pathExtension: url.pathExtension) {
            let expectedContentLength = try fileUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize!
            let range = chunkRange(ofHeaderValue: optionalRangeHeader!, totalLength: expectedContentLength)
            let requestedContentLength = range.1 - range.0 + 1 // end index is inclusive per standard
            try fileHandle.seek(toOffset: UInt64(range.0))
            data = fileHandle.readData(ofLength: requestedContentLength)
            statusCode = 206
            headers["Content-Range"] = "bytes \(String(range.0))-\(String(range.1))/\(String(expectedContentLength))"
            headers["Accept-Ranges"] = "bytes"
            headers["Content-Length"] = String(data.count)
            print("Sending headers \(String(describing: headers))")
          } else {
            data = fileHandle.readDataToEndOfFile()
            headers["Content-Length"] = String(data.count)
          }
          let response = HTTPURLResponse(url: localUrl, statusCode: statusCode, httpVersion: nil, headerFields: headers)
          urlSchemeTask.didReceive(response!)
          urlSchemeTask.didReceive(data)
          try fileHandle.close()
        } catch let error as NSError {
          urlSchemeTask.didFailWithError(error)
          return
        }
        urlSchemeTask.didFinish()
    }
      
  }
    
    func chunkRange(ofHeaderValue rangeHeader: String, totalLength length: Int) -> (Int, Int) {
        let prefix = "bytes="
        if !rangeHeader.starts(with: prefix) {
            return (0, length)
        }
    
        let index = rangeHeader.index(rangeHeader.startIndex, offsetBy: prefix.count)
        let parts = String(rangeHeader[index...]).split(separator: "-", maxSplits: 1).map({ Int($0)})
        let end = parts.count > 1 && parts[1] != nil ? parts[1]! : length
        return (parts[0] ?? 0, end)
    }

  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    print("scheme stop")
  }

  func mimeTypeForExtension(pathExtension: String) -> String {
    if !pathExtension.isEmpty {
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
        if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
          return mimetype as String
        }
      }
      return "application/octet-stream"
    }
    return "text/html"
  }

  func isMediaExtension(pathExtension: String) -> Bool {
    let mediaExtensions = ["m4v", "mov", "mp4",
                           "aac", "ac3", "aiff", "au", "flac", "m4a", "mp3", "wav"]
    if mediaExtensions.contains(pathExtension.lowercased()) {
      return true
    }
    return false
  }
}

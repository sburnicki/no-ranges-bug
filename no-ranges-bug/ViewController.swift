//
//  ViewController.swift
//  no-ranges-bug
//
//  Created by Julio Cesar Sanchez Hernandez on 23/10/2019.
//  Copyright © 2019 Julio Cesar Sanchez Hernandez. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    override func viewDidLoad() {
    super.viewDidLoad()
        let request = URLRequest(url: URL(string: "customscheme://localhost/index.html")!)
        _ = webView?.load(request)
    }
    override func loadView() {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.setURLSchemeHandler(WebViewHander(), forURLScheme: "customscheme")
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        view = webView
    }
}

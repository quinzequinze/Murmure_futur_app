//
//  ViewController.swift
//  laridmeIOS
//
//  Created by Victor J. Meunier & Cyril Martin on 09/03/2016.
//  Copyright © 2016 quinzequinze. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation

let maxRecTime: NSTimeInterval = 8.000
let minRecTime: NSTimeInterval = 4.000

var recordingSession: AVAudioSession!
var audioRecorder: AVAudioRecorder!
var phone:NSNumber = Int(UIDevice.currentDevice().name)!
var retryTimer: NSTimer!
let recordSettings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
    AVFormatIDKey : NSNumber(int: Int32(kAudioFormatMPEG4AAC)),
    AVNumberOfChannelsKey : NSNumber(int: 1),
    AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]
var duration:NSTimeInterval!

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, AVAudioRecorderDelegate {
    
    
    var webView: WKWebView?
    var webConfig:WKWebViewConfiguration {
        get {
            let webCfg:WKWebViewConfiguration = WKWebViewConfiguration()
            let userController:WKUserContentController = WKUserContentController()
            print(phone)
            let userScript = WKUserScript(
                source: "var TAG_ID = \(phone);",
                injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
                forMainFrameOnly: true
            )
            userController.addUserScript(userScript)
            userController.addScriptMessageHandler(self, name: "scriptMessageHandler")
            
            if #available(iOS 9.0, *) {
                webCfg.requiresUserActionForMediaPlayback = false
            }
            
            webCfg.userContentController = userController;
            return webCfg;
        }
    }
    
    var audioRecorder:AVAudioRecorder!


    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        webConfig.preferences = preferences
        webView = WKWebView(frame: view.bounds, configuration: webConfig)
        webView!.navigationDelegate = self
        view.addSubview(webView!)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(URL: self.directoryURL()!,
                settings: recordSettings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
        } catch {
        }
        
        UIDevice.currentDevice().batteryMonitoringEnabled = true


    }
    func batteryLevel() -> Float {
        return UIDevice.currentDevice().batteryLevel
    }
    
    func directoryURL() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        let uuid = NSUUID().UUIDString + ".m4a"
        let soundURL = documentDirectory.URLByAppendingPathComponent(uuid)
        return soundURL
    }
    
    func doRecordAction() {
        if !audioRecorder.recording {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(true)
                audioRecorder.recordForDuration(maxRecTime)
                duration = audioRecorder.currentTime
                
            } catch {
            }
        }
    }
    
    func doPlayAction() {
        
    }
    
    func doStopAction() {
        duration = audioRecorder.currentTime
        audioRecorder.stop()
    }
    
    
    func doSendAction() {
        let fileData = NSData(contentsOfURL: audioRecorder.url)
        webView?.evaluateJavaScript("uploadSound('\(fileData)')", completionHandler: { (AnyObject, NSError) -> Void in print(__FUNCTION__)})
    }
    
    func doPauseAction(sender: AnyObject) {
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
connect()
    }
    func connect(){
        let url = NSURL(string: "http://breal.local:4000")
        let urlRequest = NSURLRequest(URL: url!)
        webView!.loadRequest(urlRequest)
        
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
         print("Finished navigating to url \(navigation)")
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print("fail")
        
        retryTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "connect", userInfo: nil, repeats: false)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {

    }
    
    func getScript(name: String) ->String{
        var script:String?
        if let filePath:String = NSBundle(forClass: ViewController.self).pathForResource(name, ofType:"js") {
            script = try? String (contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        }
        return script!;
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print(message.body as! String)
        if let messageBody:String = message.body as? String {
            print(messageBody)
            if(messageBody=="beginRecord" ){
                doRecordAction()
            }
            if(messageBody=="endRecord" ){
                doStopAction()
            }
            if(messageBody=="getBattery" ){
                webView?.evaluateJavaScript("battery = \(batteryLevel())", completionHandler: { (AnyObject, NSError) -> Void in print(__FUNCTION__)})

            }
        }
    }
    func audioRecorderDidFinishRecording(audioRecorder: AVAudioRecorder, successfully flag: Bool) {
        print(duration)
        
        if(duration < minRecTime){
            print("enregistrement trop court -> suprimé")
            audioRecorder.deleteRecording()
        }else{
            doSendAction()
        }
        audioRecorder.prepareToRecord()
        
    }
}


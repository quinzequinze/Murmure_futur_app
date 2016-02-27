import UIKit
import WebKit
import AVFoundation



var userId: String = "monID"


let maxRecTime: NSTimeInterval = 8.000
let minRecTime: NSTimeInterval = 4.000
var recordingSession: AVAudioSession!
var audioRecorder: AVAudioRecorder!
let recordSettings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
    AVFormatIDKey : NSNumber(int: Int32(kAudioFormatMPEG4AAC)),
    AVNumberOfChannelsKey : NSNumber(int: 1),
    AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]


class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, AVAudioRecorderDelegate {
    var webView: WKWebView?
    var webConfig:WKWebViewConfiguration {
        get {
            let webCfg:WKWebViewConfiguration = WKWebViewConfiguration()
            let userController:WKUserContentController = WKUserContentController()
            
            let userScript = WKUserScript(
                source: "var TAG_ID = 3",
                injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
                forMainFrameOnly: true
            )
            userController.addUserScript(userScript)
            
            userController.addScriptMessageHandler(self, name: "scriptMessageHandler")
            
            if #available(iOS 9.0, *) {
                webCfg.requiresUserActionForMediaPlayback = false
            } else {
                // Fallback on earlier versions
            }
            
            //let js:String = getScript()
            //let userScript:WKUserScript =  WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
            //userController.addUserScript(userScript)
            webCfg.userContentController = userController;
            return webCfg;
        }
    }
    
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!

    
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
        ////////////
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(URL: self.directoryURL()!,
                settings: recordSettings)
                audioRecorder.delegate = self
            audioRecorder.recordForDuration(maxRecTime)
        } catch {
        }
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
            } catch {
            }
        }
    }
    
    func doPlayAction() {
        if (!audioRecorder.recording){
            do {
                try audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder.url)
                audioPlayer.play()
            } catch {
            }
        }
        
        
    }
    
    func doStopAction() {
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        //do {
          //  try audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder.url)
            //if(audioPlayer.duration < minRecTime){
              //  print("enregistrement trop court -> suprimé")
              //  audioRecorder.deleteRecording()
           // }else if(audioPlayer.playing){
             //   audioPlayer.stop()
           // }else{
             //   print("duration : " ,audioPlayer.duration )
               // print("path : " ,audioRecorder.url)
                
            //}
        //} catch {
        //}
        
        //do {
          //  try audioSession.setActive(false)
        //}
       // catch {
        //}
    }
    
    
    func doSendAction() {
        print(audioRecorder.url)
        let fileData = NSData(contentsOfURL: audioRecorder.url)
        webView?.evaluateJavaScript("client.uploadSound('\(fileData)')", completionHandler: { (AnyObject, NSError) -> Void in print(__FUNCTION__)})
    }
    
    func doPauseAction(sender: AnyObject) {
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let url = NSURL(string: "http://vigo.local:4000/")
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
        print(__FUNCTION__)
        
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        print(__FUNCTION__ ,error.localizedDescription)
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
            //print(messageBody)
            
            if(messageBody=="beginRecord" ){
                doRecordAction()
            }
            
            if(messageBody=="endRecord" ){
                doStopAction()
            }
            
            }
            if let messageBody:NSDictionary = message.body as? NSDictionary {
          
            }
            
        }
    func audioRecorderDidFinishRecording(audioRecorder: AVAudioRecorder, successfully flag: Bool) {
        print("Recording finished")
doSendAction()
    }

}
///webView?.evaluateJavaScript(js, completionHandler: { (AnyObject, NSError) -> Void in print(__FUNCTION__)})


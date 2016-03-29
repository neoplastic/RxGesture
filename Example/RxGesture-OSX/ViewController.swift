//
//  ViewController.swift
//  RxGesture-OSX
//
//  Created by Marin Todorov on 3/24/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Cocoa

import RxSwift
import RxCocoa
import RxGesture

class MacViewController: NSViewController {

    let infoList = [
        "Click the square",
        "Right click the square",
        "Click any button (left or right)",
        "Drag the square around"
    ]
    
    let codeList = [
        "myView.rx_gesture(.Click).subscribeNext {...}",
        "myView.rx_gesture(.RightClick).subscribeNext {...}",
        "myView.rx_gesture(RxGestureTypeOptions.all()).subscribeNext {...}",
        "myView.rx_gesture([.Panning(.zero), .DidPan(.zero)]).subscribeNext {...}"
    ]
    
    @IBOutlet weak var myView: NSView!
    @IBOutlet weak var myViewText: NSTextField!
    @IBOutlet weak var info: NSTextField!
    @IBOutlet weak var code: NSTextField!
    
    private let nextStep😁 = PublishSubject<Void>()
    private let bag = DisposeBag()
    private var stepBag = DisposeBag()

    override func viewWillAppear() {
        super.viewWillAppear()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        myView.wantsLayer = true
        myView.layer?.backgroundColor = NSColor.redColor().CGColor
        myView.layer?.cornerRadius = 5
        
        nextStep😁.scan(0, accumulator: {acc, _ in
            return acc < 3 ? acc + 1 : 0
        })
        .startWith(0)
        .subscribeNext(step)
        .addDisposableTo(bag)
    }
    
    func step(step: Int) {
        //release previous recognizers
        stepBag = DisposeBag()
        
        info.stringValue = "\(step+1). \(infoList[step])"
        code.stringValue = codeList[step]
        
        //add current step recognizer
        switch step {
        case 0: //left click recognizer
            myView.rx_gesture(.Click).subscribeNext {[weak self] _ in
                
                self?.myView.layer!.backgroundColor = NSColor.blueColor().CGColor
                
                let anim = CABasicAnimation(keyPath: "backgroundColor")
                anim.fromValue = NSColor.redColor().CGColor
                anim.toValue = NSColor.blueColor().CGColor
                self?.myView.layer!.addAnimation(anim, forKey: nil)
                
                self?.nextStep😁.onNext()
                
            }.addDisposableTo(stepBag)
            
        case 1: //right click recognizer
            myView.rx_gesture(.RightClick).subscribeNext {[weak self] _ in
                
                self?.myView.layer!.transform = CATransform3DMakeScale(1.5, 1.5, 1.5)

                let anim = CABasicAnimation(keyPath: "transform")
                anim.duration = 0.5
                anim.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
                anim.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1.5, 1.5, 1.5))
                self?.myView.layer!.addAnimation(anim, forKey: nil)
                
                self?.nextStep😁.onNext()
                
            }.addDisposableTo(stepBag)
            
        case 2: //any button
            myView.rx_gesture([.Click, .RightClick]).subscribeNext {[weak self] _ in
                
                self?.myView.layer!.transform = CATransform3DIdentity
                self?.myView.layer!.backgroundColor = NSColor.redColor().CGColor
                
                let anim = CABasicAnimation(keyPath: "transform")
                anim.duration = 0.5
                anim.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(1.5, 1.5, 1.5))
                anim.toValue = NSValue(CATransform3D: CATransform3DIdentity)
                self?.myView.layer!.addAnimation(anim, forKey: nil)
                
                self?.nextStep😁.onNext()
            }.addDisposableTo(stepBag)
            
        case 3: //pan
            myView.rx_gesture([.Panning(.zero), .DidPan(.zero)]).subscribeNext {[weak self] gesture in
                
                switch gesture {
                case (.Panning(let offset)):
                    self?.myViewText.stringValue = String(format: "(%.f, %.f)", arguments: [offset.x, offset.y])
                    self?.myView.layer!.transform = CATransform3DMakeTranslation(offset.x, offset.y, 0.0)
                case (.DidPan(_)):
                    self?.myViewText.stringValue = ""
                    
                    let anim = CABasicAnimation(keyPath: "transform")
                    anim.duration = 0.5
                    anim.fromValue = NSValue(CATransform3D: self!.myView.layer!.transform)
                    anim.toValue = NSValue(CATransform3D: CATransform3DIdentity)
                    self?.myView.layer!.addAnimation(anim, forKey: nil)
                    self?.myView.layer!.transform = CATransform3DIdentity
                    
                    self?.nextStep😁.onNext()
                default: break
                }
            }.addDisposableTo(stepBag)
            
        default: break
        }
    }

}

//
//  UnderlinedSegmentedControl.swift
//  Paging Underlined Segmented Control
//
//  Created by Jake Cronin on 12/2/16.
//  Copyright © 2016 Jake Cronin. All rights reserved.
//

import UIKit

@IBDesignable class UnderlinedSegmentedControl: UIControl{
	
	private var underline = UIView()		//this is the view of the selectedLabel
	private var labels = [UILabel]()		//these labels are subviews to put onto the thumb, each representing a segment
	
    var itemNames: [String] = ["供貨商",
                               "規格"]{
		didSet{
			setupLabels()
		}
	}
    
    
    
	var selectedIndex: Int = 0{
		didSet{
			animateChangedSelection()
		}
	}
	
    
    var itemFont: UIFont = UIFont.systemFont(ofSize: 12){
		didSet{
			for label in labels{
				label.font = itemFont
			}

		}
	}
	
	//Selectable Properties editable directly from Attributes Inspector in Main Storyboard//////////////////
	@IBInspectable var selectedItemColor: UIColor = UIColor(red: 0, green: 120/255, blue: 1, alpha: 1){
		didSet{
			changedColor()
		}
	}
	
    @IBInspectable var unselectedItemColor: UIColor = UIColor.black{
		didSet{
			changedColor()
		}
	}
	
    @IBInspectable var underlineColor: UIColor = UIColor(red: 0, green: 120/255, blue: 1, alpha: 1){
		didSet{
			changedColor()
		}
	}
	
    @IBInspectable var fontSize: CGFloat = 16{
		didSet{
			for label in labels{
				label.font = label.font.withSize(fontSize)
			}

		}
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//SETUP FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupSCView()
	}
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupSCView()
	}
	func setupSCView(){
		layer.cornerRadius = frame.height / 2
        //整體segment的框框顏色
        layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
        layer.borderWidth = 2
		
		setupLabels() //set up the label views and add them as subviews to the segmented controller
		
        insertSubview(underline, at: 0)
		
		
	}
	func setupLabels(){
		for label in labels{
			label.removeFromSuperview()	//remove all label views from segmented controller, so we have a blank slate
		}
        labels.removeAll(keepingCapacity: true) //empty labels array to make room for new labels
		
		for index in 0..<itemNames.count{
			let label = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 70))	//initialized at point (0,0) with hight 40, width 70
			label.text = itemNames[index]
			label.translatesAutoresizingMaskIntoConstraints = false
			label.textAlignment = .center
			//label.font = UIFont(name: "Avenir", size: 12)
            label.font = UIFont.systemFont(ofSize: 14) // 調label字的大小
            
            label.textColor = index == selectedIndex ? selectedItemColor : unselectedItemColor	//logic for selected or not
			self.addSubview(label)	//add label view as a subview to segmented view controller
			labels.append(label)	//add this newly created label to the array of labels
		}
		
        addConstraints(labels: labels, scView: self, padding: 0)
        
        //add constraints to all of the lables so they fit in the view controller nicely
	}	//build label views and add them to the scView, called by setupSCView

    
    func addConstraints(labels: [UIView], scView: UIView, padding: CGFloat){
       
		for (index, label) in labels.enumerated(){	//for each label... set constraints
			//TOP CONSTRAINT
			let topConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: scView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0)	//set top of label to top of the segmented view
			
			//BOTTOM CONSTRAINT
			let bottomConstraint = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: scView, attribute: .bottom, multiplier: 1.0, constant: 0)	//set bottom of label to bottom of segmented view
			
			//RIGHT CONSTRAINT
			var rightConstraint: NSLayoutConstraint
			if index == labels.count - 1{	//last label right side gets set to right edge of segmented view
				rightConstraint = NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: scView, attribute: .right, multiplier: 1.0, constant: 0)
			}else{	//other labels have their right side set against neighbor label
				let buttonOnRight = labels[index + 1]
				rightConstraint = NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: buttonOnRight, attribute: .left, multiplier: 1.0, constant: -padding)
			}
			
			//LEFT CONSTRAINT
			var leftConstraint: NSLayoutConstraint
			if index == 0{	//this is the first label, so left constarint set against left side of segmented view
				leftConstraint = NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: scView, attribute: .left, multiplier: 1.0, constant: padding)
			}else{
				let buttonOnRight = labels[index-1]
				leftConstraint = NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: buttonOnRight, attribute: .right, multiplier: 1.0, constant: padding)
			
				//WIDTH CONSTRAINT
				//now for each label (excluding the first label), set its width constraint equal to first label
				let firstItem = labels[0]
				let widthConstraint = NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: firstItem, attribute: .width, multiplier: 1.0  , constant: 0)
				scView.addConstraint(widthConstraint)
			}
			
			//ADD CONSTRAINTS TO THE SEGMENTED CONTROLLER
			scView.addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
		}
	}	//add constraints to labels so they fit into segmented view controller nicely, called by setupLabels
    
    
	override func layoutSubviews() {
		super.layoutSubviews()
		let selectedLabel = self.labels[self.selectedIndex]
		let underlineHeight: CGFloat = 1
		let underlineOffset: CGFloat = 5
		
        let textFrame = self.frameOfTextInLabel(label: selectedLabel)

		
		//self.underline.frame = CGRect(x: textFrame.minX, y: textFrame.minY + underlineOffset, width: textFrame.width, height: underlineHeight)
        
        
        self.underline.frame = CGRect(x: textFrame.minX, y: textFrame.minY + underlineOffset, width: textFrame.width, height: underlineHeight)
        
        //print("underlineframe: \(self.underline.frame.origin.x),\(self.underline.frame.origin.y),\(self.underline.frame.size.width),\(self.underline.frame.size.height)")
        
        //Make(textFrame.minX, textFrame.maxY + underlineOffset, textFrame.width, underlineHeight)

		
		underline.backgroundColor = underlineColor
		underline.layer.cornerRadius = underline.frame.height / 2
        //print("\(underline.frame.height)")
        
		animateChangedSelection()
	}//used to get set position and size of 'selectedView' as we did not give it constraints
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	//RUNTIME FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////
	func animateChangedSelection(){
		for label in labels {	//give all labels 'unselected' color
			label.textColor = unselectedItemColor
		}
		let label = labels[selectedIndex]			//give seleted label the 'selected label' color
		label.textColor = selectedItemColor
		
        
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .allowAnimatedContent, animations: {
        
            			let selectedLabel = self.labels[self.selectedIndex]
            			let underlineHeight: CGFloat = 5
            			let underlineOffset: CGFloat = 5
            
                        let textFrame = self.frameOfTextInLabel(label: selectedLabel)
            
            			self.underline.frame = CGRect(x: textFrame.minX, y: textFrame.maxY + underlineOffset, width: textFrame.width, height: underlineHeight)

        }, completion: nil)
    }
    
//selected view slides over to the index that was selected
//handle logic and animation when selectedIndex changes and we need to move the selectedView

    
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let location = touch.location(in: self)
        
        //let location = touch.locationInView(self)	//tracks touches without our segmented view
        
        var calculatedIndex : Int?
        for (index, item) in labels.enumerated() {	//figure out which index was selected
            
            _ = frameOfTextInLabel(label: item)//frameOfTextInLabel(item)
            if frameOfTextInLabel(label: item).contains(location) {
                calculatedIndex = index
            }
        }
        
        if calculatedIndex != nil {
            selectedIndex = calculatedIndex!	//when index is changed, animateChangedSelection is automatically called
            
            sendActions(for: .valueChanged)
            
            
            let notificationName = Notification.Name("SegmentWasSelected")
            
            //NotificationCenter.default.post(name: notificationName, object: nil
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo: ["selected":calculatedIndex!])
//            NotificationCenter.default.post(name: NSNotification.Name.init("SegmentWasSelected"), object: nil, userInfo: ["selected":calculatedIndex!])
            
            
            
            //print("selected \(calculatedIndex)")
            	//trigger any events hooked up to this segmented control
        }
        return false
    }
    
    
    
	func frameOfTextInLabel(label: UILabel) -> CGRect{
		
		let textSize = label.intrinsicContentSize
        
        // let xOffset = (label.frame.width - textSize.width) / 2
		_ = (label.frame.width - textSize.width) / 2
		//let	x = label.frame.minX + xOffset
		//let	x = label.frame.minX + xOffset/2
        let x = label.frame.minX
        
		let yOffset = (label.frame.height - textSize.height) / 2
		let y = label.frame.minY + yOffset
		
		//let width = textSize.width
        //let width = textSize.width + xOffset
        let width = label.frame.size.width
		let height = textSize.height
		//let y = label.textRectForBounds(label.frame, limitedToNumberOfLines: 0).minY
		//let yTop = label.textRectForBounds(self.frame, limitedToNumberOfLines: 0).minY
		//let yBottom =
		//let y = self.frame.minY //+ yOffset
		let toReturn = CGRect(x: x, y: y, width: width, height: height)
		return toReturn
	}
    
    
    
	
    func changedColor(){
		for label in labels{
			label.textColor = unselectedItemColor
		}
		labels[selectedIndex].textColor = selectedItemColor
		underline.backgroundColor = underlineColor
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

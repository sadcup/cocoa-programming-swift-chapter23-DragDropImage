//
//  DragDropView.swift
//  DragDropImage
//
//  Created by Netiger on 14-11-24.
//  Copyright (c) 2014年 Sadcup. All rights reserved.
//

import Cocoa
let kPrivateDragUTI = "com.sadcup.swiftdraganddrop"
class DragDropView: NSView, NSDraggingDestination, NSDraggingSource, NSPasteboardItemDataProvider{

    var image:NSImage! {
        didSet {
            self.needsDisplay = true
        }
    }
    var highlight:Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        commoninit()
    }
    
    func commoninit() {
        image = NSImage(size: self.bounds.size)
        highlight = false
        var registerTypes = [NSURLPboardType, NSPasteboardTypePDF, kPrivateDragUTI]
        self.registerForDraggedTypes(registerTypes)
    }
    
    //MARK: Pasteboard
    override var acceptsFirstResponder: Bool {
        get {
            println("Accepting first responder")
            return true
        }
    }
    override func resignFirstResponder() -> Bool {
        println("Resigning first responder")
        //self.needsDisplay = true
        self.setKeyboardFocusRingNeedsDisplayInRect(self.bounds)
        return true
    }
    override func becomeFirstResponder() -> Bool {
        println("Becoming first responder")
        self.needsDisplay = true
        return true
    }
    func writeToPasteboard(pb:NSPasteboard) {
        pb.clearContents()
        pb.writeObjects([image])
    }
    func realdFromPasteboard(pb:NSPasteboard) -> Bool {
        let classes = NSArray(object: NSImage.self)
        let objects:NSArray = pb.readObjectsForClasses(classes, options:nil)!
        self.image = objects.objectAtIndex(0) as NSImage
        return true
    }
    @IBAction func copy(sender: AnyObject) {
        let pb = NSPasteboard.generalPasteboard()
        self.writeToPasteboard(pb)
    }
    @IBAction func paste(sender: AnyObject) {
        let pb = NSPasteboard.generalPasteboard()
        if !self.realdFromPasteboard(pb) {
            NSBeep()
        }
    }
    @IBAction func cut(sender: AnyObject) {
        self.copy(sender)
        self.image = NSImage()
    }

    
    //MARK: Drag Source
    func draggingSession(session: NSDraggingSession, sourceOperationMaskForDraggingContext context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case NSDraggingContext.OutsideApplication:
            return NSDragOperation.Copy
        case NSDraggingContext.WithinApplication:
            return NSDragOperation.Copy
        default:
            return NSDragOperation.Copy
        }
    }
    
    func pasteboard(pasteboard: NSPasteboard!, item: NSPasteboardItem!, provideDataForType type: String!) {
        if type.compare(NSPasteboardTypeTIFF) == NSComparisonResult.OrderedSame {
            if let thisImage:NSImage = self.image {
                pasteboard.setData(thisImage.TIFFRepresentation!, forType: NSPasteboardTypeTIFF)
            }
        }
        else if type.compare(NSPasteboardTypePDF) == NSComparisonResult.OrderedSame {
            pasteboard.setData(self.dataWithPDFInsideRect(self.bounds), forType: NSPasteboardTypePDF)
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        var pbItem = NSPasteboardItem()
        pbItem.setDataProvider(self, forTypes: [NSPasteboardTypeTIFF, NSPasteboardTypePDF, kPrivateDragUTI])
        var dragItem = NSDraggingItem(pasteboardWriter: pbItem)
        var draggingRect = self.bounds
        dragItem.setDraggingFrame(draggingRect, contents: self.image)
        var draggingSession = self.beginDraggingSessionWithItems([dragItem], event: theEvent, source: self)
        draggingSession.animatesToStartingPositionsOnCancelOrFail = true
        draggingSession.draggingFormation = NSDraggingFormation.None
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent) -> Bool {
        return true
    }
    
    //MARK: Drag Destination
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        var maskCheck = (sender.draggingSourceOperationMask() & NSDragOperation.Copy).rawValue == 1 ? true : false
        if NSImage.canInitWithPasteboard(sender.draggingPasteboard()) {
            highlight = true
            self.needsDisplay = true
            
            //The enumerateDraggingItemsWithOptions will not work.
//            sender.enumerateDraggingItemsWithOptions(.Concurrent, forView: self, classes: [NSPasteboardItem.self], searchOptions: [NSPasteboardURLReadingContentsConformToTypesKey:self], usingBlock: { (draggingItem, idx, stop) -> Void in
//                if !contains(draggingItem.item.types as Array<String>, kPrivateDragUTI) {
//                    stop.memory = true
//                    println("1")
//                }
//                else {
//                    draggingItem.setDraggingFrame(self.bounds, contents: draggingItem.imageComponents[0].contents)
//                    println("2")
//                }
//            })
            return NSDragOperation.Copy
        }
        return NSDragOperation.None
    }
    
    override func draggingExited(sender: NSDraggingInfo?) {
        highlight = false
        self.needsDisplay = true
    }
    
    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        highlight = false
        self.needsDisplay = true
        return NSImage.canInitWithPasteboard(sender.draggingPasteboard())
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let tmp = sender.draggingPasteboard()
        if !(sender.draggingSource() === self) {
            var fileURL = NSURL()
            if NSImage.canInitWithPasteboard(sender.draggingPasteboard()) {
                self.image = NSImage(pasteboard: sender.draggingPasteboard())!
            }
            if let fileURL:NSURL = NSURL(fromPasteboard: sender.draggingPasteboard()) {
                self.window?.title = fileURL.absoluteString
            }
            else {
                self.window?.title = "(no name)"
            }
        }
        return true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        println("drawRect")
        
        if highlight {
            NSColor.grayColor().set()
            NSBezierPath.setDefaultLineWidth(5)
            NSBezierPath.strokeRect(dirtyRect)
        }
        
        if let curImage:NSImage = image {
            var imageRect = NSRect()
            imageRect.origin = NSZeroPoint
            imageRect.size = curImage.size
            var drawingRect = self.bounds
            curImage.drawInRect(drawingRect)
        }
    }
    
}














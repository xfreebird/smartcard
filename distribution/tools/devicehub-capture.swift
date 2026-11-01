import AppKit
import ApplicationServices

// Native compositor capture only. Prepare a disposable Duo's fold state and orientation in Device Hub.
func fail(_ message:String)->Never { FileHandle.standardError.write(Data((message+"\n").utf8));exit(2) }
let args=CommandLine.arguments
guard args.count==3 else { fail("Usage: devicehub-capture TASK_DEVICE_NAME Screenshot") }
let name=args[1]
guard name.hasPrefix("eSemnBun-store-"),args[2]=="Screenshot" else { fail("Only task-owned native screenshots are supported; configure fold/orientation in Device Hub") }
guard AXIsProcessTrusted() else { fail("Existing Accessibility authorization is required") }
guard let hub=NSRunningApplication.runningApplications(withBundleIdentifier:"com.apple.dt.Devices").first else { fail("Open Device Hub and select the prepared task simulator") }
guard NSWorkspace.shared.frontmostApplication?.processIdentifier==hub.processIdentifier else { fail("Bring Device Hub to the foreground before capturing the prepared Duo") }
func value(_ element:AXUIElement,_ key:String)->CFTypeRef? { var result:CFTypeRef?;AXUIElementCopyAttributeValue(element,key as CFString,&result);return result }
func nodes(_ element:AXUIElement)->[AXUIElement] { [element]+((value(element,kAXChildrenAttribute) as? [AXUIElement]) ?? []).flatMap { nodes($0) } }
let root=AXUIElementCreateApplication(hub.processIdentifier)
guard let row=nodes(root).first(where:{ element in
 value(element,kAXRoleAttribute) as? String==kAXRowRole && [kAXTitleAttribute,kAXDescriptionAttribute,kAXValueAttribute].contains { key in
 (value(element,key) as? String)?.components(separatedBy:.newlines).first==name
 }
}),value(row,kAXSelectedAttribute) as? Bool==true else { fail("Select the exact prepared task simulator in Device Hub: "+name) }
if let notice=nodes(root).first(where:{ element in value(element,kAXRoleAttribute) as? String==kAXButtonRole && [kAXTitleAttribute,kAXDescriptionAttribute].contains { key in value(element,key) as? String=="Not Now" } }) {
 AXUIElementPerformAction(notice,kAXPressAction as CFString)
 Thread.sleep(forTimeInterval:1)
}
guard let button=nodes(root).first(where:{ element in value(element,kAXRoleAttribute) as? String==kAXButtonRole && [kAXTitleAttribute,kAXDescriptionAttribute].contains { key in value(element,key) as? String=="Screenshot" } }),let p=value(button,kAXPositionAttribute),let s=value(button,kAXSizeAttribute) else { fail("Native Screenshot control unavailable; verify the task device is selected and no menu is open") }
var point=CGPoint.zero;var size=CGSize.zero
AXValueGetValue(p as! AXValue,.cgPoint,&point);AXValueGetValue(s as! AXValue,.cgSize,&size)
point.x += size.width/2;point.y += size.height/2
let down=CGEvent(mouseEventSource:nil,mouseType:.leftMouseDown,mouseCursorPosition:point,mouseButton:.left);down?.flags=[];down?.post(tap:.cghidEventTap)
let up=CGEvent(mouseEventSource:nil,mouseType:.leftMouseUp,mouseCursorPosition:point,mouseButton:.left);up?.flags=[];up?.post(tap:.cghidEventTap)
Thread.sleep(forTimeInterval:1.5)

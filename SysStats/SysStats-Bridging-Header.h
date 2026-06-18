#ifndef SysStats_Bridging_Header_h
#define SysStats_Bridging_Header_h

#import <Foundation/Foundation.h>

// Public SDK headers: client/service types + Create/CopyServices/CopyProperty.
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>

// IOHIDEvent is not declared in the public SDK; treat it as a CF type so ARC
// releases the events we copy.
typedef CFTypeRef IOHIDEventRef;

// Functions the public headers omit. Reading thermal sensors this way needs no
// root, entitlement, or helper. Allowed for Developer ID / direct distribution;
// only the Mac App Store forbids private API.
// NOTE: the public ...CreateSimpleClient enumerates services but cannot read
// their temperature events — only this private Create can.
IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int32_t options, int64_t timestamp);
double IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

#endif /* SysStats_Bridging_Header_h */

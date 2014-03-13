//
//  MessageBox.m
//
// Created by Olivier Louvignes on 2011-11-26
// Updated on 2012-08-04 for Cordova ARC-2.1+
//
// Copyright 2011 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "MessageBox.h"

@implementation MessageBox

@synthesize callbackId = _callbackId;

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

- (void)prompt:(CDVInvokedUrlCommand*)command {
  
	self.callbackId = command.callbackId;
	NSDictionary *options = [command.arguments objectAtIndex:0];
  
	// Compiling options with defaults
	NSString *title = [options objectForKey:@"title"] ?: @"Prompt";
	NSMutableString *message = [NSMutableString stringWithString: ([options objectForKey:@"message"] ?: @"")];
	NSString *type = [options objectForKey:@"type"] ?: @"text";
	NSString *placeholder = [options objectForKey:@"placeholder"] ?: @"";
  NSString *okButtonTitle = [options objectForKey:@"okButtonTitle"] ?: @"OK";
  NSString *cancelButtonTitle = [options objectForKey:@"cancelButtonTitle"] ?: @"Cancel";
	NSInteger textFieldPositionRow = (int)[options objectForKey:@"textFieldPositionRow"] ?: 1;
  
	// Increment textFieldPositionRow if there is a message
	if ([message length] != 0 && textFieldPositionRow == 1) {
		[message appendString: @"\n"];
		textFieldPositionRow = 2 + [message length] / 35;
	}
	// Append line-break to the message
	[message appendString: @"\n"];
  
	// Create UIAlertView popup
	UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:title
                                                   message:message
                                                  delegate:self
                                         cancelButtonTitle:cancelButtonTitle
                                         otherButtonTitles:okButtonTitle, nil];
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
    // iOS 5 or newer
    
    // Configure keyboard type
    prompt.alertViewStyle = [[type lowercaseString] isEqualToString:@"password"] ? UIAlertViewStyleSecureTextInput : UIAlertViewStylePlainTextInput;
    
    // Set placeholder text if any
    if ([placeholder length] != 0) [[prompt textFieldAtIndex:0] setPlaceholder:placeholder];
    
    // Display prompt
    [prompt show];
    
    [[prompt textFieldAtIndex:0] resignFirstResponder];
    
    // Set keyboard type
    if ([[type lowercaseString] isEqualToString:@"decimalpad"]) [[prompt textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
    if ([[type lowercaseString] isEqualToString:@"email"]) [[prompt textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    
    // Set cursor and have keyboard shown
    [[prompt textFieldAtIndex:0] becomeFirstResponder];
    
  } else {
    // Pre iOS 5
    
    // Create prompt textField
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 20.0 + textFieldPositionRow*25.0, 260.0, 25.0)]; // left, top, width, height
    [textField setBackgroundColor:[UIColor whiteColor]];
    if ([placeholder length] != 0) [textField setPlaceholder:placeholder];
    
    // Configure keyboard type
    if ([[type lowercaseString] isEqualToString:@"password"]) [textField setSecureTextEntry:YES];
    if ([[type lowercaseString] isEqualToString:@"decimalpad"]) [textField setKeyboardType:UIKeyboardTypeDecimalPad];
    if ([[type lowercaseString] isEqualToString:@"email"]) [textField setKeyboardType:UIKeyboardTypeEmailAddress];
    
    [prompt addSubview:textField];
    
    // Position fix for iOS < 4
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    if ([iOSVersion intValue] < 4) {
      [prompt setTransform:CGAffineTransformMakeTranslation(0.0, 110.0)];
    }
    
    // Display prompt
    [prompt show];
    
    // Set cursor and show keyboard
    [textField becomeFirstResponder];
  }
}

- (void)alertView:(UIAlertView *)view clickedButtonAtIndex:(NSInteger)buttonIndex {
	
  // Retrieve textField object from view
  UITextField *textField = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") ? [ view textFieldAtIndex: 0 ] : [view.subviews objectAtIndex:5];
  
	// Build returned result
	NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                          textField.text, @"value",
                          [NSNumber numberWithInteger:buttonIndex], @"buttonIndex", nil];
	
	// Create Plugin Result
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
	
	// Checking if cancel was clicked
	if (buttonIndex != [view cancelButtonIndex]) {
		[self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackId]];
	} else {
		//Call  the Failure Javascript function
		[self writeJavascript: [pluginResult toErrorCallbackString:self.callbackId]];
	}
	
}

@end

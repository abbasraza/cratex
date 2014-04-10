//
//  main.m
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static void EWActivateFont(NSString *fontName)
{
    NSURL *fontURL = [[NSBundle mainBundle] URLForResource:fontName withExtension:@"otf"];
    assert(fontURL);
    CFErrorRef error = NULL;
    if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL, kCTFontManagerScopeProcess, &error))
    {
        CFShow(error);
        abort();
    }
}

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        EWActivateFont(@"BlenderPro-Thin");
    }
    
    return NSApplicationMain(argc, argv);
}

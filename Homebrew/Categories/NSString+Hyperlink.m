//
//  NSAttributedString+Hyperlink.m
//  Homebrew
//
//  Created by travisjeffery on 11-05-13.
//  Copyright 2011 Travis Jeffery. All rights reserved.
//

#import "NSString+Hyperlink.h"

@implementation NSString (Hyperlink)
+ (id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];

    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    [attrString endEditing];
    
    return [[attrString copy] autorelease];
}
@end

//
//  NSAttributedString+Hyperlink.h
//  Homebrew
//
//  Created by travisjeffery on 11-05-13.
//  Copyright 2011 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Hyperlink)
    + (id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

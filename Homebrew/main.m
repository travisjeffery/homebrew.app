//
//  main.m
//  Homebrew
//
//  Created by travisjeffery on 11-05-13.
//  Copyright 2011 Travis Jeffery. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}

//
//  ITBlockingQueue.h
//  iOSToolkit
//
//  Created by Gilles Bordas on 13/07/12.
//  Copyright (c) 2012 Innovantic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITBlockingQueue : NSObject {
	
}

- (id)dequeueObjectWithTimeout:(NSTimeInterval)timeout;
- (void)queueObject:(id)object;
- (void)stop;

@end

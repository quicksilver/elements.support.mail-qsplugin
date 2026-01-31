//
//  MCOSerializable.h
//  mailcore2
//
//  Created by Dev on 07/01/21.
//  Copyright © 2021 MailCore. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MCOSerializable <NSObject>

- (instancetype)initWithDict:(NSDictionary *)dict;

- (void)updateWithDict:(NSDictionary *)dict;

- (NSDictionary *)toDict;

@end

@interface MCOSerializableUtils

+ (id<MCOSerializable>)objectFromDict:(NSDictionary *)dict;

- (NSDictionary *)dictFromObject:(id<MCOSerializable>)object;

@end

@interface NSArray (MCOSerializable)

+ (instancetype)fromSerialized:(NSArray *)items;

- (NSArray *)toSerialized;

@end

NS_ASSUME_NONNULL_END

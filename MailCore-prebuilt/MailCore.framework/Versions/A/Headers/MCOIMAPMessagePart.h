//
//  MCOIMAPMessagePart.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPMESSAGEPART_H

#define MAILCORE_MCOIMAPMESSAGEPART_H

/** Represents a message part. */

#import <MailCore/MCOAbstractMessagePart.h>

#import <MailCore/MCOSerializable.h>

@interface MCOIMAPMessagePart : MCOAbstractMessagePart <NSCoding, MCOSerializable>

/** A part identifier is of the form 1.2.1*/
@property (nonatomic, copy) NSString * partID;

@end

#endif

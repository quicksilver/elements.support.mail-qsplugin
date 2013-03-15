#import "QSEmailActions.h"
#import "QSMailMediator.h"

# define kEmailAction @"QSEmailAction"
# define kEmailItemAction @"QSEmailItemAction"
# define kEmailItemReverseAction @"QSEmailItemReverseAction"
# define kComposeEmailItemAction @"QSComposeEmailItemAction"
# define kComposeEmailItemReverseAction @"QSComposeEmailItemReverseAction"
# define MaxSubjectLength 74
#define kDirectEmailItemReverseAction @"QSDirectEmailItemReverseAction"

@implementation QSEmailActions

#pragma mark - Quicksilver Validation

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
    NSMutableArray *newActions=[NSMutableArray arrayWithCapacity:1];
	BOOL mediatorAvailable=[[QSReg tableNamed:kQSMailMediators]count];
    if ([[dObject types] containsObject:QSEmailAddressType]){
		
		if (mediatorAvailable){
			[newActions addObject:kEmailItemAction];
			[newActions addObject:kComposeEmailItemAction];
		}
        [newActions addObject:kEmailAction];
    }
    else if (mediatorAvailable && ([[dObject types] containsObject:NSFilenamesPboardType] && [dObject validPaths])
             || ([[dObject types] containsObject:NSStringPboardType] && ![[dObject types] containsObject:NSFilenamesPboardType])){
        [newActions addObject:kEmailItemReverseAction];
        [newActions addObject:kComposeEmailItemReverseAction];
    }
    return newActions;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	if ([action isEqualToString:kEmailItemAction] || [action isEqualToString:kComposeEmailItemAction]){
		return nil;
	}else if ([action isEqualToString:kEmailItemReverseAction] ||[action isEqualToString:kDirectEmailItemReverseAction] || [action isEqualToString:kComposeEmailItemReverseAction]){
		NSMutableArray *objects=[QSLib scoredArrayForString:nil inSet:[QSLib arrayForType:QSEmailAddressType]];
		return [NSArray arrayWithObjects:[NSNull null],objects,nil];
	}
	return nil;
}

- (NSImage *)iconForAction:(NSString *)actionID
{
    id<QSMailMediator> mediator = [QSReg QSMailMediator];
	if ([(QSMailMediator *)mediator respondsToSelector:@selector(iconForAction:)]) {
		return [mediator iconForAction:actionID];
	}
	return nil;
}

#pragma mark - Quicksilver Actions

- (QSObject *) sendEmailTo:(QSObject *)dObject{
	[self composeEmailTo:dObject withItem:nil sendNow:NO direct:NO];
    return nil;
}

- (QSObject *) sendEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject
{
    return [self composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject sendNow:(BOOL)YES direct:NO];
}

- (QSObject *) sendDirectEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject
{
    return [self composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject sendNow:(BOOL)YES direct:YES];
}

- (QSObject *) composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject
{
    return [self composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject sendNow:(BOOL)NO direct:NO];
}

- (QSObject *)composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject sendNow:(BOOL)sendNow direct:(BOOL)direct
{
	NSString *subject = nil;
	NSString *body = nil;
	NSArray *attachments = nil;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([iObject containsType:QSFilePathType]) {
		subject = [NSString stringWithFormat:[defaults objectForKey:@"QSMailActionFileSubject"], [iObject name]];
		body = [[NSString stringWithFormat:[defaults objectForKey:@"QSMailActionFileBody"], [iObject name]]stringByAppendingString:@"\n\n"];
		attachments = [iObject arrayForType:QSFilePathType];
	} else if ([[iObject types] containsObject:NSStringPboardType]) {
		NSString *string = [iObject stringValue];
		NSString *delimiter = @"\n";
		NSArray *components = [string componentsSeparatedByString:delimiter];
		if (![components count] < 2) {
			delimiter = @">>";
			components = [string componentsSeparatedByString:delimiter];
		}
		subject = [[components objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([subject length] > MaxSubjectLength) {
			subject = [subject substringToIndex:MaxSubjectLength];
		}
		if ([components count]>1) {
			body = [[components subarrayWithRange:NSMakeRange(1, [components count] - 1)] componentsJoinedByString:@"\n"];
		} else {
			body = [iObject stringValue];
		}
		body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	} else if (!iObject) {
		subject = @"";
		body = @"";
	}

	CTCoreAddress *from = [self defaultEmailAddress];
	if (direct) {
		NSMutableSet *addresses = [NSMutableSet set];
		NSString *name = nil;
		for (QSObject *recipient in [dObject splitObjects]) {
			name = [recipient name] ? [recipient name] : @"";
			[addresses addObject:[CTCoreAddress addressWithName:[recipient name] email:[recipient objectForType:QSEmailAddressType]]];
		}
		[self sendMessageTo:addresses from:from subject:subject body:body attachments:attachments sendNow:sendNow];
	} else {
		// mail mediators don't use MailCore types - convert before pasing info along
		NSString *fromString = nil;
		if ([from name]) {
			fromString = [NSString stringWithFormat:@"%@ <%@>", [from name], [from email]];
		} else {
			fromString = [from email];
		}
		[[QSMailMediator defaultMediator] sendEmailTo:[dObject arrayForType:QSEmailAddressType] from:fromString subject:subject body:body attachments:attachments sendNow:sendNow];
	}
	return nil;
}

# pragma mark - Helper Methods

- (CTCoreAddress *)defaultEmailAddress
{
	/* If the user puts either "Home" or "Work" as their custom from address,
	   look up the corresponding entry in their Contacts. Otherwise, just use
	   the supplied address.
	*/
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *whichAddress = [defaults objectForKey:@"QSMailActionCustomFrom"], *senderName = @"", *senderAddress = nil;
	if ([[whichAddress lowercaseString] isEqualToString:@"home"] || [[whichAddress lowercaseString] isEqualToString:@"work"]) {
		NSString *labelType = nil;
		if ([[whichAddress lowercaseString] isEqualToString:@"home"]) {
			labelType = kABEmailHomeLabel;
		} else {
			labelType = kABEmailWorkLabel;
		}
        NSArray *mes = nil;
        if ([NSApplication isMountainLion]) {
            mes = [[[ABAddressBook sharedAddressBook] me] linkedPeople];
        } else {
            mes = @[[[ABAddressBook sharedAddressBook] me]];
        }
        for (ABPerson *me in mes) {
            for (NSUInteger i = 0; i < [(ABMultiValue *)[me valueForProperty:kABEmailProperty] count]; i++) {
                if ([[(ABMultiValue *)[me valueForProperty:kABEmailProperty] labelAtIndex:i] isEqualToString:labelType]) {
                    senderAddress = [(ABMultiValue *)[me valueForProperty:kABEmailProperty] valueAtIndex:i];
                    senderName = [NSString stringWithFormat:@"%@ %@", [me valueForProperty:kABFirstNameProperty], [me valueForProperty:kABLastNameProperty]];
                    break;
                }
            }
            if (senderAddress) {
                break;
            }
        }
	} else {
		senderAddress = whichAddress;
	}
	return [CTCoreAddress addressWithName:senderName email:senderAddress];
}

- (void) sendMessageTo:(NSSet *)addresses from:(CTCoreAddress *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
    id<QSMailMediator> mediator = [QSReg QSMailMediator];
	if ([(QSMailMediator *)mediator respondsToSelector:@selector(smtpServerDetails)]) {
		// set up the message
		CTCoreMessage *message = [[CTCoreMessage alloc] init];
		[message setTo:addresses];
		[message setFrom:[NSSet setWithObject:sender]];
		[message setSubject:subject];
		// TODO: set X-Mailer to "Quicksilver VERSION"
		[message setBody:body];
		CTCoreAttachment *attachment = nil;
		for (NSString *path in pathArray) {
			attachment = [[CTCoreAttachment alloc] initWithContentsOfFile:path];
			[message addAttachment:attachment];
			[attachment release];
		}
		
		// set up the connection
		NSDictionary *serverDetails = [mediator smtpServerDetails];
		NSString *server = [serverDetails objectForKey:QSMailMediatorServer];
		if (!server) {
			// can't continue without an SMTP server
			QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"MailMediatorMissingServerNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, @"The chosen e-mail handler does not provide an SMTP server.", QSNotifierText, nil]);
			return;
		}
		NSUInteger port = [serverDetails objectForKey:QSMailMediatorPort] ? [[serverDetails objectForKey:QSMailMediatorPort] integerValue] : 25;
		BOOL tls = [[serverDetails objectForKey:QSMailMediatorTLS] isEqualToString:@"YES"];
		BOOL authn = [[serverDetails objectForKey:QSMailMediatorAuthenticate] isEqualToString:@"YES"];
		NSString *username = [serverDetails objectForKey:QSMailMediatorUsername];
		NSString *password = [serverDetails objectForKey:QSMailMediatorPassword];
		//NSLog(@"params - s: %@, p: %ld, u: %@, p: %@, tls: %d, auth: %d", server, (long)port, username, @"obscured", tls, authn);
		
		// send the message
		NSError *error;
		BOOL sent = [CTSMTPConnection sendMessage:message server:server username:username password:password port:port useTLS:tls useAuth:authn error:&error];
		[message release];
		if ( !sent )
		{
			NSString *errorMessage = [NSString stringWithFormat:@"Message could not be sent: %@", [error localizedDescription]];
			NSLog(@"%@", errorMessage);
			QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"SendEmailMessageFailedNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, errorMessage, QSNotifierText, nil]);
		}
		else{
			NSSound *sound=[[[NSSound alloc] initWithContentsOfFile:@"/Applications/Mail.app/Contents/Resources/Mail Sent.aiff" byReference:YES]autorelease];
			[sound play];
		}
	} else {
		NSLog(@"Mail mediator does not provide SMTP server details.");
		QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"MailMediatorMissingDetailsNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, @"The chosen e-mail handler does not provide SMTP server details.", QSNotifierText, nil]);
	}
}

@end

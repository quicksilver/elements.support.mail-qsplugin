#import "QSEmailActions.h"
#import "QSMailMediator.h"
#import <AddressBook/AddressBook.h>

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
    else if (mediatorAvailable && ([[dObject types] containsObject:QSFilePathType] && [dObject validPaths])
             || ([[dObject types] containsObject:QSTextType] && ![[dObject types] containsObject:QSFilePathType])){
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
    id <QSMailMediator> mediator = [QSReg QSMailMediator];
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
	} else if ([[iObject types] containsObject:QSTextType]) {
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

	MCOAddress *from = [[QSMailMediator defaultMediator] defaultEmailAddress];
	if (direct) {
		NSMutableArray *addresses = [NSMutableArray array];
		NSString *name = nil;
		for (QSObject *recipient in [dObject splitObjects]) {
			name = [recipient name] ? [recipient name] : @"";
			[addresses addObject:[MCOAddress addressWithDisplayName:[recipient name] mailbox:[recipient objectForType:QSEmailAddressType]]];
		}
		[self sendMessageTo:addresses from:from subject:subject body:body attachments:attachments sendNow:sendNow];
	} else {
		// mail mediators don't use MailCore types - convert before pasing info along
		NSString *fromString = nil;
		if ([from displayName]) {
			fromString = [NSString stringWithFormat:@"%@ <%@>", [from displayName], [from mailbox]];
		} else {
			fromString = [from mailbox];
		}
		[[QSMailMediator defaultMediator] sendEmailTo:[dObject arrayForType:QSEmailAddressType] from:fromString subject:subject body:body attachments:attachments sendNow:sendNow];
	}
	return nil;
}



- (void)sendMessageTo:(NSArray *)addresses from:(MCOAddress *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
    id<QSMailMediator> mediator = [QSReg QSMailMediator];
    
	if (![(QSMailMediator *)mediator respondsToSelector:@selector(smtpServerDetails)]) {
		NSLog(@"Mail mediator does not provide SMTP server details.");
		QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"MailMediatorMissingDetailsNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, @"The chosen e-mail handler does not provide SMTP server details.", QSNotifierText, nil]);
        return;
    }
    
    // set up the message
    MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
    [[builder header] setFrom:sender];
    [[builder header] setTo:addresses];
    [[builder header] setSubject:subject];
    // TODO: set X-Mailer to "Quicksilver VERSION"
    [builder setTextBody:body];
    MCOAttachment *attachment = nil;
    for (NSString *path in pathArray) {
        attachment = [MCOAttachment attachmentWithContentsOfFile:path];
        [builder addAttachment:attachment];
    }
    
    // set up the connection
    NSDictionary *serverDetails = [mediator smtpServerDetails];
    NSString *server = [serverDetails objectForKey:QSMailMediatorServer];
    if (!server) {
        // can't continue without an SMTP server
        QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"MailMediatorMissingServerNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, @"The chosen e-mail handler does not provide an SMTP server.", QSNotifierText, nil]);
        return;
    }
    unsigned int port = [serverDetails objectForKey:QSMailMediatorPort] ? [[serverDetails objectForKey:QSMailMediatorPort] unsignedIntValue] : 25;
    
    MCOConnectionType connType = 0;
    BOOL tls = [[serverDetails objectForKey:QSMailMediatorTLS] isEqualToString:@"YES"];
    switch (port) {
        case 465:
            connType = MCOConnectionTypeTLS;
            break;
            
        case 587:
            connType = MCOConnectionTypeStartTLS;
            break;
            
        default:
            connType = tls ? MCOConnectionTypeTLS : MCOConnectionTypeClear;
            break;
    }
    
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.hostname = server;
    smtpSession.port = port;
    
    BOOL authn = [[serverDetails objectForKey:QSMailMediatorAuthenticate] isEqualToString:@"YES"];
    if (authn) {
        NSString *username = [serverDetails objectForKey:QSMailMediatorUsername];
        NSString *password = [serverDetails objectForKey:QSMailMediatorPassword];
        if (!password) {
            QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"MailMediatorMissingServerNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, [NSString stringWithFormat:NSLocalizedStringForThisBundle(@"No password could be found for %@. Please check your login items in Keychain.app", @""), username], QSNotifierText, nil]);
            return;
        }
        smtpSession.username = username;
        smtpSession.password = password;
    }
    
    //NSLog(@"params - s: %@, p: %ld, u: %@, p: %@, tls: %d, auth: %d", server, (long)port, username, @"obscured", tls, authn);

    smtpSession.connectionType = connType;
    
    NSData * rfc822Data = [builder data];
    MCOSMTPSendOperation *sendOperation = [smtpSession sendOperationWithData:rfc822Data];
    
    [sendOperation start:^(NSError *error) {
        if(error) {
            NSString *errorMessage = [NSString stringWithFormat:@"Message could not be sent: %@", [error localizedDescription]];
            NSLog(@"%@", errorMessage);
            QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"SendEmailMessageFailedNotification", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver E-mail Support", QSNotifierTitle, errorMessage, QSNotifierText, nil]);
        } else {
            NSSound *sound=[[NSSound alloc] initWithContentsOfFile:@"/Applications/Mail.app/Contents/Resources/Mail Sent.aiff" byReference:YES];
            [sound play];
        }
    }];
    
}

@end

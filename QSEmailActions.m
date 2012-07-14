#import "QSEmailActions.h"
#import "QSMailMediator.h"

# define kEmailAction @"QSEmailAction"
# define kEmailItemAction @"QSEmailItemAction"
# define kEmailItemReverseAction @"QSEmailItemReverseAction"
# define kComposeEmailItemAction @"QSComposeEmailItemAction"
# define kComposeEmailItemReverseAction @"QSComposeEmailItemReverseAction"
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

#pragma mark - Quicksilver Actions

- (QSObject *) sendEmailTo:(QSObject *)dObject{
    NSArray *addresses=[dObject arrayForType:QSEmailAddressType];
	NSString *addressesString=[addresses componentsJoinedByString:@","];
	addressesString=[addressesString URLEncoding];
	NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@",addressesString]];
	if (!url) NSLog(@"Badurl: %@",[NSString stringWithFormat:@"mailto:%@",addressesString]);
	[[NSWorkspace sharedWorkspace] openURL:url];
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

- (QSObject *) composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject sendNow:(BOOL)sendNow direct:(BOOL)direct
{
    NSArray *addresses=[dObject arrayForType:QSEmailAddressType];
    NSString *subject=nil;
    NSString *body=nil;
    NSArray *attachments=nil;
//	iObject = (QSObject *)[iObject resolvedObject];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	NSString *from=[defaults objectForKey:@"QSMailActionCustomFrom"];
	if (![from length])from=nil;
    if ([iObject containsType:QSFilePathType]){
        subject=[NSString stringWithFormat:[defaults objectForKey:@"QSMailActionFileSubject"],[iObject name]];
        body=[[NSString stringWithFormat:[defaults objectForKey:@"QSMailActionFileBody"],[iObject name]]stringByAppendingString:@"\r\r"];
        attachments=[iObject arrayForType:QSFilePathType];
    } else if ([[iObject types] containsObject:NSStringPboardType]){
		NSString *string=[iObject stringValue];
		NSString *delimiter=@"\n";
		NSArray *components=[string componentsSeparatedByString:delimiter];
		if (![components count]<2){
			delimiter=@">>";
			components=[string componentsSeparatedByString:delimiter];
		}
		subject=[components objectAtIndex:0];
		if ([subject length]>255)subject=[subject substringToIndex:255];
		
		if ([components count]>1){
			body=[[components subarrayWithRange:NSMakeRange(1,[components count]-1)]componentsJoinedByString:@"\r"];
		}else{
			body=[iObject stringValue];
			
		}
	}
	
	//  QSMailMediator *mediator=[QSMailMediator sharedInstance];
	if (direct){
		[self sendDirectEmailTo:addresses from:from subject:subject body:body attachments:attachments sendNow:sendNow];
		
	}else{
		[[QSMailMediator defaultMediator]sendEmailTo:addresses from:from subject:subject body:body attachments:attachments sendNow:sendNow];
	}
	
	return nil;
}

# pragma mark - Helper Methods

- (NSString*)defaultEmailAddress
{
    NSDictionary *icDict = [(NSDictionary *) CFPreferencesCopyValue((CFStringRef) @"Version 2.5.4", (CFStringRef) @"com.apple.internetconfig", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
    return [[[icDict objectForKey:@"ic-added"] objectForKey:@"Email"] objectForKey:@"ic-data"];
}

- (void) sendDirectEmailTo:(NSArray *)addresses
				from:(NSString *)sender 
			 subject:(NSString *)subject 
				body:(NSString *)body 
		 attachments:(NSArray *)pathArray 
			 sendNow:(BOOL)sendNow
{
    
	//NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    //NSString* smtpFromAddress = from; //[defaultsstringForKey:PMXSMTPFromAddress];
    BOOL sent;
    NSMutableDictionary *headers;
    NSFileWrapper* fw;
    NSTextAttachment* ta;
	body=[body stringByAppendingString:@"\r\r"];
    NSMutableAttributedString* msg=[[[NSMutableAttributedString alloc]initWithString:body]autorelease];
	
	for (NSString *attachment in pathArray) {
		fw = [[[NSFileWrapper alloc] initWithPath:attachment]autorelease]; //initRegularFileWithContents:[attachment dataUsingEncoding:NSNonLossyASCIIStringEncoding]];
		[fw setPreferredFilename:[attachment lastPathComponent]];
		ta = [[[NSTextAttachment alloc] initWithFileWrapper:fw]autorelease];
		[msg appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];
	}
	
	
	headers = [NSMutableDictionary dictionary];
	[headers setObject:[addresses componentsJoinedByString:@","] forKey:@"To"];
	if (subject) [headers setObject:subject forKey:@"Subject"];
	if (sender)  [headers setObject:sender forKey:@"From"];
	[headers setObject:@"Quicksilver" forKey:@"X-Mailer"];
	[headers setObject:@"multipart/mixed" forKey:@"Content-Type"];
	[headers setObject:@"1.0" forKey:@"Mime-Version"];
	sent = [NSMailDelivery deliverMessage: msg
								  headers: headers
								   format: NSMIMEMailFormat
								 protocol: nil];
	
	//NSLog(@"headers %@",headers);
	if ( !sent )
	{
		NSBeep();
		NSLog(@"Send Failed");
	}
	else{
		NSSound *sound=[[[NSSound alloc] initWithContentsOfFile:@"/Applications/Mail.app/Contents/Resources/Mail Sent.aiff" byReference:YES]autorelease];
		[sound play];
	}
}

@end

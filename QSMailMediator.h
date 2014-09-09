#include <MailCore/MailCore.h>

#define emailsShareDomain(email1,email2) ![[[email1 componentsSeparatedByString:@"@"]lastObject]caseInsensitiveCompare:[[email2 componentsSeparatedByString:@"@"]lastObject]]
NSString *preferredMailMediatorID();
#define kQSMailMediators @"QSMailMediators"

// keys
#define QSMailMediatorServer @"Hostname"
#define QSMailMediatorPort @"PortNumber"
#define QSMailMediatorTLS @"UseTLS"
#define QSMailMediatorAuthenticate @"ShouldUseAuthentication"
#define QSMailMediatorUsername @"Username"
#define QSMailMediatorPassword @"Password"

@protocol QSMailMediator
- (void) sendEmailTo:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow;
- (NSDictionary *)smtpServerDetails;
/* smtpServerDetails keys (only QSMailMediatorServer is required)
     QSMailMediatorServer - the name or IP of the server (string)
     QSMailMediatorPort - the port to connect to (string)
     QSMailMediatorSSL - @"YES" or @"NO" (string)
     QSMailMediatorAuthenticate - @"YES" or @"NO" (string)
     QSMailMediatorUsername - username for authentication (string)
     QSMailMediatorPassword - password for authentication (string)
*/
- (NSImage *)iconForAction:(NSString *)actionID;
/* actions you can supply icons for:
     QSComposeEmailItemAction
     QSComposeEmailItemReverseAction
     QSEmailAction
     QSEmailItemAction
     QSEmailItemReverseAction
   You'll most likely just return the same one unconditionally.
*/
@end

@interface QSMailMediator : NSObject <QSMailMediator> {
    NSAppleScript *mailScript;
}
+ (id <QSMailMediator>)defaultMediator;
- (void) sendEmailTo:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow;
- (void) sendEmailWithScript:(NSAppleScript *)script to:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow;
- (NSAppleScript *)mailScript;
- (void)setMailScript:(NSAppleScript *)newMailScript;
- (NSString *)scriptPath;
@end

@interface QSRegistry (QSMailMediator)
- (id <QSMailMediator>)QSMailMediator;
- (NSString *)QSMailMediatorID;
@end
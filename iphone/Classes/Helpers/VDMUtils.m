#import "VDMUtils.h"

void ShowAlert(NSString *title, NSString *message) {
	if (![NSString isStringEmpty:message]) {
		UIAlertView *errorAlert = [[UIAlertView alloc] 
			initWithTitle:title
			message:message 
			delegate:nil 
			cancelButtonTitle:@"OK" 
			otherButtonTitles:nil];
		
		[errorAlert show];
		
		SafeRelease(errorAlert);
	}
}

#pragma mark -
#pragma mark UIView Categories
@implementation UIView (RSTLAditions)

-(void) addSubviewAnimated:(UIView *)view {
	view.alpha = 0;
	[self addSubview:view];
	[UIView animateWithDuration:0.4 animations:^{
		view.alpha = 1;
	}];
}

-(void) removeFromSuperviewAnimated {
	[UIView animateWithDuration:0.4 animations:^{
		self.alpha = 0;
	} completion:^(BOOL finished) {
		[self removeFromSuperview];
	}];
}

-(void) setOrigin:(CGPoint) newOrigin {
	CGRect frame = self.frame;
	frame.origin = newOrigin;
	self.frame = frame;
}

-(void) setSize:(CGSize) newSize {
	CGRect frame = self.frame;
	frame.size = newSize;
	self.frame = frame;
}

-(void) setHeight:(float) newHeight {
	CGRect frame = self.frame;
	frame.size.height = newHeight;
	self.frame = frame;
}

-(void) setWidth:(float) newWidth {
	CGRect frame = self.frame;
	frame.size.width = newWidth;
	self.frame = frame;
}

-(void) setX:(float) newX {
	CGRect frame = self.frame;
	frame.origin.x = newX;
	self.frame = frame;
}

-(void) setY:(float) newY {
	CGRect frame = self.frame;
	frame.origin.y = newY;
	self.frame = frame;
}

-(float) height {
	return self.bounds.size.height;
}

-(float) width {
	return self.bounds.size.width;
}

-(float) x {
	return self.frame.origin.x;
}

-(float) rightX {
	return self.x + self.width;
}

-(float) y {
	return self.frame.origin.y;
}

-(float) lowerY {
	return [self y] + [self height];
}

-(void) addTapGesture:(id) target action:(SEL) action tapCount:(int) tapCount {
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
	tap.numberOfTapsRequired = tapCount;
	[self addGestureRecognizer:tap];
	SafeRelease(tap);
}

-(void) clearGestureRecognizers {
	for (UIGestureRecognizer* gesture in [self gestureRecognizers]) {
		[self removeGestureRecognizer:gesture];
	}
}
@end

#pragma mark -
#pragma mark UIResponder Categories
@implementation UIResponder (Aditions)
-(UIViewController *) parentController {
	UIResponder *result = [self nextResponder];
	
	if (result && ![result isKindOfClass:[UIViewController class]]) {
		do {
			result = [result nextResponder];
		} while (result && ![result isKindOfClass:[UIViewController class]]);
	}
	
	return (UIViewController *)result;
}

-(UIViewController *) findTopRootViewController {
	UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
	
	if (topWindow.windowLevel != UIWindowLevelNormal) {
		NSArray *windows = [[UIApplication sharedApplication] windows];
		
		for(topWindow in windows) {
			if (topWindow.windowLevel == UIWindowLevelNormal) {
				break;
			}
		}
	}
	
	UIView *rootView = [[topWindow subviews] objectAtIndex:0];	
	id nextResponder = [rootView nextResponder];
	
	return [nextResponder isKindOfClass:[UIViewController class]]
	? nextResponder
	: nil;
}

-(UIViewController *) findControllerWithNavigationController {
	UIResponder *result = [self nextResponder];
	
	if (result && [result isKindOfClass:[UIViewController class]]) {
		if (((UIViewController *)result).navigationController) {
			return (UIViewController *)result;
		}
	}
	
	if (result && ![result isKindOfClass:[UIViewController class]]) {
		do {
			result = [result nextResponder];
			
			if (result && [result isKindOfClass:[UIViewController class]]) {
				if (((UIViewController *)result).navigationController) {
					break;
				}
			}
			
		} while (result && ![result isKindOfClass:[UIViewController class]]);
	}
	
	return (UIViewController *)result;
}

@end

#pragma mark -
#pragma mark NSMutableString Categories
@implementation NSMutableString (Additions)
-(void) replace:(NSString *) stringToReplace with:(NSString *) replacement {
	if ([NSString isStringEmpty:replacement]) {
		replacement = @"";
	}
	
	[self replaceOccurrencesOfString:stringToReplace withString:replacement options:0 range:NSMakeRange(0, self.length)];
}
@end

#pragma mark -
#pragma mark UIWebView Categories
@implementation UIWebView (Additions)
-(void) disableScrollShadow {
	UIView *scroller = [self.subviews objectAtIndex:0];
	
	for (UIView *subView in [scroller subviews]) {
		if ([subView isKindOfClass:[UIImageView class]]) {
			subView.hidden = YES;
		}
	}
}

-(void) disableBounce {
	for (id subview in self.subviews) {
		if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
			((UIScrollView *)subview).bounces = NO;	
		}
	}
}

@end

#pragma mark -
#pragma mark UIImage Categories
@implementation UIImage(Additions)
-(UIImage *) resize:(CGSize) size {
	UIGraphicsBeginImageContext(size);  
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();        
    UIGraphicsEndImageContext();
    return newThumbnail;
}
@end

#pragma mark -
#pragma mark NSString Categories
@implementation NSString (Additions)
+(BOOL) isStringEmpty:(NSString *)s {
	return !s || [s isEqualToString:@""];
}

-(NSURL*) toURL {
	return [NSURL URLWithString:self];
}

-(NSURL *) toFileURL {
	return [NSURL fileURLWithPath:self];
}

-(BOOL) contains:(NSString *) s {
	return [self rangeOfString:s].location != NSNotFound;
}

@end
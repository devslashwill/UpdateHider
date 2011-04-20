#import "HeaderView.h"

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]

@implementation HeaderView

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = RGB(173, 173, 176);
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(49, 444, 221, 22)];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = RGB(58, 58, 58);
		label.shadowColor = RGB(194, 194, 194);
		label.shadowOffset = CGSizeMake(0, 1);
		label.font = [UIFont boldSystemFontOfSize:17.0f];
		label.text = @"Pull down to toggle editing";
		[self addSubview:label];
		[label release];
		
		UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 479, 320, 1)];
		line.backgroundColor = RGB(187, 187, 189);
		[self addSubview:line];
		[line release];
	}
	return self;
}

@end

//
//  H264ViewController.h
//  h264demo
//


#import <UIKit/UIKit.h>

@interface H264ViewController : UIViewController{
    IBOutlet UIButton*          btn_start;//
    IBOutlet UILabel*           label_status;//
    IBOutlet UIImageView*       VideoView;
    IBOutlet UIImageView*       VideoViewOther;
}
@property (nonatomic, retain)	UIButton		*btn_start;
@property (nonatomic, retain)	UILabel         *label_status;
@property (nonatomic, retain)	UIImageView     *VideoView;
@property (nonatomic, retain)   UIImageView     *VideoViewOther;
- (IBAction)start: (id) sender;
@end
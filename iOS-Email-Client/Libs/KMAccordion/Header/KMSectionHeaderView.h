//
//  KMSectionHeaderView.h
//  KMAccordionTableView
//
//  Created by Klevison Matias on 5/1/14.
//
//

#import <UIKit/UIKit.h>
#import "KMAppearence.h"

@class KMSectionHeaderView;

@protocol KMSectionHeaderViewDelegate <NSObject>

@optional

- (void)sectionHeaderView:(KMSectionHeaderView *)sectionHeaderView selectedSectionAtIndex:(NSInteger)section;

@end

@interface KMSectionHeaderView : UITableViewHeaderFooterView

@property(nonatomic, weak) IBOutlet UILabel *labelName;
@property(nonatomic, weak) IBOutlet UILabel *labelWeight;
@property(nonatomic, weak) IBOutlet UILabel *labelTotalOpens;
@property(nonatomic, weak) IBOutlet UILabel *labelTotalDownloads;
@property(nonatomic, weak) IBOutlet UIImageView *imageViewFile;
@property(nonatomic, weak) IBOutlet UIButton *disclosureButton;
@property(nonatomic, weak) IBOutlet UIView *viewSeparator;
@property(nonatomic) NSInteger section;
@property UITapGestureRecognizer *tapGesture;
@property(weak) id <KMSectionHeaderViewDelegate> delegate;
@property(nonatomic, strong) KMAppearence *headerSectionAppearence;

- (void)addOverHeaderSubView:(UIView *)view;
- (IBAction)toggleOpen:(id)sender;
- (void)disableButton;

@end


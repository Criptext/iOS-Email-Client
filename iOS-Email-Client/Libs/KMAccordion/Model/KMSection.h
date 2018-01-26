//
//  KMSection.h
//  KMAccordionTableView
//
//  Created by Klevison Matias on 5/1/14.
//
//

#import <UIKit/UIKit.h>

@class KMSectionHeaderView;

@interface KMSection : NSObject <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate>

@property(getter = isOpen) BOOL open;
@property UIView *view;
@property UIView *overlayView;
@property KMSectionHeaderView *headerView;
@property(nonatomic, copy) NSString *title;
@property double size;
@property NSString *filesize;
@property NSInteger totalOpens;
@property NSInteger totalDownloads;
@property UIImage *imageFile;
@property(nonatomic, copy) UIColor *backgroundColor;
@property NSInteger sectionIndex;
@property NSArray *opensList;

@end

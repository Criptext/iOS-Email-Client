//
//  KMSection.m
//  KMAccordionTableView
//
//  Created by Klevison Matias on 5/1/14.
//
//

#import "KMSection.h"
#import "iOS_Email_Client-Swift.h"

@implementation KMSection

- (instancetype)init
{
    self = [super init];
    if (self) {
        _open = NO;
    }
    return self;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _opensList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    
    OpensViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"opensCell" forIndexPath:indexPath];

    Open *open = _opensList[indexPath.row];

    cell.localtionLabel.text = open.location;

    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:open.timestamp];
    cell.dateLabel.text = [DateUtils beatyDate:date];
    
    if(open.type == 1){
        cell.typeLabel.text = @"Open";
    }
    else{
        cell.typeLabel.text = @"Download";
    }
    
    return cell;

}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return CGSizeMake(160, 82);

}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;;
}

@end

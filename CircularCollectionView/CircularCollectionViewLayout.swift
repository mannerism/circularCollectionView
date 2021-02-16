//
//  CircularCollectionViewLayout.swift
//  CircularCollectionView
//
//  Created by Yu Juno on 2021/02/16.
//  Copyright © 2021 Rounak Jain. All rights reserved.
//

import UIKit

class CircularCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
	var anchorPoint = CGPoint(x: 0.5, y: 0.5)
	var angle: CGFloat = 0 {
		didSet {
			zIndex = Int(angle * 1000000) /// 우측 카드가 좌측 카드 위에 얹혀져 보이게 하는 효과를 가지고 온다.
			transform = CGAffineTransform(rotationAngle: angle) /// 주어진 각도에 맞게 회전을 시킨다.
		}
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let copiedAttributes: CircularCollectionViewLayoutAttributes = super.copy(with: zone) as! CircularCollectionViewLayoutAttributes
		copiedAttributes.anchorPoint = self.anchorPoint
		copiedAttributes.angle = self.angle
		return copiedAttributes
	}
}


class CircularCollectionViewLayout: UICollectionViewLayout {
	let itemSize = CGSize(width: 133, height: 173)
	var angleAtExtreme: CGFloat {
		return collectionView!.numberOfItems(inSection: 0) > 0
			? -CGFloat(collectionView!.numberOfItems(inSection: 0) - 1) * anglePerItem
			: 0
	}
	
	var angle: CGFloat {
		return angleAtExtreme * collectionView!.contentOffset.x / (collectionView!.contentSize.width - collectionView!.bounds.width)
	}
	
	var radius: CGFloat = 500 {
		didSet {
			/// When the radius changes, you recalculate everything
			invalidateLayout()
		}
	}
	
	var anglePerItem: CGFloat {
		/// Arc tangent 를 사용해서 높이와 넓이가 주어졌을때 각도를 계산할 수 있다.
		return atan(itemSize.width / radius)
	}
	
	override var collectionViewContentSize: CGSize {
		return CGSize(
			width: CGFloat(collectionView!.numberOfItems(inSection: 0)) * itemSize.width,
			height: collectionView!.bounds.height)
	}
	
	override class var layoutAttributesClass: AnyClass {
		return CircularCollectionViewLayoutAttributes.self
	}
	
	var attributesList = [CircularCollectionViewLayoutAttributes]()
	
	override func prepare() {
		super.prepare()
		/// UICollectionViewLayout이 콜 될때 가장 먼저 콜되는 부분
		/// invalidateLayout()이 콜 될때도 가장 먼저 콜 되는 부분
		/// Layout 프로세스 중 가장 중요한 부분. 왜냐면 layout attributes를 만들고 저장하는 부분이기 때문에
		
		let centerX = collectionView!.contentOffset.x + (collectionView!.bounds.width / 2.0)
		let anchorPointY = ((itemSize.height / 2) + radius) / itemSize.height
		
		/// optimization -- bonus
		
		/// 1 theta를 구하는 공식.
		let theta = atan2(
			(collectionView!.bounds.width / 2),
			radius + (itemSize.height / 2) - collectionView!.bounds.height / 2
		)
		
		/// 2 start and end 인덱스를 초기화
		var startIndex = 0
		var endIndex = collectionView!.numberOfItems(inSection: 0) - 1
		
		/// 3
		/// 만약 angle이 -theta(왼쪽 각도) 보다 작으면 스크린에서 벗어났다고 판단 한다.
		/// 따라서 이제 맨 처음(좌측)에 보이는 아이템 인덱스는 theta - angle / anglePerItem이 된다.
		if (angle < -theta) {
			startIndex = Int(floor((-theta - angle)) / anglePerItem)
		}
		
		/// 4
		endIndex = min(endIndex, Int(ceil((theta - angle) / anglePerItem)))
		
		/// 5
		if (endIndex < startIndex) {
			endIndex = 0
			startIndex = 0
		}

		
		attributesList = (startIndex...endIndex).map { (i) -> CircularCollectionViewLayoutAttributes in
			
			/// 1
			let indexPath = IndexPath(item: i, section: 0)
			let attributes = CircularCollectionViewLayoutAttributes(forCellWith: indexPath)
			attributes.size = self.itemSize
			
			/// 2
			attributes.center = CGPoint(x: centerX, y: self.collectionView!.bounds.midY)
			
			/// 3
			attributes.angle = self.angle + self.anglePerItem * CGFloat(i)
			
			attributes.anchorPoint = CGPoint(x: 0.5, y: anchorPointY)
			return attributes
		}
	}
	
	override func layoutAttributesForElements(
		in rect: CGRect
	) -> [UICollectionViewLayoutAttributes]? {
		return attributesList
	}
	
	override func layoutAttributesForItem(
		at indexPath: IndexPath
	) -> UICollectionViewLayoutAttributes? {
		return attributesList[indexPath.row]
	}
	
	override func shouldInvalidateLayout(
		forBoundsChange newBounds: CGRect
	) -> Bool {
		/// 스크롤을 할때마다 layout을 invalidate한다는 의미, 즉 prepare()가 콜이 된다는 것.
		return true
	}
}

